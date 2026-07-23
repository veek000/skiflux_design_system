import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

// Figma: **Profile Flow 05** (`1256:25179`) — Badges screen. "3 of 8 badges
// earned" + brand progress track + "40% Earned" label, then Earned and
// Locked 3-column grids. Badge art = the user-provided SVGs already staged
// in `assets/badges/` (same set the public profile uses).

/// One achievement badge: asset + earned state + locked-state requirement.
class _Badge {
  const _Badge(this.asset, this.caption, {this.earned = false});

  final String asset;

  /// Locked tiles show the requirement; earned tiles show "Earned".
  final String caption;
  final bool earned;
}

/// Demo badge set (3 of 8 earned, matching the Figma frame).
// TODO(backend, blocking): replace static badge list with real per-user badge progress fetched from backend — expects: List<{assetUrl: String, caption: String, earned: bool}>
const List<_Badge> _kBadges = [
  _Badge('assets/badges/badge_first_task_completed.svg', 'Earned',
      earned: true),
  _Badge('assets/badges/badge_3_days_streak.svg', 'Earned', earned: true),
  _Badge('assets/badges/badge_top_learner.svg', 'Earned', earned: true),
  _Badge('assets/badges/badge_10_days_streak.svg', 'Complete 10 days'),
  _Badge('assets/badges/badge_big_earner.svg', 'Earn 500 coins'),
  _Badge('assets/badges/badge_super_fan.svg', 'Like 50 videos'),
  _Badge('assets/badges/badge_referral_pro.svg', 'Refer 3 friends'),
  _Badge('assets/badges/badge_speed_learner.svg', '5 episodes in a day'),
];

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final earned = _kBadges.where((b) => b.earned).toList();
    final locked = _kBadges.where((b) => !b.earned).toList();
    final percent = (earned.length / _kBadges.length * 100).round();

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Badges',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: const SizedBox(width: SkifluxSpacing.spaceXl),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          children: [
            _progressHeader(earned.length, percent),
            const SizedBox(height: SkifluxSpacing.spaceL),
            _sectionLabel('Earned'),
            const SizedBox(height: SkifluxSpacing.spaceS),
            _grid(earned),
            const SizedBox(height: SkifluxSpacing.spaceL),
            _sectionLabel('Locked'),
            const SizedBox(height: SkifluxSpacing.spaceS),
            _grid(locked),
          ],
        ),
      ),
    );
  }

  /// "3 of 8 badges earned" · "40% Earned" over the brand progress track
  /// (`1256:25551`): labels in `UI Style/Input Content` (Creato Bold 12) —
  /// left tertiary, right brand; 8px gap; 4px `Background/Selected` pill
  /// track with the `Content/Brand` fill.
  Widget _progressHeader(int earnedCount, int percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$earnedCount of ${_kBadges.length} badges earned',
                style: SkifluxTypography.uiInputContent.copyWith(
                  color: SkifluxColors.contentTertiary,
                ),
              ),
            ),
            Text(
              '$percent% Earned',
              style: SkifluxTypography.uiInputContent.copyWith(
                color: SkifluxColors.contentBrand,
              ),
            ),
          ],
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        SizedBox(
          width: double.infinity,
          height: SkifluxSpacing.spaceXs,
          child: Stack(
            children: [
              // Track — full-width Background/Selected pill.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: SkifluxColors.backgroundSelected,
                    borderRadius: SkifluxRadii.borderPill,
                  ),
                ),
              ),
              // Fill — brand pill with its own rounded ends (Figma's
              // Rectangle 2730 is an independent rounded bar, not a clip).
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: earnedCount / _kBadges.length,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: SkifluxColors.contentBrand,
                        borderRadius: SkifluxRadii.borderPill,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: SkifluxTypography.uiButtonMedium.copyWith(
        color: SkifluxColors.contentTertiary,
      ),
    );
  }

  /// 3-column badge grid; rows wrap as needed.
  Widget _grid(List<_Badge> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: SkifluxSpacing.spaceL,
        crossAxisSpacing: SkifluxSpacing.spaceL,
        // Tile ≈ 113×113 art region + caption row (Figma 1256:25199).
        childAspectRatio: 113 / 130,
      ),
      itemCount: badges.length,
      itemBuilder: (_, i) => _BadgeTile(badge: badges[i]),
    );
  }
}

/// One badge tile — earned: brand gradient card, full-color SVG, "Earned"
/// caption; locked: grey card, desaturated SVG, requirement caption.
class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final _Badge badge;

  /// Luminance-preserving desaturation matrix for locked badge art.
  static const List<double> _greyMatrix = [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 0.5, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final art = SvgPicture.asset(badge.asset, fit: BoxFit.contain);
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
      decoration: BoxDecoration(
        gradient: badge.earned
            // Same brand50→brand200 vertical gradient as the public
            // profile's badge tiles.
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [SkifluxColors.brand50, SkifluxColors.brand200],
              )
            : null,
        color: badge.earned ? null : SkifluxColors.backgroundHover,
        borderRadius: SkifluxRadii.borderM,
      ),
      child: Column(
        children: [
          Expanded(
            child: badge.earned
                ? art
                : ColorFiltered(
                    colorFilter: const ColorFilter.matrix(_greyMatrix),
                    child: art,
                  ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Text(
            badge.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: badge.earned
                ? SkifluxTypography.uiButtonSmall.copyWith(
                    color: SkifluxColors.contentLinkPressed,
                  )
                : SkifluxTypography.bodyP11Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
          ),
        ],
      ),
    );
  }
}
