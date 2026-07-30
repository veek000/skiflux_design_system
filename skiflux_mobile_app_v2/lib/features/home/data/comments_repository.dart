library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

class CommentsRepository extends ApiRepository {
  const CommentsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  Future<Map<String, dynamic>> getComments(String episodeId, {int limit = 20, int offset = 0}) async {
    return getObject(
      '/episodes/$episodeId/comments',
      query: {'limit': limit, 'offset': offset},
      parse: (json) => json,
    );
  }

  Future<void> postComment(String episodeId, String text) async {
    await post(
      '/episodes/comment',
      body: {
        'episode_id': episodeId,
        'comment': text,
      },
      parse: (json) => null,
    );
  }
}

final commentsRepositoryProvider = Provider<CommentsRepository>(
  (ref) => CommentsRepository(ref.watch(apiClientProvider)),
);
