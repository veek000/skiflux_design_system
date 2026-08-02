/// Streak state backing the Streaks screen (Figma Streak Flow `3092:14400`).
///
/// [StreaksNotifier.refreshFromBackend] loads `GET /me/streak`. There is no
/// fallback snapshot: the store used to seed four weeks of 2029 demo history
/// and keep it on screen when the request failed, so a user with no streak —
/// or no network — was shown a 7-day run and a "May 20th - 26th" week that
/// had never happened. It now starts empty and loading, and a failed refresh
/// surfaces [StreaksState.error] for the screen to retry from.
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

/// One tracked Sun–Sat week. [start] is the week's Sunday; the label spans
/// the actual 7 tracked days, start through start+6 ("May 20th - 26th").
/// (Figma's sample label is authored as an 8-day `start+7` span — a slip the
/// computed label deliberately does not reproduce; the server's
/// [labelOverride] wins whenever it is present anyway.)
class StreakWeek {
  StreakWeek(this.start, this.days, {this.labelOverride});

  final DateTime start;
  final List<StreakDay> days;

  /// Server-rendered range label from `GET /me/streak`. Preferred over the
  /// computed [label] so client and API never disagree on the wording.
  final String? labelOverride;

  /// Whether this week is the one the API reported as current. Null start
  /// (no week loaded at all) is never "current".
  bool isCurrentFor(DateTime? currentStart) =>
      currentStart != null && sameDay(start, currentStart);

  /// Week-range pill label, e.g. "May 20th - 26th" / "Apr 29th - May 5th".
  String get label {
    final override = labelOverride;
    if (override != null && override.isNotEmpty) return override;
    // Sunday + 6 = Saturday: the last day this tracker actually shows.
    final end = start.add(const Duration(days: 6));
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
    this.error,
  });

  final int streak;
  final int bestStreak;
  final int xpEarned;
  final int milestone;
  final int milestoneXp;
  final List<StreakWeek> history;
  final bool celebrated;

  /// True once `GET /me/streak` has answered. While false there is nothing
  /// real on screen yet — the screen shows a skeleton, an error or an empty
  /// state rather than numbers.
  final bool fromBackend;
  final bool loading;

  /// Why the last refresh failed, if it did. Cleared by a successful load.
  final Object? error;

  /// The week the API reported, or null before it has answered. Nullable on
  /// purpose: `history.last` on an empty list is what forced the demo seed to
  /// exist in the first place.
  StreakWeek? get currentWeek => history.isEmpty ? null : history.last;

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

  /// [clearError] is separate from `error:` because passing null to a
  /// nullable named parameter cannot be told apart from omitting it.
  StreaksState copyWith({
    bool? celebrated,
    bool? loading,
    Object? error,
    bool clearError = false,
  }) {
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
      error: clearError ? null : (error ?? this.error),
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
  @override
  StreaksState build() {
    // Empty and loading. Every figure below is the user's own, or nothing:
    // a streak, a best streak and an XP total are claims about what someone
    // did, and there is no honest placeholder for that.
    return const StreaksState(
      streak: 0,
      bestStreak: 0,
      xpEarned: 0,
      milestone: 0,
      milestoneXp: 0,
      history: [],
      loading: true,
    );
  }

  /// The milestone sheet shows once per session, when the Streaks screen
  /// first opens with the milestone reached.
  bool consumeCelebration() {
    // `milestone` is 0 until the API answers, and `0 < 0` is false — without
    // this guard an empty or failed load would celebrate a streak of zero.
    if (state.milestone <= 0) return false;
    if (state.celebrated || state.streak < state.milestone) return false;
    state = state.copyWith(celebrated: true);
    return true;
  }

  /// Loads `GET /me/streak`.
  ///
  /// A failure records [StreaksState.error] and stops loading. It used to be
  /// swallowed, which left the demo seed on screen — the user then read four
  /// weeks of 2029 history as their own. Nothing is retained now; the screen
  /// shows the failure and a retry.
  Future<void> refreshFromBackend() async {
    // `state.loading` starts true now, so re-entrancy is tracked separately
    // rather than read off the snapshot — otherwise the first call would see
    // its own initial loading flag and return without fetching anything.
    if (_inFlight) return;
    _inFlight = true;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final summary = await ref.read(streaksRepositoryProvider).getStreak();
      state = _fromSummary(summary, celebrated: state.celebrated);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    } finally {
      _inFlight = false;
    }
  }

  bool _inFlight = false;

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
