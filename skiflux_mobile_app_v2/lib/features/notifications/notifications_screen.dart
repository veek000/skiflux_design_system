import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../shared/error_handling/error_handler.dart';
import '../../shared/widgets/load_failure.dart';
import '../../shared/widgets/loading_skeletons.dart';
import 'data/notifications_store.dart';

// Figma: **Notification Flow** (`1256:28688`) — Notifications screen
// (`1256:30744`) + empty state (`1256:30972`). All/Unread text tabs with
// live unread count, "Mark all read" nav action, Today/Yesterday
// sections, and per-type cards (icon bubble, title/body, optional action
// pill, timeago stamp, unread dot + brand-subtle tint). Unread cards are
// marked read on tap.

/// Store icon keys → Remix fills (Figma per-type notification icons).
const Map<String, IconData> _kNotificationIcons = {
  'sparkling': RemixIcons.sparkling_2_fill,
  'play': RemixIcons.play_circle_fill,
  'task': RemixIcons.task_fill,
  'coins': RemixIcons.coins_fill,
  'coin': RemixIcons.coin_fill,
  'flash': RemixIcons.flashlight_fill,
  'chat': RemixIcons.chat_3_fill,
  'mic': RemixIcons.mic_fill,
  'heart': RemixIcons.heart_3_fill,
  'award': RemixIcons.award_fill,
  'warning': RemixIcons.error_warning_fill,
  'flag': RemixIcons.flag_2_fill,
  'handCoin': RemixIcons.hand_coin_fill,
  'bankCard': RemixIcons.bank_card_fill,
  'userAdd': RemixIcons.user_add_fill,
  'megaphone': RemixIcons.megaphone_fill,
};

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(notificationsProvider.notifier).refreshFromBackend());
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final unreadCount = notifier.unreadCount;
    final notifications = _tabIndex == 0 ? all : notifier.unread;

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Notification',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Figma `1256:30744`: "Mark all read" text action on the right.
        trailingText: 'Mark all read',
        onTrailingTextTap: unreadCount == 0 ? null : notifier.markAllRead,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SkifluxSpacing.spaceL,
              SkifluxSpacing.spaceL,
              SkifluxSpacing.spaceL,
              0,
            ),
            child: SkifluxTextTabs(
              tabs: [
                const SkifluxTextTab(label: 'All'),
                SkifluxTextTab(label: 'Unread', count: unreadCount),
              ],
              selectedIndex: _tabIndex,
              onSelected: (index) => setState(() => _tabIndex = index),
            ),
          ),
          Expanded(child: _body(notifier, notifications)),
        ],
      ),
    );
  }

  /// Signed-in honesty states: loader while the first fetch runs, error +
  /// retry when it failed — the demo seed is never behind either of them.
  Widget _body(
    NotificationsNotifier notifier,
    List<AppNotification> notifications,
  ) {
    if (notifications.isEmpty && notifier.loadFailed) {
      return LoadFailure(
        error: const SkifluxFailure(SkifluxErrorKind.contentLoadFailed),
        title: "We couldn't load your notifications",
        onRetry: () => unawaited(notifier.refreshFromBackend()),
      );
    }
    if (notifications.isEmpty && notifier.loading) {
      return const ListRowSkeleton(rows: 6);
    }
    if (notifications.isEmpty) return const _EmptyState();
    return _NotificationList(notifications: notifications);
  }
}

// ── List + sections ──────────────────────────────────────────────────

/// Today / Yesterday sections (`1256:30761` / `1256:30826`); anything
/// older lands under "Earlier" (demo data never does).
class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];
    final earlier = <AppNotification>[];
    for (final n in notifications) {
      final startOfToday = DateTime(now.year, now.month, now.day);
      if (!n.time.isBefore(startOfToday)) {
        today.add(n);
      } else if (!n.time.isBefore(
        startOfToday.subtract(const Duration(days: 1)),
      )) {
        yesterday.add(n);
      } else {
        earlier.add(n);
      }
    }

    // Built as a list of (label, rows) pairs rather than three hand-spaced
    // branches. The old form put a `SizedBox` *before* the Earlier section
    // unconditionally, so a list with nothing newer than two days old — which
    // is most of them once a day has passed — opened with a stray 16px band
    // above its first heading, and the gaps between sections varied by which
    // combination of the three happened to be present.
    final sections = <(String, List<AppNotification>)>[
      if (today.isNotEmpty) ('Today', today),
      if (yesterday.isNotEmpty) ('Yesterday', yesterday),
      if (earlier.isNotEmpty) ('Earlier', earlier),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      itemCount: sections.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: SkifluxSpacing.spaceXl),
      itemBuilder: (_, i) => _Section(
        label: sections[i].$1,
        notifications: sections[i].$2,
      ),
    );
  }
}

