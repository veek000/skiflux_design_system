/// Home feed models — remote recommendations, and nothing else.
///
/// There is no sample feed behind this. A seeded card plays a stock video
/// under a made-up creator's name, which is indistinguishable from a real
/// recommendation: the user watches it, likes it, and the like posts against
/// an episode id that does not exist. Loading and failure now say so.
///
/// Content-type generalization: a feed item is either [FeedContentType.video]
/// or [FeedContentType.image]. Only the media surface differs; chrome (EP chip,
/// title, description, action rail) is shared.
library;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/token_store.dart';
import '../../profile/data/library_repository.dart';
import '../../profile/data/library_store.dart';
import 'episodes_repository.dart';

/// Whether the home card should play video or show a static image.
enum FeedContentType { video, image }

/// One full-screen feed card (home tab).
class HomeFeedItem {
  const HomeFeedItem({
    required this.type,
    required this.epTag,
    required this.title,
    required this.description,
    required this.coverAsset,
    required this.creatorName,
    required this.creatorUsername,
    required this.creatorInitials,
    /// Network URL for [FeedContentType.video] playback via `video_player`.
    /// Null for images (and for legacy call sites with no stream yet).
    this.videoUrl,
    /// CDN cover / image when the backend supplies `thumbnail_url`.
    this.coverUrl,
    /// Backend episode UUID when known.
    this.episodeId,
    this.creatorId,
    this.likeCount,
    this.commentCount,
    this.saveCount,
    this.durationSeconds,
  });

  final FeedContentType type;
  final String epTag;
  final String title;
  final String description;

  /// Local asset path for cover / image media (fallback when [coverUrl] null).
  final String coverAsset;

  /// Network thumbnail/image URL from the API.
  final String? coverUrl;

  /// HTTPS stream for video items. Image items leave this null.
  final String? videoUrl;

  final String creatorName;
  final String creatorUsername;
  final String creatorInitials;

  final String? episodeId;

  /// Creator UUID from the payload's nested `creator` — what
  /// `GET /creators/{id}` and `POST /creators/{id}/follow/` take.
  final String? creatorId;

  /// Engagement counts straight off the `Episode` payload. Null when the
  /// source didn't carry them (legacy call sites) — the rail then shows no
  /// number rather than a made-up one.
  final int? likeCount;
  final int? commentCount;
  final int? saveCount;

  /// `video_duration` in seconds; used by view tracking to decide "completed".
  final int? durationSeconds;

  bool get isVideo => type == FeedContentType.video;
  bool get isImage => type == FeedContentType.image;

  /// True when this item should construct a [VideoPlayerController].
  bool get hasPlayableVideo =>
      isVideo && videoUrl != null && videoUrl!.isNotEmpty;

  bool get hasNetworkCover => coverUrl != null && coverUrl!.isNotEmpty;
}

/// `GET /episodes/recommendations`, or an honest loading / empty / error state.
final homeFeedProvider =
    AsyncNotifierProvider<HomeFeedNotifier, List<HomeFeedItem>>(
      HomeFeedNotifier.new,
    );

class HomeFeedNotifier extends AsyncNotifier<List<HomeFeedItem>> {
  @override
  Future<List<HomeFeedItem>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<HomeFeedItem>> _load() async {
    // Recommendations are personalised, so there is nothing to fetch without a
    // session. Empty rather than an error: the home screen renders its empty
    // state, and signing in refreshes this provider.
    if (!await ref.read(tokenStoreProvider).hasSession()) {
      return const [];
    }
    // Failures propagate. `AsyncError` is what lets the screen offer a retry;
    // swallowing it here would leave the user with no way to try again.
    return ref.read(episodesRepositoryProvider).getRecommendations();
  }

  /// `POST /episodes/not-interested` — the card disappears from the feed
  /// immediately and comes back (with the error rethrown for the caller to
  /// surface) if the server rejects the request.
  Future<void> notInterested(String episodeId) async {
    final before = state.value;
    if (before != null) {
      state = AsyncData([
        for (final item in before)
          if (item.episodeId != episodeId) item,
      ]);
    }
    try {
      await ref.read(episodesRepositoryProvider).markNotInterested(episodeId);
    } catch (_) {
      if (ref.mounted && before != null) state = AsyncData(before);
      rethrow;
    }
  }
}

/// Sync view of the feed for widgets that already expect a plain list — empty
/// while loading and after a failure. Prefer [homeFeedProvider] anywhere the
/// difference between "still loading" and "nothing here" matters to the user.
final homeFeedItemsProvider = Provider<List<HomeFeedItem>>((ref) {
  return ref.watch(homeFeedProvider).value ?? const [];
});

