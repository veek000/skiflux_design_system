/// A creator's public profile — `GET /creators/{creator_id}` (UUID path
/// param), spec schema `PublicCreatorProfile`.
///
/// The schema carries follow state for the authenticated user
/// (`is_following`, `followers_count`), which seeds the Subscribe button
/// before the follow-list provider has answered.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'creators_repository.dart';

class CreatorProfile {
  const CreatorProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.initials,
    this.username = '',
    this.avatarUrl,
    this.bio,
    this.skillworld,
    this.followersCount = 0,
    this.isFollowing = false,
  });

  /// Spec `PublicCreatorProfile` — `{id, username, first_name, last_name,
  /// display_name, avatar_url, bio, skillworld, followers_count,
  /// is_following}`.
  factory CreatorProfile.fromJson(Map<String, dynamic> json) {
    final first = _string(json['first_name']) ?? '';
    final last = _string(json['last_name']) ?? '';
    final username = _string(json['username']) ?? '';
    final display = _string(json['display_name']);
    final full = '$first $last'.trim();
    final name = display ?? (full.isNotEmpty ? full : username);
    var initials = '?';
    if (first.isNotEmpty || last.isNotEmpty) {
      initials = '${first.isNotEmpty ? first[0] : ''}'
              '${last.isNotEmpty ? last[0] : ''}'
          .toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name[0].toUpperCase();
    }
    return CreatorProfile(
      id: json['id']?.toString() ?? '',
      name: name.isEmpty ? 'Creator' : name,
      username: username,
      handle: username.isEmpty ? '' : '@$username',
      initials: initials,
      avatarUrl: _string(json['avatar_url']),
      bio: _string(json['bio']),
      skillworld: _string(json['skillworld']),
      followersCount: json['followers_count'] is int
          ? json['followers_count'] as int
          : 0,
      isFollowing: json['is_following'] == true,
    );
  }

  final String id;
  final String name;
  final String username;
  final String handle;
  final String initials;
  final String? avatarUrl;
  final String? bio;
  final String? skillworld;
  final int followersCount;

  /// Follow state for the signed-in user, straight off the payload.
  final bool isFollowing;
}

/// Keyed by creator UUID. `AsyncNotifierProvider.family` (Riverpod 3.x class
/// API — the arg arrives through the constructor) so the screen gets real
/// loading / error states and a retry that refetches.
final creatorProfileProvider = AsyncNotifierProvider.autoDispose
    .family<CreatorProfileNotifier, CreatorProfile, String>(
      CreatorProfileNotifier.new,
    );

class CreatorProfileNotifier extends AsyncNotifier<CreatorProfile> {
  CreatorProfileNotifier(this.creatorId);

  /// The family argument — the creator UUID from the navigation site.
  final String creatorId;

  @override
  Future<CreatorProfile> build() =>
      ref.read(creatorsRepositoryProvider).getCreator(creatorId);

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(creatorsRepositoryProvider).getCreator(creatorId),
    );
  }
}

String? _string(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
