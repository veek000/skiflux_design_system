/// Demo streak state backing the Streaks screen (Figma Streak Flow
/// `3092:14400`). Static in-memory only — no persistence/backend yet,
/// mirroring the other feature stores.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  StreakWeek(this.start, this.days) : assert(days.length == 7);

  final DateTime start;
  final List<StreakDay> days;

  /// Whether this week is the demo "current" week ([currentStart]).
  bool isCurrentFor(DateTime currentStart) => sameDay(start, currentStart);

  /// Figma pill label, e.g. "May 20th - 27th" / "Apr 29th - May 6th".
  String get label {
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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

/// Immutable snapshot of streak demo data + session celebration flag.
class StreaksState {
  const StreaksState({
    required this.streak,
    required this.bestStreak,
    required this.xpEarned,
    required this.milestone,
    required this.milestoneXp,
    required this.history,
    this.celebrated = false,
  });

  final int streak;
  final int bestStreak;
  final int xpEarned;
  final int milestone;
  final int milestoneXp;
  final List<StreakWeek> history;
  final bool celebrated;

  StreakWeek get currentWeek => history.last;

  /// The tracked week whose Sun–Sat range contains [day], if any.
  StreakWeek? weekContaining(DateTime day) {
    for (final week in history) {
      final delta = DateTime(day.year, day.month, day.day)
          .difference(week.start)
          .inDays;
      if (delta >= 0 && delta < 7) return week;
    }
    return null;
  }

  StreaksState copyWith({bool? celebrated}) {
    return StreaksState(
      streak: streak,
      bestStreak: bestStreak,
      xpEarned: xpEarned,
      milestone: milestone,
      milestoneXp: milestoneXp,
      history: history,
      celebrated: celebrated ?? this.celebrated,
    );
  }
}

/// Riverpod choice: [NotifierProvider] — stats/history are static demo
/// data, but [consumeCelebration] mutates a once-per-session flag (was
/// static `_celebrated`). Plain Provider cannot own that mutation.
// TODO(backend, blocking): replace static streak stats and history with real per-user streak data fetched from backend — expects: {streak: int, bestStreak: int, xpEarned: int, milestone: int, milestoneXp: int, history: List<{start: DateTime, days: List<{label: String, state: StreakDayState, number: int?}>}>}
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
}

final streaksProvider = NotifierProvider<StreaksNotifier, StreaksState>(
  StreaksNotifier.new,
);
