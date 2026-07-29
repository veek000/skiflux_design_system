/// Streak state backing the Streaks screen (Figma Streak Flow `3092:14400`).
///
/// [StreaksNotifier.refreshFromBackend] loads `GET /me/streak`; the demo seed
/// remains the offline fallback, same arrangement as `wallet_store`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/streak_summary.dart' as wire;
import 'streaks_repository.dart';

/// One day cell in the "This Week" tracker.
enum StreakDayState {
  /// Orange circle + white check (`check-fill`).
  completed,

  /// Red-subtle circle + red cross (`close-fill`) — screen 01 only.
  missed,

  /// Orange-subtle circle + orange streak number (today, pending).
  today,

  /// Grey circle + disabled streak number.
  future,
}

class StreakDay {
  const StreakDay(this.label, this.state, [this.number]);

  /// Short weekday label ("Sun" … "Sat").
  final String label;
  final StreakDayState state;

  /// Streak count the user reaches by completing this day — shown for
  /// [StreakDayState.today] and [StreakDayState.future] cells.
  final int? number;
}

/// One tracked Sun–Sat week. [start] is the week's Sunday; the label
/// follows Figma's `start – start+7` convention ("May 20th - 27th").
class StreakWeek {
  StreakWeek(this.start, this.days, {this.labelOverride});

  final DateTime start;
  final List<StreakDay> days;

  /// Server-rendered range label from `GET /me/streak`. Preferred over the
  /// computed [label] so client and API never disagree on the wording.
  final String? labelOverride;

  /// Whether this week is the demo "current" week ([currentStart]).
  bool isCurrentFor(DateTime currentStart) => sameDay(start, currentStart);

  /// Figma pill label, e.g. "May 20th - 27th" / "Apr 29th - May 6th".
  String get label {
    final override = labelOverride;
    if (override != null && override.isNotEmpty) return override;
    final end = start.add(const Duration(days: 7));
    final sameMonth = start.month == end.month;
    final from = '${_months[start.month - 1]} ${_ordinal(start.day)}';
    final to = sameMonth
        ? _ordinal(end.day)
        : '${_months[end.month - 1]} ${_ordinal(end.day)}';
    return '$from - $to';
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }
}

/// Immutable snapshot of streak data + session celebration flag.
class StreaksState {
  const StreaksState({
    required this.streak,
    required this.bestStreak,
    required this.xpEarned,
    required this.milestone,
    required this.milestoneXp,
    required this.history,
    this.celebrated = false,
    this.fromBackend = false,
    this.loading = false,
  });

  final int streak;
  final int bestStreak;
  final int xpEarned;
  final int milestone;
  final int milestoneXp;
  final List<StreakWeek> history;
  final bool celebrated;

  /// True once `GET /me/streak` has answered. While false the screen is
  /// showing the demo seed.
  final bool fromBackend;
  final bool loading;

  StreakWeek get currentWeek => history.last;

  /// The tracked week whose Sun–Sat range contains [day], if any.
  StreakWeek? weekContaining(DateTime day) {
    for (final week in history) {
      final delta = DateTime(
        day.year,
        day.month,
        day.day,
      ).difference(week.start).inDays;
      if (delta >= 0 && delta < 7) return week;
    }
    return null;
  }

  StreaksState copyWith({bool? celebrated, bool? loading}) {
    return StreaksState(
      streak: streak,
      bestStreak: bestStreak,
      xpEarned: xpEarned,
      milestone: milestone,
      milestoneXp: milestoneXp,
      history: history,
      celebrated: celebrated ?? this.celebrated,
      fromBackend: fromBackend,
      loading: loading ?? this.loading,
    );
  }
}

/// Riverpod choice: [NotifierProvider] — [refreshFromBackend] replaces the
/// snapshot and [consumeCelebration] mutates a once-per-session flag. Plain
/// Provider cannot own either mutation.
//
// TODO(backend, minor): expose multi-week streak history so the week picker
// can offer past weeks — `GET /me/streak` returns only the current week —
// expects: history: List<{start_date: Date, end_date: Date, label: String,
// days: List<StreakWeekDay>}>
class StreaksNotifier extends Notifier<StreaksState> {
  static const _completed = StreakDayState.completed;
  static const _missed = StreakDayState.missed;

