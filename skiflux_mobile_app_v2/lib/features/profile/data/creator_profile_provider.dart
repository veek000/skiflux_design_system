import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'creators_repository.dart';

class CreatorProfile {
  const CreatorProfile({
    required this.name,
    required this.handle,
    required this.initials,
  });

  final String name;
  final String handle;
  final String initials;
}

final creatorProfileProvider = FutureProvider.autoDispose.family<CreatorProfile, String>((ref, creatorId) async {
  final repo = ref.read(creatorsRepositoryProvider);
  final json = await repo.getCreator(creatorId);
  
  final name = (json['display_name'] as String?) ?? (json['username'] as String?) ?? '';
  return CreatorProfile(
    name: name,
    handle: '@${json['username'] ?? 'unknown'}',
    initials: name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
  );
});
