import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/sheets/skiflux_sheet.dart';
import '../../profile/public_user_profile_screen.dart';

/// Figma: **Home & In-app Flow 10 / 09** (`198:13767`, `848:39525`)
///
/// Comments bottom sheet — comment list + compose bar. The compose bar
/// switches to its recording state via the mic button (`848:39483`); a
/// sent recording is appended to the list as a real playable voicenote.
Future<void> showCommentsSheet(BuildContext context) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => const _CommentsSheet(),
  );
}

/// Demo comment data. Voicenotes recorded in this session carry a real
/// [audioPath]; the two seeded Figma voicenotes have none (static bars).
class _CommentData {
  const _CommentData({
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

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet();

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  SkifluxComposeState _composeState = SkifluxComposeState.idle;
  final TextEditingController _controller = TextEditingController();

  /// Index of the voicenote currently playing, if any. Passing `playing`
  /// down flips each comment's own PlayerController, so switching index
  /// really pauses the previous player (not just its icon).
  int? _playingIndex;

  static const _messageText =
      "Hello, I need help tracking my order #NXC-8821. It's been 3 days "
      "and I haven't received any update.";

  // Figma order: personal message, other message, other voicenote,
  // personal voicenote.
  final List<_CommentData> _comments = [
    const _CommentData(
      author: SkifluxCommentAuthor.own,
      body: SkifluxCommentBody.message,
      message: _messageText,
    ),
    const _CommentData(
      author: SkifluxCommentAuthor.other,
      body: SkifluxCommentBody.message,
      authorName: 'Kofi Mensah',
      handle: '@kofisketch',
      message: _messageText,
    ),
    const _CommentData(
      author: SkifluxCommentAuthor.other,
      body: SkifluxCommentBody.voicenote,
      authorName: 'Lola Motion',
      handle: '@lolamotion',
    ),
    const _CommentData(
      author: SkifluxCommentAuthor.own,
      body: SkifluxCommentBody.voicenote,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay(int index) {
    setState(() => _playingIndex = _playingIndex == index ? null : index);
  }

  void _sendVoiceNote(String path) {
    setState(() {
      _comments.add(_CommentData(
        author: SkifluxCommentAuthor.own,
        body: SkifluxCommentBody.voicenote,
        audioPath: path,
        timeLabel: 'now',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: 'Comments',
      count: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              children: [
                for (var i = 0; i < _comments.length; i++) ...[
                  if (i > 0) const SizedBox(height: SkifluxSpacing.spaceL),
                  _buildComment(i),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceL,
            ),
            child: SkifluxComposeBar(
              state: _composeState,
              controller: _controller,
              onMicTap: () => setState(
                () => _composeState = SkifluxComposeState.recording,
              ),
              onDeleteTap: () => setState(
                () => _composeState = SkifluxComposeState.idle,
              ),
              onSendVoiceNote: _sendVoiceNote,
              onSend: () {
                _controller.clear();
                setState(() => _composeState = SkifluxComposeState.idle);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(int index) {
    final data = _comments[index];
    final isVoice = data.body == SkifluxCommentBody.voicenote;
    return SkifluxComment(
      authorName: data.authorName,
      handle: data.handle,
      author: data.author,
      body: data.body,
      message: data.message,
      audioPath: data.audioPath,
      timeLabel: data.timeLabel,
      playing: isVoice && _playingIndex == index,
      onPlayToggle: isVoice ? () => _togglePlay(index) : null,
      onPlaybackComplete:
          isVoice ? () => setState(() => _playingIndex = null) : null,
      onAuthorTap: () {
        // Dismiss comments, then open public learner profile.
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PublicUserProfileScreen(
              profile: PublicUserProfile.demo(
                name: data.authorName,
                username: data.handle.replaceFirst('@', ''),
              ),
            ),
          ),
        );
      },
    );
  }
}
