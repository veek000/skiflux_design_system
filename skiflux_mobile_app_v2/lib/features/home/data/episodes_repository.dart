import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'home_feed_store.dart';

/// Learner episode catalogue endpoints used by home + later library screens.
class EpisodesRepository extends ApiRepository {
  const EpisodesRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  /// Primary home feed source.
  Future<List<HomeFeedItem>> getRecommendations() => getList(
    '/episodes/recommendations',
    parse: episodeJsonToFeedItem,
  );

  Future<List<HomeFeedItem>> getFollowingEpisodes() => getList(
    '/episodes/following/',
    parse: episodeJsonToFeedItem,
  );
}

/// Maps OpenAPI `Episode` JSON → [HomeFeedItem] for the home PageView.
HomeFeedItem episodeJsonToFeedItem(Map<String, dynamic> json) {
  final id = json['id']?.toString() ?? '';
  final order = json['order'];
  final epNum = order is num ? order.toInt() : null;
  final epTag = epNum != null
      ? 'EP ${epNum.toString().padLeft(2, '0')}'
      : 'EP';

  final videoUrl = _stringOrNull(json['video_url']);
  final thumb = _stringOrNull(json['thumbnail_url']) ??
      _stringOrNull(json['preview_url']) ??
      '';

  final creator = json['creator'];
  var creatorName = 'Creator';
  var creatorUsername = '';
  var creatorInitials = 'C';
  if (creator is Map) {
    final c = Map<String, dynamic>.from(creator);
    final first = _stringOrNull(c['first_name']) ?? '';
    final last = _stringOrNull(c['last_name']) ?? '';
    final display = _stringOrNull(c['display_name']);
    creatorUsername = _stringOrNull(c['username']) ?? '';
    creatorName = (display != null && display.isNotEmpty)
        ? display
        : ('$first $last'.trim().isNotEmpty
            ? '$first $last'.trim()
            : (creatorUsername.isNotEmpty ? creatorUsername : 'Creator'));
    if (first.isNotEmpty || last.isNotEmpty) {
      creatorInitials =
          '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
              .toUpperCase();
    } else if (creatorUsername.isNotEmpty) {
      creatorInitials = creatorUsername[0].toUpperCase();
    }
  }

  final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

  return HomeFeedItem(
    type: hasVideo ? FeedContentType.video : FeedContentType.image,
    epTag: epTag,
    title: _stringOrNull(json['title']) ?? 'Episode',
    description: _stringOrNull(json['description']) ?? '',
    coverAsset: 'assets/home_video_cover.png',
    coverUrl: thumb.isEmpty ? null : thumb,
    videoUrl: hasVideo ? videoUrl : null,
    creatorName: creatorName,
    creatorUsername: creatorUsername,
    creatorInitials: creatorInitials.isEmpty ? 'C' : creatorInitials,
    episodeId: id.isEmpty ? null : id,
  );
}

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

final episodesRepositoryProvider = Provider<EpisodesRepository>(
  (ref) => EpisodesRepository(ref.watch(apiClientProvider)),
);
