import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/streaks/data/models/streak_summary.dart'
    as wire;
import 'package:skiflux/features/streaks/data/streaks_repository.dart';
import 'package:skiflux/features/streaks/data/streaks_store.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('streaksProvider', () {
    test('build starts empty and loading, with nothing from the backend', () {
      final state = container.read(streaksProvider);
      expect(state.streak, 0);
      expect(state.bestStreak, 0);
      expect(state.xpEarned, 0);
      expect(state.history, isEmpty);
      expect(state.currentWeek, isNull);
      expect(state.loading, isTrue);
      expect(state.fromBackend, isFalse);
      expect(state.error, isNull);
    });

    test('initial celebrated is false', () {
      final state = container.read(streaksProvider);
      expect(state.celebrated, isFalse);
    });

    test('consumeCelebration returns false before the API has answered', () {
      // Streak 0 and milestone 0 satisfy `streak >= milestone`; without the
      // milestone guard an empty state would celebrate a streak of zero.
      final notifier = container.read(streaksProvider.notifier);
      expect(notifier.consumeCelebration(), isFalse);
      expect(container.read(streaksProvider).celebrated, isFalse);
    });

    test('consumeCelebration returns true once the milestone is reached',
        () async {
      final c = ProviderContainer(
        overrides: [
          streaksProvider.overrideWith(() => _ReachedMilestoneNotifier()),
        ],
      );
      addTearDown(c.dispose);

      final notifier = c.read(streaksProvider.notifier);
      expect(notifier.consumeCelebration(), isTrue);
      expect(c.read(streaksProvider).celebrated, isTrue);
      // Once per session.
      expect(notifier.consumeCelebration(), isFalse);
    });

    test('consumeCelebration returns false when streak below milestone', () {
      // Create a container with a custom provider that has a low streak.
      final lowStreakContainer = ProviderContainer(
        overrides: [streaksProvider.overrideWith(() => _LowStreakNotifier())],
      );
      addTearDown(lowStreakContainer.dispose);

      final notifier = lowStreakContainer.read(streaksProvider.notifier);
      final result = notifier.consumeCelebration();
      expect(result, isFalse);
    });
  });

  group('streaksProvider refreshFromBackend', () {
    /// Sun–Sat with Sun–Thu earned, Fri = today, Sat still ahead.
    wire.StreakSummary summary({
      int current = 5,
      int best = 12,
      int xp = 310,
      int nextAt = 7,
      int xpReward = 50,
    }) {
      final friday = DateTime.now();
      final sunday = friday.subtract(const Duration(days: 5));
      wire.StreakWeekDay day(int offset, wire.StreakWeekDayStatus status) {
        final date = sunday.add(Duration(days: offset));
        return wire.StreakWeekDay(
          weekday: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][offset],
          date: DateTime(date.year, date.month, date.day),
          dayOfMonth: date.day,
          status: status,
        );
      }

      return wire.StreakSummary(
        currentStreakCount: current,
        isStreakActive: true,
        bestStreak: best,
        totalStreakXpEarned: xp,
        week: wire.StreakWeek(
          startDate: DateTime(sunday.year, sunday.month, sunday.day),
          endDate: DateTime(sunday.year, sunday.month, sunday.day)
              .add(const Duration(days: 6)),
          label: 'Server Label',
          days: [
            for (var i = 0; i < 5; i++)
              day(i, wire.StreakWeekDayStatus.completed),
            day(5, wire.StreakWeekDayStatus.upcoming),
            day(6, wire.StreakWeekDayStatus.upcoming),
          ],
        ),
        milestone: wire.StreakMilestone(
          intervalDays: 7,
          xpReward: xpReward,
          nextAtStreak: nextAt,
          daysRemaining: nextAt - current,
          reachedToday: false,
        ),
      );
    }

    ProviderContainer withRepo(StreaksRepository repo) {
      final c = ProviderContainer(
        overrides: [streaksRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('maps stats from the API onto the view model', () async {
      final c = withRepo(_FakeStreaksRepository(summary()));
      await c.read(streaksProvider.notifier).refreshFromBackend();

      final state = c.read(streaksProvider);
      expect(state.streak, 5);
      expect(state.bestStreak, 12);
      expect(state.xpEarned, 310);
      expect(state.milestone, 7);
      expect(state.milestoneXp, 50);
      expect(state.fromBackend, isTrue);
      expect(state.loading, isFalse);
    });

    test('collapses history to the single week the API reports', () async {
      final c = withRepo(_FakeStreaksRepository(summary()));
      await c.read(streaksProvider.notifier).refreshFromBackend();

      final history = c.read(streaksProvider).history;
      expect(history, hasLength(1));
      expect(history.single.days, hasLength(7));
    });

    test('prefers the server-rendered week label', () async {
      final c = withRepo(_FakeStreaksRepository(summary()));
      await c.read(streaksProvider.notifier).refreshFromBackend();

      expect(c.read(streaksProvider).currentWeek!.label, 'Server Label');
    });

    test('computed label spans the 7 tracked days (Sun through Sat)', () {
      // Sun May 20 2029 + 6 = Sat May 26 — not the 8-day "27th" span.
      expect(StreakWeek(DateTime(2029, 5, 20), const []).label,
          'May 20th - 26th');
      // Month boundary: Sun Apr 29 2029 + 6 = Sat May 5.
      expect(StreakWeek(DateTime(2029, 4, 29), const []).label,
          'Apr 29th - May 5th');
    });

    test('renders today as pending and later days as future', () async {
      final c = withRepo(_FakeStreaksRepository(summary()));
      await c.read(streaksProvider.notifier).refreshFromBackend();

      final days = c.read(streaksProvider).currentWeek!.days;
      expect(days.take(5).map((d) => d.state),
          everyElement(StreakDayState.completed));
      expect(days[5].state, StreakDayState.today);
      expect(days[6].state, StreakDayState.future);
    });

    test('numbers pending cells with the streak they would reach', () async {
      final c = withRepo(_FakeStreaksRepository(summary(current: 5)));
      await c.read(streaksProvider.notifier).refreshFromBackend();

      final days = c.read(streaksProvider).currentWeek!.days;
      expect(days[5].number, 6); // completing today → 6
      expect(days[6].number, 7); // then tomorrow → 7
      expect(days[0].number, isNull); // earned cells show a check, not a count
    });

    test('surfaces the failure instead of showing invented data', () async {
      // This used to assert the opposite — that a failed request left the
      // 2029 demo seed on screen, which read to the user as their own streak.
      final c = withRepo(_FakeStreaksRepository(null));
      await c.read(streaksProvider.notifier).refreshFromBackend();

      final state = c.read(streaksProvider);
      expect(state.history, isEmpty);
      expect(state.currentWeek, isNull);
      expect(state.streak, 0);
      expect(state.error, isNotNull);
      expect(state.fromBackend, isFalse);
      expect(state.loading, isFalse);
    });

    test('a successful retry after a failure clears the error', () async {
      final repo = _RetryingStreaksRepository(summary());
      final c = withRepo(repo);

      await c.read(streaksProvider.notifier).refreshFromBackend();
      expect(c.read(streaksProvider).error, isNotNull);

      await c.read(streaksProvider.notifier).refreshFromBackend();
      final state = c.read(streaksProvider);
      expect(state.error, isNull);
      expect(state.fromBackend, isTrue);
      expect(state.streak, 5);
    });

    test('preserves the celebration flag across a refresh', () async {
      final c = withRepo(_FakeStreaksRepository(summary(current: 9)));
      // Celebrating has to come *after* the first load now: milestone is 0
      // until the API answers, and a milestone of 0 never celebrates.
      await c.read(streaksProvider.notifier).refreshFromBackend();
      expect(c.read(streaksProvider.notifier).consumeCelebration(), isTrue);

      await c.read(streaksProvider.notifier).refreshFromBackend();
      // Already celebrated this session — must not fire again on real data.
      expect(c.read(streaksProvider).celebrated, isTrue);
      expect(c.read(streaksProvider.notifier).consumeCelebration(), isFalse);
    });
  });
}

/// Returns [result], or throws when it is null (the offline path).
class _FakeStreaksRepository extends StreaksRepository {
  _FakeStreaksRepository(this.result) : super(Dio());

  final wire.StreakSummary? result;

  @override
  Future<wire.StreakSummary> getStreak() async {
    final value = result;
    if (value == null) throw Exception('offline');
    return value;
  }
}

/// Throws once, then returns [result] — the failure-then-retry path.
class _RetryingStreaksRepository extends StreaksRepository {
  _RetryingStreaksRepository(this.result) : super(Dio());

  final wire.StreakSummary result;
  var _calls = 0;

  @override
  Future<wire.StreakSummary> getStreak() async {
    if (_calls++ == 0) throw Exception('offline');
    return result;
  }
}

/// A notifier already standing on its milestone, as a successful load leaves
/// it. The store's own `build()` cannot express this — it starts at zero.
class _ReachedMilestoneNotifier extends StreaksNotifier {
  @override
  StreaksState build() {
    return const StreaksState(
      streak: 7,
      bestStreak: 14,
      xpEarned: 240,
      milestone: 7,
      milestoneXp: 50,
      history: [],
      fromBackend: true,
    );
  }
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

