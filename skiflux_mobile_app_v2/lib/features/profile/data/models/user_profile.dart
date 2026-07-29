import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/data/decimal_converter.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// `GET /me/profile` / `PATCH /me/update` — OpenAPI `UserProfile` (path op
/// is description-only; this matches the components schema).
///
/// Money: `balance` / `bonus_balance` are decimal **strings**.
@freezed
abstract class UserProfile with _$UserProfile {
  const UserProfile._();

  const factory UserProfile({
    required String id,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String email,
    @Default('') String username,
    @Default('') String bio,
    @Default('') String country,
    @Default('') String phone,
    String? avatarUrl,
    @Default([]) List<String> goal,
    @Default([]) List<String> skillworld,
    @Default('') String status,
    @DecimalConverter() Decimal? balance,
    @DecimalConverter() Decimal? bonusBalance,
    @Default(0) int xp,
    @Default('') String currentLevel,
    @Default(0) int streakCount,
    int? rank,
    @Default(0) int taskDone,
    @Default(0) int episodeCompleted,
    @Default(false) bool biometricsEnabled,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  String get displayName {
    final full = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (full.isNotEmpty) return full;
    if (username.isNotEmpty) return username;
    return email;
  }

  String get handle =>
      username.isEmpty ? '' : (username.startsWith('@') ? username : '@$username');

  String get initials {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isNotEmpty && l.isNotEmpty) {
      return '${f[0]}${l[0]}'.toUpperCase();
    }
    if (f.isNotEmpty) return f[0].toUpperCase();
    if (username.isNotEmpty) {
      return username.replaceFirst('@', '').substring(0, 1).toUpperCase();
    }
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  String get xpLabel {
    final digits = xp.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  String get rankLabel {
    if (rank == null) return currentLevel.isEmpty ? '—' : currentLevel;
    final level = currentLevel.isEmpty ? '' : ' in $currentLevel';
    return '#$rank$level';
  }
}
