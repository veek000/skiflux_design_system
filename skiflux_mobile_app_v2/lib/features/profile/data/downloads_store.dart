/// Offline downloads — the real pipeline.
///
/// This used to be a `List<LibraryEpisode>` held in memory: "downloading" an
/// episode appended it to that list, nothing was ever fetched, the list was
/// empty again after a relaunch, and the Downloads screen multiplied its length
/// by a hardcoded `112` to print a storage figure. Every number on that screen
/// was invented and every row was unplayable.
///
/// Now the episode's `video_url` is streamed to a file in the app documents
/// directory with real progress, the registry of what is on disk is persisted
/// to `shared_preferences`, sizes are read from the files themselves, and
/// deleting a row deletes its bytes.
///
/// The backend has no downloads API — no offline entitlement, no expiry, and no
/// per-rendition URLs — so this is deliberately client-only and downloads the
/// same `video_url` the player streams.
//
// TODO(backend, minor): downloads are client-only against the streaming
// `video_url`, so the "Download quality" preference cannot be honoured and
// there is no offline entitlement or expiry for paid episodes. Expects:
// per-rendition URLs on Episode (or GET /episodes/{id}/download?quality=), plus
// a policy on offline access.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/notifications/local_notifications.dart';
import '../../settings/data/settings_store.dart';
import 'library_episode.dart';

enum DownloadState { downloading, complete, failed }

/// One episode that is on disk, or on its way there.
@immutable
class DownloadedEpisode {
  const DownloadedEpisode({
    required this.episode,
    required this.filePath,
    this.bytes = 0,
    this.progress = 1,
    this.state = DownloadState.complete,
    this.error,
  });

  final LibraryEpisode episode;

  /// Absolute path of the downloaded file.
  final String filePath;

  /// Size on disk, read from the file rather than estimated — the Downloads
  /// screen's storage line is a sum of these.
  final int bytes;

  /// 0–1 while [state] is [DownloadState.downloading].
  final double progress;

  final DownloadState state;

  /// Why the download failed, for the row to show.
  final String? error;

  bool get isComplete => state == DownloadState.complete;
  bool get isDownloading => state == DownloadState.downloading;

  /// "512 KB", "112 MB", "1.2 GB", or "—" before anything is written.
  String get sizeLabel => formatBytes(bytes);

  DownloadedEpisode copyWith({
    int? bytes,
    double? progress,
    DownloadState? state,
    String? error,
    bool clearError = false,
  }) => DownloadedEpisode(
    episode: episode,
    filePath: filePath,
    bytes: bytes ?? this.bytes,
    progress: progress ?? this.progress,
    state: state ?? this.state,
    error: clearError ? null : (error ?? this.error),
  );

  Map<String, Object?> toJson() => {
    'episode': episode.toJson(),
    'filePath': filePath,
    'bytes': bytes,
  };

  static DownloadedEpisode? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final path = map['filePath'];
    final episodeJson = map['episode'];
    if (path is! String || path.isEmpty || episodeJson is! Map) return null;
    return DownloadedEpisode(
      episode: LibraryEpisode.fromJson(Map<String, dynamic>.from(episodeJson)),
      filePath: path,
      bytes: map['bytes'] is int ? map['bytes'] as int : 0,
    );
  }
}

/// "512 KB" / "112 MB" / "1.2 GB". Decimal units, matching what a phone's own
/// storage settings show.
String formatBytes(int bytes) {
  if (bytes <= 0) return '—';
  if (bytes < 1000 * 1000) return '${(bytes / 1000).round()} KB';
  if (bytes < 1000 * 1000 * 1000) {
    return '${(bytes / (1000 * 1000)).round()} MB';
  }
  return '${(bytes / (1000 * 1000 * 1000)).toStringAsFixed(1)} GB';
}

class DownloadsNotifier extends Notifier<List<DownloadedEpisode>> {
  static const _registryKey = 'downloads.registry';

  /// Cancels in-flight transfers on delete / clear-all.
  final Map<String, CancelToken> _inFlight = {};

  /// Last percentage pushed to the tray, per episode.
  ///
  /// `onReceiveProgress` fires per chunk — hundreds of times for one episode —
  /// and each tray update is a platform-channel round trip. The notification
  /// only ever renders whole percent, so anything finer is pure cost.
  final Map<String, int> _notifiedPercent = {};

