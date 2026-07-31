/// Notification preferences: the seven switches are backend state, not
/// device state — `GET /me/notification-preferences` hydrates them, and each
/// flip is an optimistic `PATCH .../update` that rolls back on rejection.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skiflux_mobile_app_v2/features/settings/data/notification_prefs_repository.dart';
import 'package:skiflux_mobile_app_v2/features/settings/data/settings_store.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';
import 'package:skiflux_mobile_app_v2/shared/network/auth_tokens.dart';
import 'package:skiflux_mobile_app_v2/shared/network/token_store.dart';

/// In-memory keychain — flutter_secure_storage has no implementation under
/// `flutter test`.
class _FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> received = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    received.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, String body) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// Fakes the repository at the seam the notifier talks to.
class _FakePrefsRepository extends NotificationPrefsRepository {
  _FakePrefsRepository({
    this.remote = const {},
    this.getFailure,
    this.patchFailure,
  }) : super(Dio());

  final Map<String, bool> remote;
  final SkifluxFailure? getFailure;
  final SkifluxFailure? patchFailure;
  final List<({String field, bool value})> patches = [];
  var getCalls = 0;

  @override
  Future<Map<String, bool>> getPreferences() async {
    getCalls++;
    final f = getFailure;
    if (f != null) throw f;
    return remote;
  }

  @override
  Future<void> updatePreference({
    required String field,
    required bool value,
  }) async {
    final f = patchFailure;
    if (f != null) throw f;
    patches.add((field: field, value: value));
  }
}

