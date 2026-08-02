import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../tokens/colors.dart';
import '../tokens/icons.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'avatar.dart';
import 'voice_waveform.dart';

/// Figma component set: **Comment** (`848:39488`)
///
/// Variants:
/// - Personal message | Other user message
/// - Personal voicenote | Other user voicenote
/// - Playing Personal Voicenote | Playing Others Voicenote
///
/// Structure: profile header (Avatar 40 + name + @handle), speech bubble
/// (`Background/Hover`, radius TL 4 / TR pill / BR pill / BL 64, Soft lift
/// shadow), then an action row — `30min · Reply` always, plus
/// `Edit · Delete` (own) or thumb down/up (others).
///
/// Voicenote playback is real when [audioPath] is set: each comment owns a
/// [PlayerController] for its file, the waveform is extracted from the
/// audio, tap-to-seek is enabled, and the duration label ticks live during
/// playback. Without [audioPath] the voicenote row renders the static
/// decorative waveform (demo mode).
enum SkifluxCommentAuthor { own, other }

enum SkifluxCommentBody { message, voicenote }

class SkifluxComment extends StatefulWidget {
  const SkifluxComment({
    super.key,
    required this.authorName,
    required this.handle,
    this.author = SkifluxCommentAuthor.other,
    this.body = SkifluxCommentBody.message,
    this.message,
    this.audioPath,
    this.duration = '0:10',
    this.playing = false,
    this.timeLabel = '30min',
    this.avatarImage,
    this.avatarInitials,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.liked = false,
    this.likeCount = 0,
    this.onThumbUp,
    this.onThumbDown,
    this.onPlayToggle,
    this.onPlaybackComplete,
    this.onPlaybackError,
    this.onAuthorTap,
  });

  final String authorName;
  final String handle;
  final SkifluxCommentAuthor author;
  final SkifluxCommentBody body;

  /// Text body — required when [body] is [SkifluxCommentBody.message].
  final String? message;

  /// Local path of the voicenote audio file. When set, playback and the
  /// waveform are driven by a real [PlayerController]; when null the
  /// voicenote row is decorative only.
  final String? audioPath;

  /// Fallback duration label used only when [audioPath] is null.
  final String duration;

  /// Voicenote playing state: pause icon + `Content/Brand` waveform.
  /// The parent owns this so it can enforce one-at-a-time playback.
  final bool playing;

  /// Relative timestamp, e.g. `30min`.
  final String timeLabel;

  final ImageProvider? avatarImage;
  final String? avatarInitials;

  /// Whether the signed-in user has liked this comment — fills the thumb-up
  /// and tints it brand. The parent owns it so the icon reflects the real
  /// `is_liked` from the payload plus the user's own optimistic toggle.
  final bool liked;

  /// `EpisodeComment.like_count`. Rendered beside the thumb-up, so the tally
  /// the payload already carries is visible — it was parsed and kept in sync
  /// through every optimistic toggle, and then shown nowhere.
  ///
  /// Zero prints nothing: a bare thumb reads as "no likes yet" more honestly
  /// than a "0" does.
  final int likeCount;

  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onThumbUp;
  final VoidCallback? onThumbDown;
  final VoidCallback? onPlayToggle;

  /// Fired when a real playback reaches the end of the file, so the parent
  /// can clear its playing flag.
  final VoidCallback? onPlaybackComplete;

  /// Raised when the audio file cannot be prepared for playback — a truncated
  /// or unreadable recording, a failed download. The row falls back to static
  /// bars; without this the failure was invisible and the note simply never
  /// made a sound.
  final ValueChanged<Object>? onPlaybackError;

  /// Opens public user profile when the avatar / name row is tapped.
  final VoidCallback? onAuthorTap;

  @override
  State<SkifluxComment> createState() => _SkifluxCommentState();
}

class _SkifluxCommentState extends State<SkifluxComment> {
  PlayerController? _player;
  StreamSubscription<int>? _positionSub;
  StreamSubscription<void>? _completionSub;
  int _positionMs = 0;

  /// Whether [PlayerController.preparePlayer] has actually resolved.
  ///
  /// `_player != null` is not the same question: the controller is assigned
  /// before prepare runs, so a failed or still-in-flight prepare used to leave
  /// a non-null but unusable controller — [AudioFileWaveforms] bound to it drew
  /// no progress and `startPlayer()` made no sound, silently. The waveform
  /// binds only once this is true, and a toggle that arrives mid-prepare is
  /// re-applied at the end of [_initPlayer] rather than dropped.
  bool _prepared = false;

  bool get _isOwn => widget.author == SkifluxCommentAuthor.own;

  bool get _hasAudio =>
      widget.body == SkifluxCommentBody.voicenote && widget.audioPath != null;

