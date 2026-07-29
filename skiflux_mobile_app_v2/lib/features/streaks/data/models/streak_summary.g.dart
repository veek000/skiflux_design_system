// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StreakSummary _$StreakSummaryFromJson(Map<String, dynamic> json) =>
    _StreakSummary(
      currentStreakCount: (json['current_streak_count'] as num).toInt(),
      isStreakActive: json['is_streak_active'] as bool,
      bestStreak: (json['best_streak'] as num).toInt(),
      totalStreakXpEarned: (json['total_streak_xp_earned'] as num).toInt(),
      week: StreakWeek.fromJson(json['week'] as Map<String, dynamic>),
      milestone: StreakMilestone.fromJson(
        json['milestone'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$StreakSummaryToJson(_StreakSummary instance) =>
    <String, dynamic>{
      'current_streak_count': instance.currentStreakCount,
      'is_streak_active': instance.isStreakActive,
      'best_streak': instance.bestStreak,
      'total_streak_xp_earned': instance.totalStreakXpEarned,
      'week': instance.week.toJson(),
      'milestone': instance.milestone.toJson(),
    };

_StreakWeek _$StreakWeekFromJson(Map<String, dynamic> json) => _StreakWeek(
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  label: json['label'] as String,
  days: (json['days'] as List<dynamic>)
      .map((e) => StreakWeekDay.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$StreakWeekToJson(_StreakWeek instance) =>
    <String, dynamic>{
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'label': instance.label,
      'days': instance.days.map((e) => e.toJson()).toList(),
    };

_StreakWeekDay _$StreakWeekDayFromJson(Map<String, dynamic> json) =>
    _StreakWeekDay(
      weekday: json['weekday'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      dayOfMonth: (json['day_of_month'] as num?)?.toInt() ?? 0,
      status:
          $enumDecodeNullable(_$StreakWeekDayStatusEnumMap, json['status']) ??
          StreakWeekDayStatus.upcoming,
    );

Map<String, dynamic> _$StreakWeekDayToJson(_StreakWeekDay instance) =>
    <String, dynamic>{
      'weekday': instance.weekday,
      'date': instance.date.toIso8601String(),
      'day_of_month': instance.dayOfMonth,
      'status': _$StreakWeekDayStatusEnumMap[instance.status]!,
    };

const _$StreakWeekDayStatusEnumMap = {
  StreakWeekDayStatus.completed: 'completed',
  StreakWeekDayStatus.missed: 'missed',
  StreakWeekDayStatus.upcoming: 'upcoming',
  StreakWeekDayStatus.unknown: 'unknown',
};

_StreakMilestone _$StreakMilestoneFromJson(Map<String, dynamic> json) =>
    _StreakMilestone(
      intervalDays: (json['interval_days'] as num).toInt(),
      xpReward: (json['xp_reward'] as num).toInt(),
      nextAtStreak: (json['next_at_streak'] as num).toInt(),
      daysRemaining: (json['days_remaining'] as num).toInt(),
      reachedToday: json['reached_today'] as bool,
    );

Map<String, dynamic> _$StreakMilestoneToJson(_StreakMilestone instance) =>
    <String, dynamic>{
      'interval_days': instance.intervalDays,
      'xp_reward': instance.xpReward,
      'next_at_streak': instance.nextAtStreak,
      'days_remaining': instance.daysRemaining,
      'reached_today': instance.reachedToday,
    };
