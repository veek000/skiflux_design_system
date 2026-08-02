/// The notification bell that sits in a top bar, dot and all.
///
/// One widget rather than a badge argument at each call site, because the
/// dot's rule is not obvious. The spec carries no unread-count endpoint, so
/// the badge has to be derived from the fetched list — and it must stay hidden
/// until `GET /me/notifications` has actually answered. The store builds with
/// a demo seed whose cards are unread, so an unconditional
/// `SkifluxNotificationBadge` showed every signed-in user a red dot for
/// notifications that did not exist, and left it there after they had read
/// everything.
//
// TODO(backend, minor): deriving the badge means the whole list is fetched to
// learn one number, and the dot is stale until something refreshes it —
// expects: GET /me/notifications/unread-count → { count: int }.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'data/notifications_store.dart';
import 'notifications_screen.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key, this.onTap});

  /// Defaults to opening [NotificationsScreen]; supplied where the host screen
  /// wants its own route (a nested navigator, say).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched, not read: marking a row read reassigns the list, and the dot
    // has to clear on that rebuild rather than at the next screen change.
    ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final unread = notifier.fromBackend && notifier.unreadCount > 0;

    Widget glyph = const SizedBox(
      width: SkifluxIcons.sizeM,
      height: SkifluxIcons.sizeM,
      child: Center(
        child: Icon(
          RemixIcons.notification_3_fill,
          size: SkifluxIcons.sizeM,
          color: SkifluxColors.contentPrimary,
        ),
      ),
    );

    if (unread) {
      glyph = Stack(
        clipBehavior: Clip.none,
        children: [
          glyph,
          const Positioned(
            top: -SkifluxSpacing.space2xs,
            right: -SkifluxSpacing.space2xs,
            child: SkifluxNotificationBadge(
              type: SkifluxBadgeType.indicator,
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: unread ? 'Notifications, new unread' : 'Notifications',
      child: Material(
        color: SkifluxColors.backgroundHover,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap:
              onTap ??
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
          child: SizedBox(
            width: SkifluxUnit.u48,
            height: SkifluxUnit.u48,
            child: Center(child: glyph),
          ),
        ),
      ),
    );
  }
}