  @override
  void initState() {
    super.initState();
    if (_hasAudio) _initPlayer();
  }

  @override
  void didUpdateWidget(SkifluxComment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioPath != oldWidget.audioPath) {
      _disposePlayer();
      if (_hasAudio) _initPlayer();
    } else if (_prepared && _player != null &&
        widget.playing != oldWidget.playing) {
      // Parent toggled play state (tap here, or another comment started
      // and the parent paused this one). A toggle arriving before prepare
      // resolves is not lost — [_initPlayer] applies `widget.playing` when it
      // finishes.
      if (widget.playing) {
        _player!.startPlayer();
      } else {
        _player!.pausePlayer();
      }
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    final player = PlayerController();
    _player = player;
    _positionSub = player.onCurrentDurationChanged.listen((ms) {
      if (mounted) setState(() => _positionMs = ms);
    });
    _completionSub = player.onCompletion.listen((_) {
      if (mounted) {
        setState(() => _positionMs = 0);
        widget.onPlaybackComplete?.call();
      }
    });
    try {
      await player.setFinishMode(finishMode: FinishMode.pause);
      await player.preparePlayer(path: widget.audioPath!);
    } catch (error) {
      // An unprepared controller can neither draw nor play. Drop it so the row
      // renders the static bars, and tell the parent — silently swallowing this
      // is what made a broken note look like a working one.
      if (!mounted) return;
      _disposePlayer();
      setState(() {});
      widget.onPlaybackError?.call(error);
      return;
    }
    if (!mounted) return;
    // maxDuration is now known, and the waveform may bind.
    setState(() => _prepared = true);
    // Applies a toggle that arrived while prepare was still running, which
    // `didUpdateWidget` deliberately skipped.
    if (widget.playing) await player.startPlayer();
  }

