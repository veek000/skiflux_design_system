import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/widgets/video_feed_card.dart';
import '../notifications/notifications_screen.dart';
import '../profile/my_profile_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../tasks/tasks_screen.dart';

/// Figma: **Home & In-app Flow 11** (`198:13684`)
///
/// Feed home — creator header, video card with action rail, bottom tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  // Figma bottom navigation (848:41140) — Mobile Icon Tab component (62:1652).
  static const _navItems = <SkifluxMobileTabItem>[
    SkifluxMobileTabItem(
      label: 'Home',
      icon: Icon(RemixIcons.home_smile_2_fill),
    ),
    SkifluxMobileTabItem(
      label: 'Tasks',
      icon: Icon(RemixIcons.clipboard_fill),
    ),
    SkifluxMobileTabItem(
      label: 'Subscriptions',
      icon: Icon(RemixIcons.bookmark_3_fill),
    ),
    SkifluxMobileTabItem(
      label: 'Profile',
      icon: Icon(RemixIcons.user_fill),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SkifluxColors.backgroundPrimary,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SkifluxSpacing.spaceL,
                    SkifluxSpacing.spaceL,
                    SkifluxSpacing.spaceL,
                    0,
                  ),
                  // Tasks (Task Flow 1256:12977), Subscriptions
                  // (1256:17783), Profile (Profile Flow 17, 1256:23812).
                  child: switch (_tabIndex) {
                    1 => const TasksBody(),
                    2 => const SubscriptionsBody(),
                    3 => const MyProfileBody(),
                    _ => const Column(
                          children: [
                            // RepaintBoundary keeps the top bar out of the
                            // layer that re-rasterizes while the like
                            // animation runs — without it the search glyph /
                            // avatar initial can visibly flicker on
                            // like/unlike.
                            RepaintBoundary(child: _HomeTopBar()),
                            SizedBox(height: SkifluxSpacing.spaceL),
                            Expanded(
                              child: RepaintBoundary(child: VideoFeedCard()),
                            ),
                            SizedBox(height: SkifluxSpacing.spaceL),
                          ],
                        ),
                  },
                ),
              ),
              SkifluxMobileTabBar(
                items: _navItems,
                currentIndex: _tabIndex,
                onTap: (i) => setState(() => _tabIndex = i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SkifluxUnit.u48,
      child: Row(
        children: [
          // Search control — Figma: Avatar (background/hover) + search-fill
          _CircleIconButton(
            icon: RemixIcons.search_fill,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceL),
          // Creator chip (848:41279)
          const Expanded(child: _CreatorChip()),
          const SizedBox(width: SkifluxSpacing.spaceL),
          // Notifications with badge (294:7951)
          _CircleIconButton(
            icon: RemixIcons.notification_3_fill,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            badge: const SkifluxNotificationBadge(
              type: SkifluxBadgeType.indicator,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorChip extends StatelessWidget {
  const _CreatorChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SkifluxUnit.u48,
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundHover,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Row(
        children: [
          // Avatar with brand "+" CTA badge (I848:41281)
          const _AvatarWithCta(),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amara Design',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH9Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                Text(
                  '@amara',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.bodyP11Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Trailing arrow — transparent circle (848:41285)
          _CircleIconButton(
            icon: RemixIcons.arrow_right_s_line,
            filled: false,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithCta extends StatelessWidget {
  const _AvatarWithCta();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const SkifluxAvatar(
          style: SkifluxAvatarStyle.initial,
          size: SkifluxUnit.u48,
          initials: 'A',
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(SkifluxSpacing.spaceXs),
            decoration: BoxDecoration(
              color: SkifluxColors.contentBrand,
              shape: BoxShape.circle,
              border: Border.all(
                color: SkifluxColors.borderInverse,
                width: SkifluxBorderWidth.m,
              ),
            ),
            child: const Icon(
              RemixIcons.add_line,
              size: SkifluxUnit.u10,
              color: SkifluxColors.contentPrimaryInverse,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    this.onTap,
    this.filled = true,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onTap;

  /// Figma: search & notification are filled `Background/Hover`; the chip's
  /// trailing arrow is a transparent circle.
  final bool filled;

  /// Optional overlay (e.g. notification dot) anchored to the icon's corner.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    // 24px icon box, centered in the 48px circle — matches Figma padding.
    Widget glyph = SizedBox(
      width: SkifluxIcons.sizeM,
      height: SkifluxIcons.sizeM,
      child: Center(
        child: Icon(
          icon,
          size: SkifluxIcons.sizeM,
          color: SkifluxColors.contentPrimary,
        ),
      ),
    );

    if (badge != null) {
      glyph = Stack(
        clipBehavior: Clip.none,
        children: [
          glyph,
          Positioned(
            top: -SkifluxSpacing.space2xs,
            right: -SkifluxSpacing.space2xs,
            child: badge!,
          ),
        ],
      );
    }

    return Material(
      color: filled ? SkifluxColors.backgroundHover : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: SkifluxUnit.u48,
          height: SkifluxUnit.u48,
          child: Center(child: glyph),
        ),
      ),
    );
  }
}
