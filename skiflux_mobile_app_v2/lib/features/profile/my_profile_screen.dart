import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_handler.dart';
import '../../shared/widgets/network_image.dart';
import '../../shared/sheets/share_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../playlists/data/playlists_store.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';
import '../streaks/data/streaks_store.dart';
import '../streaks/streak_screen.dart';
import '../subscriptions/subscriptions_screen.dart' show CircleTapTarget;
import '../wallet/wallet_screen.dart';
import 'badges_screen.dart';
import 'change_skill_world_sheet.dart';
import 'data/download_action.dart';
import 'data/library_episode.dart';
import 'data/library_repository.dart';
import 'data/library_store.dart';
import 'data/models/user_profile.dart';
import 'data/profile_store.dart';
import 'data/skill_world_store.dart';
import 'downloads_screen.dart';
import 'library_episode_player.dart';
import 'liked_videos_screen.dart';
import 'saved_videos_screen.dart';
import 'watch_history_screen.dart';

// Figma: **Profile Flow 17** (`1256:23812`) — "My Profile" bottom-nav tab
// root. Identity comes from [meProfileProvider]; there is no stand-in for it.

class MyProfileBody extends ConsumerWidget {
  const MyProfileBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(hasSessionProvider);
    // Session gate: still show chrome while the session resolves.
    final signedOut = session.value == false;
    return Column(
      children: [
        _topBar(context),
        const SizedBox(height: SkifluxSpacing.spaceL),
        Expanded(
          child: ListView(
            children: [
              if (signedOut)
                Padding(
                  padding: const EdgeInsets.only(bottom: SkifluxSpacing.spaceL),
                  child: Text(
                    'Sign in to see your profile, coins, and history.',
                    textAlign: TextAlign.center,
                    style: SkifluxTypography.bodyP10Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ),
              const _ProfileHeader(),
              const SizedBox(height: SkifluxSpacing.spaceL),
              const _WatchHistoryHeading(),
              const SizedBox(height: SkifluxSpacing.spaceL),
              const _WatchHistoryRail(),
              const SizedBox(height: SkifluxSpacing.spaceL),
              const _MenuList(),
              const SizedBox(height: SkifluxSpacing.spaceL),
            ],
          ),
        ),
      ],
    );
  }

  /// Search circle · "My Profile" (H8 Bold 20) · settings circle.
  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        CircleTapTarget(
          icon: RemixIcons.search_fill,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
        Expanded(
          child: Center(
            child: Text(
              'My Profile',
              style: SkifluxTypography.headingH8Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
          ),
        ),
        CircleTapTarget(
          icon: RemixIcons.settings_4_fill,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }
}

// ── Header: avatar · name/handle · stat pills · Design World ─────────

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streaksProvider).streak;
    final coins = ref.watch(playlistsProvider).skillCoins;
    final profileAsync = ref.watch(meProfileProvider);
    final UserProfile? profile = profileAsync.value;

    // No stand-in identity. `Amara Design / @amara / AD / 2,450` used to fill
    // this in whenever `GET /me/profile` had not answered, so a signed-out or
    // still-loading user read someone else's name and XP as their own. In
    // flight the header holds its shape as a skeleton; with no profile at all
    // it says so.
    if (profile == null) {
      return _ProfileHeaderPlaceholder(loading: profileAsync.isLoading);
    }

    final handle = profile.handle;
    final streakLabel = profile.streakCount > 0
        ? '${profile.streakCount}'
        : '$streak';
    final avatarUrl = profile.avatarUrl;

    return Column(
      children: [
        if (avatarUrl != null && avatarUrl.isNotEmpty)
          ClipOval(
            child: SkifluxNetworkImage(
              url: avatarUrl,
              width: SkifluxUnit.u64,
              height: SkifluxUnit.u64,
              errorWidget: SkifluxAvatar(
                style: SkifluxAvatarStyle.initial,
                size: SkifluxUnit.u64,
                initials: profile.initials,
              ),
            ),
          )
        else
          SkifluxAvatar(
            style: SkifluxAvatarStyle.initial,
            size: SkifluxUnit.u64,
            initials: profile.initials,
          ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          profile.displayName,
          style: SkifluxTypography.headingH8Bold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        if (handle.isNotEmpty) ...[
          const SizedBox(height: SkifluxSpacing.spaceXs),
          Text(
            handle,
            style: SkifluxTypography.bodyP11Regular.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
        ],
        const SizedBox(height: SkifluxSpacing.spaceS),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatPill(
              icon: RemixIcons.copper_coin_fill,
              label: CoinPack.thousands(coins),
              background: SkifluxColors.backgroundNoticeSubtle,
              foreground: SkifluxColors.contentNotice,
              chevron: true,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
            ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            _StatPill(
              icon: RemixIcons.flashlight_fill,
              label: profile.xpLabel,
              background: SkifluxColors.backgroundBrandOpacity50,
              foreground: SkifluxColors.contentBrand,
            ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            _StatPill(
              icon: RemixIcons.fire_fill,
              label: streakLabel,
              background: SkifluxColors.orange100,
              foreground: SkifluxColors.orange500,
              chevron: true,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StreakScreen())),
            ),
          ],
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        const _WorldButton(),
      ],
    );
  }
}

