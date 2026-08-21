import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import '../../playlists/data/seasons_repository.dart' show coinCostOf;
import 'episode_resource.dart';
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

  /// `GET /episodes/{episode_id}` — one episode, so the feed can play a
  /// sibling picked out of the season sheet.
  ///
  /// The spec has this return **403** when the episode requires a purchase the
  /// user hasn't made. That surfaces as an error the caller shows; it is not
  /// swallowed, because silently doing nothing on a tap reads as a broken
  /// button rather than as "you don't own this yet".
  Future<HomeFeedItem> getEpisode(String episodeId) => getObject(
    '/episodes/$episodeId',
    parse: episodeJsonToFeedItem,
  );

  /// `POST /episodes/track-view` — records watch progress so watch history,
  /// continue-watching and task unlocks work downstream.
  ///
  /// Spec `TrackViewRequest`: `{episode_id, watch_duration_seconds,
  /// completed}`. Callers (the feed's [ViewTracker]) keep this silent — a
  /// failed telemetry post is never a user-facing error.
  Future<void> trackView(
    String episodeId, {
    required int watchDurationSeconds,
    bool completed = false,
  }) => post<void>(
    '/episodes/track-view',
    body: {
      'episode_id': episodeId,
      'watch_duration_seconds': watchDurationSeconds,
      'completed': completed,
    },
  );

  /// `POST /episodes/not-interested` — permanently removes the episode from
  /// the user's recommendation feed (spec `EpisodeActionRequest`).
  Future<void> markNotInterested(String episodeId) => post<void>(
    '/episodes/not-interested',
    body: {'episode_id': episodeId},
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
  String? creatorId;
  String? creatorAvatarUrl;
  if (creator is Map) {
    final c = Map<String, dynamic>.from(creator);
    final first = _stringOrNull(c['first_name']) ?? '';
    final last = _stringOrNull(c['last_name']) ?? '';
    // Spec `Creator` carries a composed `name`; older payloads used
    // first/last/display — accept all of them.
    final display =
        _stringOrNull(c['name']) ?? _stringOrNull(c['display_name']);
    creatorId = _stringOrNull(c['id']?.toString());
    creatorUsername = _stringOrNull(c['username']) ?? '';
    creatorAvatarUrl = _stringOrNull(c['avatarUrl']) ?? _stringOrNull(c['avatar_url']);
    creatorName = (display != null && display.isNotEmpty)
        ? display
        : ('$first $last'.trim().isNotEmpty
            ? '$first $last'.trim()
            : (creatorUsername.isNotEmpty ? creatorUsername : 'Creator'));
    if (first.isNotEmpty || last.isNotEmpty) {
      creatorInitials =
          '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
              .toUpperCase();
    } else if (creatorName.isNotEmpty && creatorName != 'Creator') {
      creatorInitials = creatorName[0].toUpperCase();
    } else if (creatorUsername.isNotEmpty) {
      creatorInitials = creatorUsername[0].toUpperCase();
    }
  }

  final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

  // The server's own verdict, reconciled with purchase state. Absent reads as
  // unlocked: hiding content the backend never said was paid is the worse
  // error, and the player still fails honestly if the stream is withheld.
  final purchased = json['is_purchased'] == true;
  final locked = json['is_locked'] == true && !purchased;

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
    creatorAvatarUrl: creatorAvatarUrl,
    episodeId: id.isEmpty ? null : id,
    creatorId: creatorId,
    likeCount: _intOrNull(json['like_count']),
    commentCount: _intOrNull(json['comment_count']),
    saveCount: _intOrNull(json['save_count']),
    durationSeconds: _intOrNull(json['video_duration']),
    seasonId: _stringOrNull(json['season_id']),
    seasonTitle: _stringOrNull(json['season_title']),
    skillworld: _stringOrNull(json['skillworld']),
    isLocked: locked,
    coinCost: coinCostOf(_decimalOrNull(json['skillcoin_price'])),
    // `Episode.resources` / `Episode.tasks` are inline on the viewer payload
    // and were never read, so the More Menu offered both cards on every
    // episode — Resources opened four hardcoded filenames.
    resources: parseEpisodeResources(json['resources']),
    taskCount: json['tasks'] is List ? (json['tasks'] as List).length : 0,
  );
}

/// Money is a decimal string on the wire — never `double.parse`.
Decimal? _decimalOrNull(Object? value) {
  if (value is String) return Decimal.tryParse(value.trim());
  if (value is num) return Decimal.tryParse(value.toString());
  return null;
}

int? _intOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

final episodesRepositoryProvider = Provider<EpisodesRepository>(
  (ref) => EpisodesRepository(ref.watch(apiClientProvider)),
);
