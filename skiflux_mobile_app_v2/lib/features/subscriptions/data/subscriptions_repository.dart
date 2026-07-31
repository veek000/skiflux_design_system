/// Follow-graph endpoints: who the learner follows and their latest episodes.
///
/// `GET /creators/following/` returns `FollowedCreator` rows; `GET
/// /episodes/following/` returns the OpenAPI `Episode` schema; both are list
/// endpoints, so they go through [ApiRepository.getPage] and keep pagination
/// metadata instead of pretending the body is a single object.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'subscriptions_store.dart';

class SubscriptionsRepository extends ApiRepository {
  const SubscriptionsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  /// `GET /creators/following/`
  Future<Paginated<SubscribedCreator>> getFollowingCreators({
    int limit = 50,
    int offset = 0,
  }) => getPage(
    '/creators/following/',
    query: {'limit': limit, 'offset': offset},
    parse: SubscribedCreator.fromJson,
  );

  /// `GET /episodes/following/` — latest episodes from followed creators.
  Future<Paginated<SubscriptionEpisode>> getFollowingEpisodes({
    int limit = 50,
    int offset = 0,
  }) => getPage(
    '/episodes/following/',
    query: {'limit': limit, 'offset': offset},
    parse: SubscriptionEpisode.fromJson,
  );

  /// `POST /creators/{creator_id}/follow/` — a toggle; the response carries the
  /// resulting state so callers reconcile instead of assuming.
  Future<FollowToggleResult> toggleFollow(String creatorId) async {
    final result = await post(
      '/creators/$creatorId/follow/',
      kind: SkifluxErrorKind.likeCommentReactionFailed,
      parse: FollowToggleResult.fromJson,
    );
    // `post` is nullable only when no parser is given; guard for the analyzer.
    return result ?? const FollowToggleResult();
  }
}

/// Spec `ToggleFollowResponse` — `{creator_id, is_following, followers_count}`.
class FollowToggleResult {
  const FollowToggleResult({this.isFollowing, this.followersCount});

  factory FollowToggleResult.fromJson(Map<String, dynamic> json) =>
      FollowToggleResult(
        isFollowing: json['is_following'] is bool
            ? json['is_following'] as bool
            : null,
        followersCount: json['followers_count'] is int
            ? json['followers_count'] as int
            : null,
      );

  /// Null when the body omitted it — treat the optimistic state as confirmed.
  final bool? isFollowing;
  final int? followersCount;
}

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>(
  (ref) => SubscriptionsRepository(ref.watch(apiClientProvider)),
);