/// The header with no profile behind it — in flight, or signed out.
///
/// Occupies the loaded header's footprint either way so the watch-history
/// heading below does not slide when the profile lands. Loading shows the
/// shapes; a resolved-but-absent profile says plainly that there is nobody to
/// show, which the sign-in line at the top of the screen then explains.
class _ProfileHeaderPlaceholder extends StatelessWidget {
  const _ProfileHeaderPlaceholder({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SkifluxSkeletonGroup(
        child: Column(
          children: [
            SkifluxSkeleton.circle(size: SkifluxUnit.u64),
            SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxSkeleton.text(width: 160),
            SizedBox(height: SkifluxSpacing.spaceXs),
            SkifluxSkeleton.text(width: 96),
            SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxSkeleton(
              width: 220,
              height: SkifluxUnit.u32,
              radius: SkifluxRadii.pill,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        const SkifluxAvatar(
          style: SkifluxAvatarStyle.blank,
          size: SkifluxUnit.u64,
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          'Not signed in',
          style: SkifluxTypography.headingH8Bold.copyWith(
            color: SkifluxColors.contentTertiary,
          ),
        ),
      ],
    );
  }
}

/// Tinted pill: 16px icon · Creato Bold 12 count · optional 12px chevron.
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.chevron = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceXs),
        decoration: BoxDecoration(
          color: background,
          borderRadius: SkifluxRadii.borderPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: SkifluxIcons.sizeS, color: foreground),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SkifluxSpacing.spaceXs,
              ),
              child: Text(
                label,
                style: SkifluxTypography.uiBadgeTagMedium.copyWith(
                  color: foreground,
                ),
              ),
            ),
            if (chevron)
              const Icon(
                RemixIcons.arrow_right_s_line,
                size: 12,
                color: SkifluxColors.contentTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Gradient "Design World ›" pill — tap to change SkillWorld (`1256:24173`).
///
/// Figma (`1256:24041`) fills the 130×32 pill with a *radial* gradient: a 10px
/// circle stretched by `matrix(7.2573 2.8214 -9.5762 1.7987 65 16)` about the
/// pill's centre, so blue sits in the middle and every corner runs
/// violet → magenta. Under it a `0 4 5 rgba(86,16,171,.6)` drop shadow, plus
/// the `Inner shadow` effect style as a hairline highlight on the top edge.
class _WorldButton extends ConsumerWidget {
  const _WorldButton();

  /// Gradient stops — authored directly in Figma, not colour variables.
  static const _gradientColors = [
    Color(0xFF3B82F6),
    Color(0xFF3B82F6),
    Color(0xFF5C5EF2),
    Color(0xFF7C3AED),
    Color(0xFFAB40EE),
    Color(0xFFD946EF),
  ];
  static const _gradientStops = [0.0, 0.3, 0.45, 0.6, 0.8, 1.0];

  /// The pill is 32 tall (16px content + `Space/S` padding) and Flutter
  /// resolves [RadialGradient.radius] against that shortest side, so Figma's
  /// `r="10"` becomes 10/32.
  static const double _gradientRadius = 10 / SkifluxUnit.u32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final world = ref.watch(skillWorldProvider);
    return GestureDetector(
      onTap: () => showChangeSkillWorldSheet(context),
      child: Container(
        padding: const EdgeInsets.all(SkifluxSpacing.spaceS),
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            radius: _gradientRadius,
            colors: _gradientColors,
            stops: _gradientStops,
            transform: _WorldGradientTransform(),
          ),
          borderRadius: SkifluxRadii.borderPill,
          boxShadow: [
            BoxShadow(
              color: SkifluxColors.brand500.withValues(alpha: 0.6),
              offset: const Offset(0, 4),
              blurRadius: 5,
            ),
          ],
        ),
        // Flutter has no inner shadow on [BoxDecoration]; the effect style's
        // light 1px inset reads as a fade over the top 2px of the pill.
        foregroundDecoration: BoxDecoration(
          borderRadius: SkifluxRadii.borderPill,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SkifluxEffects.innerShadowColor, Color(0x00FFF8F4)],
            stops: [0, 2 / SkifluxUnit.u32],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The selected world's own glyph, not a fixed one — the label
            // beside it already says which world, and the pair reads as a
            // single "you are in X" statement. Figma's frame shows Design's
            // nib because Design is the world its example is in.
            Icon(
              world.icon,
              size: SkifluxIcons.sizeS,
              color: SkifluxColors.contentPrimaryInverse,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SkifluxSpacing.spaceXs,
              ),
              child: Text(
                world.pillLabel,
                style: SkifluxTypography.uiButtonSmall.copyWith(
                  color: SkifluxColors.contentPrimaryInverse,
                ),
              ),
            ),
            const Icon(
              RemixIcons.arrow_right_s_line,
              size: SkifluxIcons.sizeS,
              color: SkifluxColors.contentPrimaryInverse,
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma's `gradientTransform` for the pill: the radial gradient's circle is
/// scaled/skewed by `matrix(7.2573 2.8214 -9.5762 1.7987)` about the pill's
/// centre (the matrix' 65/16 translation *is* that centre, so it drops out).
///
/// Flutter hands Skia the centre in device coordinates and the matrix maps
/// gradient space → device space, so the composite is
/// `translate(centre) · L · translate(-centre)` — a linear part of `L` and a
/// translation of `centre - L·centre`.
@immutable
class _WorldGradientTransform extends GradientTransform {
  const _WorldGradientTransform();

  static const double _a = 7.2573;
  static const double _b = 2.8214;
  static const double _c = -9.5762;
  static const double _d = 1.7987;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final centre = bounds.center;
    final tx = centre.dx - (_a * centre.dx + _c * centre.dy);
    final ty = centre.dy - (_b * centre.dx + _d * centre.dy);
    // Column-major.
    return Matrix4(
      _a,
      _b,
      0,
      0, //
      _c,
      _d,
      0,
      0, //
      0,
      0,
      1,
      0, //
      tx,
      ty,
      0,
      1, //
    );
  }
}

// ── Watch History rail ───────────────────────────────────────────────

class _WatchHistoryHeading extends StatelessWidget {
  const _WatchHistoryHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Watch History',
            style: SkifluxTypography.headingH9Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
        ),
        // Watch-history list screen (Profile Flow 15).
        GestureDetector(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const WatchHistoryScreen())),
          child: Text(
            'View all',
            style: SkifluxTypography.uiButtonLarge.copyWith(
              color: SkifluxColors.contentBrand,
            ),
          ),
        ),
      ],
    );
  }
}

