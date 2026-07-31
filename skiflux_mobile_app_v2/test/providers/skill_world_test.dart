import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/models/user_profile.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/profile_repository.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/profile_store.dart';
import 'package:skiflux_mobile_app_v2/features/profile/data/skill_world_store.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';
import 'package:skiflux_mobile_app_v2/shared/network/token_store.dart';

void main() {
  group('SkillWorldsRepository.parseSkillWorlds', () {
    test('reads a bare array of strings', () {
      expect(
        SkillWorldsRepository.parseSkillWorlds(['design', 'ai']),
        ['design', 'ai'],
      );
    });

    test('reads a {data: [...]} envelope', () {
      expect(
        SkillWorldsRepository.parseSkillWorlds({
          'data': ['crypto', 'health'],
        }),
        ['crypto', 'health'],
      );
    });

    test('reads value/label maps and normalises case', () {
      expect(
        SkillWorldsRepository.parseSkillWorlds([
          {'value': 'Design', 'label': 'Design'},
          {'slug': 'AI'},
          {'name': 'crypto'},
        ]),
        ['design', 'ai', 'crypto'],
      );
    });

    test('drops duplicates and blanks; unknown shapes yield empty', () {
      expect(
        SkillWorldsRepository.parseSkillWorlds(['design', 'design', '  ']),
        ['design'],
      );
      expect(SkillWorldsRepository.parseSkillWorlds('nope'), isEmpty);
      expect(SkillWorldsRepository.parseSkillWorlds(null), isEmpty);
    });
  });

  group('SkillWorld.fromBackendValue', () {
    test('maps every authored world by its wire name', () {
      for (final world in SkillWorld.values) {
        expect(SkillWorld.fromBackendValue(world.backendValue), world);
      }
    });

    test('spec values with no authored art resolve to null', () {
      // The spec's UserSkillworldEnum also contains these two.
      expect(SkillWorld.fromBackendValue('code'), isNull);
      expect(SkillWorld.fromBackendValue('writing'), isNull);
      expect(SkillWorld.fromBackendValue(null), isNull);
    });
  });

  group('skillWorldOptionsProvider', () {
    ProviderContainer withWorlds(_FakeSkillWorldsRepository repo) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [skillWorldsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('offers only the worlds the backend lists', () async {
      final c = withWorlds(
        _FakeSkillWorldsRepository(['design', 'ai', 'crypto']),
      );
      expect(await c.read(skillWorldOptionsProvider.future), [
        SkillWorld.design,
        SkillWorld.crypto,
        SkillWorld.ai,
      ]);
    });

    test('backend worlds without enum art are dropped, not crashed on',
        () async {
      final c = withWorlds(
        _FakeSkillWorldsRepository(['design', 'code', 'writing']),
      );
      expect(await c.read(skillWorldOptionsProvider.future), [
        SkillWorld.design,
      ]);
    });

    test('a failed or empty fetch falls back to the full enum', () async {
      expect(
        await withWorlds(_FakeSkillWorldsRepository(null))
            .read(skillWorldOptionsProvider.future),
        SkillWorld.values,
      );
      expect(
        await withWorlds(_FakeSkillWorldsRepository(const []))
            .read(skillWorldOptionsProvider.future),
        SkillWorld.values,
      );
    });
  });

  group('skillWorldProvider', () {
    ProviderContainer build({
      UserProfile? profile,
      _FakeProfileRepository? repo,
      bool signedIn = true,
    }) {
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          meProfileProvider.overrideWith(() => _FakeMeProfile(profile)),
          profileRepositoryProvider.overrideWithValue(
            repo ?? _FakeProfileRepository(),
          ),
          tokenStoreProvider.overrideWithValue(_FakeTokenStore(signedIn)),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('defaults to Design when signed out', () async {
      final c = build(profile: null, signedIn: false);
      await c.read(meProfileProvider.future);
      expect(c.read(skillWorldProvider), SkillWorld.design);
    });

    test('hydrates from the profile skillworld', () async {
      final c = build(
        profile: const UserProfile(id: 'u1', skillworld: ['crypto']),
      );
      await c.read(meProfileProvider.future);
      expect(c.read(skillWorldProvider), SkillWorld.crypto);
    });

    test('an unrepresentable profile value keeps the default', () async {
      final c = build(
        profile: const UserProfile(id: 'u1', skillworld: ['writing']),
      );
      await c.read(meProfileProvider.future);
      expect(c.read(skillWorldProvider), SkillWorld.design);
    });

    test('selectAndPersist PATCHes the profile with the wire value', () async {
      final repo = _FakeProfileRepository();
      final c = build(
        profile: const UserProfile(id: 'u1', skillworld: ['design']),
        repo: repo,
      );
      await c.read(meProfileProvider.future);

      await c.read(skillWorldProvider.notifier).selectAndPersist(
            SkillWorld.ai,
          );

      expect(c.read(skillWorldProvider), SkillWorld.ai);
      expect(repo.savedSkillworlds, [
        ['ai'],
      ]);
    });

    test('a failed persist rolls the selection back and rethrows', () async {
      final repo = _FakeProfileRepository(fail: true);
      final c = build(
        profile: const UserProfile(id: 'u1', skillworld: ['design']),
        repo: repo,
      );
      await c.read(meProfileProvider.future);

      await expectLater(
        c.read(skillWorldProvider.notifier).selectAndPersist(SkillWorld.ai),
        throwsA(isA<SkifluxFailure>()),
      );
      expect(c.read(skillWorldProvider), SkillWorld.design);
    });

    test('signed out selection stays local and never calls the API',
        () async {
      final repo = _FakeProfileRepository();
      final c = build(profile: null, repo: repo, signedIn: false);
      await c.read(meProfileProvider.future);

      await c.read(skillWorldProvider.notifier).selectAndPersist(
            SkillWorld.health,
          );

      expect(c.read(skillWorldProvider), SkillWorld.health);
      expect(repo.savedSkillworlds, isEmpty);
    });

    test('re-selecting the current world is a no-op', () async {
      final repo = _FakeProfileRepository();
      final c = build(
        profile: const UserProfile(id: 'u1', skillworld: ['design']),
        repo: repo,
      );
      await c.read(meProfileProvider.future);

      await c.read(skillWorldProvider.notifier).selectAndPersist(
            SkillWorld.design,
          );
      expect(repo.savedSkillworlds, isEmpty);
    });
  });
}

class _FakeMeProfile extends MeProfileNotifier {
  _FakeMeProfile(this.profile);

  final UserProfile? profile;

  @override
  Future<UserProfile?> build() async => profile;
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository({this.fail = false}) : super(Dio());

  final bool fail;
  final List<List<String>?> savedSkillworlds = [];

  @override
  Future<UserProfile?> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    String? country,
    String? phone,
    List<String>? skillworld,
    List<String>? goal,
    String? avatarPath,
  }) async {
    if (fail) {
      throw const SkifluxFailure(SkifluxErrorKind.contentLoadFailed);
    }
    savedSkillworlds.add(skillworld);
    return null;
  }
}

/// Returns [worlds], or throws when they are null (the offline path).
class _FakeSkillWorldsRepository extends SkillWorldsRepository {
  _FakeSkillWorldsRepository(this.worlds) : super(Dio());

  final List<String>? worlds;

  @override
  Future<List<String>> list() async {
    final value = worlds;
    if (value == null) throw Exception('offline');
    return value;
  }
}

/// Presence-only session gate, with no platform channel behind it.
class _FakeTokenStore extends TokenStore {
  _FakeTokenStore(this.signedIn) : super(const FlutterSecureStorage());

  final bool signedIn;

  @override
  Future<bool> hasSession() async => signedIn;
}
