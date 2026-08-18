import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/widgets/load_failure.dart';
import '../../shared/widgets/video_feed_card.dart';
import '../notifications/notification_bell_button.dart';
import '../playlists/data/playlists_store.dart';
import '../profile/my_profile_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../subscriptions/data/subscriptions_store.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../tasks/tasks_screen.dart';
import 'data/home_feed_store.dart';

/// Figma: **Home & In-app Flow 11** (`198:13684`)
///
/// Feed home — creator header, full-height media card (video or image),
/// bottom tabs. Feed is vertical [PageView] (one item per page); not a
/// scrollable multi-card list.
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
    SkifluxMobileTabItem(label: 'Tasks', icon: Icon(RemixIcons.clipboard_fill)),
    SkifluxMobileTabItem(
      label: 'Subscriptions',
      icon: Icon(RemixIcons.bookmark_3_fill),
    ),
    SkifluxMobileTabItem(label: 'Profile', icon: Icon(RemixIcons.user_fill)),
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
                    _ => const _HomeFeedBody(),
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

/// Home tab: top bar + vertical page feed of [HomeFeedItem]s.
class _HomeFeedBody extends ConsumerStatefulWidget {
  const _HomeFeedBody();

  @override
  ConsumerState<_HomeFeedBody> createState() => _HomeFeedBodyState();
}

class _HomeFeedBodyState extends ConsumerState<_HomeFeedBody> {
  late final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// An episode picked out of the EP chip's season sheet opens *here*, as a
  /// page of the feed the user is already scrolling — not in a modal on top of
  /// it. The modal belongs to the surfaces with no feed behind them.
  ///
  /// The episode is inserted right after the current page when it isn't
  /// already loaded, so scrolling back still lands where the user was.
  Future<void> _openEpisodeInFeed(PlaylistEpisode ep) async {
    try {
      final index = await ref
          .read(homeFeedProvider.notifier)
          .openEpisode(ep.id, afterIndex: _pageIndex);
      if (!mounted || !_pageController.hasClients) return;
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } catch (e, st) {
      // `GET /episodes/{id}` answers 403 for an episode that still needs
      // buying, so this is a real message, not a swallowed no-op.
      if (!mounted) return;
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(homeFeedProvider);
    // The chrome stays put across all four states — search and notifications
    // work whether or not recommendations loaded — so only the body below it
    // swaps. `current` is null until there is something to name.
    final items = feed.value ?? const <HomeFeedItem>[];
    final current = items.isEmpty
        ? null
        : items[_pageIndex.clamp(0, items.length - 1)];

    return Column(
      children: [
        // RepaintBoundary keeps the top bar out of the layer that
        // re-rasterizes while the like animation / progress ticker runs.
        RepaintBoundary(
          child: _HomeTopBar(creator: current),
        ),
        const SizedBox(height: SkifluxSpacing.spaceL),
        Expanded(
          child: switch (feed) {
            AsyncLoading() => const _FeedSkeleton(),
            AsyncError(:final error) => LoadFailure(
              error: error,
              title: "We couldn't load your feed",
              onRetry: () => ref.read(homeFeedProvider.notifier).refresh(),
            ),
            _ when items.isEmpty => const SkifluxEmptyState(
              icon: Icon(
                RemixIcons.play_circle_line,
                size: SkifluxEmptyState.iconSize,
                color: SkifluxColors.contentBrand,
              ),
              title: 'Nothing to watch yet',
              message:
                  'Follow a few creators and your recommendations will show '
                  'up here.',
            ),
            _ => PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _pageIndex = i),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: SkifluxSpacing.spaceL),
                  child: RepaintBoundary(
                    child: VideoFeedCard(
                      item: item,
                      // Only the visible page decodes/plays; off-screen pauses.
                      isActive: index == _pageIndex,
                      onOpenEpisode: _openEpisodeInFeed,
                    ),
                  ),
                );
              },
            ),
          },
        ),
      ],
    );
  }
}

