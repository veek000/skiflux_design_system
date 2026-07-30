library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

/// Data model for a badge definition from the API.
class Badge {
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    this.isActive = true,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        iconUrl: json['icon_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final bool isActive;
}

/// A badge earned by the authenticated user — wraps the [Badge] definition
/// with the timestamp it was awarded.
class UserBadge {
  const UserBadge({
    required this.id,
    required this.badge,
    required this.earnedAt,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) => UserBadge(
        id: json['id'] as String,
        badge: Badge.fromJson(json['badge'] as Map<String, dynamic>),
        earnedAt: DateTime.parse(json['earned_at'] as String),
      );

  final String id;
  final Badge badge;
  final DateTime earnedAt;
}

class BadgesRepository extends ApiRepository {
  const BadgesRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  /// `GET /api/v1/profile/me/badges` — returns all badges earned by the user.
  Future<List<UserBadge>> getMyBadges() => getList(
        '/profile/me/badges',
        parse: UserBadge.fromJson,
      );
}

final badgesRepositoryProvider = Provider<BadgesRepository>(
  (ref) => BadgesRepository(ref.watch(apiClientProvider)),
);

/// Async provider that exposes the user's earned badge list.
final userBadgesProvider = FutureProvider<List<UserBadge>>((ref) {
  return ref.watch(badgesRepositoryProvider).getMyBadges();
});
