/// Download an HLS (`.m3u8`) presentation for offline playback.
///
/// A bare `Dio().download(video_url)` only saved the playlist (~1KB) while
/// every `#EXTINF` segment URI still pointed at the CDN — that is the
/// "1KB link file" users saw. This fetches the media playlist, every
/// segment (and AES key URI when present), rewrites the playlist to
/// relative local paths, and returns the path of the playable local
/// `.m3u8`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Result of a successful HLS offline package.
class HlsOfflinePackage {
  const HlsOfflinePackage({
    required this.playlistPath,
    required this.bytes,
  });

  /// Absolute path of the rewritten local media playlist.
  final String playlistPath;

  /// Sum of bytes written (playlist + segments + keys).
  final int bytes;
}

typedef HlsProgress = void Function(double fraction, int receivedBytes);

/// Download [playlistUrl] into [destDir], reporting [onProgress] 0–1.
///
/// Throws if the playlist cannot be parsed, has no segments, or a transfer
/// fails. Partial files under [destDir] are the caller's to clean up.
Future<HlsOfflinePackage> downloadHlsOffline({
  required String playlistUrl,
  required Directory destDir,
  required Dio dio,
  CancelToken? cancelToken,
  Map<String, dynamic>? headers,
  HlsProgress? onProgress,
}) async {
  if (!await destDir.exists()) {
    await destDir.create(recursive: true);
  }

  final rootText = await _getText(
    dio,
    playlistUrl,
    headers: headers,
    cancelToken: cancelToken,
  );
  if (!_looksLikeHls(rootText)) {
    throw StateError('Not an HLS playlist');
  }

  var mediaUrl = playlistUrl;
  var mediaText = rootText;

  if (_isMasterPlaylist(rootText)) {
    final variant = _pickVariant(rootText, playlistUrl);
    if (variant == null) {
      throw StateError('HLS master playlist has no playable variants');
    }
    mediaUrl = variant;
    mediaText = await _getText(
      dio,
      mediaUrl,
      headers: headers,
      cancelToken: cancelToken,
    );
  }

  final base = Uri.parse(mediaUrl);
  final lines = const LineSplitter().convert(mediaText);
  final outLines = <String>[];
  final downloads = <({String url, String fileName})>[];

  for (final raw in lines) {
    final line = raw.trimRight();
    final trimmed = line.trim();

    if (trimmed.startsWith('#EXT-X-KEY:') || trimmed.startsWith('#EXT-X-MAP:')) {
      final isKey = trimmed.startsWith('#EXT-X-KEY:');
      final localName = isKey
          ? 'key_${downloads.length}.key'
          : 'init_${downloads.length}.mp4';
      final rewritten = _rewriteAttributeUri(
        trimmed,
        base,
        localName: localName,
        onUri: (absolute) => downloads.add((url: absolute, fileName: localName)),
      );
      outLines.add(rewritten);
      continue;
    }

    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      outLines.add(line);
      continue;
    }

    // Media segment URI.
    final absolute = base.resolve(trimmed).toString();
    final localName =
        'seg_${downloads.length.toString().padLeft(5, '0')}${_extensionOf(absolute)}';
    downloads.add((url: absolute, fileName: localName));
    outLines.add(localName);
  }

  if (downloads.isEmpty) {
    throw StateError('HLS playlist has no segments');
  }

  var received = 0;
  for (var i = 0; i < downloads.length; i++) {
    final item = downloads[i];
    final path = '${destDir.path}/${item.fileName}';
    await dio.download(
      item.url,
      path,
      cancelToken: cancelToken,
      options: Options(headers: headers),
    );
    final len = await File(path).length();
    received += len;
    onProgress?.call(((i + 1) / downloads.length).clamp(0.0, 1.0), received);
  }

  final playlistPath = '${destDir.path}/index.m3u8';
  final playlistBody = '${outLines.join('\n')}\n';
  await File(playlistPath).writeAsString(playlistBody, flush: true);
  received += playlistBody.length;

  debugPrint(
    'HLS offline: ${downloads.length} parts → $playlistPath ($received bytes)',
  );

  return HlsOfflinePackage(playlistPath: playlistPath, bytes: received);
}

bool isHlsUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  return path.contains('.m3u8');
}

bool _looksLikeHls(String text) {
  final head = text.trimLeft();
  return head.startsWith('#EXTM3U');
}

bool _isMasterPlaylist(String text) => text.contains('#EXT-X-STREAM-INF');

/// Pick a mid/high variant — prefer the highest bandwidth under ~3 Mbps so
/// offline packs stay reasonable on cellular-sized storage.
String? _pickVariant(String masterText, String masterUrl) {
  final base = Uri.parse(masterUrl);
  final lines = const LineSplitter().convert(masterText);
  final variants = <({int bandwidth, String url})>[];

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (!line.startsWith('#EXT-X-STREAM-INF:')) continue;
    final bwMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
    final bandwidth = int.tryParse(bwMatch?.group(1) ?? '') ?? 0;
    for (var j = i + 1; j < lines.length; j++) {
      final uriLine = lines[j].trim();
      if (uriLine.isEmpty) continue;
      if (uriLine.startsWith('#')) break;
      variants.add((
        bandwidth: bandwidth,
        url: base.resolve(uriLine).toString(),
      ));
      break;
    }
  }

  if (variants.isEmpty) return null;
  variants.sort((a, b) => a.bandwidth.compareTo(b.bandwidth));
  const cap = 3000000; // ~3 Mbps
  final underCap = variants.where((v) => v.bandwidth > 0 && v.bandwidth <= cap);
  if (underCap.isNotEmpty) return underCap.last.url;
  return variants[variants.length ~/ 2].url;
}

String _rewriteAttributeUri(
  String tagLine,
  Uri base, {
  required String localName,
  required void Function(String absolute) onUri,
}) {
  final match = RegExp(r'URI="([^"]+)"').firstMatch(tagLine);
  if (match == null) return tagLine;
  final absolute = base.resolve(match.group(1)!).toString();
  onUri(absolute);
  return tagLine.replaceFirst(match.group(0)!, 'URI="$localName"');
}

Future<String> _getText(
  Dio dio,
  String url, {
  Map<String, dynamic>? headers,
  CancelToken? cancelToken,
}) async {
  final response = await dio.get<String>(
    url,
    cancelToken: cancelToken,
    options: Options(
      headers: headers,
      responseType: ResponseType.plain,
    ),
  );
  final data = response.data;
  if (data == null || data.isEmpty) {
    throw StateError('Empty HLS playlist at $url');
  }
  return data;
}

String _extensionOf(String url) {
  final path = Uri.tryParse(url)?.path ?? '';
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return '.ts';
  final ext = path.substring(dot);
  if (ext.length > 5) return '.ts';
  return ext;
}
