import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'users_repository.dart';
import '../public_user_profile_screen.dart';

final publicUserProfileProvider = FutureProvider.autoDispose.family<PublicUserProfile, String>((ref, username) async {
  final repo = ref.read(usersRepositoryProvider);
  final json = await repo.getUserByUsername(username);
  
  return PublicUserProfile(
    name: (json['display_name'] as String?) ?? (json['username'] as String?) ?? '',
    username: (json['username'] as String?) ?? '',
    league: (json['league'] as String?) ?? 'Novice',
    xp: (json['xp'] as int?) ?? 350,
    leaderboardRank: (json['rank'] as int?) ?? 12,
    tasksDone: (json['tasks_done'] as int?) ?? 8,
    email: 'hidden', // Public profile doesn't expose email
    skills: (json['skills'] as List?)?.cast<String>() ?? const [],
  );
});
