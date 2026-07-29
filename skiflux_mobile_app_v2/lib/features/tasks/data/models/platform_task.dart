import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/data/decimal_converter.dart';

part 'platform_task.freezed.dart';
part 'platform_task.g.dart';

/// Lifecycle per platform-tasks.md §1: not_started → in_progress → claimable
/// → claimed. Rewards are granted on claim only, never when the underlying
/// action happens.
enum PlatformTaskStatus {
  @JsonValue('not_started')
  notStarted,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('claimable')
  claimable,
  @JsonValue('claimed')
  claimed,
}

/// One entry of `GET /me/platform-tasks` — exact field match to the list
/// response shape quoted in platform-tasks.md §4.
@freezed
abstract class PlatformTask with _$PlatformTask {
  const factory PlatformTask({
    required String id,
    required String slug,
    required String title,
    required String description,
    required String category,

    /// Empty string = manual task (user submits, then claims).
    required String triggerType,

    /// Legacy write alias of [triggerType]; the list response returns both.
    required String actionType,
    required String verificationMode,
    required int progressTarget,
    required int progressCurrent,
    required String icon,
    required Map<String, dynamic> metadata,
    required int sortOrder,
    required int xpReward,
    @DecimalConverter() required Decimal skillcoinReward,
    required PlatformTaskStatus status,
    required bool claimable,
    required bool completed,

    /// Required in the spec's PlatformTaskUser response but absent from the
    /// platform-tasks.md example payload — defaulted true (a task returned in
    /// the user's list is live) so both shapes parse.
    @Default(true) bool isActive,

    /// Flash-challenge timer, frontend-enforced — server-side expiry is not
    /// implemented yet per the doc.
    int? durationMinutes,
    String? externalUrl,
    DateTime? startedAt,
    DateTime? claimableAt,
    DateTime? claimedAt,
    DateTime? completedAt,
  }) = _PlatformTask;

  factory PlatformTask.fromJson(Map<String, dynamic> json) =>
      _$PlatformTaskFromJson(json);
}
