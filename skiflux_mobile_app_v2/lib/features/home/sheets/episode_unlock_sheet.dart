import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/sheets/skiflux_sheet.dart';
import '../../playlists/data/playlists_store.dart';

// Figma: Other Video Player Flow 05–01 — Episode Cost → unlock → success
// (`1256:27469` … `1256:27907`).

Future<void> showEpisodeUnlockSheet(
  BuildContext context, {
  required String episodeId,
}) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => _EpisodeUnlockSheet(episodeId: episodeId),
  );
}

class _EpisodeUnlockSheet extends StatefulWidget {
  const _EpisodeUnlockSheet({required this.episodeId});

  final String episodeId;

  @override
  State<_EpisodeUnlockSheet> createState() => _EpisodeUnlockSheetState();
}

enum _UnlockPhase { cost, processing, success }

class _EpisodeUnlockSheetState extends State<_EpisodeUnlockSheet> {
  final _store = PlaylistsStore.instance;
  _UnlockPhase _phase = _UnlockPhase.cost;
  bool _busy = false;

  PlaylistEpisode? get _ep => _store.byId(widget.episodeId);

  @override
  Widget build(BuildContext context) {
    final ep = _ep;
    if (ep == null) {
      return const SkifluxSheetShell(
        title: 'Episode',
        child: Padding(
          padding: EdgeInsets.all(SkifluxSpacing.spaceL),
          child: Text('Episode not found'),
        ),
      );
    }

    if (_phase == _UnlockPhase.success) {
      return SkifluxSheetShell(
        title: 'Episode Unlocked!',
        child: Padding(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 98,
                height: 98,
                decoration: const BoxDecoration(
                  color: SkifluxColors.backgroundPositiveSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  RemixIcons.check_fill,
                  size: 48,
                  color: SkifluxColors.contentPositive,
                ),
              ),
              const SizedBox(height: SkifluxSpacing.spaceS),
              Text(
                'Episode Unlocked!',
                textAlign: TextAlign.center,
                style: SkifluxTypography.headingH7Bold.copyWith(
                  color: SkifluxColors.contentPrimary,
                ),
              ),
              const SizedBox(height: SkifluxSpacing.spaceXs),
              Text(
                '${ep.epTag} is now available. Enjoy the lesson and complete '
                'the task to earn rewards.',
                textAlign: TextAlign.center,
                style: SkifluxTypography.bodyP8Regular.copyWith(
                  color: SkifluxColors.contentTertiary,
                ),
              ),
              const SizedBox(height: SkifluxSpacing.spaceXl),
              SkifluxButton(
                label: 'Close',
                expanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    if (_phase == _UnlockPhase.processing) {
      return const SkifluxSheetShell(
        title: 'Unlocking…',
        child: Padding(
          padding: EdgeInsets.all(SkifluxSpacing.space4xl),
          child: Center(child: SkifluxSpinner()),
        ),
      );
    }

    final canAfford = _store.skillCoins >= ep.coinCost;

    return SkifluxSheetShell(
      title: 'Episode Cost',
      child: Padding(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ep.epTag,
              style: SkifluxTypography.uiBadgeTagMedium.copyWith(
                color: SkifluxColors.contentBrand,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              ep.title,
              style: SkifluxTypography.headingH8Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            Container(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              decoration: BoxDecoration(
                color: SkifluxColors.backgroundHover,
                borderRadius: SkifluxRadii.borderL,
              ),
              child: Row(
                children: [
                  const Icon(
                    RemixIcons.copper_coin_fill,
                    size: 28,
                    color: SkifluxColors.contentNoticeBold,
                  ),
                  const SizedBox(width: SkifluxSpacing.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ep.coinCost} SkillCoins',
                          style: SkifluxTypography.headingH9Bold.copyWith(
                            color: SkifluxColors.contentPrimary,
                          ),
                        ),
                        Text(
                          'Your balance: ${_store.skillCoins}',
                          style: SkifluxTypography.bodyP10Regular.copyWith(
                            color: canAfford
                                ? SkifluxColors.contentTertiary
                                : SkifluxColors.contentNegative,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!canAfford) ...[
              const SizedBox(height: SkifluxSpacing.spaceM),
              Text(
                'Not enough SkillCoins. Complete tasks or missions to earn more.',
                style: SkifluxTypography.bodyP10Regular.copyWith(
                  color: SkifluxColors.contentNegative,
                ),
              ),
            ],
            const SizedBox(height: SkifluxSpacing.spaceXl),
            SkifluxButton(
              label: canAfford
                  ? 'Unlock with SkillCoins'
                  : 'Not enough coins',
              expanded: true,
              onPressed: !canAfford || _busy
                  ? null
                  : () => _unlock(context, ep),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxButton(
              label: 'Cancel',
              type: SkifluxButtonType.secondary,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlock(BuildContext context, PlaylistEpisode ep) async {
    setState(() {
      _busy = true;
      _phase = _UnlockPhase.processing;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final ok = _store.tryUnlock(ep.id);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _phase = _UnlockPhase.cost;
      });
      return;
    }
    setState(() {
      _busy = false;
      _phase = _UnlockPhase.success;
    });
  }
}
