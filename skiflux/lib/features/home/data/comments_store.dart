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
import '../../profile/data/profile_store.dart';
import 'comments_repository.dart';
import 'home_feed_store.dart';

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
    this.durationLabel = '0:00',
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
    // Backends have shipped several spellings; any non-empty media URL means
    // this row is a voice note — otherwise a just-sent note reloads as a blank
    // text bubble (empty `text`, no `audio_url` key match).
    final audioUrl = _string(json['audio_url']) ??
        _string(json['audio']) ??
        _string(json['voice_url']) ??
        _string(json['voice_note_url']) ??
        _string(json['audio_file']) ??
        _string(json['file_url']);
    final text = _string(json['text']);
    final createdAt = DateTime.tryParse(
      _string(json['created_at']) ?? '',
    )?.toLocal();
    // `audio_public_id` without a URL still marks a voice note (CDN URL may
    // arrive later); empty text + that flag must not render as a blank message.
    final hasAudioHint = audioUrl != null ||
        _string(json['audio_public_id']) != null ||
        json['has_audio'] == true;
    final durationMs = _intId(json['audio_duration_ms']) ??
        _durationMsFromSeconds(json['audio_duration']) ??
        _durationMsFromSeconds(json['duration']) ??
        _durationMsFromSeconds(json['voice_duration']);

    return CommentItem(
      id: _intId(json['id']),
      parentId: _intId(json['parent_id']),
      // Parsed rows start as "other"; [CommentsNotifier] re-marks the ones it
      // can attribute to the signed-in user. Ownership is not in the payload,
      // so it cannot be decided here — see `CommentsNotifier._resolveOwnership`.
      author: SkifluxCommentAuthor.other,
      body: hasAudioHint
          ? SkifluxCommentBody.voicenote
          : SkifluxCommentBody.message,
      authorName: name.isNotEmpty ? name : 'Learner',
      // No username in the payload — showing none beats inventing "@amara".
      handle: '',
      avatarUrl: _string(json['user_avatar']),
      message: text,
      audioUrl: audioUrl,
      durationLabel: formatVoiceDurationMs(durationMs),
      timeLabel: shortAgeLabel(createdAt),
      likeCount: json['like_count'] is int
          ? json['like_count'] as int
          : (json['like_count'] is num ? (json['like_count'] as num).toInt() : 0),
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

  /// Remote voice-note URL from the payload. The sheet resolves it to a cached
  /// local file (`voiceNoteCacheProvider`) before handing it to the player,
  /// which can only open a path.
  final String? audioUrl;

  /// Fallback `m:ss` label before the player reports a real length. Never the
  /// old hardcoded `0:10` — use `0:00` until known.
  final String durationLabel;

  final String timeLabel;
  final int likeCount;
  final bool isLiked;

  /// Nested replies straight off the payload; the store flattens them into
  /// the sheet's single list, after their parent.
  final List<CommentItem> replies;

  bool get isReply => parentId != null;

  CommentItem copyWith({
    int? id,
    int? likeCount,
    bool? isLiked,
    SkifluxCommentAuthor? author,
    SkifluxCommentBody? body,
    String? message,
    String? audioPath,
    String? audioUrl,
    String? durationLabel,
    bool clearAudioPath = false,
  }) => CommentItem(
    id: id ?? this.id,
    parentId: parentId,
    author: author ?? this.author,
    body: body ?? this.body,
    authorName: authorName,
    handle: handle,
    avatarUrl: avatarUrl,
    message: message ?? this.message,
    audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
    audioUrl: audioUrl ?? this.audioUrl,
    durationLabel: durationLabel ?? this.durationLabel,
    timeLabel: timeLabel,
    likeCount: likeCount ?? this.likeCount,
    isLiked: isLiked ?? this.isLiked,
    replies: replies,
  );
}

