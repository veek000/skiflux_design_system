import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/leaderboard/data/leaderboard_store.dart';

void main() {
  group('leaderboardProvider', () {
    test('returns static data with correct shape', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final data = container.read(leaderboardProvider);
      expect(data.leagues, hasLength(6));
      expect(data.currentRank, 12);
      expect(data.betterThanPercent, 60);
      expect(data.entries, hasLength(15));
    });

    test('podium returns top 3 entries', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final data = container.read(leaderboardProvider);
      expect(data.podium, hasLength(3));
      expect(data.podium[0].rank, 1);
      expect(data.podium[0].name, 'Lola Motion');
      expect(data.podium[1].rank, 2);
      expect(data.podium[2].rank, 3);
    });

    test('ranked returns entries 4-15', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final data = container.read(leaderboardProvider);
      expect(data.ranked, hasLength(12));
      expect(data.ranked[0].rank, 4);
      expect(data.ranked[11].rank, 15);
    });

    test('entries have correct fields populated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(leaderboardProvider).entries[0];
      expect(first.name, isNotEmpty);
      expect(first.username, isNotEmpty);
      expect(first.initials, isNotEmpty);
      expect(first.xp, greaterThan(0));
      expect(first.handle, startsWith('@'));
    });

    test('xpLabel formats thousands', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Entry with 4820 XP should format as "4,820".
      final first = container.read(leaderboardProvider).entries[0];
      expect(first.xpLabel, '4,820');
    });
  });
}
