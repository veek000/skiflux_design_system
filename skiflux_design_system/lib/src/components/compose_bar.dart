import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:remixicon/remixicon.dart';

import '../tokens/colors.dart';
import '../tokens/icons.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'voice_waveform.dart';

/// Figma component set: **Compose Bar** (`848:39483`)
///
/// Variants: Default | Mic Active
/// - Default: mic button (transparent) · "Add a comment..." · send
///   (`Brand/200` inactive → `Content/Brand` when text is present).
/// - Mic Active (recording): delete button (`Background/Negative`) ·
///   `Content/Brand` live waveform + timer · send (`Content/Brand`).
///
/// Interaction states (beyond the Figma variants):
/// - Focused: the whole bar gets a `Border/Focus` stroke while the text
///   field has focus.
/// - Send activates (`Content/Brand`) only when the input has text or a
///   recording is in progress.
///
/// Recording is real: the mic button starts an [RecorderController]
/// capture (m4a in the app documents directory) and the waveform renders
/// live mic amplitude. Send stops the recording and reports the file via
/// [onSendVoiceNote]; delete discards it and removes the temp file.
enum SkifluxComposeState { idle, recording }

class SkifluxComposeBar extends StatefulWidget {
  const SkifluxComposeBar({
    super.key,
    this.state = SkifluxComposeState.idle,
    this.controller,
    this.hintText = 'Add a comment...',
    this.onMicTap,
    this.onDeleteTap,
    this.onSend,
    this.onSendVoiceNote,
    this.onRecordingFailed,
  });

  final SkifluxComposeState state;
  final TextEditingController? controller;
  final String hintText;

  final VoidCallback? onMicTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onSend;

  /// Called with the recorded file path when send is tapped while
  /// recording. The file lives in the app documents directory; the
  /// receiver owns it from here (attach, upload, or delete).
  final ValueChanged<String>? onSendVoiceNote;

  /// Raised when a recording could not be started or produced no file — mic
  /// permission refused, the recorder throwing, an empty capture.
  ///
  /// Without this the bar failed silently in the most confusing way possible:
  /// the parent had already switched it to the recording state, so the user saw
  /// a waveform (flat, because nothing was being captured), tapped send, and
  /// **nothing happened at all** — no note, no error. [reason] is a
  /// user-facing sentence; the parent decides how to show it and is expected to
  /// put the bar back to idle.
  final ValueChanged<String>? onRecordingFailed;

  @override
  State<SkifluxComposeBar> createState() => _SkifluxComposeBarState();
}

class _SkifluxComposeBarState extends State<SkifluxComposeBar> {
  static const double _controlSize = 30;

  final FocusNode _focusNode = FocusNode();
  TextEditingController? _ownedController;

  late final RecorderController _recorder = RecorderController();
  String? _recordingPath;

  TextEditingController get _controller =>
      widget.controller ?? (_ownedController ??= TextEditingController());

  bool get _recording => widget.state == SkifluxComposeState.recording;

