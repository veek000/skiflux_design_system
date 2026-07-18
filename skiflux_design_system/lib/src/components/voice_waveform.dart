import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Shared waveform bar geometry for [SkifluxComment] voicenotes and the
/// compose bar's recording state — extracted from the Figma components
/// (`848:39484`…, `848:39481`): bar width 2.371, gap 2, corner radius 32,
/// max bar height 22.761.
abstract final class SkifluxWaveformStyle {
  static const double barWidth = 2.371;
  static const double barGap = 2;
  static const double barRadius = 32;
  static const double maxHeight = 22.761;

  /// Distance between bar starts (audio_waveforms `spacing`).
  static const double barPitch = barWidth + barGap;

  /// Live recording style (compose bar): all bars `Content/Brand`.
  /// audio_waveforms paints each sample up AND down from the vertical
  /// center, so the per-half scale factor is half the total bar height.
  static WaveStyle recorder() => const WaveStyle(
        waveColor: SkifluxColors.contentBrand,
        waveThickness: barWidth,
        spacing: barPitch,
        waveCap: StrokeCap.round,
        showMiddleLine: false,
        extendWaveform: true,
        showDurationLabel: false,
        scaleFactor: maxHeight,
      );

  /// File playback style (comment voicenote): played bars `Content/Brand`,
  /// unplayed bars `Content/Brand Inactive`.
  static PlayerWaveStyle player() => const PlayerWaveStyle(
        fixedWaveColor: SkifluxColors.contentBrandInactive,
        liveWaveColor: SkifluxColors.contentBrand,
        waveThickness: barWidth,
        spacing: barPitch,
        waveCap: StrokeCap.round,
        showSeekLine: false,
        scaleFactor: maxHeight * 2,
      );
}

/// Static decorative voice-note waveform.
///
/// Used when no real audio file backs the bars (e.g. demo comments without
/// an [audio source]); live recording and real playback use the
/// audio_waveforms widgets styled via [SkifluxWaveformStyle].
///
/// Figma: static bar strip inside **Comment** (`848:39484`…) and
/// **Compose Bar / Mic Active** (`848:39481`).
class SkifluxVoiceWaveform extends StatelessWidget {
  const SkifluxVoiceWaveform({
    super.key,
    this.color = SkifluxColors.contentBrandInactive,
    this.barCount,
  });

  /// Bar fill. Idle voicenote → `Content/Brand Inactive`;
  /// playing / recording → `Content/Brand`.
  final Color color;

  /// Optional cap on how many bars to draw (pattern repeats if longer).
  final int? barCount;

  /// Bar height pattern extracted from the Figma component (in px).
  static const List<double> _heights = [
    8, 8, 10, 12, 16, 18, 22.761, 22.761, 22.761, 22.761, 22.761, 15, 15, //
    15, 22.761, 20, 22.761, 22.761, 22.761, 15, 22.761, 22.761, 22.761, 8,
    8, 12, 14, 22.761, 8, 10, 22.761, 22.761, 22.761, 14, 14, 22.761,
    22.761, 14, 22.761, 14, 22.761, 22.761, 22.761, 16, 14, 8, 8, 8, 8,
  ];

  @override
  Widget build(BuildContext context) {
    final count = barCount ?? _heights.length;
    return SizedBox(
      height: SkifluxWaveformStyle.maxHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: SkifluxWaveformStyle.barGap),
            Container(
              width: SkifluxWaveformStyle.barWidth,
              height: _heights[i % _heights.length],
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    BorderRadius.circular(SkifluxWaveformStyle.barRadius),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