/// The shape of one feed card while the recommendations are in flight: the
/// media block, then the two lines of title and description under it.
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: SkifluxSpacing.spaceL),
      child: SkifluxSkeletonGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: SkifluxSkeleton(radius: SkifluxRadii.l)),
            SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxSkeleton.text(width: 140, height: SkifluxSpacing.spaceL),
            SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxSkeleton.text(),
            SizedBox(height: SkifluxSpacing.spaceXs),
            SkifluxSkeleton.text(width: 220),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ──────────────────────────────────────────────────────────

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.creator});

  /// Null while the feed is loading, and whenever it has nothing to show.
  final HomeFeedItem? creator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SkifluxUnit.u48,
      child: Row(
        children: [
          // Search control — Figma: Avatar (background/hover) + search-fill
          _CircleIconButton(
            icon: RemixIcons.search_fill,
            label: 'Search',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          const SizedBox(width: SkifluxSpacing.spaceL),
          // Creator chip (848:41279)
          Expanded(
            child: creator == null
                ? const _CreatorChipSkeleton()
                : _CreatorChip(item: creator!),
          ),
          const SizedBox(width: SkifluxSpacing.spaceL),
          // Notifications with badge (294:7951). The dot is the widget's own
          // business — it appears only for real unread rows.
          const NotificationBellButton(),
        ],
      ),
    );
  }
}

