// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
// import 'package:skiflux_design_system/skiflux_design_system.dart';
//
// import '../../../shared/error_handling/error_display.dart';
// import '../../../shared/error_handling/error_handler.dart';
// import '../../../shared/sheets/confirm_sheet.dart';
// import '../../../shared/sheets/skiflux_sheet.dart';
// import '../../../shared/toast/skiflux_toast.dart';
// import '../../../shared/widgets/load_failure.dart';
// import '../../../shared/widgets/loading_skeletons.dart';
// import '../../../shared/widgets/network_image.dart';
// import '../data/comments_store.dart';
// import '../data/voice_note_cache.dart';
// import 'report_comment_sheet.dart';
//
// /// Figma: **Home & In-app Flow 10 / 09** (`198:13767`, `848:39525`)
// ///
// /// Comments bottom sheet — comment list + compose bar. The compose bar
// /// switches to its recording state via the mic button (`848:39483`); a
// /// sent recording uploads as a multipart `audio_file` and stays in the list
// /// as a real playable voicenote only if the upload succeeds. A note that came
// /// back from the server is downloaded to the app cache first (see
// /// [voiceNoteCacheProvider]) — the player takes a path, never a URL.
// ///
// /// Header count comes from the backend total, not a hardcoded number.
// /// Thumb-up posts the real `POST /comments/like` toggle; Reply posts to
// /// `POST /comments/{id}/reply/`. On the user's own rows, Edit reuses the
// /// compose bar (prefilled) against `PATCH /comments/{id}/` and Delete confirms
// /// before `DELETE /comments/{id}/`; on everyone else's, thumb-down asks for a
// /// category and posts `POST /comments/{id}/report/`. Author taps are disabled
// /// because the `EpisodeComment` payload carries no username/user id to
// /// navigate with.
// Future<void> showCommentsSheet(BuildContext context, String episodeId) {
//   return showSkifluxSheet(
//     context: context,
//     builder: (_) => _CommentsSheet(episodeId),
//   );
// }
//
// class _CommentsSheet extends ConsumerStatefulWidget {
//   const _CommentsSheet(this.episodeId);
//   final String episodeId;
//
//   @override
//   ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
// }
//
// class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
//   final TextEditingController _controller = TextEditingController();
//
//   final AudioPlayer _audioPlayer = AudioPlayer();
//
//   /// The row being edited, if any. Editing borrows the compose bar rather than
//   /// adding a second text field, so this is what tells `_sendComment` to
//   /// `PATCH` an existing comment instead of posting a new one.
//   CommentItem? _editing;
//
//   // @override
//   // void initState() {
//   //   super.initState();
//   //   WidgetsBinding.instance.addPostFrameCallback((_) {
//   //     ref.read(commentsProvider.notifier).init(widget.episodeId);
//   //   });
//   // }
//
//   @override
//   void initState() {
//     super.initState();
//
//     _audioPlayer.onPlayerComplete.listen((_) {
//       if (!mounted) return;
//
//       ref.read(commentsProvider.notifier).clearPlaying();
//     });
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(commentsProvider.notifier).init(widget.episodeId);
//     });
//   }
//
//   // @override
//   // void dispose() {
//   //   _controller.dispose();
//   //   super.dispose();
//   // }
//
//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   Future<void> _sendVoiceNote(String path) async {
//     try {
//       // An empty/invalid path is a failure of the record→send path itself.
//       if (path.trim().isEmpty) {
//         throw const SkifluxFailure(SkifluxErrorKind.voicenoteFailed);
//       }
//       await ref.read(commentsProvider.notifier).addVoiceNote(path);
//     } catch (e, st) {
//       if (!mounted) return;
//       await ErrorDisplay.show(
//         context,
//         ref,
//         e is SkifluxFailure
//             ? e
//             : SkifluxFailure(SkifluxErrorKind.voicenoteFailed, cause: e),
//         stackTrace: st,
//       );
//     }
//   }
//
//   /// The compose bar could not record. Returns it to idle so the user isn't
//   /// left staring at a recording UI that will never produce a note.
//   void _reportRecordingFailure(String reason) {
//     if (!mounted) return;
//     ref
//         .read(commentsProvider.notifier)
//         .setComposeState(SkifluxComposeState.idle);
//     SkifluxToast.error(context, reason);
//   }
//
//   Future<void> _sendComment() async {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;
//     final editing = _editing;
//     try {
//       if (editing != null) {
//         await ref.read(commentsProvider.notifier).editComment(editing, text);
//         if (mounted) {
//           setState(() => _editing = null);
//           _controller.clear();
//         }
//         return;
//       }
//       await ref.read(commentsProvider.notifier).addMessage(text);
//       if (mounted) _controller.clear();
//     } catch (e, st) {
//       if (!mounted) return;
//       // Toast: like/comment/reaction failed (classification table).
//       await ErrorDisplay.show(
//         context,
//         ref,
//         e is SkifluxFailure
//             ? e
//             : SkifluxFailure(
//                 SkifluxErrorKind.likeCommentReactionFailed,
//                 cause: e,
//               ),
//         stackTrace: st,
//       );
//     }
//   }
//
//   /// Load [comment]'s text into the compose bar. A reply in progress is
//   /// cancelled first — the bar can only be doing one of the two.
//   void _startEdit(CommentItem comment) {
//     ref.read(commentsProvider.notifier).cancelReply();
//     setState(() => _editing = comment);
//     _controller
//       ..text = comment.message ?? ''
//       ..selection = TextSelection.collapsed(offset: _controller.text.length);
//   }
//
//   void _cancelEdit() {
//     setState(() => _editing = null);
//     _controller.clear();
//   }
//
//   Future<void> _deleteComment(CommentItem comment) async {
//     final confirmed = await showConfirmSheet(
//       context,
//       title: 'Delete comment?',
//       message: comment.replies.isEmpty
//           ? 'This removes your comment for everyone. It cannot be undone.'
//           : 'This removes your comment and its replies for everyone. It '
//                 'cannot be undone.',
//       confirmLabel: 'Delete',
//       icon: RemixIcons.delete_bin_6_fill,
//     );
//     if (confirmed != true || !mounted) return;
//     // A row being edited that is now gone would leave the compose bar
//     // patching a deleted comment.
//     if (_editing?.id == comment.id) _cancelEdit();
//     try {
//       await ref.read(commentsProvider.notifier).deleteComment(comment);
//       if (mounted) SkifluxToast.success(context, 'Comment deleted');
//     } catch (e, st) {
//       if (!mounted) return;
//       // Includes the rejection an incorrect ownership guess earns; the row
//       // comes back and the user is told, rather than it silently reappearing.
//       await ErrorDisplay.show(context, ref, e, stackTrace: st);
//     }
//   }
//
//   Future<void> _reportComment(CommentItem comment) async {
//     final category = await showReportCommentSheet(context);
//     if (category == null || !mounted) return;
//     try {
//       await ref
//           .read(commentsProvider.notifier)
//           .reportComment(comment, category);
//       if (mounted) SkifluxToast.success(context, 'Thanks for your report');
//     } catch (e, st) {
//       if (!mounted) return;
//       await ErrorDisplay.show(context, ref, e, stackTrace: st);
//     }
//   }
//
//   Future<void> _toggleLike(CommentItem comment) async {
//     try {
//       await ref.read(commentsProvider.notifier).toggleCommentLike(comment);
//     } catch (e, st) {
//       if (!mounted) return;
//       await ErrorDisplay.show(context, ref, e, stackTrace: st);
//     }
//   }
//
//   Future<void> _playVoiceNote(int index, String audioPath) async {
//     try {
//       debugPrint('[VOICE PLAYER] Playing comment $index');
//       debugPrint('[VOICE PLAYER] Path: $audioPath');
//
//       // Stop whatever is currently playing.
//       await _audioPlayer.stop();
//
//       // Tell the UI which comment is playing.
//       ref.read(commentsProvider.notifier).setPlaying(index);
//
//       // Load the actual local file.
//       await _audioPlayer.setSource(
//         DeviceFileSource(audioPath),
//       );
//
//       // Start playback.
//       await _audioPlayer.resume();
//     } catch (e, st) {
//       debugPrint('[VOICE PLAYER] Playback failed: $e');
//       debugPrint('[VOICE PLAYER] Stack: $st');
//
//       _reportPlaybackFailure(index, e);
//     }
//   }
//
//   Future<void> _stopVoiceNote(int index) async {
//     try {
//       await _audioPlayer.stop();
//
//       ref.read(commentsProvider.notifier).clearPlaying();
//     } catch (e, st) {
//       debugPrint('[VOICE PLAYER] Stop failed: $e');
//       debugPrint('[VOICE PLAYER] Stack: $st');
//     }
//   }
//
//   /// A voice note whose audio can't be prepared. The row has already fallen
//   /// back to static bars; this says why, once, and clears any playing flag so
//   /// the play button doesn't sit stuck showing pause.
//   void _reportPlaybackFailure(int index, Object error) {
//     if (!mounted) return;
//     if (ref.read(commentsProvider).playingIndex == index) {
//       ref.read(commentsProvider.notifier).clearPlaying();
//     }
//     SkifluxToast.error(context, "That voice note couldn't be played");
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final session = ref.watch(commentsProvider);
//     final notifier = ref.read(commentsProvider.notifier);
//
//     return SkifluxSheetShell(
//       title: 'Comments',
//       count: session.totalCount,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Flexible(child: _list(session, notifier)),
//           if (_editing != null)
//             _ComposeContextBar(
//               icon: RemixIcons.edit_2_line,
//               label: 'Editing your comment',
//               onCancel: _cancelEdit,
//             )
//           else if (session.replyingTo != null)
//             _ComposeContextBar(
//               icon: RemixIcons.reply_line,
//               label: 'Replying to ${session.replyingTo!.authorName}',
//               onCancel: notifier.cancelReply,
//             ),
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: SkifluxSpacing.spaceL,
//             ),
//             child: SkifluxComposeBar(
//               state: session.composeState,
//               controller: _controller,
//               hintText: _editing != null
//                   ? 'Edit your comment...'
//                   : 'Add a comment...',
//               // Recording a voice note mid-edit would send a new comment
//               // rather than change the one being edited.
//               onMicTap: _editing != null
//                   ? null
//                   : () =>
//                         notifier.setComposeState(SkifluxComposeState.recording),
//               onDeleteTap: () =>
//                   notifier.setComposeState(SkifluxComposeState.idle),
//               onSendVoiceNote: _sendVoiceNote,
//               // A refused mic grant (or a capture that produced nothing) used
//               // to leave the bar showing a flat waveform and the send button
//               // doing nothing at all. Say what happened and put the bar back.
//               onRecordingFailed: _reportRecordingFailure,
//               onSend: _sendComment,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _list(CommentsState session, CommentsNotifier notifier) {
//     if (session.isLoading && session.comments.isEmpty) {
//       // Avatar, then the name over the comment body — the shape of the rows
//       // that follow, so the compose bar doesn't jump when they arrive.
//       return const ListRowSkeleton(rows: 5);
//     }
//     if (session.error != null && session.comments.isEmpty) {
//       return Padding(
//         padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
//         child: LoadFailure(
//           error: session.error!,
//           title: "We couldn't load comments",
//           onRetry: () => ref.read(commentsProvider.notifier).retry(),
//         ),
//       );
//     }
//     if (session.comments.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.all(SkifluxSpacing.space2xl),
//         child: SkifluxEmptyState(
//           icon: Icon(
//             RemixIcons.chat_3_line,
//             size: SkifluxEmptyState.iconSize,
//             color: SkifluxColors.contentBrand,
//           ),
//           title: 'No comments yet',
//           message: 'Be the first to say something about this episode.',
//         ),
//       );
//     }
//     return ListView.builder(
//       shrinkWrap: true,
//       controller: ModalScrollController.of(context),
//       padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
//       itemCount: session.comments.length,
//       itemBuilder: (context, i) {
//         final comment = _buildComment(i, session, notifier);
//         if (i == 0) return comment;
//         return Padding(
//           padding: const EdgeInsets.only(top: SkifluxSpacing.spaceL),
//           child: comment,
//         );
//       },
//     );
//   }
//
//   Widget _buildComment(
//     int index,
//     CommentsState session,
//     CommentsNotifier notifier,
//   ) {
//     final data = session.comments[index];
//     final isVoice = data.body == SkifluxCommentBody.voicenote;
//     // Prefer a session-local recorder path. Otherwise download `audio_url`
//     // into the cache — the player takes a path, never a URL.
//     final remoteUrl = (data.audioPath == null || data.audioPath!.isEmpty)
//         ? data.audioUrl
//         : null;
//     // final cacheAsync = isVoice && remoteUrl != null
//     //     ? ref.watch(voiceNoteCacheProvider(remoteUrl))
//     //     : null;
//     // final audioPath = data.audioPath ?? cacheAsync?.value;
//     final cacheAsync = isVoice && remoteUrl != null
//         ? ref.watch(voiceNoteCacheProvider(remoteUrl))
//         : null;
//
//     if (isVoice && remoteUrl != null) {
//       debugPrint('[VOICE] Comment ${data.id}');
//       debugPrint('[VOICE] Remote URL: $remoteUrl');
//       debugPrint('[VOICE] Cache state: $cacheAsync');
//       debugPrint('[VOICE] Cache value: ${cacheAsync?.value}');
//       debugPrint('[VOICE] Cache error: ${cacheAsync?.error}');
//     }
//
//     final audioPath = data.audioPath ?? cacheAsync?.value;
//     final playable = isVoice && audioPath != null;
//     final caching =
//         isVoice &&
//         !playable &&
//         remoteUrl != null &&
//         cacheAsync != null &&
//         cacheAsync.isLoading;
//     final isOwn = data.author == SkifluxCommentAuthor.own;
//     // Every write needs a confirmed backend id; optimistic rows have none yet.
//     final confirmed = data.id != null;
//     final Widget comment = SkifluxComment(
//       authorName: data.authorName,
//       handle: data.handle,
//       author: data.author,
//       body: data.body,
//       message: data.message,
//       audioPath: audioPath,
//       avatarImage: data.avatarUrl != null
//           ? skifluxImageProvider(data.avatarUrl!)
//           : null,
//       timeLabel: data.timeLabel,
//       playing: playable && session.playingIndex == index,
//       // onPlayToggle: playable
//       //     ? () => notifier.togglePlay(index)
//       //     : caching
//       //     ? () => SkifluxToast.info(context, 'Loading voice note…')
//       //     : null,
//       onPlayToggle: playable
//           ? () async {
//         final currentlyPlaying = session.playingIndex == index;
//
//         if (currentlyPlaying) {
//           await _stopVoiceNote(index);
//         } else {
//           await _playVoiceNote(index, audioPath!);
//         }
//       }
//           : caching
//           ? () => SkifluxToast.info(context, 'Loading voice note…')
//           : null,
//       onPlaybackComplete: playable ? notifier.clearPlaying : null,
//       // A note that can't be prepared used to fail silently — static bars, no
//       // sound, no explanation.
//       onPlaybackError: (error) => _reportPlaybackFailure(index, error),
//       onReply: confirmed ? () => notifier.startReply(data) : null,
//       // `POST /comments/like` is the thumb-up toggle. The count travels with
//       // it: `like_count` was parsed and kept in sync through every optimistic
//       // flip, and then never rendered anywhere.
//       liked: data.isLiked,
//       likeCount: data.likeCount,
//       onThumbUp: confirmed ? () => _toggleLike(data) : null,
//       // Thumb-down reports. Own rows don't render it at all (the DS hides it),
//       // and a voice note has no text to edit.
//       onThumbDown: confirmed && !isOwn ? () => _reportComment(data) : null,
//       onEdit: confirmed && isOwn && !isVoice ? () => _startEdit(data) : null,
//       onDelete: confirmed && isOwn ? () => _deleteComment(data) : null,
//       // No username/user id on the payload → no honest profile to open.
//       onAuthorTap: null,
//     );
//     if (!data.isReply) return comment;
//     // Replies sit inset under their parent in the flat list.
//     return Padding(
//       padding: const EdgeInsets.only(left: SkifluxSpacing.spaceXl),
//       child: comment,
//     );
//   }
// }
//
// /// One-line strip over the compose bar naming what the next send will do —
// /// "Replying to {name}" or "Editing your comment" — with a cancel affordance.
// /// Without it, Reply (or Edit) would silently reroute the next send.
// class _ComposeContextBar extends StatelessWidget {
//   const _ComposeContextBar({
//     required this.icon,
//     required this.label,
//     required this.onCancel,
//   });
//
//   final IconData icon;
//   final String label;
//   final VoidCallback onCancel;
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//         SkifluxSpacing.spaceL,
//         0,
//         SkifluxSpacing.spaceL,
//         SkifluxSpacing.spaceS,
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             size: SkifluxIcons.sizeS,
//             color: SkifluxColors.contentTertiary,
//           ),
//           const SizedBox(width: SkifluxSpacing.spaceS),
//           Expanded(
//             child: Text(
//               label,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: SkifluxTypography.bodyP11Regular.copyWith(
//                 color: SkifluxColors.contentTertiary,
//               ),
//             ),
//           ),
//           GestureDetector(
//             onTap: onCancel,
//             child: const Icon(
//               RemixIcons.close_line,
//               size: SkifluxIcons.sizeS,
//               color: SkifluxColors.contentTertiary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/error_handling/error_display.dart';
import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/sheets/confirm_sheet.dart';
import '../../../shared/sheets/skiflux_sheet.dart';
import '../../../shared/toast/skiflux_toast.dart';
import '../../../shared/widgets/load_failure.dart';
import '../../../shared/widgets/loading_skeletons.dart';
import '../../../shared/widgets/network_image.dart';
import '../data/comments_store.dart';
import '../data/voice_note_cache.dart';
import 'report_comment_sheet.dart';

