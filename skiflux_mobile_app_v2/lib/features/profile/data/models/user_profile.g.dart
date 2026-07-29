// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  id: json['id'] as String,
  firstName: json['first_name'] as String? ?? '',
  lastName: json['last_name'] as String? ?? '',
  email: json['email'] as String? ?? '',
  username: json['username'] as String? ?? '',
  bio: json['bio'] as String? ?? '',
  country: json['country'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  avatarUrl: json['avatar_url'] as String?,
  goal:
      (json['goal'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  skillworld:
      (json['skillworld'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  status: json['status'] as String? ?? '',
  balance: _$JsonConverterFromJson<String, Decimal>(
    json['balance'],
    const DecimalConverter().fromJson,
  ),
  bonusBalance: _$JsonConverterFromJson<String, Decimal>(
    json['bonus_balance'],
    const DecimalConverter().fromJson,
  ),
  xp: (json['xp'] as num?)?.toInt() ?? 0,
  currentLevel: json['current_level'] as String? ?? '',
  streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
  rank: (json['rank'] as num?)?.toInt(),
  taskDone: (json['task_done'] as num?)?.toInt() ?? 0,
  episodeCompleted: (json['episode_completed'] as num?)?.toInt() ?? 0,
  biometricsEnabled: json['biometrics_enabled'] as bool? ?? false,
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'username': instance.username,
      'bio': instance.bio,
      'country': instance.country,
      'phone': instance.phone,
      'avatar_url': instance.avatarUrl,
      'goal': instance.goal,
      'skillworld': instance.skillworld,
      'status': instance.status,
      'balance': _$JsonConverterToJson<String, Decimal>(
        instance.balance,
        const DecimalConverter().toJson,
      ),
      'bonus_balance': _$JsonConverterToJson<String, Decimal>(
        instance.bonusBalance,
        const DecimalConverter().toJson,
      ),
      'xp': instance.xp,
      'current_level': instance.currentLevel,
      'streak_count': instance.streakCount,
      'rank': instance.rank,
      'task_done': instance.taskDone,
      'episode_completed': instance.episodeCompleted,
      'biometrics_enabled': instance.biometricsEnabled,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