  bool get _hasText => _controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onStateChanged);
    _controller.addListener(_onStateChanged);
    if (_recording) _startRecording();
  }

  @override
  void didUpdateWidget(SkifluxComposeBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onStateChanged);
      _controller.addListener(_onStateChanged);
    }
    if (widget.state != oldWidget.state) {
      if (_recording) {
        _startRecording();
      } else {
        // Left recording without send (delete/cancel) — discard.
        _discardRecording();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller?.removeListener(_onStateChanged);
    _ownedController?.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  /// Begin capturing.
  ///
  /// `checkPermission()` both reads and *requests* the mic grant, so a refusal
  /// lands here. It used to `return` on refusal and on any throw, leaving the
  /// bar showing a recording UI that was recording nothing.
  Future<void> _startRecording() async {
    try {
      if (!await _recorder.checkPermission()) {
        _fail('Microphone access is needed to record a voice note');
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.record(path: path);
      _recordingPath = path;
    } catch (error) {
      debugPrint('SkifluxComposeBar: recording failed to start → $error');
      _recordingPath = null;
      _fail("We couldn't start recording");
    }
  }

  void _fail(String reason) {
    if (!mounted) return;
    widget.onRecordingFailed?.call(reason);
  }

  Future<void> _discardRecording() async {
    final path = _recordingPath;
    _recordingPath = null;
    if (_recorder.isRecording) await _recorder.stop(false);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _sendRecording() async {
    String? path;
    try {
      path = await _recorder.stop(false) ?? _recordingPath;
    } catch (error) {
      debugPrint('SkifluxComposeBar: recorder.stop failed → $error');
      path = _recordingPath;
    }
    _recordingPath = null;
    // `stop(false)` leaves the controller holding the finished recording's
    // state, so a second note in the same session records against a stale
    // buffer (or refuses outright). Reset returns it to a fresh state; the
    // file on disk is untouched and is what gets sent below.
    _recorder.reset();

    // No file, or an empty one: the capture never happened (refused mic, a
    // recorder that failed to start, a tap-send faster than the first frame).
    // Reporting it is the whole point — this path used to fall through to
    // `onSend`, which the comments sheet ignores when there is no text, so the
    // send button simply did nothing.
    if (path == null || !_hasBytes(path)) {
      _fail("That recording didn't capture any audio");
      widget.onSend?.call();
      return;
    }
    widget.onSendVoiceNote?.call(path);
    widget.onSend?.call();
  }

  static bool _hasBytes(String path) {
    try {
      final file = File(path);
      return file.existsSync() && file.lengthSync() > 0;
    } catch (_) {
      // Cannot stat it — let the upload be the judge rather than dropping a
      // recording that may be perfectly good.
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus && !_recording;
    final sendActive = _recording || _hasText;

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundHover,
        borderRadius: SkifluxRadii.borderPill,
        // Focused: whole bar gets the active stroke (Border/Focus).
        border: focused
            ? Border.all(
                color: SkifluxColors.borderFocus,
                width: SkifluxBorderWidth.s,
              )
            : null,
      ),
      child: Row(
        children: [
          _circleButton(
            background: _recording ? SkifluxColors.backgroundNegative : null,
            icon: _recording
                ? RemixIcons.delete_bin_5_fill
                : RemixIcons.mic_fill,
            iconSize: _recording ? SkifluxIcons.sizeS : SkifluxUnit.u20,
            iconColor: _recording
                ? SkifluxColors.contentPrimaryInverse
                : SkifluxColors.contentDisabled,
            onTap: _recording ? widget.onDeleteTap : widget.onMicTap,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(child: _recording ? _recordingBody() : _inputBody()),
          const SizedBox(width: SkifluxSpacing.spaceS),
          _circleButton(
            // Send: Brand/200 (inactive) → Content/Brand once there is text
            // or an active recording.
            background: sendActive
                ? SkifluxColors.contentBrand
                : SkifluxColors.brand200,
            icon: RemixIcons.send_plane_2_fill,
            iconSize: SkifluxIcons.sizeS,
            iconColor: SkifluxColors.contentPrimaryInverse,
            onTap: !sendActive
                ? null
                : _recording
                    ? _sendRecording
                    : widget.onSend,
          ),
        ],
      ),
    );
  }

  Widget _inputBody() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      style: SkifluxTypography.bodyP8Regular.copyWith(
        color: SkifluxColors.contentPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        // The theme's InputDecorationTheme styles standalone inputs as
        // white filled pills with per-state outline borders; here the
        // field must sit directly on the bar's Background/Hover pill with
        // no box or border of its own. `border:` alone doesn't cover the
        // state borders — the theme's enabled/focused borders would still
        // apply — so each one is cleared explicitly.
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hintText: widget.hintText,
        hintStyle: SkifluxTypography.bodyP8Regular.copyWith(
          color: SkifluxColors.contentDisabled,
        ),
      ),
    );
  }

  Widget _recordingBody() {
    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => AudioWaveforms(
              size:
                  Size(constraints.maxWidth, SkifluxWaveformStyle.maxHeight),
              recorderController: _recorder,
              waveStyle: SkifluxWaveformStyle.recorder(),
            ),
          ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceS),
        StreamBuilder<Duration>(
          stream: _recorder.onCurrentDuration,
          initialData: Duration.zero,
          builder: (context, snapshot) {
            return Text(
              _format(snapshot.data ?? Duration.zero),
              style: SkifluxTypography.uiInputContent.copyWith(
                color: SkifluxColors.contentBrand,
              ),
            );
          },
        ),
      ],
    );
  }

  static String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _circleButton({
    Color? background,
    required IconData icon,
    required double iconSize,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _controlSize,
        height: _controlSize,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}