/// A container over [repo] with an in-memory keychain — signed out until the
/// test seeds a session via `seedSession`.
ProviderContainer _container(_FakePrefsRepository repo) {
  final c = ProviderContainer(
    overrides: [
      notificationPrefsRepositoryProvider.overrideWithValue(repo),
      tokenStoreProvider.overrideWithValue(TokenStore(_FakeSecureStorage())),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  Future<TokenStore> seedSession(ProviderContainer c) async {
    final store = c.read(tokenStoreProvider);
    await store.write(const AuthTokens(access: 'acc', refresh: 'ref'));
    return store;
  }

  group('NotificationPref wire names', () {
    test('match the OpenAPI NotificationPreferences fields exactly', () {
      expect(NotificationPref.values.map((p) => p.wireName), [
        'new_episodes',
        'task_updates',
        'comment_replies',
        'comment_likes',
        'coin_earnings',
        'badges',
        'platform_announcements',
      ]);
    });
  });

  group('NotificationPrefsRepository', () {
    ({NotificationPrefsRepository repo, _StubAdapter adapter}) build(
      Future<ResponseBody> Function(RequestOptions options) handler,
    ) {
      final adapter = _StubAdapter(handler);
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.test/api/v1',
          contentType: Headers.jsonContentType,
          validateStatus: (s) => s != null && s >= 200 && s < 300,
        ),
      )..httpClientAdapter = adapter;
      return (repo: NotificationPrefsRepository(dio), adapter: adapter);
    }

    test('GET parses the seven booleans and drops updated_at', () async {
      final env = build(
        (_) async => _json(200, '''
          {"new_episodes": true, "task_updates": false,
           "comment_replies": true, "comment_likes": false,
           "coin_earnings": true, "badges": false,
           "platform_announcements": true,
           "updated_at": "2026-07-30T10:00:00Z"}'''),
      );

      final prefs = await env.repo.getPreferences();

      expect(env.adapter.received.single.path, '/me/notification-preferences');
      expect(env.adapter.received.single.method, 'GET');
      expect(prefs, {
        'new_episodes': true,
        'task_updates': false,
        'comment_replies': true,
        'comment_likes': false,
        'coin_earnings': true,
        'badges': false,
        'platform_announcements': true,
      });
    });

    test('update PATCHes only the changed field to the update path', () async {
      final env = build((_) async => _json(200, '{"badges": true}'));

      await env.repo.updatePreference(field: 'badges', value: true);

      final request = env.adapter.received.single;
      expect(request.path, '/me/notification-preferences/update');
      expect(request.method, 'PATCH');
      final body = request.data is String
          ? jsonDecode(request.data as String)
          : request.data;
      expect(body, {'badges': true});
    });

    test('a rejected PATCH surfaces as the settings-save toast kind', () async {
      final env = build((_) async => _json(500, '{}'));

      await expectLater(
        env.repo.updatePreference(field: 'badges', value: true),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.settingsSaveFailed,
          ),
        ),
      );
    });
  });

  group('SettingsNotifier.syncNotificationPrefs', () {
    test('pulls the backend answer into state', () async {
      final repo = _FakePrefsRepository(remote: {
        'new_episodes': false,
        'task_updates': true,
        'comment_replies': true,
        'comment_likes': true,
        'coin_earnings': false,
        'badges': true,
        'platform_announcements': false,
      });
      final c = _container(repo);
      await seedSession(c);

      await c.read(settingsProvider.notifier).syncNotificationPrefs();

      final prefs = c.read(settingsProvider).notifications;
      expect(repo.getCalls, 1);
      expect(prefs[NotificationPref.newEpisodes], isFalse);
      expect(prefs[NotificationPref.taskUpdates], isTrue);
      expect(prefs[NotificationPref.badges], isTrue);
      expect(prefs[NotificationPref.platformAnnouncements], isFalse);
    });

    test('a partial response leaves unmentioned switches alone', () async {
      final repo = _FakePrefsRepository(remote: {'badges': true});
      final c = _container(repo);
      await seedSession(c);
      final before = c.read(settingsProvider).notifications;

      await c.read(settingsProvider.notifier).syncNotificationPrefs();

      final after = c.read(settingsProvider).notifications;
      expect(after[NotificationPref.badges], isTrue);
      expect(
        after[NotificationPref.newEpisodes],
        before[NotificationPref.newEpisodes],
      );
    });

    test('makes no call when signed out', () async {
      final repo = _FakePrefsRepository();
      final c = _container(repo);
      // No session seeded.

      await c.read(settingsProvider.notifier).syncNotificationPrefs();

      expect(repo.getCalls, 0);
    });

    test('a failed GET degrades to the cached values, silently', () async {
      final repo = _FakePrefsRepository(
        getFailure: const SkifluxFailure(SkifluxErrorKind.contentLoadFailed),
      );
      final c = _container(repo);
      await seedSession(c);
      final before = c.read(settingsProvider).notifications;

      // Must not throw — reads degrade gracefully.
      await c.read(settingsProvider.notifier).syncNotificationPrefs();

      expect(c.read(settingsProvider).notifications, before);
    });
  });

  group('SettingsNotifier.setNotificationPref', () {
    test('optimistic flip, PATCHing only the changed field', () async {
      final repo = _FakePrefsRepository();
      final c = _container(repo);
      await seedSession(c);

      await c
          .read(settingsProvider.notifier)
          .setNotificationPref(NotificationPref.badges, true);

      expect(
        c.read(settingsProvider).notifications[NotificationPref.badges],
        isTrue,
      );
      expect(repo.patches.single, (field: 'badges', value: true));
    });

    test('a no-op flip sends nothing', () async {
      final repo = _FakePrefsRepository();
      final c = _container(repo);
      await seedSession(c);
      // newEpisodes defaults to true.

      await c
          .read(settingsProvider.notifier)
          .setNotificationPref(NotificationPref.newEpisodes, true);

      expect(repo.patches, isEmpty);
    });

    test('a rejected PATCH rolls the switch back and rethrows', () async {
      final repo = _FakePrefsRepository(
        patchFailure: const SkifluxFailure(SkifluxErrorKind.unknown),
      );
      final c = _container(repo);
      await seedSession(c);

      await expectLater(
        c
            .read(settingsProvider.notifier)
            .setNotificationPref(NotificationPref.badges, true),
        throwsA(isA<SkifluxFailure>()),
      );

      // Rolled back — the UI must not keep claiming a state the server
      // refused to store.
      expect(
        c.read(settingsProvider).notifications[NotificationPref.badges],
        isFalse,
      );
    });
  });

  group('SettingsNotifier.ready', () {
    test('completes, so gate decisions can await hydration safely', () async {
      final repo = _FakePrefsRepository();
      final c = _container(repo);

      await expectLater(
        c.read(settingsProvider.notifier).ready,
        completes,
      );
    });
  });
}