/// The creator chip's silhouette, held while the feed loads so the top bar
/// keeps its height and the search / notification buttons don't jump.
class _CreatorChipSkeleton extends StatelessWidget {
  const _CreatorChipSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SkifluxUnit.u48,
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundHover,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: const SkifluxSkeletonGroup(
        child: Row(
          children: [
            SkifluxSkeleton.circle(size: SkifluxUnit.u48),
            SizedBox(width: SkifluxSpacing.spaceS),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkifluxSkeleton.text(width: 96),
                SizedBox(height: SkifluxSpacing.spaceXs),
                SkifluxSkeleton.text(width: 64, height: SkifluxSpacing.spaceS),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Creator chip (848:41279). Avatar + name/handle crossfade with a soft
/// blur out → swap → blur in when the feed page changes creator.
class _CreatorChip extends StatefulWidget {
  const _CreatorChip({required this.item});

  final HomeFeedItem item;

  @override
  State<_CreatorChip> createState() => _CreatorChipState();
}

class _CreatorChipState extends State<_CreatorChip>
    with SingleTickerProviderStateMixin {
  /// How long each half of the transition takes (out, then in).
  static const _half = Duration(milliseconds: 180);

  /// Peak Gaussian sigma at full “disappear” (subtle, not mushy).
  static const _maxBlur = 10.0;

  late HomeFeedItem _displayed;
  late final AnimationController _ctrl;
  var _running = false;
  /// Latest page while a transition is in flight (rapid vertical swipes).
  HomeFeedItem? _pending;

  @override
  void initState() {
    super.initState();
    _displayed = widget.item;
    // 0 = sharp + opaque, 1 = blurred + transparent.
    _ctrl = AnimationController(vsync: this, duration: _half);
  }

  @override
  void didUpdateWidget(covariant _CreatorChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        widget.item.creatorUsername != _displayed.creatorUsername ||
        widget.item.creatorName != _displayed.creatorName ||
        widget.item.creatorInitials != _displayed.creatorInitials;
    if (changed) {
      _transitionTo(widget.item);
    }
  }

  Future<void> _transitionTo(HomeFeedItem next) async {
    // Coalesce rapid swipes onto the latest creator only.
    if (_running) {
      _pending = next;
      return;
    }
    _running = true;
    try {
      var target = next;
      while (mounted) {
        _pending = null;
        await _ctrl.forward(from: 0);
        if (!mounted) return;
        setState(() => _displayed = target);
        await _ctrl.reverse();
        final queued = _pending;
        if (queued == null) break;
        // Skip no-ops if we already show the queued creator.
        if (queued.creatorUsername == _displayed.creatorUsername &&
            queued.creatorName == _displayed.creatorName) {
          break;
        }
        target = queued;
      }
    } finally {
      _running = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_ctrl.value);
                final sigma = _maxBlur * t;
                final opacity = (1.0 - t).clamp(0.0, 1.0);
                // Tiny settle so the blur doesn’t feel static.
                final dy = 4.0 * t;

                Widget identity = Row(
                  children: [
                    _AvatarWithFollowCta(item: _displayed),
                    const SizedBox(width: SkifluxSpacing.spaceS),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayed.creatorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SkifluxTypography.headingH9Bold.copyWith(
                              color: SkifluxColors.contentPrimary,
                            ),
                          ),
                          Text(
                            '@${_displayed.creatorUsername}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SkifluxTypography.bodyP11Regular.copyWith(
                              color: SkifluxColors.contentTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                identity = Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: identity,
                  ),
                );

                if (sigma > 0.01) {
                  identity = ImageFiltered(
                    imageFilter: ImageFilter.blur(
                      sigmaX: sigma,
                      sigmaY: sigma,
                      tileMode: TileMode.decal,
                    ),
                    child: identity,
                  );
                }

                return identity;
              },
            ),
          ),
          // Trailing arrow stays sharp — only creator identity transitions.
          // `GET /creators/{id}` takes the creator UUID from the episode
          // payload, not the username; without one there is nothing to open.
          _CircleIconButton(
            icon: RemixIcons.arrow_right_s_line,
            filled: false,
            label: 'View creator',
            onTap: _displayed.creatorId == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfileScreen(creatorId: _displayed.creatorId!),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

/// Creator avatar + optional follow "+" badge (Figma I848:41281).
///
/// The badge is **absent** (not disabled) when [SubscriptionsState.isSubscribed]
/// — the single follow predicate — already lists this creator, and also when
/// the payload carried no creator UUID (there would be no endpoint to call).
/// Tap runs the real follow toggle: the toast appears only after the backend
/// confirms, and a failure surfaces through [ErrorDisplay].
class _AvatarWithFollowCta extends ConsumerWidget {
  const _AvatarWithFollowCta({required this.item});

  final HomeFeedItem item;

  Future<void> _follow(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(subscriptionsProvider.notifier).subscribe(
            SubscribedCreator(
              id: item.creatorId ?? '',
              name: item.creatorName,
              username: item.creatorUsername,
              initials: item.creatorInitials,
            ),
          );
      if (!context.mounted) return;
      SkifluxToast.success(context, 'Subscribed to ${item.creatorName}');
    } catch (e, st) {
      if (!context.mounted) return;
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alreadyFollowed = ref.watch(subscriptionsProvider).isSubscribed(
          item.creatorId ?? item.creatorUsername,
        );
    final canFollow = item.creatorId != null && item.creatorId!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        SkifluxAvatar(
          style: SkifluxAvatarStyle.initial,
          size: SkifluxUnit.u48,
          initials: item.creatorInitials,
        ),
        if (!alreadyFollowed && canFollow)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _follow(context, ref),
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
    this.label,
  });

  final IconData icon;
  final VoidCallback? onTap;

  /// Figma: search & notification are filled `Background/Hover`; the chip's
  /// trailing arrow is a transparent circle.
  final bool filled;

  /// Accessibility semantic label.
  final String? label;

  @override
  Widget build(BuildContext context) {
    // 24px icon box, centered in the 48px circle — matches Figma padding.
    // The notification bell no longer builds from here: its dot has a rule
    // (only real unread rows, only after the list has answered), so it lives
    // in [NotificationBellButton] instead of a badge slot on this button.
    final glyph = SizedBox(
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

    final button = Material(
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

    if (label != null && label!.isNotEmpty) {
      return Semantics(
        button: true,
        label: label,
        child: button,
      );
    }

    return button;
  }
}
