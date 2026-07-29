/// Notifications backing the Notifications screen (Figma Notification Flow
/// `1256:28688`).
///
/// [NotificationsNotifier.refreshFromBackend] loads `GET /me/notifications`;
/// the demo cards stay as the offline fallback, same arrangement as
/// `wallet_store` and `streaks_store`. Read state is optimistic — the row goes
/// read immediately and `POST /me/{id}/read` syncs behind it.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/notification_item.dart';
import 'notifications_repository.dart';

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
    this.id,
  });

  /// Server id, needed to sync a read back to `POST /me/{id}/read`. Null on
  /// the demo cards — those are marked read locally only.
  final String? id;

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

/// Store: the live feed (or the demo seed until it answers) + unread
/// bookkeeping.
///
/// Uses [NotifierProvider] because the notifications list is mutable
/// (mark read / mark all read). A plain [Provider] cannot own mutations.
//
// TODO(backend, minor): add a bulk mark-all-read endpoint — "Mark all read"
// currently fans out one `POST /me/{id}/read` per unread row — expects:
// POST /me/notifications/read-all → 200
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() => _seed(DateTime.now());

  /// True once `GET /me/notifications` has answered. While false the screen is
  /// showing the demo seed.
  bool get fromBackend => _fromBackend;
  bool _fromBackend = false;
  bool _loading = false;

  List<AppNotification> get unread =>
      state.where((n) => n.unread).toList(growable: false);

  int get unreadCount => state.where((n) => n.unread).length;

  void markAllRead() {
    final synced = <String>[];
    for (final n in state) {
      if (!n.unread) continue;
      n.unread = false;
      final id = n.id;
      if (id != null) synced.add(id);
    }
    // Reassign so listeners rebuild (in-place mutation alone is silent).
    state = List<AppNotification>.of(state);
    for (final id in synced) {
      unawaited(_syncRead(id));
    }
  }

  void markRead(AppNotification notification) {
    if (!notification.unread) return;
    notification.unread = false;
    state = List<AppNotification>.of(state);
    final id = notification.id;
    if (id != null) unawaited(_syncRead(id));
  }

  /// Loads `GET /me/notifications`. Keeps the current list on failure so the
  /// screen never empties out — same contract as the other stores.
  ///
  /// An empty feed *does* replace the seed: a fresh account is supposed to see
  /// the empty state, not demo cards.
  Future<void> refreshFromBackend() async {
    if (_loading) return;
    _loading = true;
    try {
      final items = await ref.read(notificationsRepositoryProvider).list();
      _fromBackend = true;
      state = [for (final item in items) _fromItem(item)];
    } catch (_) {
      // Offline / unreachable — leave the current cards in place.
    } finally {
      _loading = false;
    }
  }

  /// Read state is applied locally first; a failed sync is not worth an error
  /// toast, and the next refresh re-reads the server's truth anyway.
  Future<void> _syncRead(String id) async {
    try {
      await ref.read(notificationsRepositoryProvider).markRead(id);
    } catch (_) {
      // Swallowed by design — see above.
    }
  }

  static AppNotification _fromItem(NotificationItem item) {
    return AppNotification(
      id: item.id.isEmpty ? null : item.id,
      title: item.title,
      body: item.message,
      icon: iconKeyFor(item.type),
      // A row without a parseable timestamp still has to sort and group; "now"
      // puts it at the top of Today rather than dropping it.
      time: item.createdAt ?? DateTime.now(),
      action: item.actionLabel,
      unread: !item.isRead,
    );
  }

  /// Maps a server notification `type` onto the screen's icon keys.
  ///
  /// The type vocabulary is undocumented (see the blocking TODO in
  /// `notifications_repository.dart`), so this matches on substrings rather
  /// than an exact-value table. An unmatched type is returned unchanged — the
  /// screen's own lookup then falls back to the generic bell, which is the
  /// honest rendering for a category we don't recognise.
  static String iconKeyFor(String type) {
    final t = type.toLowerCase();
    if (t.isEmpty) return 'sparkling';
    for (final entry in _iconKeywords.entries) {
      if (t.contains(entry.key)) return entry.value;
    }
    return type;
  }

  /// Ordered: earlier entries win, so "withdrawal" beats the bare "coin" it
  /// would otherwise share a card with.
  static const Map<String, String> _iconKeywords = {
    'withdraw': 'handCoin',
    'deposit': 'bankCard',
    'payment': 'bankCard',
    'topup': 'bankCard',
    'top_up': 'bankCard',
    'referral': 'userAdd',
    'follow': 'userAdd',
    'reply': 'chat',
    'comment': 'chat',
    'voice': 'mic',
    'like': 'heart',
    'badge': 'award',
    'milestone': 'flag',
    'streak': 'flash',
    'task': 'task',
    'submission': 'task',
    'episode': 'play',
    'video': 'play',
    'coin': 'coins',
    'reward': 'coins',
    'announce': 'megaphone',
    'welcome': 'sparkling',
    'warning': 'warning',
    'revision': 'warning',
  };

  static List<AppNotification> _seed(DateTime now) {
    final yesterday = now.subtract(const Duration(days: 1));
    return [
      // ── Today ──
      AppNotification(
        title: 'Welcome to SkiFlux',
        body:
            'Watch an episode, complete the task, and earn your first '
            'SkillCoins today.',
        icon: 'sparkling',
        time: now.subtract(const Duration(minutes: 2)),
        unread: true,
      ),
      AppNotification(
        title: 'New episode',
        body:
            'Amara Design just dropped "Design Systems from Scratch". '
            'Your task is ready too.',
        icon: 'play',
        time: now.subtract(const Duration(minutes: 14)),
        action: 'Watch EP. 04',
        unread: true,
      ),
      AppNotification(
        title: 'Task submitted',
        body:
            'Your task for EP 01 "Intro to UI Design Thinking" is under '
            "review. You'll hear back soon.",
        icon: 'task',
        time: now.subtract(const Duration(hours: 1)),
        unread: true,
      ),
      AppNotification(
        title: 'SkillCoins earned',
        body:
            'Your EP 01 task was approved — 50 SkillCoins added to your '
            'wallet. Keep going — EP 02 is waiting.',
        icon: 'coins',
        time: now.subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        title: 'Your first coins',
        body:
            'You just earned your first 50 SkillCoins. Complete more '
            'tasks to grow your wallet.',
        icon: 'coin',
        time: now.subtract(const Duration(hours: 5)),
      ),
      // ── Yesterday ──
      AppNotification(
        title: 'Keep your streak',
        body:
            "You're on a 3-day streak. Watch today's episode to keep "
            'it going.',
        icon: 'flash',
        time: yesterday.subtract(const Duration(hours: 2)),
        action: 'Watch Now',
      ),
      AppNotification(
        title: 'New reply',
        body:
            'Tolu Dev replied to your comment on "Intro to UI Design '
            'Thinking".',
        icon: 'chat',
        time: yesterday.subtract(const Duration(hours: 3)),
        action: 'View Reply',
      ),
      AppNotification(
        title: 'Voice reply',
        body:
            'Figma Academy left a voice note on your comment in "Auto '
            'Layout Mastery".',
        icon: 'mic',
        time: yesterday.subtract(const Duration(hours: 4)),
        action: 'Listen to Reply',
      ),
      AppNotification(
        title: 'Your comment got a like',
        body:
            'Motion Lab liked what you said on "Component Libraries '
            'in Figma".',
        icon: 'heart',
        time: yesterday.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        title: 'Badge unlocked',
        body:
            'You earned the "First Task Done" badge. Keep going — more '
            'are waiting.',
        icon: 'award',
        time: yesterday.subtract(const Duration(hours: 6)),
        action: 'View Badge',
      ),
      AppNotification(
        title: 'Revision needed',
        body:
            'Your EP 02 task needs a small fix. Tap to see the feedback '
            'and resubmit.',
        icon: 'warning',
        time: yesterday.subtract(const Duration(hours: 7)),
        action: 'View Feedback',
      ),
      AppNotification(
        title: 'Milestone reached',
        body:
            'You just hit 500 SkillCoins. You can now unlock a premium '
            'course or withdraw to your account.',
        icon: 'flag',
        time: yesterday.subtract(const Duration(hours: 8)),
        action: 'Open Wallet',
      ),
      AppNotification(
        title: 'Withdrawal successful',
        body:
            'Your 200-coin withdrawal (₦1,200) is on its way. It may '
            'take up to 24 hrs.',
        icon: 'handCoin',
        time: yesterday.subtract(const Duration(hours: 9)),
      ),
      AppNotification(
        title: 'Deposit successful',
        body:
            'Your deposit of ₦1,200 was successful. 200 SkillCoins have '
            'been added to your wallet.',
        icon: 'bankCard',
        time: yesterday.subtract(const Duration(hours: 10)),
      ),
      AppNotification(
        title: 'Referral reward',
        body:
            'Someone joined SkiFlux with your link. 30 SkillCoins have '
            'been added to your wallet.',
        icon: 'userAdd',
        time: yesterday.subtract(const Duration(hours: 11)),
      ),
      AppNotification(
        title: 'From SkiFlux',
        body:
            "New creators just joined. Check out who's posting this "
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
