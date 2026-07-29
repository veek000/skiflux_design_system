// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LeaderboardRow _$LeaderboardRowFromJson(Map<String, dynamic> json) =>
    _LeaderboardRow(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );

Map<String, dynamic> _$LeaderboardRowToJson(_LeaderboardRow instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'username': instance.username,
      'avatar_url': instance.avatarUrl,
      'xp': instance.xp,
      'is_current_user': instance.isCurrentUser,
    };
