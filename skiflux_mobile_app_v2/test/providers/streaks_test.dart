import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/streaks/data/streaks_store.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('streaksProvider', () {
    test('build returns seeded streak data', () {
      final state = container.read(streaksProvider);
      expect(state.streak, 7);
      expect(state.bestStreak, 14);
      expect(state.xpEarned, 240);
      expect(state.milestone, 7);
      expect(state.milestoneXp, 50);
    });

    test('seed has 4 weeks of history', () {
      final state = container.read(streaksProvider);
      expect(state.history, hasLength(4));
    });

    test('initial celebrated is false', () {
      final state = container.read(streaksProvider);
      expect(state.celebrated, isFalse);
    });

    test('consumeCelebration returns true on first call', () {
      final notifier = container.read(streaksProvider.notifier);
      final result = notifier.consumeCelebration();
      expect(result, isTrue);
    });

    test('consumeCelebration returns false on second call', () {
      final notifier = container.read(streaksProvider.notifier);
      notifier.consumeCelebration();
      final result = notifier.consumeCelebration();
      expect(result, isFalse);
    });

    test('consumeCelebration sets celebrated to true', () {
      final notifier = container.read(streaksProvider.notifier);
      notifier.consumeCelebration();
      final state = container.read(streaksProvider);
      expect(state.celebrated, isTrue);
    });

    test('consumeCelebration returns false when streak below milestone', () {
      // Create a container with a custom provider that has a low streak.
      final lowStreakContainer = ProviderContainer(
        overrides: [
          streaksProvider.overrideWith(
            () => _LowStreakNotifier(),
          ),
        ],
      );
      addTearDown(lowStreakContainer.dispose);

      final notifier = lowStreakContainer.read(streaksProvider.notifier);
      final result = notifier.consumeCelebration();
      expect(result, isFalse);
    });
  });
}

/// A notifier that returns a streak below the milestone threshold.
class _LowStreakNotifier extends StreaksNotifier {
  @override
  StreaksState build() {
    return const StreaksState(
      streak: 2,
      bestStreak: 5,
      xpEarned: 100,
      milestone: 7,
      milestoneXp: 50,
      history: [],
    );
  }
}
