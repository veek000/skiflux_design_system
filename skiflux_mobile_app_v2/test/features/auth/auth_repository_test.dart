import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/auth_endpoints.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/auth_repository.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';
import 'package:skiflux_mobile_app_v2/shared/network/auth_interceptor.dart';
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

/// 204 with no body — several auth endpoints (resend, forgot, reset) document
/// no response schema at all.
ResponseBody _empty([int status = 204]) =>
    ResponseBody.fromString('', status, headers: const {});

void main() {
  late _FakeSecureStorage storage;
  late TokenStore tokens;

  setUp(() {
    storage = _FakeSecureStorage();
    tokens = TokenStore(storage);
  });

  ({AuthRepository repo, _StubAdapter adapter}) build(
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
    return (repo: AuthRepository(dio, tokens), adapter: adapter);
  }

  Map<String, dynamic> bodyOf(RequestOptions options) =>
      options.data is String
      ? jsonDecode(options.data as String) as Map<String, dynamic>
      : (options.data as Map).cast<String, dynamic>();

  group('login', () {
    test('posts the spec body and persists the returned pair', () async {
      final env = build(
        (_) async =>
            _json(200, '{"access":"acc-1","refresh":"ref-1"}'),
      );

      final result = await env.repo.login(
        email: '  rider@skiflux.com ',
        password: 'hunter2',
      );

      final request = env.adapter.received.single;
      expect(request.path, AuthEndpoints.login);
      expect(bodyOf(request), {
        'email': 'rider@skiflux.com',
        'password': 'hunter2',
      });
      expect(result, const AuthTokens(access: 'acc-1', refresh: 'ref-1'));
      expect(storage.values['skiflux.auth.access'], 'acc-1');
      expect(tokens.cached?.refresh, 'ref-1');
    });

    test('accepts the OAuth-style spelling without any caller change', () async {
      // The response shape is undocumented (tracker 61b); AuthTokens is the one
      // adapter that absorbs whichever spelling the backend lands on.
      final env = build(
        (_) async => _json(
          200,
          '{"access_token":"acc-2","refresh_token":"ref-2"}',
        ),
      );

      final result = await env.repo.login(
        email: 'rider@skiflux.com',
        password: 'hunter2',
      );

      expect(result.access, 'acc-2');
      expect(result.refresh, 'ref-2');
    });

    test('bad credentials surface as authFailed, not unknown', () async {
      final env = build(
        (_) async => _json(401, '{"detail":"No active account found"}'),
      );

      await expectLater(
        env.repo.login(email: 'rider@skiflux.com', password: 'wrong'),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.authFailed,
          ),
        ),
      );
      expect(tokens.cached, isNull, reason: 'no session on a failed login');
    });

    test('a body with no recognisable token is a failure, not a session',
        () async {
      final env = build((_) async => _json(200, '{"detail":"ok"}'));

      await expectLater(
        env.repo.login(email: 'rider@skiflux.com', password: 'hunter2'),
        throwsA(isA<SkifluxFailure>()),
      );
      expect(storage.values, isEmpty);
    });
  });

  group('signup', () {
    test('sends password_confirm and mints no session', () async {
      final env = build((_) async => _json(201, '{"detail":"OTP sent"}'));

      await env.repo.signup(
        email: 'rider@skiflux.com',
        password: 'hunter2',
        passwordConfirm: 'hunter2',
        firstName: 'Ada',
      );

      final request = env.adapter.received.single;
      expect(request.path, AuthEndpoints.signup);
      expect(bodyOf(request), {
        'email': 'rider@skiflux.com',
        'password': 'hunter2',
        'password_confirm': 'hunter2',
        'first_name': 'Ada',
      });
      // The spec's flow is signup -> OTP; only verifyEmail can hand back tokens.
      expect(tokens.cached, isNull);
    });

    test('omits optional name fields when blank', () async {
      final env = build((_) async => _json(201, '{}'));

      await env.repo.signup(
        email: 'rider@skiflux.com',
        password: 'hunter2',
        passwordConfirm: 'hunter2',
        firstName: '',
        lastName: null,
      );

      expect(
        bodyOf(env.adapter.received.single).keys,
        containsAll(<String>['email', 'password', 'password_confirm']),
      );
      expect(bodyOf(env.adapter.received.single).containsKey('first_name'),
          isFalse);
    });
  });

  group('verifyEmail', () {
    test('hits the spec path, not the app\'s old /auth/verify guess', () async {
      final env = build((_) async => _empty());

      await env.repo.verifyEmail(email: 'rider@skiflux.com', otp: '123456');

      expect(
        env.adapter.received.single.path,
        AuthEndpoints.verifyRegisterEmail,
      );
      expect(bodyOf(env.adapter.received.single), {
        'email': 'rider@skiflux.com',
        'otp': '123456',
      });
    });

    test('returns null when verification mints no session', () async {
      // Backends split here; absence routes the caller to sign-in rather than
      // failing the verification the user just completed.
      final env = build((_) async => _empty());

      expect(
        await env.repo.verifyEmail(email: 'rider@skiflux.com', otp: '123456'),
        isNull,
      );
      expect(storage.values, isEmpty);
    });

    test('persists the pair when verification does mint one', () async {
      final env = build(
        (_) async => _json(200, '{"access":"acc-3","refresh":"ref-3"}'),
      );

      final result = await env.repo.verifyEmail(
        email: 'rider@skiflux.com',
        otp: '123456',
      );

      expect(result?.access, 'acc-3');
      expect(storage.values['skiflux.auth.refresh'], 'ref-3');
    });

    test('an expired OTP surfaces as authFailed', () async {
      final env = build((_) async => _json(400, '{"otp":["Invalid or expired"]}'));

      await expectLater(
        env.repo.verifyEmail(email: 'rider@skiflux.com', otp: '000000'),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.authFailed,
          ),
        ),
      );
    });
  });

  test('resendOtp posts email to the spec path', () async {
    final env = build((_) async => _empty());

    await env.repo.resendOtp(email: 'rider@skiflux.com');

    expect(env.adapter.received.single.path, AuthEndpoints.resendRegisterOtp);
    expect(bodyOf(env.adapter.received.single), {'email': 'rider@skiflux.com'});
  });

  test('forgotPassword posts email to the spec path', () async {
    final env = build((_) async => _empty());

    await env.repo.forgotPassword(email: 'rider@skiflux.com');

    expect(env.adapter.received.single.path, AuthEndpoints.forgotPassword);
    expect(bodyOf(env.adapter.received.single), {'email': 'rider@skiflux.com'});
  });

  test('verifyResetOtp checks the code on its own endpoint', () async {
    // Not `verify-register-email`: that one only knows the signup code, so
    // reusing it here would reject every valid reset code.
    final env = build((_) async => _empty());

    await env.repo.verifyResetOtp(email: 'rider@skiflux.com', otp: '654321');

    final request = env.adapter.received.single;
    expect(request.path, AuthEndpoints.verifyForgotPasswordOtp);
    expect(bodyOf(request), {'email': 'rider@skiflux.com', 'otp': '654321'});
    expect(request.extra[noAuthExtra], isTrue);
  });

  test('a rejected reset code surfaces as authFailed', () async {
    final env = build(
      (_) async => _json(400, '{"otp":["Invalid or expired code."]}'),
    );

    await expectLater(
      env.repo.verifyResetOtp(email: 'rider@skiflux.com', otp: '000000'),
      throwsA(
        isA<SkifluxFailure>().having(
          (f) => f.kind,
          'kind',
          SkifluxErrorKind.authFailed,
        ),
      ),
    );
  });

  test('resetPassword is OTP-based, not token-based', () async {
    final env = build((_) async => _empty());

    await env.repo.resetPassword(
      email: 'rider@skiflux.com',
      otp: '654321',
      newPassword: 'newpass1',
      confirmNewPassword: 'newpass1',
    );

    final request = env.adapter.received.single;
    expect(request.path, AuthEndpoints.resetPassword);
    expect(bodyOf(request), {
      'email': 'rider@skiflux.com',
      'otp': '654321',
      'new_password': 'newpass1',
      'confirm_new_password': 'newpass1',
    });
  });

  group('social sign-in', () {
    test('google posts id_token to its own endpoint', () async {
      final env = build(
        (_) async => _json(200, '{"access":"g-acc","refresh":"g-ref"}'),
      );

      final result = await env.repo.googleSignIn(idToken: 'native-google-token');

      final request = env.adapter.received.single;
      expect(request.path, AuthEndpoints.googleMobile);
      expect(bodyOf(request), {'id_token': 'native-google-token'});
      expect(result.access, 'g-acc');
      expect(tokens.cached?.refresh, 'g-ref');
    });

    test('apple is a distinct endpoint, not a provider field', () async {
      final env = build(
        (_) async => _json(200, '{"access":"a-acc","refresh":"a-ref"}'),
      );

      await env.repo.appleSignIn(idToken: 'native-apple-token');

      expect(env.adapter.received.single.path, AuthEndpoints.appleMobile);
    });
  });

  group('logout', () {
    test('blacklists the refresh token then clears the keychain', () async {
      await tokens.write(
        const AuthTokens(access: 'acc-9', refresh: 'ref-9'),
      );
      final env = build((_) async => _empty());

      await env.repo.logout();

      final request = env.adapter.received.single;
      expect(request.path, AuthEndpoints.logout);
      expect(bodyOf(request), {'refresh_token': 'ref-9'});
      expect(tokens.cached, isNull);
      expect(storage.values, isEmpty);
    });

    test('clears locally even when the server call fails', () async {
      // A user who taps sign out ends up signed out on this device regardless.
      await tokens.write(
        const AuthTokens(access: 'acc-9', refresh: 'ref-9'),
      );
      final env = build((_) async => _json(500, '{}'));

      await env.repo.logout();

      expect(await tokens.hasSession(), isFalse);
      expect(storage.values, isEmpty);
    });

    test('makes no call when there is no session', () async {
      final env = build((_) async => _empty());

      await env.repo.logout();

      expect(env.adapter.received, isEmpty);
    });
  });

  test('hasSession reports stored presence without a network call', () async {
    final env = build((_) async => _empty());

    expect(await env.repo.hasSession(), isFalse);
    await tokens.write(const AuthTokens(access: 'a', refresh: 'r'));
    expect(await env.repo.hasSession(), isTrue);
    expect(env.adapter.received, isEmpty);
  });

  test('every auth call except logout goes out unauthenticated', () async {
    // The spec marks these public; sending a stale bearer invites a 401 storm
    // through the interceptor on the sign-in screen.
    await tokens.write(const AuthTokens(access: 'stale', refresh: 'r'));
    final env = build(
      (_) async => _json(200, '{"access":"a","refresh":"b"}'),
    );

    await env.repo.login(email: 'rider@skiflux.com', password: 'hunter2');

    expect(env.adapter.received.single.extra[noAuthExtra], isTrue);
  });
}
