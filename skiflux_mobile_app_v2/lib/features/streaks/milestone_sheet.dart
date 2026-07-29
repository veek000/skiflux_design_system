import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import 'data/streaks_store.dart';

// Figma: **Streak Screen 04** overlay (`2259:13266`) — milestone
// celebration sheet: purple gradient header with light rays and a laurel
// "+50 XP" crest, "Milestone Completed!" copy, sticky Close button.
//
// Sheet consumption: reads [streaksProvider] for milestone / milestoneXp
// display values only (no mutations from this sheet).

Future<void> showMilestoneSheet(BuildContext context) {
  return showSkifluxSheet(
    context: context,
    builder: (_) => const _MilestoneSheet(),
  );
}

class _MilestoneSheet extends ConsumerWidget {
  const _MilestoneSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaks = ref.watch(streaksProvider);
    final media = MediaQuery.of(context);
    return Material(
      color: SkifluxColors.backgroundPrimary,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(SkifluxRadii.x),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              _CelebrationHeader(milestoneXp: streaks.milestoneXp),
              // Close circle over the header (`2259:13267`).
              Positioned(
                top: SkifluxSpacing.spaceL,
                right: SkifluxSpacing.spaceL,
                child: Material(
                  color: SkifluxColors.backgroundPressed,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(SkifluxSpacing.spaceS),
                      child: Icon(
                        RemixIcons.close_line,
                        size: SkifluxIcons.sizeM,
                        color: SkifluxColors.contentPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.space2xl,
            ),
            child: Column(
              children: [
                Text(
                  'Milestone Completed!',
                  textAlign: TextAlign.center,
                  style: SkifluxTypography.headingH7Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.spaceXs),
                Text.rich(
                  TextSpan(
                    text:
                        'You’ve earned ${streaks.milestoneXp} XP '
                        'for completing a milestone of ',
                    children: [
                      TextSpan(
                        text: '${streaks.milestone} days streaks',
                        style: SkifluxTypography.bodyP8Semibold.copyWith(
                          color: SkifluxColors.contentSecondary,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: SkifluxTypography.bodyP8Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SkifluxSpacing.spaceL,
              SkifluxSpacing.spaceL,
              SkifluxSpacing.spaceL,
              SkifluxSpacing.spaceS,
            ),
            child: SkifluxButton(
              label: 'Close',
              expanded: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(height: media.padding.bottom + SkifluxSpacing.spaceS),
        ],
      ),
    );
  }
}

/// Gradient header (`2291:11448`): brand purple fading to white, the
/// light-ray burst behind a laurel-wreathed "+50 XP / Earned" crest.
class _CelebrationHeader extends StatelessWidget {
  const _CelebrationHeader({required this.milestoneXp});

  final int milestoneXp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: SkifluxRadii.borderX,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.05, 0.72],
          colors: [
            SkifluxColors.backgroundBrand,
            SkifluxColors.backgroundPrimary,
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Light-ray burst (393×96 pre-cropped export) filling the header.
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/streaks/light_ray.svg',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/streaks/laurel_left.svg',
                  height: SkifluxUnit.u64,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SkifluxSpacing.spaceXs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+$milestoneXp XP',
                        style: SkifluxTypography.headingH6ExtraBold.copyWith(
                          color: SkifluxColors.contentPrimaryInverse,
                        ),
                      ),
                      Text(
                        'Earned',
                        style: SkifluxTypography.bodyP10Semibold.copyWith(
                          color: SkifluxColors.contentBrand,
                        ),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/streaks/laurel_right.svg',
                  height: SkifluxUnit.u64,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
