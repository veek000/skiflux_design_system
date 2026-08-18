import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/notifications/data/models/notification_item.dart';
import 'package:skiflux/features/notifications/data/notifications_repository.dart';
import 'package:skiflux/features/notifications/data/notifications_store.dart';
import 'package:skiflux/shared/network/token_store.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(
          _FakeNotificationsRepository([]),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('notificationsProvider', () {
    test('build returns seeded notifications', () {
      final notifications = container.read(notificationsProvider);
      expect(notifications.length, 16);
      expect(notifications[0].title, 'Welcome to SkiFlux');
    });

    test('initial unread count is 3', () {
      final notifier = container.read(notificationsProvider.notifier);
      expect(notifier.unreadCount, 3);
    });

    test('markRead sets notification to read', () {
      final notifier = container.read(notificationsProvider.notifier);
      final first = container.read(notificationsProvider)[0];
      expect(first.unread, isTrue);

      notifier.markRead(first);
      expect(first.unread, isFalse);
      expect(notifier.unreadCount, 2);
    });

    test('markRead on already-read notification is no-op', () {
      final notifier = container.read(notificationsProvider.notifier);
      final readNotification = container.read(notificationsProvider)[3];
      expect(readNotification.unread, isFalse);

      notifier.markRead(readNotification);
      expect(readNotification.unread, isFalse);
      expect(notifier.unreadCount, 3);
    });

    test('markAllRead sets all to read', () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.markAllRead();
      for (final n in container.read(notificationsProvider)) {
        expect(n.unread, isFalse);
      }
      expect(notifier.unreadCount, 0);
    });

    test('unread getter returns only unread notifications', () {
      final notifier = container.read(notificationsProvider.notifier);
      final unread = notifier.unread;
      expect(unread.length, 3);
      for (final n in unread) {
        expect(n.unread, isTrue);
      }
    });
  });

  group('notificationsProvider refreshFromBackend', () {
    ProviderContainer withRepo(
      _FakeNotificationsRepository repo, {
      bool signedIn = true,
    }) {
      final c = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repo),
          tokenStoreProvider.overrideWithValue(_FakeTokenStore(signedIn)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    NotificationItem item({
      String id = 'n1',
      String type = 'new_episode',
      bool isRead = false,
      String? actionLabel,
      DateTime? createdAt,
    }) => NotificationItem(
      id: id,
      title: 'Title',
      message: 'Body',
      type: type,
      isRead: isRead,
      actionLabel: actionLabel,
      createdAt: createdAt,
    );

    test('replaces the demo seed with the fetched feed', () async {
      final c = withRepo(_FakeNotificationsRepository([item(), item(id: 'n2')]));
      await c.read(notificationsProvider.notifier).refreshFromBackend();

      final list = c.read(notificationsProvider);
      expect(list, hasLength(2));
      expect(list.first.title, 'Title');
      expect(c.read(notificationsProvider.notifier).fromBackend, isTrue);
    });

    test('an empty feed clears the seed so the empty state shows', () async {
      final c = withRepo(_FakeNotificationsRepository([]));
      await c.read(notificationsProvider.notifier).refreshFromBackend();

      expect(c.read(notificationsProvider), isEmpty);
    });

    test('signed-in failure is an error state, never the demo seed', () async {
      // The seed includes fabricated money notifications — a signed-in user
      // must get an error + retry, not those.
      final c = withRepo(_FakeNotificationsRepository(null));
      await c.read(notificationsProvider.notifier).refreshFromBackend();

      expect(c.read(notificationsProvider), isEmpty);
      expect(c.read(notificationsProvider.notifier).loadFailed, isTrue);
      expect(c.read(notificationsProvider.notifier).fromBackend, isFalse);
    });

    test('signed out keeps the demo seed and never calls the API', () async {
      final repo = _FakeNotificationsRepository([item()]);
      final c = withRepo(repo, signedIn: false);
      await c.read(notificationsProvider.notifier).refreshFromBackend();

      expect(c.read(notificationsProvider), hasLength(16));
      expect(c.read(notificationsProvider.notifier).fromBackend, isFalse);
      expect(c.read(notificationsProvider.notifier).loadFailed, isFalse);
      expect(repo.listCalls, 0);
    });

    test('a failed re-fetch keeps the last live list, not an error', () async {
      final repo = _FakeNotificationsRepository([item()]);
      final c = withRepo(repo);
      await c.read(notificationsProvider.notifier).refreshFromBackend();

      repo.failNext = true;
      await c.read(notificationsProvider.notifier).refreshFromBackend();

      expect(c.read(notificationsProvider), hasLength(1));
      expect(c.read(notificationsProvider.notifier).loadFailed, isFalse);
    });

    test('a retry after a failure recovers to the live feed', () async {
      final repo = _FakeNotificationsRepository([item()], failNext: true);
      final c = withRepo(repo);
      await c.read(notificationsProvider.notifier).refreshFromBackend();
      expect(c.read(notificationsProvider.notifier).loadFailed, isTrue);

      repo.failNext = false;
      await c.read(notificationsProvider.notifier).refreshFromBackend();

      expect(c.read(notificationsProvider), hasLength(1));
      expect(c.read(notificationsProvider.notifier).loadFailed, isFalse);
      expect(c.read(notificationsProvider.notifier).fromBackend, isTrue);
    });

    test('maps read state onto the unread flag', () async {
      final c = withRepo(
        _FakeNotificationsRepository([
          item(isRead: true),
          item(id: 'n2', isRead: false),
        ]),
      );
      await c.read(notificationsProvider.notifier).refreshFromBackend();

      expect(c.read(notificationsProvider.notifier).unreadCount, 1);
    });

    test('stamps a row with no timestamp so it still groups', () async {
      final c = withRepo(_FakeNotificationsRepository([item()]));
      await c.read(notificationsProvider.notifier).refreshFromBackend();

      final now = DateTime.now();
      final time = c.read(notificationsProvider).single.time;
      expect(now.difference(time).inMinutes, lessThan(1));
    });

    test('marking a fetched row read posts to the backend', () async {
      final repo = _FakeNotificationsRepository([item()]);
      final c = withRepo(repo);
      final notifier = c.read(notificationsProvider.notifier);
      await notifier.refreshFromBackend();

      notifier.markRead(c.read(notificationsProvider).single);
      await Future<void>.delayed(Duration.zero);
      expect(repo.markedRead, ['n1']);
    });

    test('marking all read calls markAllRead on repository', () async {
      final repo = _FakeNotificationsRepository([
        item(),
        item(id: 'n2'),
        item(id: 'n3', isRead: true),
      ]);
      final c = withRepo(repo);
      final notifier = c.read(notificationsProvider.notifier);
      await notifier.refreshFromBackend();

      notifier.markAllRead();
      await Future<void>.delayed(Duration.zero);
      expect(repo.markAllReadCalled, isTrue);
      expect(notifier.unreadCount, 0);
    });

    test('a failed mark-read still leaves the row read locally', () async {
      final repo = _FakeNotificationsRepository([item()], failMarkRead: true);
      final c = withRepo(repo);
      final notifier = c.read(notificationsProvider.notifier);
      await notifier.refreshFromBackend();

      notifier.markRead(c.read(notificationsProvider).single);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.unreadCount, 0);
    });

    test('demo rows markAllRead is invoked safely', () async {
      final repo = _FakeNotificationsRepository(null);
      final c = withRepo(repo);
      final notifier = c.read(notificationsProvider.notifier);

      notifier.markAllRead();
      await Future<void>.delayed(Duration.zero);
      expect(repo.markAllReadCalled, isTrue);
    });
  });

  group('NotificationsRepository.parse', () {
    test('reads the documented NotificationItem', () {
      // The spec's six flat fields plus `data`. Note there is no `message`,
      // no `icon` and no `action_label` — the body key is `body`.
      final item = NotificationsRepository.parse({
        'id': 'abc',
        'type': 'task_submitted',
        'title': 'Task submitted',
        'body': 'Under review',
        'data': <String, dynamic>{},
        'is_read': true,
        'created_at': '2026-07-01T10:00:00Z',
      });

      expect(item.id, 'abc');
      expect(item.title, 'Task submitted');
      expect(item.message, 'Under review');
      expect(item.type, 'task_submitted');
      expect(item.createdAt?.toUtc(), DateTime.utc(2026, 7, 1, 10));
      expect(item.isRead, isTrue);
      // Nothing in `data` to build a pill from, so the card renders without one
      // rather than inventing a label.
      expect(item.actionLabel, isNull);
    });

    test('the documented body key wins over the tolerated alias', () {
      final item = NotificationsRepository.parse({
        'id': 'a',
        'body': 'Documented',
        'message': 'Tolerated',
      });
      expect(item.message, 'Documented');
    });

    test('falls back to alias field names', () {
      final item = NotificationsRepository.parse({
        'notification_id': 42,
        'message': 'Alias body',
        'notification_type': 'coin_earned',
        'send_time': '2026-07-01T10:00:00Z',
        'unread': true,
      });

      expect(item.id, '42');
      expect(item.message, 'Alias body');
      expect(item.type, 'coin_earned');
      expect(item.isRead, isFalse);
    });

    test('read_at being set counts as read', () {
      final item = NotificationsRepository.parse({
        'id': 'a',
        'read_at': '2026-07-01T10:00:00Z',
      });
      expect(item.isRead, isTrue);
    });

    test('reads epoch seconds and milliseconds alike', () {
      final seconds = NotificationsRepository.parse({
        'timestamp': 1767225600,
      }).createdAt;
      final millis = NotificationsRepository.parse({
        'timestamp': 1767225600000,
      }).createdAt;
      expect(seconds, isNotNull);
      expect(seconds, millis);
    });

    test('an unparseable timestamp leaves createdAt null', () {
      final item = NotificationsRepository.parse({
        'id': 'a',
        'created_at': 'not a date',
      });
      expect(item.createdAt, isNull);
    });

    test('falls back to a nested data payload', () {
      final item = NotificationsRepository.parse({
        'id': 'a',
        'data': {'type': 'streak_reminder', 'action_label': 'Watch Now'},
      });
      expect(item.type, 'streak_reminder');
      expect(item.actionLabel, 'Watch Now');
    });

    test('a payload of nothing but an id still parses', () {
      final item = NotificationsRepository.parse({'id': 'a'});
      expect(item.title, isEmpty);
      expect(item.message, isEmpty);
      expect(item.isRead, isFalse);
      expect(item.actionLabel, isNull);
    });
  });

  group('NotificationsNotifier.iconKeyFor', () {
    test('matches types by keyword', () {
      expect(NotificationsNotifier.iconKeyFor('new_episode'), 'play');
      expect(NotificationsNotifier.iconKeyFor('coin_earned'), 'coins');
      expect(NotificationsNotifier.iconKeyFor('comment_reply'), 'chat');
      expect(NotificationsNotifier.iconKeyFor('badge_unlocked'), 'award');
      expect(NotificationsNotifier.iconKeyFor('streak_reminder'), 'flash');
    });

    test('withdrawal beats the bare coin it also contains', () {
      expect(NotificationsNotifier.iconKeyFor('withdrawal_coins'), 'handCoin');
    });

    test('an unrecognised type passes through to the generic bell', () {
      expect(NotificationsNotifier.iconKeyFor('brand_new_thing'), 'brand_new_thing');
    });

    test('an empty type falls back to the welcome icon', () {
      expect(NotificationsNotifier.iconKeyFor(''), 'sparkling');
    });
  });
}

/// Returns [items], or throws when they are null (the offline path) or when
/// [failNext] is set. Records every id passed to [markRead] so the
/// optimistic-read sync can be asserted.
class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository(
    this.items, {
    this.failMarkRead = false,
    this.failNext = false,
  }) : super(Dio());

  final List<NotificationItem>? items;
  final bool failMarkRead;
  bool failNext;
  int listCalls = 0;
  final List<String> markedRead = [];

  @override
  Future<List<NotificationItem>> list({
    int? limit,
    int? offset,
    bool? unreadOnly,
  }) async {
    listCalls++;
    final value = items;
    if (value == null || failNext) throw Exception('offline');
    return value;
  }

  bool markAllReadCalled = false;

  @override
  Future<void> markRead(String id) async {
    markedRead.add(id);
    if (failMarkRead) throw Exception('offline');
  }

  @override
  Future<void> markAllRead() async {
    markAllReadCalled = true;
  }
}

/// Presence-only session gate, with no platform channel behind it.
class _FakeTokenStore extends TokenStore {
  _FakeTokenStore(this.signedIn) : super(const FlutterSecureStorage());

  final bool signedIn;

  @override
  Future<bool> hasSession() async => signedIn;
}

