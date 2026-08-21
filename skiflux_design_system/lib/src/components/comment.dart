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
    this.duration = '0:00',
    this.durationMs,
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

  /// Fallback duration label used only when the player has not yet reported a
  /// real length (no [audioPath], or prepare still in flight). Prefer a real
  /// value from the file/`duration_ms` payload — the old `'0:10'` default made
  /// every note look 10 seconds long.
  final String duration;

  /// Known length in milliseconds (from the recorder or API). Seeds the label
  /// immediately so a just-sent note shows e.g. `0:07` before prepare finishes.
  final int? durationMs;

  /// Voicenote playing state: pause icon + brand waveform + remaining-time
  /// countdown (WhatsApp-style). The parent owns this so it can enforce
  /// one-at-a-time playback.
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
  StreamSubscription<PlayerState>? _stateSub;
  int _positionMs = 0;

  /// Total length in ms once [preparePlayer] resolves. Kept locally so the
  /// duration label does not depend on reading [PlayerController.maxDuration]
  /// after dispose races, and so we can show a remaining-time countdown.
  int _totalMs = 0;

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

  bool get _isActivelyPlaying => widget.playing && _prepared;

  @override
  void initState() {
    super.initState();
    _seedTotalFromWidget();
    if (_hasAudio) _initPlayer();
  }

  void _seedTotalFromWidget() {
    final seeded = widget.durationMs ?? _parseDurationLabel(widget.duration);
    if (seeded != null && seeded > 0 && _totalMs <= 0) {
      _totalMs = seeded;
    }
  }

  /// Parses `m:ss` / `mm:ss` labels. Returns null for empty/`0:00`.
  static int? _parseDurationLabel(String label) {
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
  void didUpdateWidget(SkifluxComment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.durationMs != oldWidget.durationMs ||
        widget.duration != oldWidget.duration) {
      _seedTotalFromWidget();
    }
    if (widget.audioPath != oldWidget.audioPath) {
      _disposePlayer();
      _seedTotalFromWidget();
      if (_hasAudio) _initPlayer();
    } else if (_prepared && _player != null &&
        widget.playing != oldWidget.playing) {
      // Parent toggled play state (tap here, or another comment started
      // and the parent paused this one). A toggle arriving before prepare
      // resolves is not lost — [_initPlayer] applies `widget.playing` when it
      // finishes.
      if (widget.playing) {
        unawaited(_player!.startPlayer());
      } else {
        unawaited(_player!.pausePlayer());
      }
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    final path = widget.audioPath;
    if (path == null || path.isEmpty) return;

    final player = PlayerController();
    // Smoother remaining-time ticks while playing (WhatsApp-like).
    player.updateFrequency = UpdateFrequency.high;
    _player = player;
    _positionSub = player.onCurrentDurationChanged.listen((ms) {
      if (!mounted) return;
      setState(() => _positionMs = ms < 0 ? 0 : ms);
    });
    _stateSub = player.onPlayerStateChanged.listen((_) {
      // Rebuild so the pause icon / brand waveform stay in sync if the native
      // player pauses itself (e.g. audio focus loss).
      if (mounted) setState(() {});
    });
    _completionSub = player.onCompletion.listen((_) {
      if (!mounted) return;
      setState(() => _positionMs = 0);
      widget.onPlaybackComplete?.call();
    });
    try {
      await player.setFinishMode(finishMode: FinishMode.pause);
      // Normalize Windows/file URIs the same way the package expects.
      final normalized = path.startsWith('file:')
          ? Uri.parse(path).toFilePath()
          : path;
      await player.preparePlayer(
        path: normalized,
        shouldExtractWaveform: true,
        noOfSamples: 64,
      );
      var total = player.maxDuration;
      if (total <= 0) {
        // Some devices report duration only after a second probe.
        total = await player.getDuration(DurationType.max);
      }
      if (!mounted) return;
      setState(() {
        _prepared = true;
        // Keep the recorder-seeded length if the player still reports -1/0
        // (common right after a fresh capture on some devices).
        if (total > 0) _totalMs = total;
      });
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
    // Applies a toggle that arrived while prepare was still running, which
    // `didUpdateWidget` deliberately skipped.
    if (widget.playing) await player.startPlayer();
  }

  void _disposePlayer() {
    _positionSub?.cancel();
    _completionSub?.cancel();
    _stateSub?.cancel();
    _positionSub = null;
    _completionSub = null;
    _stateSub = null;
    _player?.dispose();
    _player = null;
    _prepared = false;
    _positionMs = 0;
    _totalMs = 0;
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
    // Active (playing) state: brand-colored duration + pause glyph + live
    // waveform progress — mirrors WhatsApp's sent-note affordance.
    final active = _isActivelyPlaying || widget.playing;
    final waveColor = active
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
            decoration: BoxDecoration(
              color: SkifluxColors.backgroundBrand,
              shape: BoxShape.circle,
              // Slight ring while playing so the control reads as "active".
              border: active
                  ? Border.all(
                      color: SkifluxColors.contentBrand,
                      width: 1.5,
                    )
                  : null,
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
                    continuousWaveform: true,
                    playerWaveStyle: SkifluxWaveformStyle.player(),
                  ),
                )
              // Static fallback: no audio, or prepare hasn't resolved (or
              // failed). Tint brand while the parent thinks we're playing so
              // the row still looks active during prepare.
              : LayoutBuilder(
                  builder: (context, constraints) => SkifluxVoiceWaveform(
                    color: active
                        ? SkifluxColors.contentBrand
                        : SkifluxColors.contentBrandInactive,
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

  /// Idle → total length. Playing / paused mid-note → remaining time counting
  /// down (WhatsApp). Never invents a 10-second length.
  String _durationLabel() {
    final total = _totalMs > 0
        ? _totalMs
        : (_player != null && _player!.maxDuration > 0
            ? _player!.maxDuration
            : 0);
    if (total <= 0) return widget.duration;

    final showRemaining = widget.playing || _positionMs > 0;
    final ms = showRemaining
        ? (total - _positionMs).clamp(0, total)
        : total;
    return _formatMs(ms);
  }

  static String _formatMs(int ms) {
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
