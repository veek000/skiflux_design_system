/// Episode comment endpoints.
///
/// `GET /episodes/{id}/comments` returns the spec's `EpisodeComment` rows
/// (flat: `user_first_name`, `text`, `audio_url`, `like_count`, `is_liked`,
/// `replies`, timestamps) — a list endpoint, so it goes through
/// [ApiRepository.getPage] and keeps whatever count the envelope carries.
///
/// `POST /episodes/comment` takes `EpisodeCommentCreateRequest`
/// `{episode_id, text, audio_file}` — the field is `text` (a previous pass
/// posted `comment`, which the backend ignored). Voice notes go up as
/// multipart `audio_file` from the recorder's local file.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'comments_store.dart';

class CommentsRepository extends ApiRepository {
  const CommentsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  /// `GET /episodes/{id}/comments`
  Future<Paginated<CommentItem>> getComments(
    String episodeId, {
    int limit = 50,
    int offset = 0,
  }) => getPage(
    '/episodes/$episodeId/comments',
    query: {'limit': limit, 'offset': offset},
    parse: CommentItem.fromJson,
  );

  /// `POST /episodes/comment` — text comment.
  Future<void> postComment(String episodeId, String text) => post<void>(
    '/episodes/comment',
    body: {'episode_id': episodeId, 'text': text},
    kind: SkifluxErrorKind.likeCommentReactionFailed,
  );

  /// `POST /episodes/comment` — multipart voice note from the recorded file.
  Future<void> postVoiceComment(String episodeId, String audioFilePath) =>
      guard(() async {
        final form = FormData.fromMap({
          'episode_id': episodeId,
          'audio_file': await MultipartFile.fromFile(audioFilePath),
        });
        await dio.post<dynamic>('/episodes/comment', data: form);
      }, kind: SkifluxErrorKind.voicenoteFailed);

  /// `POST /comments/like` — like/unlike toggle (`CommentActionRequest`).
  Future<void> toggleCommentLike(int commentId) => post<void>(
    '/comments/like',
    body: {'comment_id': commentId},
    kind: SkifluxErrorKind.likeCommentReactionFailed,
  );

  /// `POST /comments/{comment_id}/reply/` — text reply
  /// (`EpisodeCommentReplyCreateRequest`).
  Future<void> replyToComment(int commentId, String text) => post<void>(
    '/comments/$commentId/reply/',
    body: {'text': text},
    kind: SkifluxErrorKind.likeCommentReactionFailed,
  );

  /// `PATCH /comments/{comment_id}/` — edit the text of one's own comment
  /// (`PatchedEpisodeCommentUpdateRequest`, `text` max 500). The server is the
  /// only authority on ownership; a 403 here is the honest answer for a row the
  /// client guessed wrong about.
  Future<void> editComment(int commentId, String text) => patch<void>(
    '/comments/$commentId/',
    body: {'text': text},
    kind: SkifluxErrorKind.likeCommentReactionFailed,
  );

  /// `DELETE /comments/{comment_id}/` — 204, no body.
  Future<void> deleteComment(int commentId) => delete(
    '/comments/$commentId/',
    kind: SkifluxErrorKind.likeCommentReactionFailed,
  );

  /// `POST /comments/{comment_id}/report/` — `ReportCommentRequest`, whose
  /// `category` is **required**, so the caller has to have asked which one.
  /// 400 means "already reported or comment not found".
  Future<void> reportComment(int commentId, String category) => post<void>(
    '/comments/$commentId/report/',
    body: {'category': category},
    kind: SkifluxErrorKind.likeCommentReactionFailed,
  );
}

/// The spec's `ReportCommentCategoryEnum`, with the labels its description
/// spells out. Wire values are sent verbatim; the labels are what the picker
/// shows.
enum ReportCommentCategory {
  toxicLanguage('toxic_language', 'Toxic / Offensive language'),
  spam('spam', 'Spam / External promotion'),
  harassment('harassment', 'Harassment'),
  inappropriateSolicitation(
    'inappropriate_solicitation',
    'Inappropriate solicitation',
  ),
  duplicate('duplicate', 'Duplicate'),
  other('other', 'Other');

  const ReportCommentCategory(this.wireValue, this.label);

  final String wireValue;
  final String label;
}

final commentsRepositoryProvider = Provider<CommentsRepository>(
  (ref) => CommentsRepository(ref.watch(apiClientProvider)),
);
