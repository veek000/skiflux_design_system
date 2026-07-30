import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/error_handling/error_display.dart';
import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/sheets/skiflux_sheet.dart';
import '../../profile/public_user_profile_screen.dart';
import '../data/comments_store.dart';

/// Figma: **Home & In-app Flow 10 / 09** (`198:13767`, `848:39525`)
///
/// Comments bottom sheet — comment list + compose bar. The compose bar
/// switches to its recording state via the mic button (`848:39483`); a
/// sent recording is appended to the list as a real playable voicenote.
///
/// Feature state: [commentsProvider] (autoDispose). Local only:
/// [TextEditingController].
Future<void> showCommentsSheet(BuildContext context, String episodeId) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => _CommentsSheet(episodeId),
  );
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet(this.episodeId);
  final String episodeId;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(commentsProvider.notifier).init(widget.episodeId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendVoiceNote(String path) async {
    try {
      // Local validation until an upload API exists — empty/invalid path
      // is a real failure of the record→send path.
      if (path.trim().isEmpty) {
        throw const SkifluxFailure(SkifluxErrorKind.voicenoteFailed);
      }
      ref.read(commentsProvider.notifier).addVoiceNote(path);
    } catch (e, st) {
      if (!mounted) return;
      await ErrorDisplay.show(
        context,
        ref,
        e is SkifluxFailure
            ? e
            : SkifluxFailure(SkifluxErrorKind.voicenoteFailed, cause: e),
        stackTrace: st,
      );
    }
  }

  Future<void> _sendComment() async {
    try {
      final text = _controller.text.trim();
      if (text.isEmpty) return;
      await ref.read(commentsProvider.notifier).addMessage(text);
      _controller.clear();
    } catch (e, st) {
      if (!mounted) return;
      // Toast: like/comment/reaction failed (classification table).
      await ErrorDisplay.show(
        context,
        ref,
        SkifluxFailure(SkifluxErrorKind.likeCommentReactionFailed, cause: e),
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(commentsProvider);
    final notifier = ref.read(commentsProvider.notifier);

    return SkifluxSheetShell(
      title: 'Comments',
      count: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              controller: ModalScrollController.of(context),
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              itemCount: session.comments.length,
              itemBuilder: (context, i) {
                final comment = _buildComment(i, session, notifier);
                if (i == 0) return comment;
                return Padding(
                  padding: const EdgeInsets.only(top: SkifluxSpacing.spaceL),
                  child: comment,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceL,
            ),
            child: SkifluxComposeBar(
              state: session.composeState,
              controller: _controller,
              onMicTap: () =>
                  notifier.setComposeState(SkifluxComposeState.recording),
              onDeleteTap: () =>
                  notifier.setComposeState(SkifluxComposeState.idle),
              onSendVoiceNote: _sendVoiceNote,
              onSend: _sendComment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(
    int index,
    CommentsState session,
    CommentsNotifier notifier,
  ) {
    final data = session.comments[index];
    final isVoice = data.body == SkifluxCommentBody.voicenote;
    return SkifluxComment(
      authorName: data.authorName,
      handle: data.handle,
      author: data.author,
      body: data.body,
      message: data.message,
      audioPath: data.audioPath,
      timeLabel: data.timeLabel,
      playing: isVoice && session.playingIndex == index,
      onPlayToggle: isVoice ? () => notifier.togglePlay(index) : null,
      onPlaybackComplete: isVoice ? notifier.clearPlaying : null,
      onAuthorTap: () {
        // Dismiss comments, then open public learner profile.
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PublicUserProfileScreen(
              username: data.handle.replaceAll('@', ''),
            ),
          ),
        );
      },
    );
  }
}