/// The rail is `GET /me/watch-history`, not the subscriptions feed.
///
/// It used to render `subscriptionsProvider.feed().take(5)` — the five newest
/// episodes from creators the user follows, watched or not — under a heading
/// that says "Watch History". Its "Remove from watch history" could only hide
/// a card for the session, because there was nothing to remove it from.
///
/// Everything stays inside the same 172px box the loaded cards occupy, so the
/// menu below it does not move between loading, empty and loaded.
class _WatchHistoryRail extends ConsumerWidget {
  const _WatchHistoryRail();

  /// 98 thumb + 8 gap + 2-line H10 title + 4 gap + 16 creator row.
  static const double _height = 172;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryProvider);

    return SizedBox(
      height: _height,
      child: switch (history) {
        AsyncLoading() => const _WatchHistoryRailSkeleton(),
        AsyncError(:final error) => _WatchHistoryRailError(
          error: error,
          onRetry: () => ref.read(watchHistoryProvider.notifier).refresh(),
        ),
        AsyncData(:final value) => value.isEmpty
            ? const SkifluxEmptyState.compact(
                icon: Icon(
                  RemixIcons.history_fill,
                  size: SkifluxEmptyState.iconSizeCompact,
                  color: SkifluxColors.contentBrand,
                ),
                title: 'Nothing watched yet',
                message: 'Episodes you watch show up here.',
              )
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                // The rail is a preview; "View all" above it opens the rest.
                itemCount: value.length > 10 ? 10 : value.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: SkifluxSpacing.spaceL),
                itemBuilder: (_, i) => _WatchHistoryCard(entry: value[i]),
              ),
      },
    );
  }
}

