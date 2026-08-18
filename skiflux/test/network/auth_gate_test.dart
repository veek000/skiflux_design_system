/// Central [AuthGate]: refresh coalesce, unlock validation, reauth arming.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/shared/network/auth_gate.dart';
import 'package:skiflux/shared/network/auth_tokens.dart';
import 'package:skiflux/shared/network/network_config.dart';
import 'package:skiflux/shared/network/token_store.dart';

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

  Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> received = [];
  var calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    calls++;
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

void main() {
  late TokenStore tokens;
  late _StubAdapter adapter;
  late ProviderContainer container;
  late AuthGate gate;

  setUp(() {
    tokens = TokenStore(_FakeSecureStorage());
    adapter = _StubAdapter(
      (_) async => _json(
        200,
        '{"access_token":"new-access","refresh_token":"new-refresh"}',
      ),
    );
    final raw = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;

    container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(tokens),
        rawDioProvider.overrideWithValue(raw),
      ],
    );
    gate = container.read(authGateProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('ensureValidSession', () {
    test('no tokens → none, no network', () async {
      expect(await gate.ensureValidSession(), SessionValidation.none);
      expect(adapter.calls, 0);
      expect(container.read(authGateProvider).needsReauth, isFalse);
    });

    test('valid refresh → valid and pair rotated', () async {
      await tokens.write(
        const AuthTokens(access: 'old', refresh: 'old-refresh'),
      );
      expect(await gate.ensureValidSession(), SessionValidation.valid);
      expect(tokens.cached?.access, 'new-access');
      expect(adapter.received.single.path, refreshPath);
      expect(container.read(authGateProvider).needsReauth, isFalse);
    });

    test('rejected refresh → invalid, cleared, no reauth arm', () async {
      await tokens.write(
        const AuthTokens(access: 'old', refresh: 'dead'),
      );
      adapter.handler = (_) async => _json(401, '{"detail":"expired"}');

      expect(await gate.ensureValidSession(), SessionValidation.invalid);
      expect(await tokens.hasSession(), isFalse);
      // Unlock owns the next screen — shell must not also navigate.
      expect(container.read(authGateProvider).needsReauth, isFalse);
    });

    test('concurrent unlocks share one refresh', () async {
      await tokens.write(
        const AuthTokens(access: 'old', refresh: 'r'),
      );
      final results = await Future.wait([
        gate.ensureValidSession(),
        gate.ensureValidSession(),
        gate.ensureValidSession(),
      ]);
      expect(results, everyElement(SessionValidation.valid));
      expect(adapter.calls, 1);
    });
  });

  group('declareSessionLost', () {
    test('arms reauth once while in the app', () {
      gate.leaveAuthStack();
      gate.declareSessionLost();
      gate.declareSessionLost();
      gate.declareSessionLost();

      final state = container.read(authGateProvider);
      expect(state.needsReauth, isTrue);
      expect(state.generation, 1);
    });

    test('suppressed on the auth stack', () {
      gate.enterAuthStack();
      gate.declareSessionLost();
      expect(container.read(authGateProvider).needsReauth, isFalse);
    });

    test('suppressed while unlock is in flight', () async {
      await tokens.write(
        const AuthTokens(access: 'old', refresh: 'r'),
      );
      // Slow refresh so unlock is in flight when we declare.
      adapter.handler = (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _json(401, '{}');
      };
      gate.leaveAuthStack();

      final unlock = gate.ensureValidSession();
      // Declare while unlock is running — must not arm shell reauth.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      gate.declareSessionLost();
      expect(container.read(authGateProvider).needsReauth, isFalse);

      expect(await unlock, SessionValidation.invalid);
      expect(container.read(authGateProvider).needsReauth, isFalse);
    });

    test('markReauthHandled clears the arm so a later expiry can fire', () {
      gate.leaveAuthStack();
      gate.declareSessionLost();
      expect(container.read(authGateProvider).needsReauth, isTrue);

      gate.markReauthHandled();
      expect(container.read(authGateProvider).needsReauth, isFalse);

      gate.declareSessionLost();
      expect(container.read(authGateProvider).generation, 2);
      expect(container.read(authGateProvider).needsReauth, isTrue);
    });
  });
}

