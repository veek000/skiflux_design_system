/// Demo streak state backing the Streaks screen (Figma Streak Flow
/// `3092:14400`). Static in-memory only — no persistence/backend yet,
/// mirroring [SubscriptionsStore].
library;

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

  bool get isCurrent => sameDay(start, StreaksStore.currentWeek.start);

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

/// Static demo store — streak 7 matches Figma Streak Screen 03/04 so the
/// 7-day milestone celebration is reachable.
abstract final class StreaksStore {
  static const int streak = 7;
  static const int bestStreak = 14;
  static const int xpEarned = 240;

  /// Milestone celebrated by the sheet on Streak Screen 04.
  static const int milestone = 7;
  static const int milestoneXp = 50;

  static const _completed = StreakDayState.completed;
  static const _missed = StreakDayState.missed;

  /// Four weeks of demo history, newest last (= the current week). Year
  /// 2029 puts May 20 on a Sunday, matching the Figma "May 20th - 27th"
  /// label against the Sun-first tracker. Current week: Sun–Fri
  /// completed, Sat ahead. (Figma screen 03's Sat cell reads "5" — an
  /// authoring slip; the real next streak number after 7 is 8.) The
  /// May 13 week ends completed so today's streak of 7 adds up
  /// (Sat + Sun–Fri).
  static final List<StreakWeek> history = [
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
  ];

  static StreakWeek get currentWeek => history.last;

  /// The tracked week whose Sun–Sat range contains [day], if any.
  static StreakWeek? weekContaining(DateTime day) {
    for (final week in history) {
      final delta = DateTime(day.year, day.month, day.day)
          .difference(week.start)
          .inDays;
      if (delta >= 0 && delta < 7) return week;
    }
    return null;
  }

  /// The milestone sheet shows once per session, when the Streaks screen
  /// first opens with the milestone reached.
  static bool _celebrated = false;

  static bool consumeCelebration() {
    if (_celebrated || streak < milestone) return false;
    _celebrated = true;
    return true;
  }
}
