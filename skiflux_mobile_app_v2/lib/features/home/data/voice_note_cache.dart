/// Local cache for remote voice-note audio.
///
/// The comment widget plays from a **local file** — `PlayerController` needs a
/// path, not a URL. A note recorded this session already has one, but the same
/// note reloaded from the server arrives as `audio_url` only, so it rendered a
/// dead row: static bars, no play button. That is the whole of defect #13's
/// remote half.
///
/// This downloads the URL once into the app cache directory and returns the
/// path. Keyed by URL and `autoDispose`-with-`keepAlive`, so replaying the same
/// note — or scrolling it out of view and back — reuses the file instead of
/// re-fetching it.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../shared/error_handling/error_handler.dart';

/// Resolves [audioUrl] to a playable local file path, downloading it on first
/// use. Throws a [SkifluxFailure] the sheet can surface if the fetch fails —
/// the row then stays on its static waveform rather than pretending to play.
final voiceNoteCacheProvider = FutureProvider.autoDispose
    .family<String, String>((ref, audioUrl) async {
      // A downloaded note outlives its provider's listeners: the file is on
      // disk either way, and re-resolving the same URL should be free.
      ref.keepAlive();

      final dir = await getApplicationCacheDirectory();
      final cacheDir = Directory('${dir.path}/voice_notes');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      // Hash the URL rather than reuse its last path segment: signed media URLs
      // repeat generic names ("audio.m4a") across different notes, which would
      // make one note play another's audio.
      final name = _cacheKey(audioUrl);
      final file = File('${cacheDir.path}/$name${_extension(audioUrl)}');
      if (await file.exists() && await file.length() > 0) return file.path;

      try {
        // A bare Dio, not `apiClientProvider`: media URLs are absolute and
        // pre-signed, so the API base URL and auth header do not apply.
        final response = await Dio().get<List<int>>(
          audioUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data;
        if (bytes == null || bytes.isEmpty) {
          throw const SkifluxFailure(SkifluxErrorKind.voicenoteFailed);
        }
        await file.writeAsBytes(bytes, flush: true);
        return file.path;
      } on SkifluxFailure {
        rethrow;
      } catch (error, stackTrace) {
        // A half-written file would be cached as valid on the next attempt.
        if (await file.exists()) await file.delete();
        throw SkifluxFailure(
          SkifluxErrorKind.voicenoteFailed,
          cause: error,
          stackTrace: stackTrace,
        );
      }
    });

/// Filename-safe key for [url].
///
/// A plain FNV-1a hash, not `package:crypto` — that is only a transitive
/// dependency here, and this is a cache filename, not a security boundary. The
/// URL length is mixed in so two URLs colliding on the hash alone still land on
/// different files.
String _cacheKey(String url) {
  var hash = 0x811c9dc5;
  for (final unit in url.codeUnits) {
    hash = (hash ^ unit) & 0xffffffff;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return '${hash.toRadixString(16)}_${url.length}';
}

/// File extension from the URL path, defaulting to `.m4a` (what the recorder
/// writes). The player picks its decoder from the extension, so a missing one
/// is worse than a guess.
String _extension(String url) {
  final path = Uri.tryParse(url)?.path ?? '';
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return '.m4a';
  final ext = path.substring(dot);
  return ext.length <= 5 ? ext : '.m4a';
}
