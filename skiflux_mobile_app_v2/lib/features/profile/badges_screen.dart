import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'data/badges_repository.dart';

// Figma: **Profile Flow 05** (`1256:25179`) — Badges screen. "3 of 8 badges
// earned" + brand progress track + "40% Earned" label, then Earned and
// Locked 3-column grids. Badge art = the user-provided SVGs already staged
// in `assets/badges/` (same set the public profile uses).

/// Static catalogue mapping badge names to local SVG asset paths.
/// Every badge in the app is listed here — all start **inactive**.
/// Only badges returned by the backend are marked as earned.
const _kBadgeAssets = <String, String>{
  'First Task Completed': 'assets/badges/badge_first_task_completed.svg',
  '3 Days Streak': 'assets/badges/badge_3_days_streak.svg',
  'Top Learner': 'assets/badges/badge_top_learner.svg',
  '10 Days Streak': 'assets/badges/badge_10_days_streak.svg',
  'Big Earner': 'assets/badges/badge_big_earner.svg',
  'Super Fan': 'assets/badges/badge_super_fan.svg',
  'Referral Pro': 'assets/badges/badge_referral_pro.svg',
  'Speed Learner': 'assets/badges/badge_speed_learner.svg',
};

/// Locked-state captions for each badge (the requirement text).
const _kLockedCaptions = <String, String>{
  'First Task Completed': 'Complete first task',
  '3 Days Streak': 'Complete 3 days',
  'Top Learner': 'Top learner rank',
  '10 Days Streak': 'Complete 10 days',
  'Big Earner': 'Earn 500 coins',
  'Super Fan': 'Like 50 videos',
  'Referral Pro': 'Refer 3 friends',
  'Speed Learner': '5 episodes in a day',
};

/// One display badge derived purely from the backend response.
class _DisplayBadge {
  const _DisplayBadge({
    required this.name,
    required this.caption,
    required this.earned,
    this.localAsset,
    this.networkUrl,
  });

  final String name;
  final String caption;
  final bool earned;
  final String? localAsset;
  final String? networkUrl;
}

/// Builds the complete badge list: all badges start inactive, then any
/// badge the backend says the user earned gets marked as active.
List<_DisplayBadge> _buildDisplayBadges(List<UserBadge> earnedBadges) {
  final earnedByName = <String, UserBadge>{
    for (final ub in earnedBadges) ub.badge.name: ub,
  };

  return _kBadgeAssets.entries.map((entry) {
    final earned = earnedByName[entry.key];
    return _DisplayBadge(
      name: entry.key,
      caption: earned != null
          ? 'Earned'
          : _kLockedCaptions[entry.key] ?? entry.key,
      earned: earned != null,
      localAsset: entry.value,
      networkUrl: earned?.badge.iconUrl,
    );
  }).toList();
}

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: ref.watch(userBadgesProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(RemixIcons.error_warning_line,
                        size: 48, color: SkifluxColors.contentTertiary),
                    const SizedBox(height: SkifluxSpacing.spaceS),
                    Text('Couldn\'t load badges',
                        style: SkifluxTypography.bodyP9Regular
                            .copyWith(color: SkifluxColors.contentTertiary)),
                    const SizedBox(height: SkifluxSpacing.spaceM),
                    SkifluxButton(
                      label: 'Retry',
                      size: SkifluxButtonSize.s,
                      onPressed: () => ref.invalidate(userBadgesProvider),
                    ),
                  ],
                ),
              ),
              data: (earnedBadges) {
                final badges = _buildDisplayBadges(earnedBadges);
                final earned = badges.where((b) => b.earned).toList();
                final locked = badges.where((b) => !b.earned).toList();
                final total = badges.length;
                final percent =
                    total > 0 ? (earned.length / total * 100).round() : 0;

                return ListView(
                  padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
                  children: [
                    _progressHeader(earned.length, total, percent),
                    const SizedBox(height: SkifluxSpacing.spaceL),
                    if (earned.isNotEmpty) ...[
                      _sectionLabel('Earned'),
                      const SizedBox(height: SkifluxSpacing.spaceS),
                      _grid(earned),
                      const SizedBox(height: SkifluxSpacing.spaceL),
                    ],
                    _sectionLabel('Locked'),
                    const SizedBox(height: SkifluxSpacing.spaceS),
                    _grid(locked),
                  ],
                );
              },
            ),
      ),
    );
  }

  /// "3 of 8 badges earned" · "40% Earned" over the brand progress track.
  Widget _progressHeader(int earnedCount, int total, int percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$earnedCount of $total badges earned',
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
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: SkifluxColors.backgroundSelected,
                    borderRadius: SkifluxRadii.borderPill,
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: total > 0 ? earnedCount / total : 0,
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
  Widget _grid(List<_DisplayBadge> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: SkifluxSpacing.spaceL,
        crossAxisSpacing: SkifluxSpacing.spaceL,
        childAspectRatio: 113 / 130,
      ),
      itemCount: badges.length,
      itemBuilder: (_, i) => _BadgeTile(badge: badges[i]),
    );
  }
}

/// One badge tile — earned: brand gradient card, full-color icon, "Earned"
/// caption; locked: grey card, desaturated icon, requirement caption.
class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final _DisplayBadge badge;

  /// Luminance-preserving desaturation matrix for locked badge art.
  static const List<double> _greyMatrix = [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 0.5, 0,
  ];

  @override
  Widget build(BuildContext context) {
    // Prefer network icon (from backend) when available,
    // fall back to local SVG asset.
    final Widget art;
    if (badge.networkUrl != null && badge.networkUrl!.isNotEmpty) {
      art = SvgPicture.network(badge.networkUrl!, fit: BoxFit.contain);
    } else if (badge.localAsset != null) {
      art = SvgPicture.asset(badge.localAsset!, fit: BoxFit.contain);
    } else {
      art = const Icon(RemixIcons.award_fill,
          color: SkifluxColors.contentTertiary);
    }

    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceM),
      decoration: BoxDecoration(
        gradient: badge.earned
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