/// Three card silhouettes at the real 128×98 thumbnail size.
///
/// Uses a horizontal [ListView] (same as the loaded rail) instead of a [Row].
/// Three 128px cards + gaps are wider than a typical phone content area
/// (~328px after page padding), so a Row overflowed by ~88px and flashed the
/// yellow/black stripe before history loaded.
class _WatchHistoryRailSkeleton extends StatelessWidget {
  const _WatchHistoryRailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkifluxSkeletonGroup(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) =>
            const SizedBox(width: SkifluxSpacing.spaceL),
        itemBuilder: (_, _) => const _WatchHistoryCardSkeleton(),
      ),
    );
  }
}

class _WatchHistoryCardSkeleton extends StatelessWidget {
  const _WatchHistoryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 128,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkifluxSkeleton(width: 128, height: 98, radius: SkifluxRadii.l),
          SizedBox(height: SkifluxSpacing.spaceS),
          SkifluxSkeleton.text(),
          SizedBox(height: SkifluxSpacing.spaceXs),
          SkifluxSkeleton.text(width: 80),
        ],
      ),
    );
  }
}

/// A failed load, at rail scale: what went wrong plus a way to try again,
/// rather than a silently empty strip that reads as "you've watched nothing".
class _WatchHistoryRailError extends ConsumerWidget {
  const _WatchHistoryRailError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            // Same classifier the full-screen [LoadFailure] uses, so this
            // never puts an exception string in front of the user.
            ref.read(errorHandlerProvider).classify(error).message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SkifluxTypography.bodyP11Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          SkifluxButton(
            label: 'Retry',
            size: SkifluxButtonSize.s,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// 128px column: thumbnail (EP chip on brand + duration chip on overlay),
/// 2-line title, creator name + "more" glyph. The glyph opens the same row
/// More Menu the Watch History screen uses (**Profile Flow 14** `1256:24327`).
class _WatchHistoryCard extends ConsumerWidget {
  const _WatchHistoryCard({required this.entry});

  final WatchHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = entry.episode;
    return SizedBox(
      width: 128,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // The card is the whole point of the rail: tapping it resumes the
        // episode in the same modal player the library screens open.
        onTap: () => showLibraryEpisodePlayer(context, episode),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _thumbnail(),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              episode.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SkifluxTypography.headingH10Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    episode.creatorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SkifluxTypography.bodyP11Regular.copyWith(
                      color: SkifluxColors.contentTertiary,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _openRowMenu(context, ref),
                  child: const Icon(
                    RemixIcons.more_2_fill,
                    size: SkifluxIcons.sizeS,
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Same handlers as the Watch History screen's rows, so the sheet behaves
  /// identically wherever it is opened from.
  Future<void> _openRowMenu(BuildContext context, WidgetRef ref) async {
    final action = await showWatchHistoryMenuSheet(context);
    if (!context.mounted || action == null) return;
    switch (action) {
      case WatchHistoryMenuAction.remove:
        // Goes to `DELETE /me/watch-history/{episode_id}` and stays gone.
        // The card used to be hidden for the session only, so it came back
        // on the next rebuild.
        try {
          await ref.read(watchHistoryProvider.notifier).remove(entry);
          if (!context.mounted) return;
          SkifluxToast.info(context, 'Removed from watch history');
        } catch (error) {
          if (!context.mounted) return;
          SkifluxToast.error(
            context,
            ref.read(errorHandlerProvider).classify(error).message,
          );
        }
      case WatchHistoryMenuAction.download:
        await downloadEpisode(context, ref, entry.episode);
      case WatchHistoryMenuAction.save:
        // Really saves, same as the Watch History screen's own row menu — the
        // episode shows up under Saved Videos afterwards.
        try {
          await ref
              .read(libraryRepositoryProvider)
              .toggleSave(entry.episode.id);
          ref.invalidate(savedEpisodesProvider);
          if (!context.mounted) return;
          SkifluxToast.success(context, 'Saved to your videos');
        } catch (error) {
          if (!context.mounted) return;
          SkifluxToast.error(
            context,
            ref.read(errorHandlerProvider).classify(error).message,
          );
        }
      case WatchHistoryMenuAction.share:
        await showShareSheet(
          context,
          title: '${entry.episode.epTag} · ${entry.episode.title}',
          url: shareableMediaUrl(entry.episode.videoUrl),
        );
    }
  }

  Widget _thumbnail() {
    final url = entry.episode.thumbnailUrl;
    return ClipRRect(
      borderRadius: SkifluxRadii.borderL,
      child: SizedBox(
        width: 128,
        height: 98,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // `Episode.thumbnail_url` is required by the schema, so the asset
            // is a decode/404 fallback. Every card showing the same stock
            // frame was the giveaway that the field was never read.
            if (url != null && url.isNotEmpty)
              SkifluxNetworkImage(url: url, errorWidget: _placeholderCover())
            else
              _placeholderCover(),
            Positioned(
              top: SkifluxSpacing.spaceS,
              left: SkifluxSpacing.spaceS,
              // Figma: EP chip here is solid brand (unlike the feed card's
              // overlay chip).
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SkifluxSpacing.spaceS,
                  vertical: SkifluxSpacing.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: SkifluxColors.contentBrand,
                  borderRadius: BorderRadius.circular(SkifluxRadii.x),
                ),
                child: Text(
                  entry.episode.epTag,
                  style: SkifluxTypography.bodyP11Semibold.copyWith(
                    color: SkifluxColors.contentPrimaryInverse,
                  ),
                ),
              ),
            ),
            // Hidden rather than "0:00" when the payload omits the duration.
            if (entry.episode.durationLabel.isNotEmpty)
              Positioned(
                bottom: SkifluxSpacing.spaceS,
                right: SkifluxSpacing.spaceS,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SkifluxSpacing.spaceXs,
                    vertical: SkifluxSpacing.space2xs,
                  ),
                  decoration: BoxDecoration(
                    color: SkifluxColors.overlay50,
                    borderRadius: BorderRadius.circular(SkifluxRadii.x),
                  ),
                  child: Text(
                    entry.episode.durationLabel,
                    style: SkifluxTypography.bodyP11Semibold.copyWith(
                      color: SkifluxColors.contentPrimaryInverse,
                    ),
                  ),
                ),
              ),
            // How far in the user actually got — the one thing that makes
            // this a history card rather than a catalogue card. Drawn only
            // for a started episode, never as a full bar by default.
            if (entry.progress > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: entry.progress,
                  minHeight: 3,
                  backgroundColor: SkifluxColors.overlay50,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    SkifluxColors.contentBrand,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The stock cover, used only when the episode carries no thumbnail or the
  /// network image fails to decode.
  Widget _placeholderCover() => Image.asset(
    'assets/home_video_raw1.png',
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => const ColoredBox(color: SkifluxColors.magenta900),
  );
}

// ── Menu list ────────────────────────────────────────────────────────

class _MenuList extends ConsumerWidget {
  const _MenuList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `rankLabel` formats "#12 in Master" from `rank` + `current_level`. With
    // no profile the row simply carries no detail — it used to read "#12 in
    // Master" for everyone, including signed-out users who have no standing.
    final profile = ref.watch(meProfileProvider).value;

    return Column(
      children: [
        _MenuRow(
          icon: RemixIcons.trophy_fill,
          label: 'Leaderboard',
          detail: profile?.rankLabel,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
        ),
        _MenuRow(
          icon: RemixIcons.download_fill,
          label: 'Downloads',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const DownloadsScreen())),
        ),
        _MenuRow(
          icon: RemixIcons.bookmark_fill,
          label: 'Saved Videos',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SavedVideosScreen())),
        ),
        _MenuRow(
          icon: RemixIcons.heart_3_fill,
          label: 'Liked Videos',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LikedVideosScreen())),
        ),
        _MenuRow(
          icon: RemixIcons.award_fill,
          label: 'Badges',
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BadgesScreen())),
        ),
      ],
    );
  }
}

/// 48px row: 24px fill icon · Button-Large label · optional detail text ·
/// chevron. Rows without [onTap] are deferred stubs.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.detail,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      child: SizedBox(
        height: SkifluxUnit.u48,
        child: Row(
          children: [
            Icon(
              icon,
              size: SkifluxIcons.sizeM,
              color: SkifluxColors.contentPrimary,
            ),
            const SizedBox(width: SkifluxSpacing.spaceL),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SkifluxTypography.uiButtonLarge.copyWith(
                  color: SkifluxColors.contentPrimary,
                ),
              ),
            ),
            if (detail != null) ...[
              Text(
                detail!,
                style: SkifluxTypography.bodyP10Regular.copyWith(
                  color: SkifluxColors.contentTertiary,
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
            ],
            const Icon(
              RemixIcons.arrow_right_s_line,
              size: SkifluxIcons.sizeM,
              color: SkifluxColors.contentPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
