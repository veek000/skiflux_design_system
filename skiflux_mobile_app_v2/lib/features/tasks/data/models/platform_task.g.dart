// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlatformTask _$PlatformTaskFromJson(Map<String, dynamic> json) =>
    _PlatformTask(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      triggerType: json['trigger_type'] as String,
      actionType: json['action_type'] as String,
      verificationMode: json['verification_mode'] as String,
      progressTarget: (json['progress_target'] as num).toInt(),
      progressCurrent: (json['progress_current'] as num).toInt(),
      icon: json['icon'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
      sortOrder: (json['sort_order'] as num).toInt(),
      xpReward: (json['xp_reward'] as num).toInt(),
      skillcoinReward: const DecimalConverter().fromJson(
        json['skillcoin_reward'] as String,
      ),
      status: $enumDecode(_$PlatformTaskStatusEnumMap, json['status']),
      claimable: json['claimable'] as bool,
      completed: json['completed'] as bool,
      isActive: json['is_active'] as bool? ?? true,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      externalUrl: json['external_url'] as String?,
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      claimableAt: json['claimable_at'] == null
          ? null
          : DateTime.parse(json['claimable_at'] as String),
      claimedAt: json['claimed_at'] == null
          ? null
          : DateTime.parse(json['claimed_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$PlatformTaskToJson(
  _PlatformTask instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'title': instance.title,
  'description': instance.description,
  'category': instance.category,
  'trigger_type': instance.triggerType,
  'action_type': instance.actionType,
  'verification_mode': instance.verificationMode,
  'progress_target': instance.progressTarget,
  'progress_current': instance.progressCurrent,
  'icon': instance.icon,
  'metadata': instance.metadata,
  'sort_order': instance.sortOrder,
  'xp_reward': instance.xpReward,
  'skillcoin_reward': const DecimalConverter().toJson(instance.skillcoinReward),
  'status': _$PlatformTaskStatusEnumMap[instance.status]!,
  'claimable': instance.claimable,
  'completed': instance.completed,
  'is_active': instance.isActive,
  'duration_minutes': instance.durationMinutes,
  'external_url': instance.externalUrl,
  'started_at': instance.startedAt?.toIso8601String(),
  'claimable_at': instance.claimableAt?.toIso8601String(),
  'claimed_at': instance.claimedAt?.toIso8601String(),
  'completed_at': instance.completedAt?.toIso8601String(),
};

const _$PlatformTaskStatusEnumMap = {
  PlatformTaskStatus.notStarted: 'not_started',
  PlatformTaskStatus.inProgress: 'in_progress',
  PlatformTaskStatus.claimable: 'claimable',
  PlatformTaskStatus.claimed: 'claimed',
};
