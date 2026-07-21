import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/sheets/skiflux_sheet.dart';
import '../../playlists/data/playlists_store.dart';

// Figma: Other Video Player Flow 06 (`1256:27378`) — Playback Speed list.

const _kSpeeds = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

Future<void> showPlaybackSpeedSheet(BuildContext context) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => const _PlaybackSpeedSheet(),
  );
}

class _PlaybackSpeedSheet extends ConsumerWidget {
  const _PlaybackSpeedSheet();

  String _label(double s) {
    if (s == s.roundToDouble()) return '${s.toInt()}.0x';
    return '${s}x';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(playerPrefsProvider);
    final notifier = ref.read(playerPrefsProvider.notifier);
    return SkifluxSheetShell(
      title: 'Playback Speed',
      child: ListView(
        shrinkWrap: true,
        // Sheet drags down only when the list is at its top.
        controller: ModalScrollController.of(context),
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          0,
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
        ),
        children: [
          for (final s in _kSpeeds)
            InkWell(
              onTap: () {
                notifier.setSpeed(s);
                Navigator.of(context).pop();
              },
              child: SizedBox(
                height: SkifluxUnit.u48,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _label(s),
                        style: SkifluxTypography.uiButtonLarge.copyWith(
                          color: prefs.speed == s
                              ? SkifluxColors.contentBrand
                              : SkifluxColors.contentPrimary,
                        ),
                      ),
                    ),
                    if (prefs.speed == s)
                      const Icon(
                        RemixIcons.check_fill,
                        color: SkifluxColors.contentBrand,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