/// Figma: **Home & In-app Flow 10 / 09** (`198:13767`, `848:39525`)
///
/// Comments bottom sheet — comment list + compose bar. The compose bar
/// switches to its recording state via the mic button (`848:39483`); a
/// sent recording uploads as a multipart `audio_file` and stays in the list
/// as a real playable voicenote only if the upload succeeds. A note that came
/// back from the server is downloaded to the app cache first (see
/// [voiceNoteCacheProvider]) — the player takes a path, never a URL.
///
/// Voicenote playback itself is owned entirely by [SkifluxComment]: each row
/// preps and plays its own file through its own `PlayerController` once
/// [SkifluxComment.playing] is true. This sheet's only job is deciding *which*
/// index is playing, via [CommentsNotifier.setPlaying] /
/// [CommentsNotifier.clearPlaying] — it does not touch audio directly.
///
/// Header count comes from the backend total, not a hardcoded number.
/// Thumb-up posts the real `POST /comments/like` toggle; Reply posts to
/// `POST /comments/{id}/reply/`. On the user's own rows, Edit reuses the
/// compose bar (prefilled) against `PATCH /comments/{id}/` and Delete confirms
/// before `DELETE /comments/{id}/`; on everyone else's, thumb-down asks for a
/// category and posts `POST /comments/{id}/report/`. Author taps are disabled
/// because the `EpisodeComment` payload carries no username/user id to
/// navigate with.
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

  /// The row being edited, if any. Editing borrows the compose bar rather than
  /// adding a second text field, so this is what tells `_sendComment` to
  /// `PATCH` an existing comment instead of posting a new one.
  CommentItem? _editing;

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

  Future<void> _sendVoiceNote(String path, Duration duration) async {
    try {
      // An empty/invalid path is a failure of the record→send path itself.
      if (path.trim().isEmpty) {
        throw const SkifluxFailure(SkifluxErrorKind.voicenoteFailed);
      }
      await ref
          .read(commentsProvider.notifier)
          .addVoiceNote(path, duration: duration);
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

  /// The compose bar could not record. Returns it to idle so the user isn't
  /// left staring at a recording UI that will never produce a note.
  void _reportRecordingFailure(String reason) {
    if (!mounted) return;
    ref
        .read(commentsProvider.notifier)
        .setComposeState(SkifluxComposeState.idle);
    SkifluxToast.error(context, reason);
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final editing = _editing;
    try {
      if (editing != null) {
        await ref.read(commentsProvider.notifier).editComment(editing, text);
        if (mounted) {
          setState(() => _editing = null);
          _controller.clear();
        }
        return;
      }
      await ref.read(commentsProvider.notifier).addMessage(text);
      if (mounted) _controller.clear();
    } catch (e, st) {
      if (!mounted) return;
      // Toast: like/comment/reaction failed (classification table).
      await ErrorDisplay.show(
        context,
        ref,
        e is SkifluxFailure
            ? e
            : SkifluxFailure(
          SkifluxErrorKind.likeCommentReactionFailed,
          cause: e,
        ),
        stackTrace: st,
      );
    }
  }

  /// Load [comment]'s text into the compose bar. A reply in progress is
  /// cancelled first — the bar can only be doing one of the two.
  void _startEdit(CommentItem comment) {
    ref.read(commentsProvider.notifier).cancelReply();
    setState(() => _editing = comment);
    _controller
      ..text = comment.message ?? ''
      ..selection = TextSelection.collapsed(offset: _controller.text.length);
  }

  void _cancelEdit() {
    setState(() => _editing = null);
    _controller.clear();
  }

  Future<void> _deleteComment(CommentItem comment) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Delete comment?',
      message: comment.replies.isEmpty
          ? 'This removes your comment for everyone. It cannot be undone.'
          : 'This removes your comment and its replies for everyone. It '
          'cannot be undone.',
      confirmLabel: 'Delete',
      icon: RemixIcons.delete_bin_6_fill,
    );
    if (confirmed != true || !mounted) return;
    // A row being edited that is now gone would leave the compose bar
    // patching a deleted comment.
    if (_editing?.id == comment.id) _cancelEdit();
    try {
      await ref.read(commentsProvider.notifier).deleteComment(comment);
      if (mounted) SkifluxToast.success(context, 'Comment deleted');
    } catch (e, st) {
      if (!mounted) return;
      // Includes the rejection an incorrect ownership guess earns; the row
      // comes back and the user is told, rather than it silently reappearing.
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  Future<void> _reportComment(CommentItem comment) async {
    final category = await showReportCommentSheet(context);
    if (category == null || !mounted) return;
    try {
      await ref
          .read(commentsProvider.notifier)
          .reportComment(comment, category);
      if (mounted) SkifluxToast.success(context, 'Thanks for your report');
    } catch (e, st) {
      if (!mounted) return;
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  Future<void> _toggleLike(CommentItem comment) async {
    try {
      await ref.read(commentsProvider.notifier).toggleCommentLike(comment);
    } catch (e, st) {
      if (!mounted) return;
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  /// Flip which row is "playing". [SkifluxComment] owns the actual audio —
  /// this only decides which index it should be true for, so only one row
  /// plays at a time.
  void _togglePlay(int index) {
    final notifier = ref.read(commentsProvider.notifier);
    if (ref.read(commentsProvider).playingIndex == index) {
      notifier.clearPlaying();
    } else {
      notifier.setPlaying(index);
    }
  }

  /// A voice note whose audio can't be prepared. The row has already fallen
  /// back to static bars; this says why, once, and clears any playing flag so
  /// the play button doesn't sit stuck showing pause.
  void _reportPlaybackFailure(int index, Object error) {
    if (!mounted) return;
    if (ref.read(commentsProvider).playingIndex == index) {
      ref.read(commentsProvider.notifier).clearPlaying();
    }
    SkifluxToast.error(context, "That voice note couldn't be played");
  }


  int? _durationMsFromLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty || trimmed == '0:00') return null;
    final parts = trimmed.split(':');
    if (parts.length != 2) return null;
    final m = int.tryParse(parts[0]);
    final s = int.tryParse(parts[1]);
    if (m == null || s == null) return null;
    final ms = ((m * 60) + s) * 1000;
    return ms > 0 ? ms : null;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(commentsProvider);
    final notifier = ref.read(commentsProvider.notifier);

    return SkifluxSheetShell(
      title: 'Comments',
      count: session.totalCount,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: _list(session, notifier)),
          if (_editing != null)
            _ComposeContextBar(
              icon: RemixIcons.edit_2_line,
              label: 'Editing your comment',
              onCancel: _cancelEdit,
            )
          else if (session.replyingTo != null)
            _ComposeContextBar(
              icon: RemixIcons.reply_line,
              label: 'Replying to ${session.replyingTo!.authorName}',
              onCancel: notifier.cancelReply,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceL,
            ),
            child: SkifluxComposeBar(
              state: session.composeState,
              controller: _controller,
              hintText: _editing != null
                  ? 'Edit your comment...'
                  : 'Add a comment...',
              // Recording a voice note mid-edit would send a new comment
              // rather than change the one being edited.
              onMicTap: _editing != null
                  ? null
                  : () =>
                  notifier.setComposeState(SkifluxComposeState.recording),
              onDeleteTap: () =>
                  notifier.setComposeState(SkifluxComposeState.idle),
              onSendVoiceNote: _sendVoiceNote,
              // A refused mic grant (or a capture that produced nothing) used
              // to leave the bar showing a flat waveform and the send button
              // doing nothing at all. Say what happened and put the bar back.
              onRecordingFailed: _reportRecordingFailure,
              onSend: _sendComment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(CommentsState session, CommentsNotifier notifier) {
    if (session.isLoading && session.comments.isEmpty) {
      // Avatar, then the name over the comment body — the shape of the rows
      // that follow, so the compose bar doesn't jump when they arrive.
      return const ListRowSkeleton(rows: 5);
    }
    if (session.error != null && session.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        child: LoadFailure(
          error: session.error!,
          title: "We couldn't load comments",
          onRetry: () => ref.read(commentsProvider.notifier).retry(),
        ),
      );
    }
    if (session.comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(SkifluxSpacing.space2xl),
        child: SkifluxEmptyState(
          icon: Icon(
            RemixIcons.chat_3_line,
            size: SkifluxEmptyState.iconSize,
            color: SkifluxColors.contentBrand,
          ),
          title: 'No comments yet',
          message: 'Be the first to say something about this episode.',
        ),
      );
    }
    return ListView.builder(
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
    );
  }

  Widget _buildComment(
      int index,
      CommentsState session,
      CommentsNotifier notifier,
      ) {
    final data = session.comments[index];
    final isVoice = data.body == SkifluxCommentBody.voicenote;
    // Prefer a session-local recorder path. Otherwise download `audio_url`
    // into the cache — the player takes a path, never a URL.
    final remoteUrl = (data.audioPath == null || data.audioPath!.isEmpty)
        ? data.audioUrl
        : null;
    final cacheAsync = isVoice && remoteUrl != null
        ? ref.watch(voiceNoteCacheProvider(remoteUrl))
        : null;

    final audioPath = data.audioPath ?? cacheAsync?.value;
    final playable = isVoice && audioPath != null;
    final caching =
        isVoice &&
            !playable &&
            remoteUrl != null &&
            cacheAsync != null &&
            cacheAsync.isLoading;
    final isOwn = data.author == SkifluxCommentAuthor.own;
    // Every write needs a confirmed backend id; optimistic rows have none yet.
    final confirmed = data.id != null;
    final durationMs = _durationMsFromLabel(data.durationLabel);
    final Widget comment = SkifluxComment(
      // Stable identity so a post-upload rebuild doesn't dispose the player
      // mid-prepare (which left just-sent notes silent with `0:00`).
      key: ValueKey(
        'comment-${data.id ?? data.audioPath ?? data.audioUrl ?? index}',
      ),
      authorName: data.authorName,
      handle: data.handle,
      author: data.author,
      body: data.body,
      message: data.message,
      audioPath: audioPath,
      // Real length comes from the player once prepared; seed from the
      // recorder/API so the label isn't blank while prepare runs.
      duration: data.durationLabel,
      durationMs: durationMs,
      avatarImage: data.avatarUrl != null
          ? skifluxImageProvider(data.avatarUrl!)
          : null,
      timeLabel: data.timeLabel,
      playing: playable && session.playingIndex == index,
      onPlayToggle: playable
          ? () => _togglePlay(index)
          : caching
          ? () => SkifluxToast.info(context, 'Loading voice note…')
          : null,
      onPlaybackComplete: playable ? notifier.clearPlaying : null,
      // A note that can't be prepared used to fail silently — static bars, no
      // sound, no explanation.
      onPlaybackError: (error) => _reportPlaybackFailure(index, error),
      onReply: confirmed ? () => notifier.startReply(data) : null,
      // `POST /comments/like` is the thumb-up toggle. The count travels with
      // it: `like_count` was parsed and kept in sync through every optimistic
      // flip, and then never rendered anywhere.
      liked: data.isLiked,
      likeCount: data.likeCount,
      onThumbUp: confirmed ? () => _toggleLike(data) : null,
      // Thumb-down reports. Own rows don't render it at all (the DS hides it),
      // and a voice note has no text to edit.
      onThumbDown: confirmed && !isOwn ? () => _reportComment(data) : null,
      onEdit: confirmed && isOwn && !isVoice ? () => _startEdit(data) : null,
      onDelete: confirmed && isOwn ? () => _deleteComment(data) : null,
      // No username/user id on the payload → no honest profile to open.
      onAuthorTap: null,
    );
    if (!data.isReply) return comment;
    // Replies sit inset under their parent in the flat list.
    return Padding(
      padding: const EdgeInsets.only(left: SkifluxSpacing.spaceXl),
      child: comment,
    );
  }
}

/// One-line strip over the compose bar naming what the next send will do —
/// "Replying to {name}" or "Editing your comment" — with a cancel affordance.
/// Without it, Reply (or Edit) would silently reroute the next send.
class _ComposeContextBar extends StatelessWidget {
  const _ComposeContextBar({
    required this.icon,
    required this.label,
    required this.onCancel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onCancel;


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SkifluxSpacing.spaceL,
        0,
        SkifluxSpacing.spaceL,
        SkifluxSpacing.spaceS,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: SkifluxIcons.sizeS,
            color: SkifluxColors.contentTertiary,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SkifluxTypography.bodyP11Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: const Icon(
              RemixIcons.close_line,
              size: SkifluxIcons.sizeS,
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ],
      ),
    );
  }
}