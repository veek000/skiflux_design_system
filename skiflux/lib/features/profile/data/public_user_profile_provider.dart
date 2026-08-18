/// Another learner's public profile, from the spec's `PublicUserProfile`.
///
/// The field names here are the schema's, checked against it. An earlier pass
/// guessed `display_name`, `league`, `tasks_done` and `skills` — none of which
/// exist — so each one silently fell through to a demo default that rendered
/// as though it were this person's.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../public_user_profile_screen.dart';
import 'badge_catalogue.dart';
import 'users_repository.dart';

/// Keyed by username (with or without the `@`). Riverpod 3.x family class
/// API — the arg arrives through the constructor — so the screen gets real
/// loading / error states and a retry that refetches.
final publicUserProfileProvider = AsyncNotifierProvider.autoDispose
    .family<PublicUserProfileNotifier, PublicUserProfile, String>(
      PublicUserProfileNotifier.new,
    );

class PublicUserProfileNotifier extends AsyncNotifier<PublicUserProfile> {
  PublicUserProfileNotifier(this.username);

  final String username;

  @override
  Future<PublicUserProfile> build() => _fetch();

  Future<PublicUserProfile> _fetch() async {
    // `GET /users/by-username/{username}` — 404 for deactivated/suspended
    // accounts propagates as an error state, never as invented data.
    final repo = ref.read(usersRepositoryProvider);
    return parsePublicUserProfile(
      await repo.getUserByUsername(username.replaceFirst('@', '')),
    );
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

/// Maps the response onto the screen's model.
///
/// Public so tests can exercise the mapping without Dio.
// TODO(backend, blocking): `earned_badges`, `task_done` and `episode_completed`
// are all typed `string` on PublicUserProfile (untyped SerializerMethodFields)
// — earned_badges needs to be a list so the app can flip its local badge art
// from locked to earned — expects: earned_badges: List<{name: String,
// earned_at: String}>, task_done: int, episode_completed: int
// TODO(backend, blocking): no completed-task list on the public profile, so the
// "Completed Task" section stays empty — expects: GET /users/{id}/completed-tasks
// → List<{kind: 'project'|'assessment', title: String, submitted_at: String,
// file_url: String?, score: int?}>
// TODO(backend, minor): the spec omits `email` by design, but the product wants
// a contactable address here (job-portfolio positioning) — the contact row
// hides itself until one exists — expects: email: String on GET /users/{id}
PublicUserProfile parsePublicUserProfile(Map<String, dynamic> json) {
  // The schema carries `first_name`/`last_name`, never a composed name.
  final first = _string(json['first_name']) ?? '';
  final last = _string(json['last_name']) ?? '';
  final username = _string(json['username']) ?? '';
  final name = '$first $last'.trim();

  return PublicUserProfile(
    // Falling back to the handle keeps a nameless account readable.
    name: name.isNotEmpty ? name : username,
    username: username,
    avatarUrl: _string(json['avatar_url']),
    // `current_level`, not `league`.
    league: _string(json['current_level']),
    xp: _int(json['xp']),
    leaderboardRank: _int(json['rank']),
    // `task_done`, singular.
    tasksDone: _int(json['task_done']),
    // No skills array exists; `skillworld` is the learner's declared domain and
    // is what the Skills chips render — see the minor TODO above.
    skills: _stringList(json['skillworld']),
    badges: badgeItemsFor(_badgeNames(json['earned_badges'])),
    email: _string(json['email']),
  );
}

/// Names of the badges this learner has earned, however the payload carries
/// them: a list of badge objects, a list of names, or a joined string.
List<String> _badgeNames(Object? raw) {
  if (raw is! List) return _stringList(raw);
  return [
    for (final entry in raw)
      if (entry is Map)
        _string(entry['name']) ??
            _string(entry['badge'] is Map ? entry['badge']['name'] : null) ??
            ''
      else
        _string(entry) ?? '',
  ].where((name) => name.isNotEmpty).toList();
}

/// A list, a single string, or a comma-joined string, as a list.
List<String> _stringList(Object? raw) {
  if (raw is List) {
    return [for (final entry in raw) ?_string(entry)];
  }
  final single = _string(raw);
  if (single == null) return const [];
  return single
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

String? _string(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// `task_done` and `episode_completed` are typed as strings in the schema, so a
/// count can arrive either way.
int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
