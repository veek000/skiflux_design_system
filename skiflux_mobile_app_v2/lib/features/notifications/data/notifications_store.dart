/// Demo notifications backing the Notifications screen (Figma
/// Notification Flow `1256:28688`). Read state is session-local
/// ([NotificationsNotifier]) — no persistence, matching the other stores.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One notification card (Figma `Frame 5818`… variants). [action] is the
/// optional pill-button label ("Watch EP. 04", "View Reply", …).
class AppNotification {
  AppNotification({
    required this.title,
    required this.body,
    required this.icon,
    required this.time,
    this.action,
    this.unread = false,
  });

  final String title;
  final String body;

  /// Remix icon name key — resolved to IconData in the screen so the
  /// store stays flutter-free.
  final String icon;

  /// When it happened; rendered relatively via `timeago` and used for
  /// the Today / Yesterday section grouping.
  final DateTime time;

  final String? action;
  bool unread;
}

/// Session store: seeded demo cards + unread bookkeeping.
///
/// Uses [NotifierProvider] because the notifications list is mutable
/// (mark read / mark all read). A plain [Provider] cannot own mutations.
// TODO(backend, blocking): replace static _seed() notifications list with real per-user notification feed fetched from backend — expects: List<{title: String, body: String, icon: String, time: DateTime, action: String?, unread: bool}>
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() => _seed(DateTime.now());

  List<AppNotification> get unread =>
      state.where((n) => n.unread).toList(growable: false);

  int get unreadCount => state.where((n) => n.unread).length;

  void markAllRead() {
    for (final n in state) {
      n.unread = false;
    }
    // Reassign so listeners rebuild (in-place mutation alone is silent).
    state = List<AppNotification>.of(state);
  }

  void markRead(AppNotification notification) {
    if (!notification.unread) return;
    notification.unread = false;
    state = List<AppNotification>.of(state);
  }

  static List<AppNotification> _seed(DateTime now) {
    final yesterday = now.subtract(const Duration(days: 1));
    return [
      // ── Today ──
      AppNotification(
        title: 'Welcome to SkiFlux',
        body: 'Watch an episode, complete the task, and earn your first '
            'SkillCoins today.',
        icon: 'sparkling',
        time: now.subtract(const Duration(minutes: 2)),
        unread: true,
      ),
      AppNotification(
        title: 'New episode',
        body: 'Amara Design just dropped "Design Systems from Scratch". '
            'Your task is ready too.',
        icon: 'play',
        time: now.subtract(const Duration(minutes: 14)),
        action: 'Watch EP. 04',
        unread: true,
      ),
      AppNotification(
        title: 'Task submitted',
        body: 'Your task for EP 01 "Intro to UI Design Thinking" is under '
            "review. You'll hear back soon.",
        icon: 'task',
        time: now.subtract(const Duration(hours: 1)),
        unread: true,
      ),
      AppNotification(
        title: 'SkillCoins earned',
        body: 'Your EP 01 task was approved — 50 SkillCoins added to your '
            'wallet. Keep going — EP 02 is waiting.',
        icon: 'coins',
        time: now.subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        title: 'Your first coins',
        body: 'You just earned your first 50 SkillCoins. Complete more '
            'tasks to grow your wallet.',
        icon: 'coin',
        time: now.subtract(const Duration(hours: 5)),
      ),
      // ── Yesterday ──
      AppNotification(
        title: 'Keep your streak',
        body: "You're on a 3-day streak. Watch today's episode to keep "
            'it going.',
        icon: 'flash',
        time: yesterday.subtract(const Duration(hours: 2)),
        action: 'Watch Now',
      ),
      AppNotification(
        title: 'New reply',
        body: 'Tolu Dev replied to your comment on "Intro to UI Design '
            'Thinking".',
        icon: 'chat',
        time: yesterday.subtract(const Duration(hours: 3)),
        action: 'View Reply',
      ),
      AppNotification(
        title: 'Voice reply',
        body: 'Figma Academy left a voice note on your comment in "Auto '
            'Layout Mastery".',
        icon: 'mic',
        time: yesterday.subtract(const Duration(hours: 4)),
        action: 'Listen to Reply',
      ),
      AppNotification(
        title: 'Your comment got a like',
        body: 'Motion Lab liked what you said on "Component Libraries '
            'in Figma".',
        icon: 'heart',
        time: yesterday.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        title: 'Badge unlocked',
        body: 'You earned the "First Task Done" badge. Keep going — more '
            'are waiting.',
        icon: 'award',
        time: yesterday.subtract(const Duration(hours: 6)),
        action: 'View Badge',
      ),
      AppNotification(
        title: 'Revision needed',
        body: 'Your EP 02 task needs a small fix. Tap to see the feedback '
            'and resubmit.',
        icon: 'warning',
        time: yesterday.subtract(const Duration(hours: 7)),
        action: 'View Feedback',
      ),
      AppNotification(
        title: 'Milestone reached',
        body: 'You just hit 500 SkillCoins. You can now unlock a premium '
            'course or withdraw to your account.',
        icon: 'flag',
        time: yesterday.subtract(const Duration(hours: 8)),
        action: 'Open Wallet',
      ),
      AppNotification(
        title: 'Withdrawal successful',
        body: 'Your 200-coin withdrawal (₦1,200) is on its way. It may '
            'take up to 24 hrs.',
        icon: 'handCoin',
        time: yesterday.subtract(const Duration(hours: 9)),
      ),
      AppNotification(
        title: 'Deposit successful',
        body: 'Your deposit of ₦1,200 was successful. 200 SkillCoins have '
            'been added to your wallet.',
        icon: 'bankCard',
        time: yesterday.subtract(const Duration(hours: 10)),
      ),
      AppNotification(
        title: 'Referral reward',
        body: 'Someone joined SkiFlux with your link. 30 SkillCoins have '
            'been added to your wallet.',
        icon: 'userAdd',
        time: yesterday.subtract(const Duration(hours: 11)),
      ),
      AppNotification(
        title: 'From SkiFlux',
        body: "New creators just joined. Check out who's posting this "
            'week and find your next favourite series.',
        icon: 'megaphone',
        time: yesterday.subtract(const Duration(hours: 12)),
        action: 'Explore Creators',
      ),
    ];
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);