/// Section-card rounding (`Frame 5811` radius L). Const so the clip and
/// the foreground stroke use the exact same geometry.
const BorderRadius _sectionRadius = BorderRadius.all(
  Radius.circular(SkifluxRadii.l),
);

/// Section label + card stack. The stack is a bordered card (`Frame
/// 5811`): 1px borderTertiary stroke on ALL sides, radius L corners,
/// content clipped; cards separate with hairlines (skipped on the last
/// card so it doesn't double the container stroke).
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.notifications});

  final String label;
  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SkifluxTypography.uiButtonMedium.copyWith(
            color: SkifluxColors.contentPrimary,
          ),
        ),
        const SizedBox(height: SkifluxSpacing.spaceS),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(borderRadius: _sectionRadius),
          // Stroke painted OVER the clipped cards — with a plain border
          // decoration the card fills bleed across the stroke on the
          // corner curve and the rounding looks chipped.
          foregroundDecoration: BoxDecoration(
            borderRadius: _sectionRadius,
            border: Border.all(
              color: SkifluxColors.borderTertiary,
              width: SkifluxBorderWidth.xs,
            ),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notifications.length,
            itemBuilder: (context, i) {
              return _NotificationCard(
                notifications[i],
                showDivider: i < notifications.length - 1,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────

/// One notification (`Frame 5818`… variants): 30px brand icon bubble,
/// H10 Bold title + p10 body, optional small primary action pill,
/// p11 disabled timestamp, 8px unread dot. Unread cards are tinted
/// backgroundBrandOpacity50; tapping marks read.
class _NotificationCard extends ConsumerWidget {
  const _NotificationCard(this.notification, {required this.showDivider});

  final AppNotification notification;

  /// Hairline under the card — off for the section's last card (the
  /// container's own stroke closes the stack).
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: notification.unread
          ? SkifluxColors.backgroundBrandOpacity50
          : SkifluxColors.backgroundPrimary,
      child: InkWell(
        onTap: () =>
            ref.read(notificationsProvider.notifier).markRead(notification),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          decoration: showDivider
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: SkifluxColors.borderTertiary,
                      width: SkifluxBorderWidth.xs,
                    ),
                  ),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: SkifluxColors.contentBrand,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _kNotificationIcons[notification.icon] ??
                      RemixIcons.notification_3_fill,
                  size: 20,
                  color: SkifluxColors.contentPrimaryInverse,
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: SkifluxTypography.headingH10Bold.copyWith(
                        color: SkifluxColors.contentSecondary,
                      ),
                    ),
                    Text(
                      notification.body,
                      style: SkifluxTypography.bodyP10Regular.copyWith(
                        color: SkifluxColors.contentSecondary,
                      ),
                    ),
                    if (notification.action != null) ...[
                      const SizedBox(height: SkifluxSpacing.spaceXs),
                      SkifluxButton(
                        label: notification.action!,
                        size: SkifluxButtonSize.s,
                        onPressed: () {},
                      ),
                    ],
                    const SizedBox(height: SkifluxSpacing.spaceXs),
                    Text(
                      timeago.format(notification.time),
                      style: SkifluxTypography.bodyP11Regular.copyWith(
                        color: SkifluxColors.contentDisabled,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceL),
              // Unread indicator (`Future/point`, hidden when read).
              SizedBox(
                width: SkifluxSpacing.spaceL,
                height: SkifluxSpacing.spaceL,
                child: notification.unread
                    ? Center(
                        child: Container(
                          width: SkifluxSpacing.spaceS,
                          height: SkifluxSpacing.spaceS,
                          decoration: const BoxDecoration(
                            color: SkifluxColors.contentBrand,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────

/// `1256:30972`: brand100 98px bell circle, H7 Bold title, p8 body.
/// Shown when the selected tab has no cards (Figma frames it for a
/// fresh account; here it also appears once Unread is cleared).
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: SkifluxSpacing.spaceXl,
        vertical: SkifluxSpacing.space4xl,
      ),
      child: Column(
        children: [
          Container(
            width: 98,
            height: 98,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SkifluxColors.brand100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              RemixIcons.notification_3_fill,
              size: SkifluxUnit.u48,
              color: SkifluxColors.contentBrand,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Text(
            'No notifications yet',
            textAlign: TextAlign.center,
            style: SkifluxTypography.headingH7Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceXs),
          Text(
            'Replies to your comments, new episodes from creators you '
            'follow, task updates, and coin earnings will all show up here.',
            textAlign: TextAlign.center,
            style: SkifluxTypography.bodyP8Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