  @override
  StreaksState build() {
    // Streak 7 matches Figma Streak Screen 03/04 so the 7-day milestone
    // celebration is reachable. Four weeks of demo history, newest last
    // (= the current week). Year 2029 puts May 20 on a Sunday, matching
    // the Figma "May 20th - 27th" label against the Sun-first tracker.
    // Current week: Sun–Fri completed, Sat ahead. (Figma screen 03's Sat
    // cell reads "5" — an authoring slip; the real next streak number
    // after 7 is 8.) The May 13 week ends completed so today's streak of
    // 7 adds up (Sat + Sun–Fri).
    return StreaksState(
      streak: 7,
      bestStreak: 14,
      xpEarned: 240,
      milestone: 7,
      milestoneXp: 50,
      history: [
        StreakWeek(DateTime(2029, 4, 29), const [
          StreakDay('Sun', _completed),
          StreakDay('Mon', _completed),
          StreakDay('Tue', _completed),
          StreakDay('Wed', _completed),
          StreakDay('Thu', _completed),
          StreakDay('Fri', _completed),
          StreakDay('Sat', _completed),
        ]),
        StreakWeek(DateTime(2029, 5, 6), const [
          StreakDay('Sun', _completed),
          StreakDay('Mon', _completed),
          StreakDay('Tue', _completed),
          StreakDay('Wed', _completed),
          StreakDay('Thu', _completed),
          StreakDay('Fri', _completed),
          StreakDay('Sat', _missed),
        ]),
        StreakWeek(DateTime(2029, 5, 13), const [
          StreakDay('Sun', _missed),
          StreakDay('Mon', _completed),
          StreakDay('Tue', _completed),
          StreakDay('Wed', _missed),
          StreakDay('Thu', _completed),
          StreakDay('Fri', _completed),
          StreakDay('Sat', _completed),
        ]),
        StreakWeek(DateTime(2029, 5, 20), const [
          StreakDay('Sun', _completed),
          StreakDay('Mon', _completed),
          StreakDay('Tue', _completed),
          StreakDay('Wed', _completed),
          StreakDay('Thu', _completed),
          StreakDay('Fri', _completed),
          StreakDay('Sat', StreakDayState.future, 8),
        ]),
      ],
    );
  }

  /// The milestone sheet shows once per session, when the Streaks screen
  /// first opens with the milestone reached.
  bool consumeCelebration() {
    if (state.celebrated || state.streak < state.milestone) return false;
    state = state.copyWith(celebrated: true);
    return true;
  }

  /// Loads `GET /me/streak`. Keeps the current (demo or prior) snapshot on
  /// failure so the screen never empties out — same contract as
  /// `WalletNotifier.refreshFromBackend`.
  Future<void> refreshFromBackend() async {
    if (state.loading) return;
    state = state.copyWith(loading: true);
    try {
      final summary = await ref.read(streaksRepositoryProvider).getStreak();
      state = _fromSummary(summary, celebrated: state.celebrated);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  /// Adapts the wire [wire.StreakSummary] onto the screen's view model.
  ///
  /// The API reports one week, so [StreaksState.history] becomes a
  /// single-entry list — the week picker then offers exactly the week that
  /// exists rather than inventing past ones.
  static StreaksState _fromSummary(
    wire.StreakSummary summary, {
    required bool celebrated,
  }) {
    return StreaksState(
      streak: summary.currentStreakCount,
      bestStreak: summary.bestStreak,
      xpEarned: summary.totalStreakXpEarned,
      milestone: summary.milestone.nextAtStreak,
      milestoneXp: summary.milestone.xpReward,
      history: [_weekFrom(summary.week, summary.currentStreakCount)],
      celebrated: celebrated,
      fromBackend: true,
    );
  }

  static StreakWeek _weekFrom(wire.StreakWeek week, int currentStreak) {
    final today = DateTime.now();
    var upcomingSoFar = 0;
    final days = <StreakDay>[];
    for (final day in week.days) {
      final isToday = StreakWeek.sameDay(day.date, today);
      // The wire enum has no "today": a not-yet-earned day that *is* today
      // renders as the pending (orange-subtle) cell, later ones as future.
      final state = switch (day.status) {
        wire.StreakWeekDayStatus.completed => StreakDayState.completed,
        wire.StreakWeekDayStatus.missed => StreakDayState.missed,
        _ => isToday ? StreakDayState.today : StreakDayState.future,
      };
      // Pending cells show the streak count the user reaches by completing
      // that day — today is current+1, each later day one more again.
      int? number;
      if (state == StreakDayState.today || state == StreakDayState.future) {
        upcomingSoFar++;
        number = currentStreak + upcomingSoFar;
      }
      days.add(StreakDay(_weekdayLabel(day), state, number));
    }
    return StreakWeek(
      DateTime(week.startDate.year, week.startDate.month, week.startDate.day),
      days,
      labelOverride: week.label,
    );
  }

  /// Prefer the server's weekday name; fall back to deriving it from the
  /// date so a payload that omits `weekday` still labels its cells.
  static String _weekdayLabel(wire.StreakWeekDay day) {
    if (day.weekday.isNotEmpty) {
      final w = day.weekday;
      return w.length <= 3
          ? w
          : '${w[0].toUpperCase()}${w.substring(1, 3).toLowerCase()}';
    }
    // DateTime.weekday: 1 = Monday … 7 = Sunday.
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(day.date.weekday - 1) % 7];
  }
}

final streaksProvider = NotifierProvider<StreaksNotifier, StreaksState>(
  StreaksNotifier.new,
);
