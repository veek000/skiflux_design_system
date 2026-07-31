/// Comments state for the episode comments sheet.
///
/// Parses the spec's `EpisodeComment` rows as they are — flat
/// `user_first_name` / `user_last_name` / `user_avatar` / `text` /
/// `audio_url` / `like_count` / `is_liked` / `replies` — instead of the
/// invented nested `author` object an earlier pass guessed at (which made
/// every real comment render as "Unknown"). No demo seed sits behind the
/// list: an empty episode shows the real empty state.
///
/// Writes are optimistic with rollback: the row appears immediately, the
/// call confirms it, and a failure removes it again and rethrows so the
/// sheet can surface the error — the previous version swallowed failures
/// and left phantom comments on screen.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/error_handling/error_handler.dart';
import 'comments_repository.dart';

class CommentItem {
  const CommentItem({
    required this.author,
    required this.body,
    this.id,
    this.parentId,
    this.authorName = '',
    this.handle = '',
    this.avatarUrl,
    this.message,
    this.audioPath,
    this.audioUrl,
    this.timeLabel = 'now',
    this.likeCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  /// Spec `EpisodeComment`. `replies` is flattened by the store, not here.
  factory CommentItem.fromJson(Map<String, dynamic> json) {
    final first = _string(json['user_first_name']) ?? '';
    final last = _string(json['user_last_name']) ?? '';
    final name = '$first $last'.trim();
    final audioUrl = _string(json['audio_url']);
    final text = _string(json['text']);
    final createdAt = DateTime.tryParse(
      _string(json['created_at']) ?? '',
    )?.toLocal();

    return CommentItem(
      id: json['id'] is int ? json['id'] as int : null,
      parentId: json['parent_id'] is int ? json['parent_id'] as int : null,
      // The schema carries no user_id/username, so ownership is unknowable —
      // rows from the backend all render as "other" (no Edit/Delete row).
      author: SkifluxCommentAuthor.other,
      body: audioUrl != null
          ? SkifluxCommentBody.voicenote
          : SkifluxCommentBody.message,
      authorName: name.isNotEmpty ? name : 'Learner',
      // No username in the payload — showing none beats inventing "@amara".
      handle: '',
      avatarUrl: _string(json['user_avatar']),
      message: text,
      audioUrl: audioUrl,
      timeLabel: shortAgeLabel(createdAt),
      likeCount: json['like_count'] is int ? json['like_count'] as int : 0,
      isLiked: json['is_liked'] == true,
      replies: [
        for (final reply in (json['replies'] is List
            ? json['replies'] as List
            : const []))
          if (reply is Map)
            CommentItem.fromJson(Map<String, dynamic>.from(reply)),
      ],
    );
  }

  /// Backend comment id (integer per the spec). Null on optimistic rows that
  /// haven't been confirmed/reloaded yet — like/reply need a real id.
  final int? id;
  final int? parentId;

  final SkifluxCommentAuthor author;
  final SkifluxCommentBody body;
  final String authorName;
  final String handle;
  final String? avatarUrl;
  final String? message;

  /// Local file path — set only for voice notes recorded on this device this
  /// session; drives real waveform playback.
  final String? audioPath;

  /// Remote voice-note URL from the payload. The comment widget can only play
  /// local files today, so these render as a static voicenote row.
  final String? audioUrl;

  final String timeLabel;
  final int likeCount;
  final bool isLiked;

  /// Nested replies straight off the payload; the store flattens them into
  /// the sheet's single list, after their parent.
  final List<CommentItem> replies;

  bool get isReply => parentId != null;

  CommentItem copyWith({int? likeCount, bool? isLiked}) => CommentItem(
    id: id,
    parentId: parentId,
    author: author,
    body: body,
    authorName: authorName,
    handle: handle,
    avatarUrl: avatarUrl,
    message: message,
    audioPath: audioPath,
    audioUrl: audioUrl,
    timeLabel: timeLabel,
    likeCount: likeCount ?? this.likeCount,
    isLiked: isLiked ?? this.isLiked,
    replies: replies,
  );
}

class CommentsState {
  const CommentsState({
    required this.comments,
    this.totalCount = 0,
    this.playingIndex,
    this.clearPlayingIndex = false,
    this.composeState = SkifluxComposeState.idle,
    this.isLoading = false,
    this.error,
    this.replyingTo,
  });

  final List<CommentItem> comments;

  /// Header count — server total when the envelope carried one, else the
  /// number of rows actually shown (replies included).
  final int totalCount;

  final int? playingIndex;
  final bool clearPlayingIndex;
  final SkifluxComposeState composeState;
  final bool isLoading;

  /// Last load failure; the sheet renders a retry panel instead of quietly
  /// showing an empty (or, worse, demo) list.
  final Object? error;

  /// Set while composing a reply to an existing comment; the next send posts
  /// to `POST /comments/{id}/reply/` instead of the episode comment endpoint.
  final CommentItem? replyingTo;

  CommentsState copyWith({
    List<CommentItem>? comments,
    int? totalCount,
    int? playingIndex,
    bool clearPlayingIndex = false,
    SkifluxComposeState? composeState,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    CommentItem? replyingTo,
    bool clearReplyingTo = false,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      totalCount: totalCount ?? this.totalCount,
      playingIndex:
          clearPlayingIndex ? null : (playingIndex ?? this.playingIndex),
      clearPlayingIndex: false,
      composeState: composeState ?? this.composeState,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      replyingTo: clearReplyingTo ? null : (replyingTo ?? this.replyingTo),
    );
  }
}

class CommentsNotifier extends Notifier<CommentsState> {
  @override
  CommentsState build() {
    return const CommentsState(comments: []);
  }

  String? _episodeId;

  void init(String episodeId) {
    if (_episodeId == episodeId) return;
    _episodeId = episodeId;
    state = const CommentsState(comments: [], isLoading: true);
    _load();
  }

  /// Retry after a failed load.
  Future<void> retry() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load();
  }

  Future<void> _load() async {
    final episodeId = _episodeId;
    if (episodeId == null || episodeId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final page = await ref
          .read(commentsRepositoryProvider)
          .getComments(episodeId);
      if (!ref.mounted) return;
      final flat = _flatten(page.results);
      // Rows beyond this page still count toward the header total.
      final beyondPage = page.count - page.results.length;
      state = state.copyWith(
        comments: flat,
        totalCount: flat.length + (beyondPage > 0 ? beyondPage : 0),
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      if (!ref.mounted) return;
      // Empty is the truth until a load succeeds; no seed re-substitution.
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  /// Top-level comments with their `replies` inlined after the parent, so a
  /// reply is visible in the flat list the sheet renders.
  List<CommentItem> _flatten(List<CommentItem> topLevel) {
    return List.unmodifiable([
      for (final comment in topLevel) ...[comment, ...comment.replies],
    ]);
  }

  void setComposeState(SkifluxComposeState value) {
    if (state.composeState == value) return;
    state = state.copyWith(composeState: value);
  }

  void togglePlay(int index) {
    final next = state.playingIndex == index ? null : index;
    state = state.copyWith(playingIndex: next, clearPlayingIndex: next == null);
  }

  void clearPlaying() {
    if (state.playingIndex == null) return;
    state = state.copyWith(clearPlayingIndex: true);
  }

  /// Begin composing a reply to [target]. Requires a confirmed backend id.
  void startReply(CommentItem target) {
    if (target.id == null) return;
    state = state.copyWith(replyingTo: target);
  }

  void cancelReply() {
    if (state.replyingTo == null) return;
    state = state.copyWith(clearReplyingTo: true);
  }

  /// Send the composed text — as a reply when [CommentsState.replyingTo] is
  /// set, else as a new episode comment. Optimistic append; rollback and
  /// rethrow on failure so the sheet shows the error.
  Future<void> addMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final episodeId = _episodeId;
    if (episodeId == null || episodeId.isEmpty) {
      throw const SkifluxFailure(SkifluxErrorKind.likeCommentReactionFailed);
    }

    final replyTarget = state.replyingTo;
    final optimistic = CommentItem(
      author: SkifluxCommentAuthor.own,
      body: SkifluxCommentBody.message,
      parentId: replyTarget?.id,
      authorName: 'You',
      message: trimmed,
      timeLabel: 'now',
    );
    final before = state.comments;
    final beforeCount = state.totalCount;
    state = state.copyWith(
      comments: _insertAfterParent(before, optimistic, replyTarget),
      totalCount: beforeCount + 1,
      composeState: SkifluxComposeState.idle,
      clearReplyingTo: true,
    );

    try {
      final repo = ref.read(commentsRepositoryProvider);
      if (replyTarget?.id != null) {
        await repo.replyToComment(replyTarget!.id!, trimmed);
      } else {
        await repo.postComment(episodeId, trimmed);
      }
      // Pick up the server row (real id, timestamps) so like/reply work on
      // it. A failed refresh keeps the optimistic row — the post succeeded.
      unawaited(_load());
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          comments: before,
          totalCount: beforeCount,
          replyingTo: replyTarget,
        );
      }
      rethrow;
    }
  }

  /// Upload the recorded voice note (multipart `audio_file`). Optimistic
  /// playable row; removed again if the upload fails.
  Future<void> addVoiceNote(String path) async {
    final episodeId = _episodeId;
    if (episodeId == null || episodeId.isEmpty) {
      throw const SkifluxFailure(SkifluxErrorKind.voicenoteFailed);
    }
    final optimistic = CommentItem(
      author: SkifluxCommentAuthor.own,
      body: SkifluxCommentBody.voicenote,
      authorName: 'You',
      audioPath: path,
      timeLabel: 'now',
    );
    final before = state.comments;
    final beforeCount = state.totalCount;
    state = state.copyWith(
      comments: [...before, optimistic],
      totalCount: beforeCount + 1,
      composeState: SkifluxComposeState.idle,
    );
    try {
      await ref
          .read(commentsRepositoryProvider)
          .postVoiceComment(episodeId, path);
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(comments: before, totalCount: beforeCount);
      }
      rethrow;
    }
  }

