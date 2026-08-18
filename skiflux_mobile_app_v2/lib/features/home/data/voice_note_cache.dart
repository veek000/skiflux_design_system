/// Local cache for remote voice-note audio.
///
/// The comment widget plays from a **local file** — `PlayerController` needs a
/// path, not a URL. A note recorded this session already has one, but the same
/// note reloaded from the server arrives as `audio_url` only, so it rendered a
/// dead row: static bars, no play button.
///
/// This downloads the URL once into the app cache directory and returns the
/// path. Keyed by URL and `autoDispose`-with-`keepAlive`, so replaying the same
/// note — or scrolling it out of view and back — reuses the file instead of
/// re-fetching it.
///
/// Relative URLs are resolved against [EnvConfig.apiBaseUrl]. Same-origin
/// fetches send the session bearer token — bare Dio used to 401 those and
/// leave the note unplayable.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../config/env_config.dart';
import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/token_store.dart';

/// Resolves [audioUrl] to a playable local file path, downloading it on first
/// use. Throws a [SkifluxFailure] the sheet can surface if the fetch fails —
/// the row then stays on its static waveform rather than pretending to play.
final voiceNoteCacheProvider = FutureProvider.autoDispose
    .family<String, String>((ref, audioUrl) async {
      // A downloaded note outlives its provider's listeners: the file is on
      // disk either way, and re-resolving the same URL should be free.
      ref.keepAlive();

      final absolute = resolveVoiceNoteUrl(audioUrl);
      if (absolute == null) {
        throw const SkifluxFailure(SkifluxErrorKind.voicenoteFailed);
      }

      final dir = await getApplicationCacheDirectory();
      final cacheDir = Directory('${dir.path}/voice_notes');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      // Hash the absolute URL rather than reuse its last path segment: signed
      // media URLs repeat generic names ("audio.m4a") across different notes.
      final name = _cacheKey(absolute);
      final file = File('${cacheDir.path}/$name${_extension(absolute)}');
      if (await file.exists() && await file.length() > 0) return file.path;

      try {
        final headers = <String, dynamic>{};
        if (_needsAuth(absolute)) {
          final tokens = await ref.read(tokenStoreProvider).read();
          if (tokens != null) {
            headers['Authorization'] = 'Bearer ${tokens.access}';
          }
        }

        final response = await Dio().get<List<int>>(
          absolute,
          options: Options(
            responseType: ResponseType.bytes,
            headers: headers.isEmpty ? null : headers,
          ),
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

/// Turn a relative or absolute media path into a fetchable HTTPS URL.
///
/// Returns null when there is nothing usable to fetch.
String? resolveVoiceNoteUrl(String? url) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (!EnvConfig.isApiBaseUrlConfigured) return null;
  final base = EnvConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  if (trimmed.startsWith('/')) return '$base$trimmed';
  return '$base/$trimmed';
}

bool _needsAuth(String absoluteUrl) {
  final host = EnvConfig.apiHost;
  if (host.isEmpty) return false;
  final uri = Uri.tryParse(absoluteUrl);
  return uri != null && uri.host == host;
}

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
