/// [AuthFlowNotifier.signInWithGoogle] / [AuthFlowNotifier.signInWithApple] —
/// the seam between the native token and the two social endpoints.
///
/// The three outcomes that matter are all here: a completed flow ends signed in
/// with a token pair in the store, a cancelled one is a no-op with **no error
/// on screen**, and a rejected token surfaces the server's message.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/auth_endpoints.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/auth_repository.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/auth_store.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/social_auth.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';
import 'package:skiflux_mobile_app_v2/shared/network/token_store.dart';

/// In-memory keychain — flutter_secure_storage has no `flutter test` backend.
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

/// Scripted token minting — the SDKs never run under `flutter test`.
class _ScriptedSocialAuth extends SocialAuthService {
  _ScriptedSocialAuth({this.token, this.failure})
    : super(googleServerClientId: 'web-client-id', googleIosClientId: '');

  final String? token;
  final SkifluxFailure? failure;
  int signOutCount = 0;

  @override
  Future<String?> googleIdToken() async {
    if (failure != null) throw failure!;
    return token;
  }

  @override
  Future<String?> appleIdToken() => googleIdToken();

  @override
  Future<void> signOut() async => signOutCount++;
}

ResponseBody _json(int status, String body) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  late _FakeSecureStorage storage;
  late TokenStore tokens;

  setUp(() {
    storage = _FakeSecureStorage();
    tokens = TokenStore(storage);
  });

  /// A container whose auth repository talks to [handler] and whose social
  /// service is [social].
  ({ProviderContainer container, _StubAdapter adapter}) build({
    required SocialAuthService social,
    Future<ResponseBody> Function(RequestOptions options)? handler,
  }) {
    final adapter = _StubAdapter(
      handler ?? (_) async => _json(200, '{"access":"acc-1","refresh":"ref-1"}'),
    );
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.test/api/v1',
        contentType: Headers.jsonContentType,
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    )..httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuthRepository(dio, tokens)),
        socialAuthServiceProvider.overrideWithValue(social),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, adapter: adapter);
  }

  Map<String, dynamic> bodyOf(RequestOptions options) => options.data is String
      ? jsonDecode(options.data as String) as Map<String, dynamic>
      : (options.data as Map).cast<String, dynamic>();

  test('Google: posts the id_token and ends with a session', () async {
    final env = build(social: _ScriptedSocialAuth(token: 'google-id-token'));
    final notifier = env.container.read(authFlowProvider.notifier);

    expect(await notifier.signInWithGoogle(), isTrue);

    final request = env.adapter.received.single;
    expect(request.path, AuthEndpoints.googleMobile);
    expect(bodyOf(request), {'id_token': 'google-id-token'});
    expect(await notifier.hasSession(), isTrue);
    expect(env.container.read(authFlowProvider).submitting, isFalse);
  });

  test('Apple: posts to its own endpoint', () async {
    final env = build(social: _ScriptedSocialAuth(token: 'apple-id-token'));

    expect(
      await env.container.read(authFlowProvider.notifier).signInWithApple(),
      isTrue,
    );
    expect(env.adapter.received.single.path, AuthEndpoints.appleMobile);
  });

  test('a cancelled picker is not a failure', () async {
    // The whole point of the null token: the user stopped, so nothing is sent
    // and the screen must not accuse them of anything.
    final env = build(social: _ScriptedSocialAuth());
    final notifier = env.container.read(authFlowProvider.notifier);

    expect(await notifier.signInWithGoogle(), isFalse);
    expect(env.adapter.received, isEmpty);

    final state = env.container.read(authFlowProvider);
    expect(state.signInError, isNull);
    expect(state.submitting, isFalse);
    expect(await notifier.hasSession(), isFalse);
  });

  test('a native failure surfaces copy and clears submitting', () async {
    final env = build(
      social: _ScriptedSocialAuth(
        failure: const SkifluxFailure(SkifluxErrorKind.authFailed),
      ),
    );
    final notifier = env.container.read(authFlowProvider.notifier);

    expect(await notifier.signInWithGoogle(), isFalse);
    expect(env.adapter.received, isEmpty);

    final state = env.container.read(authFlowProvider);
    expect(state.signInError, isNotNull);
    expect(state.submitting, isFalse);
  });

  test('a rejected token surfaces the server message', () async {
    final env = build(
      social: _ScriptedSocialAuth(token: 'stale-token'),
      handler: (_) async =>
          _json(401, '{"detail":"Google token has expired."}'),
    );
    final notifier = env.container.read(authFlowProvider.notifier);

    expect(await notifier.signInWithGoogle(), isFalse);
    expect(env.container.read(authFlowProvider).signInError, isNotNull);
    expect(await notifier.hasSession(), isFalse);
  });

  test('signing out also drops the provider cache', () async {
    final social = _ScriptedSocialAuth(token: 'google-id-token');
    final env = build(social: social);
    final notifier = env.container.read(authFlowProvider.notifier);

    await notifier.signInWithGoogle();
    await notifier.signOut();

    // Otherwise Google silently reuses the account and "Switch accounts"
    // switches nothing.
    expect(social.signOutCount, 1);
    expect(await notifier.hasSession(), isFalse);
  });
}