/// Elapsed fraction for the Figma progress bar from a video controller clock.
///
/// Returns 0 when duration is unknown/zero. Clamped to [0, 1].
double videoProgressFraction(Duration position, Duration duration) {
  final totalMs = duration.inMilliseconds;
  if (totalMs <= 0) return 0;
  return (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
}

// ── Like / save engagement ───────────────────────────────────────────

/// This session's like/save toggles, per episode UUID.
///
/// The `Episode` schema carries `like_count`/`save_count` but no
/// `is_liked`/`is_saved`, so the base state comes from membership in the
/// learner's `GET /me/liked` / `GET /me/saved` lists when those have loaded,
/// and defaults to false otherwise. Toggles are optimistic against the real
/// `POST /episodes/like` / `POST /episodes/save` endpoints (both toggles),
/// roll back on failure, and rethrow so the card can surface the error.
class EpisodeEngagement {
  const EpisodeEngagement({this.liked, this.saved});

  /// Null = untouched this session; fall back to membership / payload.
  final bool? liked;
  final bool? saved;

  EpisodeEngagement copyWith({bool? liked, bool? saved}) => EpisodeEngagement(
    liked: liked ?? this.liked,
    saved: saved ?? this.saved,
  );
}

final feedEngagementProvider =
    NotifierProvider<FeedEngagementNotifier, Map<String, EpisodeEngagement>>(
      FeedEngagementNotifier.new,
    );

class FeedEngagementNotifier extends Notifier<Map<String, EpisodeEngagement>> {
  @override
  Map<String, EpisodeEngagement> build() => const {};

  EpisodeEngagement _of(String episodeId) =>
      state[episodeId] ?? const EpisodeEngagement();

  void _put(String episodeId, EpisodeEngagement value) {
    state = {...state, episodeId: value};
  }

  /// Whether [episodeId] reads as liked right now: this session's toggle if
  /// any, else membership in the loaded `GET /me/liked` page, else false.
  bool isLiked(String episodeId) =>
      _of(episodeId).liked ?? _inList(ref.read(likedEpisodesProvider), episodeId);

  bool isSaved(String episodeId) =>
      _of(episodeId).saved ?? _inList(ref.read(savedEpisodesProvider), episodeId);

  /// Toggle like — optimistic, rolled back and rethrown on failure. Returns
  /// the state the UI should show after the flip.
  Future<bool> toggleLike(String episodeId) async {
    final current = isLiked(episodeId);
    final next = !current;
    final before = _of(episodeId);
    _put(episodeId, before.copyWith(liked: next));
    try {
      await ref.read(libraryRepositoryProvider).toggleLike(episodeId);
      // The liked list is now stale; refetch next time it's shown.
      ref.invalidate(likedEpisodesProvider);
      return next;
    } catch (_) {
      if (ref.mounted) _put(episodeId, before.copyWith(liked: current));
      rethrow;
    }
  }

  Future<bool> toggleSave(String episodeId) async {
    final current = isSaved(episodeId);
    final next = !current;
    final before = _of(episodeId);
    _put(episodeId, before.copyWith(saved: next));
    try {
      await ref.read(libraryRepositoryProvider).toggleSave(episodeId);
      ref.invalidate(savedEpisodesProvider);
      return next;
    } catch (_) {
      if (ref.mounted) _put(episodeId, before.copyWith(saved: current));
      rethrow;
    }
  }

  static bool _inList(AsyncValue<List<dynamic>> list, String episodeId) {
    final value = list.value;
    if (value == null) return false;
    return value.any((e) => e.id == episodeId);
  }
}

/// Count for the rail: payload count plus this session's delta. Null in →
/// null out, so unknown counts render as no number instead of a fake one.
int? engagedCount(int? payloadCount, {required bool base, required bool now}) {
  if (payloadCount == null) return null;
  if (base == now) return payloadCount;
  if (now) return payloadCount + 1;
  final decremented = payloadCount - 1;
  return decremented < 0 ? 0 : decremented;
}

// ── View tracking ────────────────────────────────────────────────────

/// Throttled `POST /episodes/track-view` from feed playback.
///
/// The card reports playback position on every controller tick; this posts at
/// most once per [interval] while the position advances, and once more on
/// page change / dispose via [flush]. `watch_duration_seconds` is the current
/// position (the same figure `GET /me/watch-history` reports back), and
/// `completed` flips when 95% of the video has played. Failures are silent —
/// view telemetry must never toast — and are not retried, so a dead backend
/// costs one request per interval at most.
class ViewTracker {
  ViewTracker({
    required this.episodeId,
    required Future<void> Function(
      String episodeId, {
      required int watchDurationSeconds,
      required bool completed,
    })
    post,
    this.interval = const Duration(seconds: 10),
    this.totalSeconds,
  }) : _post = post;

  final String episodeId;
  final Duration interval;

  /// Payload `video_duration`; when null, "completed" falls back to the
  /// controller-reported total passed to [onProgress].
  final int? totalSeconds;

  final Future<void> Function(
    String episodeId, {
    required int watchDurationSeconds,
    required bool completed,
  })
  _post;

  int _lastPostedSeconds = -1;
  DateTime? _lastPostAt;
  int _positionSeconds = 0;
  bool _completed = false;
  bool _disposed = false;

  /// Feed a playback tick. Posts when [interval] has elapsed since the last
  /// post and the position moved.
  void onProgress(Duration position, Duration total) {
    if (_disposed) return;
    _positionSeconds = position.inSeconds;
    final totalSecs = totalSeconds ?? total.inSeconds;
    if (!_completed && totalSecs > 0 && position.inSeconds >= totalSecs * 0.95) {
      _completed = true;
      _send(); // completion posts immediately, not on the next interval
      return;
    }
    final now = DateTime.now();
    final due =
        _lastPostAt == null || now.difference(_lastPostAt!) >= interval;
    if (due && _positionSeconds != _lastPostedSeconds) {
      _send();
    }
  }

  /// Final post when the card leaves the screen. Safe to call repeatedly.
  void flush() {
    if (_disposed) return;
    if (_positionSeconds > 0 && _positionSeconds != _lastPostedSeconds) {
      _send();
    }
  }

  void dispose() {
    flush();
    _disposed = true;
  }

  void _send() {
    final seconds = _positionSeconds;
    _lastPostAt = DateTime.now();
    _lastPostedSeconds = seconds;
    try {
      _post(episodeId, watchDurationSeconds: seconds, completed: _completed)
          .catchError((Object error) {
            // Silent by contract: telemetry loss is not a user problem.
            debugPrint(
              'ViewTracker: track-view failed for $episodeId → $error',
            );
          });
    } catch (error) {
      // A synchronously-throwing poster must not break playback either.
      debugPrint('ViewTracker: track-view failed for $episodeId → $error');
    }
  }
}
