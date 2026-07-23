import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/subscriptions/data/subscriptions_store.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('subscriptionsProvider', () {
    test('build returns seeded creators and episodes', () {
      final state = container.read(subscriptionsProvider);
      expect(state.creators, hasLength(4));
      expect(state.episodes, hasLength(8));
    });

    test('feed returns all episodes by default', () {
      final state = container.read(subscriptionsProvider);
      final feed = state.feed();
      expect(feed, hasLength(8));
    });

    test('feed with today filter returns only postedToday episodes', () {
      final state = container.read(subscriptionsProvider);
      final feed = state.feed(filter: SubscriptionFeedFilter.today);
      expect(feed.length, greaterThan(0));
      for (final ep in feed) {
        expect(ep.postedToday, isTrue);
      }
    });

    test('feed with continueWatching filter returns partial progress', () {
      final state = container.read(subscriptionsProvider);
      final feed =
          state.feed(filter: SubscriptionFeedFilter.continueWatching);
      expect(feed.length, greaterThan(0));
      for (final ep in feed) {
        expect(ep.watchProgress, greaterThan(0));
        expect(ep.watchProgress, lessThan(1));
      }
    });

    test('feed with unwatched filter returns only untouched episodes', () {
      final state = container.read(subscriptionsProvider);
      final feed = state.feed(filter: SubscriptionFeedFilter.unwatched);
      expect(feed.length, greaterThan(0));
      for (final ep in feed) {
        expect(ep.watchProgress, 0);
      }
    });

    test('feed sorts new episodes first', () {
      final state = container.read(subscriptionsProvider);
      final feed = state.feed();
      var seenNonNew = false;
      for (final ep in feed) {
        if (!ep.isNew) seenNonNew = true;
        // Once we've seen a non-new, we should not see a new again.
        if (seenNonNew) expect(ep.isNew, isFalse);
      }
    });

    test('feed filtered by creator returns only that creators episodes', () {
      final state = container.read(subscriptionsProvider);
      final feed = state.feed(creatorUsername: 'amara');
      expect(feed.length, greaterThan(0));
      for (final ep in feed) {
        expect(ep.creatorUsername, 'amara');
      }
    });

    test('unsubscribe removes creator from feed', () {
      final notifier = container.read(subscriptionsProvider.notifier);
      final amara = container.read(subscriptionsProvider).creators[0];
      expect(amara.username, 'amara');

      notifier.unsubscribe(amara);
      final state = container.read(subscriptionsProvider);
      expect(state.creators, hasLength(3));
      expect(state.creators.any((c) => c.username == 'amara'), isFalse);

      // Feed should no longer contain amara's episodes.
      final feed = state.feed();
      for (final ep in feed) {
        expect(ep.creatorUsername, isNot('amara'));
      }
    });

    test('setNotificationMode changes mode', () {
      final notifier = container.read(subscriptionsProvider.notifier);
      final amara = container.read(subscriptionsProvider).creators[0];

      notifier.setNotificationMode(amara, CreatorNotificationMode.none);
      expect(amara.notificationMode, CreatorNotificationMode.none);
    });

    test('sortedCreators sorts A-Z correctly', () {
      final state = container.read(subscriptionsProvider);
      final sorted = state.sortedCreators(SubscriptionListSort.aToZ);
      expect(sorted[0].name, 'Amara Design');
      expect(sorted[1].name, 'Design Dan');
      expect(sorted[2].name, 'Kojo Sketches');
      expect(sorted[3].name, 'Lola Motion');
    });

    test('newCountFor returns correct count', () {
      final state = container.read(subscriptionsProvider);
      final amara = state.creators[0];
      expect(state.newCountFor(amara), 3);
    });
  });
}
