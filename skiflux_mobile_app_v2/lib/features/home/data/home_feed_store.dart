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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/token_store.dart';
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
