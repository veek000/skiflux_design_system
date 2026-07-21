import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../leaderboard/leaderboard_screen.dart';
import '../playlists/data/playlists_store.dart';
import '../search/search_screen.dart';
import '../streaks/data/streaks_store.dart';
import '../streaks/streak_screen.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart' show CircleTapTarget;
import '../wallet/wallet_screen.dart';
import 'badges_screen.dart';
import 'downloads_screen.dart';
import 'liked_videos_screen.dart';
import 'saved_videos_screen.dart';
import 'watch_history_screen.dart';

// Figma: **Profile Flow 17** (`1256:23812`) — "My Profile" bottom-nav tab
// root. Header (avatar, name/handle, coins · XP · streak pills, gradient
// "Design World" button), Watch History rail, and the menu list
// (Leaderboard / Downloads / Saved / Liked / Badges). Detail screens are
// deferred — rows and pills are inert stubs for now.

/// Demo identity/stats shown on the tab (no auth yet). Coins now come live
/// from [playlistsProvider] (see _ProfileHeader).
abstract final class _MyProfileDemo {
  static const name = 'Amara Design';
  static const handle = '@amara';
  static const initials = 'AD';
  static const xp = '2,450';
  static const world = 'Design World';
  static const leaderboardRank = '#12 in Master';
}

class MyProfileBody extends ConsumerWidget {
  const MyProfileBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(subscriptionsProvider);
    final history = subs.creators.isEmpty
        ? const <SubscriptionEpisode>[]
        : subs.feed().take(5).toList();
    return Column(
      children: [
        _topBar(context),
        const SizedBox(height: SkifluxSpacing.spaceL),
        Expanded(
          child: ListView(
            children: [
              const _ProfileHeader(),
              const SizedBox(height: SkifluxSpacing.spaceL),
              const _WatchHistoryHeading(),
              const SizedBox(height: SkifluxSpacing.spaceL),
              _WatchHistoryRail(episodes: history),
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
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
        // Settings screen is a deferred stub.
        CircleTapTarget(
          icon: RemixIcons.settings_4_fill,
          onTap: () {},
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
    // Live wallet balance — updates after buy-coins / unlock / withdraw.
    final coins = ref.watch(playlistsProvider).skillCoins;
    return Column(
      children: [
        const SkifluxAvatar(
          style: SkifluxAvatarStyle.initial,
          size: SkifluxUnit.u64,
          initials: _MyProfileDemo.initials,
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Text(
          _MyProfileDemo.name,
          style: SkifluxTypography.headingH8Bold.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceXs),
        Text(
          _MyProfileDemo.handle,
          style: SkifluxTypography.bodyP11Regular.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              ),
            ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            const _StatPill(
              icon: RemixIcons.flashlight_fill,
              label: _MyProfileDemo.xp,
              background: SkifluxColors.backgroundBrandOpacity50,
              foreground: SkifluxColors.contentBrand,
            ),
            const SizedBox(width: SkifluxSpacing.spaceS),
            _StatPill(
              icon: RemixIcons.fire_fill,
              label: '$streak',
              background: SkifluxColors.orange100,
              foreground: SkifluxColors.orange500,
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StreakScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        const _WorldButton(),
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

/// Gradient "Design World ›" pill with the purple drop shadow.
class _WorldButton extends StatelessWidget {
  const _WorldButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceS),
      decoration: BoxDecoration(
        // Figma: radial blue → violet → magenta sweep; approximated with a
        // linear gradient over the same stops.
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF5C5EF2),
            Color(0xFF7C3AED),
            Color(0xFFAB40EE),
            Color(0xFFD946EF),
          ],
        ),
        borderRadius: SkifluxRadii.borderPill,
        boxShadow: const [
          // Figma: drop shadow 0/4/5 @ brand 60%.
          BoxShadow(
            color: Color(0x995610AB),
            offset: Offset(0, 4),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            RemixIcons.pen_nib_fill,
            size: SkifluxIcons.sizeS,
            color: SkifluxColors.contentPrimaryInverse,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SkifluxSpacing.spaceXs,
            ),
            child: Text(
              _MyProfileDemo.world,
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WatchHistoryScreen()),
          ),
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

class _WatchHistoryRail extends StatelessWidget {
  const _WatchHistoryRail({required this.episodes});

  final List<SubscriptionEpisode> episodes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // 98 thumb + 8 gap + 2-line H10 title + 4 gap + 16 creator row.
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: episodes.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: SkifluxSpacing.spaceL),
        itemBuilder: (_, i) => _WatchHistoryCard(episode: episodes[i]),
      ),
    );
  }
}

/// 128px column: thumbnail (EP chip on brand + duration chip on overlay),
/// 2-line title, creator name + "more" glyph.
class _WatchHistoryCard extends ConsumerWidget {
  const _WatchHistoryCard({required this.episode});

  final SubscriptionEpisode episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creator = ref.watch(subscriptionsProvider).creatorOf(episode);
    return SizedBox(
      width: 128,
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
                  creator.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.bodyP11Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ),
              const Icon(
                RemixIcons.more_2_fill,
                size: SkifluxIcons.sizeS,
                color: SkifluxColors.contentTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumbnail() {
    return ClipRRect(
      borderRadius: SkifluxRadii.borderL,
      child: SizedBox(
        width: 128,
        height: 98,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/home_video_raw1.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: SkifluxColors.magenta900),
            ),
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
                  episode.epTag,
                  style: SkifluxTypography.bodyP11Semibold.copyWith(
                    color: SkifluxColors.contentPrimaryInverse,
                  ),
                ),
              ),
            ),
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
                  episode.duration,
                  style: SkifluxTypography.bodyP11Semibold.copyWith(
                    color: SkifluxColors.contentPrimaryInverse,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu list ────────────────────────────────────────────────────────

class _MenuList extends StatelessWidget {
  const _MenuList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuRow(
          icon: RemixIcons.trophy_fill,
          label: 'Leaderboard',
          detail: _MyProfileDemo.leaderboardRank,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
          ),
        ),
        _MenuRow(
          icon: RemixIcons.download_fill,
          label: 'Downloads',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DownloadsScreen()),
          ),
        ),
        _MenuRow(
          icon: RemixIcons.bookmark_fill,
          label: 'Saved Videos',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SavedVideosScreen()),
          ),
        ),
        _MenuRow(
          icon: RemixIcons.heart_3_fill,
          label: 'Liked Videos',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LikedVideosScreen()),
          ),
        ),
        _MenuRow(
          icon: RemixIcons.award_fill,
          label: 'Badges',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BadgesScreen()),
          ),
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
