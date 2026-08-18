import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/widgets/loading_skeletons.dart';
import '../playlists/data/playlists_store.dart';
import 'data/badge_catalogue.dart';
import 'data/badges_repository.dart';
import 'data/models/user_profile.dart';
import 'data/profile_store.dart';

// Figma: **Profile Flow 05** (`1256:25179`) — Badges screen. "3 of 8 badges
// earned" + brand progress track + "40% Earned" label, then Earned and
// Locked 3-column grids. Badge art is local and complete — the catalogue and
// the earned rule both live in `data/badge_catalogue.dart`, shared with the
// public profile.

/// One tile: a badge from the local catalogue, in its earned or locked state.
class DisplayBadge {
  const DisplayBadge({
    required this.name,
    required this.caption,
    required this.earned,
    required this.asset,
  });

  final String name;
  final String caption;
  final bool earned;
  final String asset;
}

/// The whole catalogue, every badge locked, then flipped to earned for each
/// name the backend listed **or** that [hints] clearly unlocks on the client.
///
/// Matching is on the badge's display name, normalised — `Badge` carries no
/// slug. A name the backend sends that this build has no art for is simply not
/// shown.
List<DisplayBadge> buildDisplayBadges(
  List<UserBadge> earnedBadges, {
  BadgeProgressHints hints = const BadgeProgressHints(),
}) {
  final earned = {
    for (final ub in earnedBadges) badgeKey(ub.badge.name),
    for (final name in inferredEarnedBadgeNames(hints)) badgeKey(name),
  };

  return [
    for (final entry in kBadgeAssets.entries)
      DisplayBadge(
        name: entry.key,
        caption: earned.contains(badgeKey(entry.key))
            ? 'Earned'
            : kBadgeLockedCaptions[entry.key] ?? entry.key,
        earned: earned.contains(badgeKey(entry.key)),
        asset: entry.value,
      ),
  ];
}

BadgeProgressHints badgeHintsFromProfile(UserProfile? profile, {int coins = 0}) {
  if (profile == null) return BadgeProgressHints(coins: coins);
  return BadgeProgressHints(
    taskDone: profile.taskDone,
    streakCount: profile.streakCount,
    coins: coins,
    episodeCompleted: profile.episodeCompleted,
  );
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
              // Two rows of the same 3-up tile grid `_grid` builds, at the
              // tile's own 113:130 ratio.
              loading: () => const CardGridSkeleton(
                count: 6,
                columns: 3,
                aspectRatio: 113 / 130,
              ),
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
                final profile = ref.watch(meProfileProvider).value;
                final coins = ref.watch(playlistsProvider).skillCoins;
                final badges = buildDisplayBadges(
                  earnedBadges,
                  hints: badgeHintsFromProfile(profile, coins: coins),
                );
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
  Widget _grid(List<DisplayBadge> badges) {
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

  final DisplayBadge badge;

  /// Luminance-preserving desaturation matrix for locked badge art.
  static const List<double> _greyMatrix = [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 0.5, 0,
  ];

  @override
  Widget build(BuildContext context) {
    // Local art only. `Badge.icon_url` is deliberately ignored: the earned and
    // locked states are the *same* drawing, one desaturated, so sourcing the
    // earned tile from the network would put two different sets of artwork
    // side by side in the same grid.
    final art = SvgPicture.asset(badge.asset, fit: BoxFit.contain);

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
