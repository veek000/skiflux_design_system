/// Session state for the comments bottom sheet (Home Flow 09/10).
///
/// Riverpod choice: [NotifierProvider.autoDispose] — comment list, compose
/// mode, and voicenote playback index mutate together while the sheet is
/// open. Auto-dispose resets seed data when the sheet closes (matches the
/// previous StatefulWidget lifecycle). TextEditingController stays on the
/// widget (not Riverpod).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

/// One comment row (message or voicenote).
class CommentItem {
  const CommentItem({
    required this.author,
    required this.body,
    this.authorName = 'Amara Design',
    this.handle = '@amara',
    this.message,
    this.audioPath,
    this.timeLabel = '30min',
  });

  final SkifluxCommentAuthor author;
  final SkifluxCommentBody body;
  final String authorName;
  final String handle;
  final String? message;
  final String? audioPath;
  final String timeLabel;
}

/// Immutable snapshot of the comments sheet session.
class CommentsState {
  const CommentsState({
    required this.comments,
    this.composeState = SkifluxComposeState.idle,
    this.playingIndex,
  });

  final List<CommentItem> comments;
  final SkifluxComposeState composeState;
  final int? playingIndex;

  CommentsState copyWith({
    List<CommentItem>? comments,
    SkifluxComposeState? composeState,
    int? playingIndex,
    bool clearPlayingIndex = false,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      composeState: composeState ?? this.composeState,
      playingIndex:
          clearPlayingIndex ? null : (playingIndex ?? this.playingIndex),
    );
  }
}

class CommentsNotifier extends Notifier<CommentsState> {
  static const _messageText =
      "Hello, I need help tracking my order #NXC-8821. It's been 3 days "
      "and I haven't received any update.";

  @override
  CommentsState build() {
    // Figma order: personal message, other message, other voicenote,
    // personal voicenote.
    return const CommentsState(
      comments: [
        CommentItem(
          author: SkifluxCommentAuthor.own,
          body: SkifluxCommentBody.message,
          message: _messageText,
        ),
        CommentItem(
          author: SkifluxCommentAuthor.other,
          body: SkifluxCommentBody.message,
          authorName: 'Kofi Mensah',
          handle: '@kofisketch',
          message: _messageText,
        ),
        CommentItem(
          author: SkifluxCommentAuthor.other,
          body: SkifluxCommentBody.voicenote,
          authorName: 'Lola Motion',
          handle: '@lolamotion',
        ),
        CommentItem(
          author: SkifluxCommentAuthor.own,
          body: SkifluxCommentBody.voicenote,
        ),
      ],
    );
  }

  void setComposeState(SkifluxComposeState value) {
    if (state.composeState == value) return;
    state = state.copyWith(composeState: value);
  }

  void togglePlay(int index) {
    final next = state.playingIndex == index ? null : index;
    state = state.copyWith(
      playingIndex: next,
      clearPlayingIndex: next == null,
    );
  }

  void clearPlaying() {
    if (state.playingIndex == null) return;
    state = state.copyWith(clearPlayingIndex: true);
  }

  /// Append a recorded voicenote. Caller validates [path] is non-empty.
  void addVoiceNote(String path) {
    state = state.copyWith(
      comments: [
        ...state.comments,
        CommentItem(
          author: SkifluxCommentAuthor.own,
          body: SkifluxCommentBody.voicenote,
          audioPath: path,
          timeLabel: 'now',
        ),
      ],
    );
  }

  /// Append a text message and return to idle compose. No-op if [text] empty.
  void addMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      comments: [
        ...state.comments,
        CommentItem(
          author: SkifluxCommentAuthor.own,
          body: SkifluxCommentBody.message,
          message: trimmed,
          timeLabel: 'now',
        ),
      ],
      composeState: SkifluxComposeState.idle,
    );
  }
}

/// Sheet-scoped: disposed when the comments sheet unmounts.
// TODO(backend, blocking): replace seeded demo comments with real per-video comments fetched from backend, and persist sent comments/voicenotes server-side — expects: List<{author: SkifluxCommentAuthor, body: SkifluxCommentBody, authorName: String, handle: String, message: String?, audioPath: String?, timeLabel: String}>
final commentsProvider =
    NotifierProvider.autoDispose<CommentsNotifier, CommentsState>(
  CommentsNotifier.new,
);