  /// Like/unlike toggle (`POST /comments/like`) — optimistic flip with
  /// rollback. No-ops on rows without a confirmed id.
  Future<void> toggleCommentLike(CommentItem comment) async {
    final id = comment.id;
    if (id == null) return;
    final before = state.comments;
    state = state.copyWith(
      comments: [
        for (final c in before)
          if (c.id == id)
            c.copyWith(
              isLiked: !c.isLiked,
              likeCount: c.isLiked
                  ? (c.likeCount > 0 ? c.likeCount - 1 : 0)
                  : c.likeCount + 1,
            )
          else
            c,
      ],
    );
    try {
      await ref.read(commentsRepositoryProvider).toggleCommentLike(id);
    } catch (_) {
      if (ref.mounted) state = state.copyWith(comments: before);
      rethrow;
    }
  }

  List<CommentItem> _insertAfterParent(
    List<CommentItem> list,
    CommentItem item,
    CommentItem? parent,
  ) {
    if (parent == null) return [...list, item];
    final index = list.indexWhere((c) => c.id == parent.id);
    if (index < 0) return [...list, item];
    // After the parent and any of its existing replies.
    var insertAt = index + 1;
    while (insertAt < list.length && list[insertAt].parentId == parent.id) {
      insertAt++;
    }
    return [...list]..insert(insertAt, item);
  }
}

final commentsProvider = NotifierProvider<CommentsNotifier, CommentsState>(
  CommentsNotifier.new,
);

/// Compact relative timestamp for comment rows: "now", "5m", "2h", "3d", "2w".
///
/// A payload without a parseable `created_at` shows no label at all — an
/// optimistic local row is genuinely "now", but an unknown server timestamp
/// is not.
String shortAgeLabel(DateTime? createdAt, {DateTime? now}) {
  if (createdAt == null) return '';
  final delta = (now ?? DateTime.now()).difference(createdAt);
  if (delta.isNegative || delta.inMinutes < 1) return 'now';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m';
  if (delta.inHours < 24) return '${delta.inHours}h';
  if (delta.inDays < 7) return '${delta.inDays}d';
  if (delta.inDays < 30) return '${delta.inDays ~/ 7}w';
  if (delta.inDays < 365) return '${delta.inDays ~/ 30}mo';
  return '${delta.inDays ~/ 365}y';
}

String? _string(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
