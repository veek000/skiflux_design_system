library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

/// Data model for a badge definition from the API.
///
/// Parsing is deliberately tolerant: the spec says `id` is a UUID string and
/// `earned_at` a date-time, but a backend that sends an integer id or omits a
/// timestamp must degrade to a badge that still renders — not a [TypeError]
/// that takes the whole screen down.
class Badge {
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    this.isActive = true,
  });

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
        // Int-or-string tolerated; the id is only ever an opaque key.
        id: switch (json['id']) {
          final String id => id,
          final int id => '$id',
          _ => '',
        },
        name: json['name'] as String? ?? '',
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
    this.earnedAt,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    final badge = json['badge'];
    return UserBadge(
      id: switch (json['id']) {
        final String id => id,
        final int id => '$id',
        _ => '',
      },
      badge: Badge.fromJson(
        badge is Map<String, dynamic>
            ? badge
            : badge is Map
                ? Map<String, dynamic>.from(badge)
                : const {},
      ),
      // Presence in the response is what "earned" means; a missing or
      // malformed timestamp must not unearn the badge.
      earnedAt: DateTime.tryParse(json['earned_at'] as String? ?? ''),
    );
  }

  final String id;
  final Badge badge;

  /// When the award happened — null when the backend omitted it.
  final DateTime? earnedAt;
}

class BadgesRepository extends ApiRepository {
  const BadgesRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  /// `GET /me/badges` — every badge this learner has been awarded.
  ///
  /// Presence in this list *is* the award; each entry carries its own
  /// `earned_at`. Do not filter on `Badge.is_active`, which is the platform's
  /// enable flag — see `badge_catalogue.dart`.
  ///
  /// `/me/*`, not `/profile/me/*`: the latter is a legacy alias kept for the
  /// web client, and mobile is documented as calling `/me/*` only.
  Future<List<UserBadge>> getMyBadges() =>
      getList('/me/badges', parse: UserBadge.fromJson);
}

final badgesRepositoryProvider = Provider<BadgesRepository>(
  (ref) => BadgesRepository(ref.watch(apiClientProvider)),
);

/// Async provider that exposes the user's earned badge list.
final userBadgesProvider = FutureProvider<List<UserBadge>>((ref) {
  return ref.watch(badgesRepositoryProvider).getMyBadges();
});
