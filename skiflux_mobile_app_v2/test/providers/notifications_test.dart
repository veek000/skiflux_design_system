import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/notifications/data/notifications_store.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
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
}
