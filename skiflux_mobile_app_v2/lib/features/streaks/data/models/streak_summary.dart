import 'package:freezed_annotation/freezed_annotation.dart';

part 'streak_summary.freezed.dart';
part 'streak_summary.g.dart';

/// `GET /me/streak` — OpenAPI `StreakSummary`.
///
/// Names mirror the spec's schemas rather than the UI's vocabulary; the
/// adapter into [StreaksState] lives in `streaks_store.dart`. Import this
/// library with a prefix — [StreakWeek] here is the wire payload and collides
/// with the UI class of the same name.
@freezed
abstract class StreakSummary with _$StreakSummary {
  const factory StreakSummary({
    required int currentStreakCount,
    required bool isStreakActive,
    required int bestStreak,
    required int totalStreakXpEarned,
    required StreakWeek week,
    required StreakMilestone milestone,
  }) = _StreakSummary;

  factory StreakSummary.fromJson(Map<String, dynamic> json) =>
      _$StreakSummaryFromJson(json);
}

/// The single Sun–Sat window the API reports on. Multi-week history is not
/// yet exposed (tracker Tier 4), so the week picker has exactly one entry
/// once real data is in — no invented past weeks.
@freezed
abstract class StreakWeek with _$StreakWeek {
  const factory StreakWeek({
    required DateTime startDate,
    required DateTime endDate,

    /// Server-rendered range label ("May 20th - 27th"). Preferred over the
    /// client's own formatting so the two never disagree.
    required String label,
    required List<StreakWeekDay> days,
  }) = _StreakWeek;

  factory StreakWeek.fromJson(Map<String, dynamic> json) =>
      _$StreakWeekFromJson(json);
}

@freezed
abstract class StreakWeekDay with _$StreakWeekDay {
  const factory StreakWeekDay({
    /// Short weekday name ("Sun" … "Sat").
    @Default('') String weekday,
    required DateTime date,
    @Default(0) int dayOfMonth,
    @Default(StreakWeekDayStatus.upcoming) StreakWeekDayStatus status,
  }) = _StreakWeekDay;

  factory StreakWeekDay.fromJson(Map<String, dynamic> json) =>
      _$StreakWeekDayFromJson(json);
}

/// `StreakWeekDayStatusEnum`. The API has no separate "today" — the UI
/// derives it by comparing [StreakWeekDay.date] against the current date.
@JsonEnum(fieldRename: FieldRename.snake)
enum StreakWeekDayStatus {
  completed,
  missed,
  upcoming,

  /// Forward-compatibility: an unrecognised status renders as upcoming
  /// rather than throwing mid-list.
  @JsonValue('unknown')
  unknown,
}

@freezed
abstract class StreakMilestone with _$StreakMilestone {
  const factory StreakMilestone({
    /// Streak length that earns the reward (7 = a weekly milestone).
    required int intervalDays,
    required int xpReward,
    required int nextAtStreak,
    required int daysRemaining,
    required bool reachedToday,
  }) = _StreakMilestone;

  factory StreakMilestone.fromJson(Map<String, dynamic> json) =>
      _$StreakMilestoneFromJson(json);
}