/// `m:ss` for a voice-note length. Null/unknown → `0:00` (never invent `0:10`).
String formatVoiceDurationMs(int? ms) {
  if (ms == null || ms <= 0) return '0:00';
  final d = Duration(milliseconds: ms);
  return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

int? _durationMsFromSeconds(Object? raw) {
  if (raw is int) return raw > 0 ? raw * 1000 : null;
  if (raw is num) {
    final n = raw.toDouble();
    if (n <= 0) return null;
    // Values > 1000 are already ms (e.g. 4500); smaller look like seconds.
    return n > 1000 ? n.round() : (n * 1000).round();
  }
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    // "0:07" / "1:05"
    final parts = trimmed.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (m != null && s != null) return ((m * 60) + s) * 1000;
    }
    final n = num.tryParse(trimmed);
    if (n != null) return _durationMsFromSeconds(n);
  }
  return null;
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
    // The sheet can open before `GET /me/profile` answers, and ownership is
    // resolved against that profile — so re-resolve when it lands rather than
    // leaving the user's own comments without Edit/Delete for the session.
    ref.listen(meProfileProvider, (_, _) {
      if (state.comments.isEmpty) return;
      state = state.copyWith(comments: _resolveOwnership(state.comments));
    });
    return const CommentsState(comments: []);
  }

  String? _episodeId;

  /// Backend ids of comments this session posted, so a row the user just wrote
  /// is theirs beyond doubt even if the name check below cannot prove it.
  final Set<int> _ownIds = <int>{};

  /// Local voice-note files recorded this session, keyed by server comment id.
  /// Survives `_load` so a reload that only returns `audio_url` does not leave
  /// the just-sent note unplayable.
  final Map<int, String> _localAudioById = <int, String>{};

  /// Path of a voice note that has been uploaded but not yet claimed a server
  /// id (between optimistic append and `_loadAndClaimNew`).
  String? _pendingLocalAudio;

  void init(String episodeId) {
    if (_episodeId == episodeId) return;
    _episodeId = episodeId;
    _pendingLocalAudio = null;
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
      final flat = _resolveOwnership(
        _withLocalAudio(_flatten(page.results)),
      ); // session paths only — no pending attach on a plain refresh
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

  /// Decide which rows the signed-in user may edit or delete.
  ///
  /// `EpisodeComment` carries no `user_id` and no `is_mine` — only
  /// `user_first_name` / `user_last_name`. So ownership is *inferred*: a row is
  /// treated as the user's when this session posted it (its id is in
  /// [_ownIds]), or when its author name matches the signed-in profile's
  /// first + last, case-insensitively.
  ///
  /// The name match is a heuristic and can be wrong: another learner with the
  /// same name would see Edit and Delete on their row. The server owns the
  /// decision — `PATCH`/`DELETE /comments/{id}/` reject a comment the caller
  /// does not own — and the sheet surfaces that rejection rather than pretending
  /// the write worked. Guessing *narrow* is the alternative and is worse: it
  /// hides Edit/Delete from every user for every one of their own comments.
  //
  // TODO(backend, minor): ownership is inferred from a display name because the
  // payload has no identity for the commenter — expects: `is_mine: bool` (or a
  // `user_id` uuid) on EpisodeComment.
  List<CommentItem> _resolveOwnership(List<CommentItem> comments) {
    final profile = ref.read(meProfileProvider).value;
    final me = profile == null
        ? ''
        : '${profile.firstName.trim()} ${profile.lastName.trim()}'
              .trim()
              .toLowerCase();

    bool isMine(CommentItem c) {
      if (c.id != null && _ownIds.contains(c.id)) return true;
      if (me.isEmpty) return false;
      return c.authorName.trim().toLowerCase() == me;
    }

    return List.unmodifiable([
      for (final c in comments)
        isMine(c) ? c.copyWith(author: SkifluxCommentAuthor.own) : c,
    ]);
  }

  /// Remember the ids that appeared since [before] — the rows a just-completed
  /// post added. Used after a send so the new comment is unambiguously ours
  /// even when the name check cannot decide.
  void _rememberOwnIds(Set<int> before) {
    for (final c in state.comments) {
      final id = c.id;
      if (id != null && !before.contains(id)) _ownIds.add(id);
    }
  }

  Set<int> _currentIds() => {
    for (final c in state.comments)
      if (c.id != null) c.id!,
  };

  /// Reload after a send, then claim whatever rows are new as this user's.
  ///
  /// The reload itself cannot know: [_resolveOwnership] runs inside [_load]
  /// with the id set as it was *before* the send. So the ids are diffed
  /// afterwards and ownership re-applied.
  ///
  /// Also re-attaches any session-local voice file paths: the GET payload only
  /// carries `audio_url`, and dropping the recorder's path was what made a
  /// just-sent note unplayable after refresh.
  Future<void> _loadAndClaimNew() async {
    final before = _currentIds();
    // Snapshot paths from the optimistic list before `_load` replaces it.
    for (final c in state.comments) {
      final id = c.id;
      final path = c.audioPath;
      if (id != null && path != null && path.isNotEmpty) {
        _localAudioById[id] = path;
      }
    }
    final pendingPath = _pendingLocalAudio;

    await _load();
    if (!ref.mounted) return;
    _rememberOwnIds(before);

    final newIds = _currentIds().difference(before);
    if (pendingPath != null && pendingPath.isNotEmpty) {
      for (final id in newIds) {
        _localAudioById.putIfAbsent(id, () => pendingPath);
      }
      if (newIds.isNotEmpty) _pendingLocalAudio = null;
    }

    var merged = _withLocalAudio(state.comments, claimPendingFor: newIds);

    // GET sometimes lags the POST — the optimistic voicenote would vanish and
    // leave nothing (or a blank text row). Keep a local playable row until the
    // server echoes it.
    if (pendingPath != null &&
        pendingPath.isNotEmpty &&
        newIds.isEmpty &&
        !merged.any((c) => c.audioPath == pendingPath)) {
      merged = List.unmodifiable([
        ...merged,
        CommentItem(
          author: SkifluxCommentAuthor.own,
          body: SkifluxCommentBody.voicenote,
          authorName: 'You',
          audioPath: pendingPath,
          timeLabel: 'now',
        ),
      ]);
    }

    state = state.copyWith(
      comments: _resolveOwnership(merged),
      totalCount: merged.length > state.totalCount
          ? merged.length
          : state.totalCount,
    );
  }

  /// Overlay session-local recorder paths onto rows that need them.
  ///
  /// Critical: the server often returns a just-uploaded voice note **without**
  /// `audio_url` (processing lag / field rename). `fromJson` then classifies
  /// it as an empty text message — which is the "blank comment" users saw
  /// after the optimistic voicenote disappeared. When we still hold the
  /// recorder file for that id (or a pending path for newly claimed ids),
  /// force [SkifluxCommentBody.voicenote] + [CommentItem.audioPath].
  List<CommentItem> _withLocalAudio(
    List<CommentItem> comments, {
    Set<int> claimPendingFor = const {},
  }) {
    if (_localAudioById.isEmpty &&
        (_pendingLocalAudio == null || claimPendingFor.isEmpty)) {
      return comments;
    }
    final pending = _pendingLocalAudio;
    final out = <CommentItem>[];
    for (final c in comments) {
      var path = c.id != null ? _localAudioById[c.id!] : null;
      if (path == null &&
          pending != null &&
          c.id != null &&
          claimPendingFor.contains(c.id)) {
        path = pending;
        _localAudioById[c.id!] = pending;
      }
      if (path == null || path.isEmpty) {
        out.add(c);
        continue;
      }
      if (c.body == SkifluxCommentBody.voicenote && c.audioPath == path) {
        out.add(c);
        continue;
      }
      out.add(
        c.copyWith(
          body: SkifluxCommentBody.voicenote,
          audioPath: path,
        ),
      );
    }
    return List.unmodifiable(out);
  }

  void setComposeState(SkifluxComposeState value) {
    if (state.composeState == value) return;
    state = state.copyWith(composeState: value);
  }

  // void togglePlay(int index) {
  //   final next = state.playingIndex == index ? null : index;
  //   state = state.copyWith(playingIndex: next, clearPlayingIndex: next == null);
  // }
  void setPlaying(int index) {
    state = state.copyWith(
      playingIndex: index,
    );
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
      unawaited(_loadAndClaimNew());
      // The feed rail's comment_count is a load-time snapshot; move it too.
      ref.read(feedEngagementProvider.notifier).bumpComments(episodeId, 1);
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
    _pendingLocalAudio = path;
    state = state.copyWith(
      comments: [...before, optimistic],
      totalCount: beforeCount + 1,
      composeState: SkifluxComposeState.idle,
    );
    try {
      final created = await ref
          .read(commentsRepositoryProvider)
          .postVoiceComment(episodeId, path);

      // Prefer the created row when the POST returns one — attach the local
      // recorder path immediately so playback never depends on a race with
      // GET /comments.
      if (created != null && ref.mounted) {
        final id = created.id;
        if (id != null) {
          _ownIds.add(id);
          _localAudioById[id] = path;
          _pendingLocalAudio = null;
        }
        final playable = created.copyWith(
          author: SkifluxCommentAuthor.own,
          // POST body often omits `audio_url` → fromJson would be a blank
          // message; keep the row as a playable voicenote with the local file.
          body: SkifluxCommentBody.voicenote,
          audioPath: path,
        );
        state = state.copyWith(
          comments: [
            for (final c in before) c,
            playable,
          ],
          totalCount: beforeCount + 1,
        );
      }

      // Still refresh for ids / ordering / remote audio_url, but keep local
      // paths via `_withLocalAudio`.
      unawaited(_loadAndClaimNew());
      ref.read(feedEngagementProvider.notifier).bumpComments(episodeId, 1);
    } catch (_) {
      _pendingLocalAudio = null;
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

  /// Edit one's own comment (`PATCH /comments/{id}/`) — optimistic text swap
  /// with rollback. No-ops on rows without a confirmed id.
  Future<void> editComment(CommentItem comment, String text) async {
    final id = comment.id;
    final trimmed = text.trim();
    if (id == null || trimmed.isEmpty || trimmed == comment.message) return;
    final before = state.comments;
    state = state.copyWith(
      comments: [
        for (final c in before)
          if (c.id == id) c.copyWith(message: trimmed) else c,
      ],
      composeState: SkifluxComposeState.idle,
    );
    try {
      await ref.read(commentsRepositoryProvider).editComment(id, trimmed);
    } catch (_) {
      // Includes the 403 a wrong ownership guess earns; the old text comes
      // back and the sheet says what happened.
      if (ref.mounted) state = state.copyWith(comments: before);
      rethrow;
    }
  }

  /// Delete one's own comment (`DELETE /comments/{id}/`) — optimistic removal
  /// of the row *and* any replies nested under it, with rollback.
  Future<void> deleteComment(CommentItem comment) async {
    final id = comment.id;
    if (id == null) return;
    final before = state.comments;
    final beforeCount = state.totalCount;
    // A deleted parent takes its replies with it, so the header count has to
    // drop by all of them, not by one.
    final removed = before
        .where((c) => c.id == id || c.parentId == id)
        .length;
    state = state.copyWith(
      comments: [
        for (final c in before)
          if (c.id != id && c.parentId != id) c,
      ],
      totalCount: beforeCount - removed >= 0 ? beforeCount - removed : 0,
    );
    try {
      await ref.read(commentsRepositoryProvider).deleteComment(id);
      final episodeId = _episodeId;
      if (episodeId != null && episodeId.isNotEmpty) {
        ref
            .read(feedEngagementProvider.notifier)
            .bumpComments(episodeId, -removed);
      }
      _ownIds.remove(id);
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(comments: before, totalCount: beforeCount);
      }
      rethrow;
    }
  }

  /// Report someone else's comment (`POST /comments/{id}/report/`).
  ///
  /// [category] is one of the spec's `ReportCommentCategoryEnum` wire values —
  /// the field is required, so the caller must have asked. Nothing about the
  /// row changes locally: a report is a message to moderation, and pretending
  /// the comment went away would be a lie.
  Future<void> reportComment(
    CommentItem comment,
    ReportCommentCategory category,
  ) async {
    final id = comment.id;
    if (id == null) return;
    await ref
        .read(commentsRepositoryProvider)
        .reportComment(id, category.wireValue);
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

/// Comment ids arrive as int, num, or numeric string depending on the envelope.
int? _intId(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
