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
import 'episode_resource.dart';
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
    this.seasonId,
    this.seasonTitle,
    this.skillworld,
    this.isLocked = false,
    this.coinCost = 0,
    this.resources = const [],
    this.taskCount = 0,
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

  /// `Episode.season_id` / `season_title` — what the EP chip opens. Null on a
  /// standalone episode (or a legacy call site), in which case the chip is not
  /// tappable rather than opening an empty sheet.
  final String? seasonId;
  final String? seasonTitle;

  /// `Episode.skillworld`, raw backend value.
  final String? skillworld;

  /// The server's own `is_locked` (already reconciled with `is_purchased` by
  /// the parser) and the whole-coin price for the unlock sheet.
  final bool isLocked;
  final int coinCost;

  bool get isVideo => type == FeedContentType.video;
  bool get isImage => type == FeedContentType.image;

  /// True when this item should construct a [VideoPlayerController].
  bool get hasPlayableVideo =>
      isVideo && videoUrl != null && videoUrl!.isNotEmpty;

  bool get hasNetworkCover => coverUrl != null && coverUrl!.isNotEmpty;

  /// True when the EP chip can open a season sheet.
  bool get hasSeason => seasonId != null && seasonId!.isNotEmpty;

  /// Files and links attached to this episode, from `Episode.resources`.
  ///
  /// Empty means empty: the More Menu hides its "Episode Resources" card
  /// rather than opening a sheet of four hardcoded filenames, which is what it
  /// used to show on every episode in the app.
  final List<EpisodeResource> resources;

  /// How many tasks `Episode.tasks` carried. Only the count is kept — the More
  /// Menu needs to know whether to offer the card, and the task screens fetch
  /// their own detail.
  final int taskCount;

  bool get hasResources => resources.isNotEmpty;
  bool get hasTask => taskCount > 0;
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

  /// Makes [episodeId] a page of this feed and returns its index.
  ///
  /// Called when the user picks a sibling episode out of the season sheet
  /// while watching in home: that has to play *in the feed*, not in a modal.
  /// If the episode is already loaded its existing index is returned — the
  /// feed is not reordered under the user. Otherwise it is fetched and
  /// inserted directly after [afterIndex] so their place in the feed survives.
  ///
  /// Throws when the fetch fails (including the 403 `GET /episodes/{id}`
  /// returns for an unpurchased episode); the caller surfaces it.
  Future<int> openEpisode(String episodeId, {int afterIndex = -1}) async {
    final current = state.value ?? const <HomeFeedItem>[];
    final existing = current.indexWhere((e) => e.episodeId == episodeId);
    if (existing >= 0) return existing;

    final item = await ref
        .read(episodesRepositoryProvider)
        .getEpisode(episodeId);

    // Re-read: the fetch was awaited, so the feed may have changed underneath.
    final latest = state.value ?? const <HomeFeedItem>[];
    final already = latest.indexWhere((e) => e.episodeId == episodeId);
    if (already >= 0) return already;

    final at = (afterIndex + 1).clamp(0, latest.length);
    state = AsyncData([...latest.sublist(0, at), item, ...latest.sublist(at)]);
    return at;
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

/// This session's like/save toggles and count movement, per episode UUID.
///
/// The `Episode` schema carries `like_count`/`save_count` but no
/// `is_liked`/`is_saved`, so the base state comes from membership in the
/// learner's `GET /me/liked` / `GET /me/saved` lists when those have loaded,
/// and defaults to false otherwise. Toggles are optimistic against the real
/// `POST /episodes/like` / `POST /episodes/save` endpoints (both toggles),
/// roll back on failure, and rethrow so the card can surface the error.
///
/// The counts are tracked as explicit **deltas** rather than derived from
/// `base != now`. Derivation looked equivalent but wasn't: liking invalidates
/// `likedEpisodesProvider`, the refetched list then contains the episode, base
/// agrees with the toggle again, and the +1 vanished from the rail a moment
/// after the user earned it. A delta is only cancelled by the opposite action
/// or by a feed refresh that brings a fresh server count.
class EpisodeEngagement {
  const EpisodeEngagement({
    this.liked,
    this.saved,
    this.likeDelta = 0,
    this.saveDelta = 0,
    this.commentDelta = 0,
  });

  /// Null = untouched this session; fall back to membership / payload.
  final bool? liked;
  final bool? saved;

  /// Net movement this session, added on top of the payload's count.
  final int likeDelta;
  final int saveDelta;
  final int commentDelta;

  EpisodeEngagement copyWith({
    bool? liked,
    bool? saved,
    int? likeDelta,
    int? saveDelta,
    int? commentDelta,
  }) => EpisodeEngagement(
    liked: liked ?? this.liked,
    saved: saved ?? this.saved,
    likeDelta: likeDelta ?? this.likeDelta,
    saveDelta: saveDelta ?? this.saveDelta,
    commentDelta: commentDelta ?? this.commentDelta,
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
  ///
  /// The bool and the delta move together and roll back together, so the rail
  /// can never show a filled heart next to an unmoved count.
  Future<bool> toggleLike(String episodeId) async {
    final current = isLiked(episodeId);
    final next = !current;
    final before = _of(episodeId);
    _put(
      episodeId,
      before.copyWith(
        liked: next,
        likeDelta: before.likeDelta + (next ? 1 : -1),
      ),
    );
    try {
      await ref.read(libraryRepositoryProvider).toggleLike(episodeId);
      // The liked list is now stale; refetch next time it's shown.
      ref.invalidate(likedEpisodesProvider);
      return next;
    } catch (_) {
      // Restore the *resolved* prior value, not the untouched null: after a
      // rejected toggle the rail must state a position rather than fall back
      // to a membership list the failed write may already have disturbed.
      if (ref.mounted) _put(episodeId, before.copyWith(liked: current));
      rethrow;
    }
  }

  Future<bool> toggleSave(String episodeId) async {
    final current = isSaved(episodeId);
    final next = !current;
    final before = _of(episodeId);
    _put(
      episodeId,
      before.copyWith(
        saved: next,
        saveDelta: before.saveDelta + (next ? 1 : -1),
      ),
    );
    try {
      await ref.read(libraryRepositoryProvider).toggleSave(episodeId);
      ref.invalidate(savedEpisodesProvider);
      return next;
    } catch (_) {
      if (ref.mounted) _put(episodeId, before.copyWith(saved: current));
      rethrow;
    }
  }

  /// Move [episodeId]'s comment count by [by] (+1 posted, -1 deleted).
  ///
  /// Called by the comments sheet once the server has accepted the write. The
  /// feed payload's `comment_count` is a snapshot from load time and there is
  /// no per-episode refetch on the rail, so without this the number the user
  /// just changed sits still until the whole feed reloads.
  void bumpComments(String episodeId, int by) {
    if (by == 0) return;
    final before = _of(episodeId);
    _put(episodeId, before.copyWith(commentDelta: before.commentDelta + by));
  }

  static bool _inList(AsyncValue<List<dynamic>> list, String episodeId) {
    final value = list.value;
    if (value == null) return false;
    return value.any((e) => e.id == episodeId);
  }
}

/// Count for the rail: payload count plus this session's delta, clamped at 0.
///
/// Null in → null out, so unknown counts render as no number instead of a fake
/// one. Taking the delta rather than `base`/`now` is the whole point: the
/// server count and the session's movement are independent, so refetching
/// `GET /me/liked` no longer silently cancels the +1 the user just earned.
int? engagedCount(int? payloadCount, int delta) {
  if (payloadCount == null) return null;
  final total = payloadCount + delta;
  return total < 0 ? 0 : total;
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