  void _disposePlayer() {
    _positionSub?.cancel();
    _completionSub?.cancel();
    _player?.dispose();
    _player = null;
    _prepared = false;
    _positionMs = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _profileHeader(),
        const SizedBox(height: SkifluxSpacing.spaceS),
        _bubble(),
        const SizedBox(height: SkifluxSpacing.spaceS),
        _actionRow(),
      ],
    );
  }

  Widget _profileHeader() {
    return InkWell(
      onTap: widget.onAuthorTap,
      borderRadius: SkifluxRadii.borderM,
      child: Row(
        children: [
          SkifluxAvatar(
            style: widget.avatarImage != null
                ? SkifluxAvatarStyle.avatar
                : SkifluxAvatarStyle.initial,
            size: SkifluxUnit.u40,
            image: widget.avatarImage,
            initials: widget.avatarInitials ??
                (widget.authorName.isEmpty ? '?' : widget.authorName[0]),
          ),
          const SizedBox(width: SkifluxSpacing.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Figma: Creato Display Bold 18 with a 24px line height
                  // (24/18 ≈ 1.333, vs headingH9Bold's default 1.3).
                  style: SkifluxTypography.headingH9Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                    height: 24 / 18,
                  ),
                ),
                Text(
                  widget.handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.uiBadgeTagSmall.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: const BoxDecoration(
        color: SkifluxColors.backgroundHover,
        // Figma: rounded-tl-4 / tr-999 / br-999 / bl-64.
        // The raw Figma values render as visually uniform corners because
        // Figma clamps each radius to the available side; Flutter instead
        // scales ALL radii down together, which made the 64/999 mix look
        // lopsided (huge bottom-left swoop). Radius/XL on the three rounded
        // corners reproduces the clamped Figma appearance.
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(SkifluxRadii.xs),
          topRight: Radius.circular(SkifluxRadii.xl),
          bottomRight: Radius.circular(SkifluxRadii.xl),
          bottomLeft: Radius.circular(SkifluxRadii.xl),
        ),
        // Effect style: `Soft lift`
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: widget.body == SkifluxCommentBody.message
          ? _textBody()
          : _voiceBody(),
    );
  }

  Widget _textBody() {
    return Text(
      widget.message ?? '',
      style: SkifluxTypography.bodyP9Regular.copyWith(
        color: SkifluxColors.contentSecondary,
      ),
    );
  }

  Widget _voiceBody() {
    final waveColor = widget.playing
        ? SkifluxColors.contentBrand
        : SkifluxColors.contentBrandInactive;
    return Row(
      children: [
        // Play / pause control — Figma "Send" circle, Background/Brand.
        GestureDetector(
          onTap: widget.onPlayToggle,
          child: Container(
            width: SkifluxUnit.u28 + SkifluxSpacing.space2xs,
            height: SkifluxUnit.u28 + SkifluxSpacing.space2xs,
            decoration: const BoxDecoration(
              color: SkifluxColors.backgroundBrand,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.playing
                  ? RemixIcons.pause_mini_line
                  : RemixIcons.play_mini_fill,
              size: SkifluxIcons.sizeS,
              color: SkifluxColors.contentPrimaryInverse,
            ),
          ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceS),
        Expanded(
          child: _prepared && _player != null
              ? LayoutBuilder(
                  builder: (context, constraints) => AudioFileWaveforms(
                    size: Size(
                      constraints.maxWidth,
                      SkifluxWaveformStyle.maxHeight,
                    ),
                    playerController: _player!,
                    waveformType: WaveformType.fitWidth,
                    enableSeekGesture: true,
                    playerWaveStyle: SkifluxWaveformStyle.player(),
                  ),
                )
              // Static fallback: no audio, or prepare hasn't resolved (or
              // failed). Fill the row with bars so the waveform runs right up
              // to the duration label (same spaceS gap as between the play
              // button and the waveform).
              : LayoutBuilder(
                  builder: (context, constraints) => SkifluxVoiceWaveform(
                    barCount: ((constraints.maxWidth +
                                SkifluxWaveformStyle.barGap) /
                            SkifluxWaveformStyle.barPitch)
                        .floor(),
                  ),
                ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceS),
        Text(
          _durationLabel(),
          style: SkifluxTypography.uiInputLabel.copyWith(color: waveColor),
        ),
      ],
    );
  }

  String _durationLabel() {
    final player = _player;
    if (player == null) return widget.duration;
    // Elapsed while playing (or mid-seek), total length otherwise.
    final ms = widget.playing || _positionMs > 0
        ? _positionMs
        : player.maxDuration;
    if (ms <= 0) return widget.duration;
    final d = Duration(milliseconds: ms);
    final seconds = d.inSeconds % 60;
    return '${d.inMinutes}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Timestamp + text actions on the left, reactions on the right.
  ///
  /// An own comment used to return the left group alone, which cost it the
  /// thumb-up as well as the thumb-down — so the author could neither see nor
  /// change the like state on their own row. Only the thumb-down is withheld
  /// now: it opens a report, and reporting oneself is not a thing.
  ///
  /// The left group is a [Wrap] rather than a Row because an own comment
  /// carries four items (time, Reply, Edit, Delete); on a narrow sheet they
  /// flow onto a second line instead of overflowing.
  Widget _actionRow() {
    final left = Wrap(
      spacing: SkifluxSpacing.spaceM,
      runSpacing: SkifluxSpacing.spaceXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          widget.timeLabel,
          style: SkifluxTypography.uiButtonSmall.copyWith(
            color: SkifluxColors.contentDisabled,
          ),
        ),
        _action(
          icon: RemixIcons.question_answer_line,
          label: 'Reply',
          color: SkifluxColors.contentDisabled,
          onTap: widget.onReply,
        ),
        if (_isOwn) ...[
          _action(
            icon: RemixIcons.edit_2_line,
            label: 'Edit',
            color: SkifluxColors.contentDisabled,
            onTap: widget.onEdit,
          ),
          _action(
            icon: RemixIcons.delete_bin_6_line,
            label: 'Delete',
            color: SkifluxColors.contentNegative,
            onTap: widget.onDelete,
          ),
        ],
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: left),
        const SizedBox(width: SkifluxSpacing.spaceM),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isOwn) ...[
              GestureDetector(
                onTap: widget.onThumbDown,
                child: const Icon(
                  RemixIcons.thumb_down_line,
                  size: SkifluxIcons.sizeS,
                  color: SkifluxColors.contentDisabled,
                ),
              ),
              const SizedBox(
                  width: SkifluxSpacing.spaceS + SkifluxSpacing.space2xs),
            ],
            GestureDetector(
              onTap: widget.onThumbUp,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.liked
                        ? RemixIcons.thumb_up_fill
                        : RemixIcons.thumb_up_line,
                    size: SkifluxIcons.sizeS,
                    color: widget.liked
                        ? SkifluxColors.contentBrand
                        : SkifluxColors.contentDisabled,
                  ),
                  if (widget.likeCount > 0) ...[
                    const SizedBox(width: SkifluxSpacing.spaceXs),
                    Text(
                      '${widget.likeCount}',
                      style: SkifluxTypography.uiButtonSmall.copyWith(
                        color: widget.liked
                            ? SkifluxColors.contentBrand
                            : SkifluxColors.contentDisabled,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: SkifluxIcons.sizeS, color: color),
          const SizedBox(width: SkifluxSpacing.spaceXs),
          Text(
            label,
            style: SkifluxTypography.uiButtonSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
