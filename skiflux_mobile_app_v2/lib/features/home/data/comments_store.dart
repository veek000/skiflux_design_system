import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'comments_repository.dart';

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

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      author: SkifluxCommentAuthor.other,
      body: json['comment_type'] == 'voice' ? SkifluxCommentBody.voicenote : SkifluxCommentBody.message,
      authorName: (json['author']?['display_name'] as String?) ?? 'Unknown',
      handle: '@${(json['author']?['username'] as String?) ?? ''}',
      message: json['comment'] as String?,
      timeLabel: 'now',
    );
  }

  final SkifluxCommentAuthor author;
  final SkifluxCommentBody body;
  final String authorName;
  final String handle;
  final String? message;
  final String? audioPath;
  final String timeLabel;
}

class CommentsState {
  const CommentsState({
    required this.comments,
    this.playingIndex,
    this.clearPlayingIndex = false,
    this.composeState = SkifluxComposeState.idle,
    this.isLoading = false,
  });

  final List<CommentItem> comments;
  final int? playingIndex;
  final bool clearPlayingIndex;
  final SkifluxComposeState composeState;
  final bool isLoading;

  CommentsState copyWith({
    List<CommentItem>? comments,
    int? playingIndex,
    bool clearPlayingIndex = false,
    SkifluxComposeState? composeState,
    bool? isLoading,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      playingIndex: clearPlayingIndex ? null : (playingIndex ?? this.playingIndex),
      clearPlayingIndex: false,
      composeState: composeState ?? this.composeState,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CommentsNotifier extends Notifier<CommentsState> {
  @override
  CommentsState build() {
    return const CommentsState(comments: [], isLoading: true);
  }

  String? _arg;

  void init(String arg) {
    if (_arg == arg) return;
    _arg = arg;
    _load();
  }

  Future<void> _load() async {
    if (_arg == null) return;
    try {
      final repo = ref.read(commentsRepositoryProvider);
      final json = await repo.getComments(_arg!);
      final List<dynamic> results = json['results'] as List<dynamic>? ?? [];
      final comments = results.map((e) => CommentItem.fromJson(e as Map<String, dynamic>)).toList();
      state = state.copyWith(comments: comments, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
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
      composeState: SkifluxComposeState.idle,
    );
  }

  Future<void> addMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _arg == null) return;

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

    try {
      await ref.read(commentsRepositoryProvider).postComment(_arg!, trimmed);
    } catch (e) {
      // Handle error natively
    }
  }
}

final commentsProvider = NotifierProvider<CommentsNotifier, CommentsState>(
  CommentsNotifier.new,
);