  @override
  List<DownloadedEpisode> build() {
    unawaited(restore());
    return const [];
  }

  /// Reload what is genuinely on disk.
  ///
  /// Entries whose file has gone — cleared by the OS under storage pressure,
  /// or by the user in system settings — are dropped rather than listed. A row
  /// that cannot play is worse than no row.
  Future<void> restore() async {
    // Whole body guarded: this runs detached from `build()`, so a plugin that
    // is not there — `shared_preferences` under `flutter test`, a sandboxed
    // filesystem — would otherwise surface as an unhandled async error with no
    // owner. An empty list is the honest answer in that case.
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_registryKey) ?? const [];
      final restored = <DownloadedEpisode>[];
      for (final entry in raw) {
        DownloadedEpisode? parsed;
        try {
          parsed = DownloadedEpisode.fromJson(jsonDecode(entry) as Object?);
        } catch (_) {
          // A corrupt row is dropped, not fatal.
          continue;
        }
        if (parsed == null) continue;
        final file = File(parsed.filePath);
        if (!file.existsSync()) continue;
        restored.add(parsed.copyWith(bytes: file.lengthSync()));
      }
      if (!ref.mounted) return;
      state = List.unmodifiable(restored);
      // Prune whatever vanished so the registry stops carrying dead keys.
      if (restored.length != raw.length) await _persist();
    } catch (error, stackTrace) {
      debugPrint('Downloads registry unreadable: $error\n$stackTrace');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_registryKey, [
        for (final d in state)
          if (d.isComplete) jsonEncode(d.toJson()),
      ]);
    } catch (error) {
      // The files are still on disk; only the registry of them is lost, and
      // [restore] tolerates that. Failing the delete/download the user asked
      // for because a write to prefs failed would be worse.
      debugPrint('Downloads registry not saved: $error');
    }
  }

  bool isDownloaded(String episodeId) =>
      state.any((d) => d.episode.id == episodeId && d.isComplete);

  /// Local file for [episodeId], or null when it is not downloaded. The player
  /// uses this to play offline instead of streaming.
  String? filePathFor(String episodeId) {
    for (final d in state) {
      if (d.episode.id == episodeId && d.isComplete) return d.filePath;
    }
    return null;
  }

  /// Total bytes on disk — summed from real file sizes, not a per-video guess.
  int get totalBytes =>
      state.fold(0, (sum, d) => sum + (d.isComplete ? d.bytes : 0));

  /// Download [episode] for offline playback.
  ///
  /// Throws [SkifluxFailure] when there is no video URL, when the Wi-Fi-only
  /// preference blocks it, or when the transfer fails. Progress is published
  /// on [state] as it goes.
  Future<void> download(LibraryEpisode episode) async {
    if (isDownloaded(episode.id)) return;

    final url = episode.videoUrl;
    if (url == null || url.isEmpty) {
      throw const SkifluxFailure(SkifluxErrorKind.downloadFailed);
    }

    // "Download on Wi-Fi only" was stored and then ignored. Checked before a
    // byte moves, because the whole point of the setting is the data bill.
    if (ref.read(settingsProvider).downloadOnWifiOnly && !await _onWifi()) {
      throw const SkifluxFailure(SkifluxErrorKind.downloadWifiOnly);
    }

    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/downloads');
    if (!await folder.exists()) await folder.create(recursive: true);
    final path = '${folder.path}/${episode.id}${_extensionOf(url)}';

    final cancel = CancelToken();
    _inFlight[episode.id] = cancel;
    _upsert(
      DownloadedEpisode(
        episode: episode,
        filePath: path,
        progress: 0,
        state: DownloadState.downloading,
      ),
    );
    // The tray bar, so a transfer stays visible with the app backgrounded.
    final tray = ref.read(localNotificationsProvider);
    _notifiedPercent[episode.id] = -1;
    unawaited(tray.showProgress(episode.id, episode.title, 0));

    try {
      // A bare Dio: media URLs are absolute and pre-signed, so the API base
      // URL and auth header do not apply.
      await Dio().download(
        url,
        path,
        cancelToken: cancel,
        onReceiveProgress: (received, total) {
          if (total <= 0 || !ref.mounted) return;
          final fraction = received / total;
          _update(
            episode.id,
            (d) => d.copyWith(progress: fraction, bytes: received),
          );
          final percent = (fraction * 100).round();
          if (_notifiedPercent[episode.id] == percent) return;
          _notifiedPercent[episode.id] = percent;
          unawaited(tray.showProgress(episode.id, episode.title, fraction));
        },
      );
      if (!ref.mounted) return;
      _update(
        episode.id,
        (d) => d.copyWith(
          bytes: File(path).lengthSync(),
          progress: 1,
          state: DownloadState.complete,
          clearError: true,
        ),
      );
      unawaited(tray.showComplete(episode.id, episode.title));
      await _persist();
    } catch (error) {
      // A partial file is dead weight: nothing can play it, and the registry
      // would count its bytes toward the storage line.
      final partial = File(path);
      if (await partial.exists()) await partial.delete();
      if (cancel.isCancelled) {
        // Cancellation is the user's own doing (delete / clear all); the tray
        // line goes with it rather than reporting a failure they caused.
        unawaited(tray.cancel(episode.id));
        if (ref.mounted) _removeFromState(episode.id);
        return;
      }
      unawaited(tray.showFailed(episode.id, episode.title));
      if (!ref.mounted) {
        throw const SkifluxFailure(SkifluxErrorKind.downloadFailed);
      }
      _update(
        episode.id,
        (d) => d.copyWith(state: DownloadState.failed, error: 'Failed'),
      );
      throw const SkifluxFailure(SkifluxErrorKind.downloadFailed);
    } finally {
      _inFlight.remove(episode.id);
      _notifiedPercent.remove(episode.id);
    }
  }

  Future<bool> _onWifi() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (_) {
      // Cannot tell → do not block the user on a check that failed.
      return true;
    }
  }

  /// Remove one download, file and all.
  Future<void> remove(String episodeId) async {
    _inFlight.remove(episodeId)?.cancel();
    unawaited(ref.read(localNotificationsProvider).cancel(episodeId));
    DownloadedEpisode? entry;
    for (final d in state) {
      if (d.episode.id == episodeId) entry = d;
    }
    _removeFromState(episodeId);
    await _persist();
    if (entry == null) return;
    try {
      final file = File(entry.filePath);
      if (await file.exists()) await file.delete();
    } catch (error) {
      // The row is already gone from the list, which is what the user asked
      // for. A file we cannot delete is a leak to report, not a failed action.
      debugPrint('Could not delete ${entry.filePath}: $error');
    }
  }

  /// Remove every download. Deletes the folder rather than the entries one by
  /// one, so a file the registry lost track of goes too.
  Future<void> clearAll() async {
    final tray = ref.read(localNotificationsProvider);
    for (final entry in _inFlight.entries) {
      entry.value.cancel();
      unawaited(tray.cancel(entry.key));
    }
    _inFlight.clear();
    _notifiedPercent.clear();
    state = const [];
    await _persist();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/downloads');
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (error) {
      debugPrint('Could not clear the downloads folder: $error');
    }
  }

  void _upsert(DownloadedEpisode entry) {
    final at = state.indexWhere((d) => d.episode.id == entry.episode.id);
    if (at < 0) {
      state = List.unmodifiable([...state, entry]);
      return;
    }
    state = List.unmodifiable([...state]..[at] = entry);
  }

  void _update(
    String episodeId,
    DownloadedEpisode Function(DownloadedEpisode) change,
  ) {
    state = List.unmodifiable([
      for (final d in state)
        if (d.episode.id == episodeId) change(d) else d,
    ]);
  }

  void _removeFromState(String episodeId) {
    state = List.unmodifiable([
      for (final d in state)
        if (d.episode.id != episodeId) d,
    ]);
  }

  static String _extensionOf(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return '.mp4';
    final ext = path.substring(dot);
    return ext.length <= 5 ? ext : '.mp4';
  }
}

final downloadsProvider =
    NotifierProvider<DownloadsNotifier, List<DownloadedEpisode>>(
      DownloadsNotifier.new,
    );
