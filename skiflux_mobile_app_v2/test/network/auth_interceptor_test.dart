import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/shared/network/auth_interceptor.dart';
import 'package:skiflux_mobile_app_v2/shared/network/auth_tokens.dart';
import 'package:skiflux_mobile_app_v2/shared/network/token_store.dart';

/// In-memory stand-in for the platform keychain — flutter_secure_storage has no
/// implementation under `flutter test`.
class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage() : super();

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

/// Serves canned responses without a network. [onRequest] decides each reply,
/// so a test can 401 the first attempt and 200 the replay.
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

ResponseBody _json(int status, String body) =>
    ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });

void main() {
  late _FakeSecureStorage storage;
  late TokenStore tokens;

  setUp(() async {
    storage = _FakeSecureStorage();
    tokens = TokenStore(storage);
    await tokens.write(
      const AuthTokens(access: 'stale-access', refresh: 'good-refresh'),
    );
  });

  /// Wires a main client (with the interceptor) and the raw retry client onto
  /// one stub adapter, mirroring api_client.dart's two-Dio arrangement.
  ({Dio dio, _StubAdapter adapter, List<String> refreshCalls, int lostCount})
  build({
    required Future<ResponseBody> Function(RequestOptions options) handler,
    Future<AuthTokens> Function(AuthTokens current)? refresh,
  }) {
    final adapter = _StubAdapter(handler);
    final raw = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    final refreshCalls = <String>[];
    var lost = 0;

    dio.interceptors.add(
      AuthInterceptor(
        tokenStore: tokens,
        retryClient: raw,
        refresh:
            refresh ??
            (current) async {
              refreshCalls.add(current.refresh);
              return const AuthTokens(
                access: 'fresh-access',
                refresh: 'good-refresh',
              );
            },
        onSessionLost: () => lost++,
      ),
    );
    return (
      dio: dio,
      adapter: adapter,
      refreshCalls: refreshCalls,
      lostCount: lost,
    );
  }

  test('attaches the stored access token as a bearer header', () async {
    final env = build(handler: (_) async => _json(200, '{"ok":true}'));
    await env.dio.get<dynamic>('/wallet/my-wallet');
    expect(
      env.adapter.received.single.headers['Authorization'],
      'Bearer stale-access',
    );
  });

  test('sends no Authorization header on a noAuth request', () async {
    // Login/signup/refresh/skillworlds are public and must stay unauthenticated.
    final env = build(handler: (_) async => _json(200, '{"ok":true}'));
    await env.dio.post<dynamic>(
      '/auth/login',
      options: Options(extra: {noAuthExtra: true}),
    );
    expect(
      env.adapter.received.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('a 401 triggers one refresh and replays with the new token', () async {
    final env = build(
      handler: (options) async {
        final isRetry = options.headers['Authorization'] == 'Bearer fresh-access';
        return isRetry
            ? _json(200, '{"balance":"1500.50"}')
            : _json(401, '{"detail":"Token is invalid or expired"}');
      },
    );

    final response = await env.dio.get<dynamic>('/wallet/my-wallet');

    expect(response.statusCode, 200);
    expect(env.refreshCalls, ['good-refresh']);
    expect(env.adapter.received, hasLength(2));
    expect(
      env.adapter.received.last.headers['Authorization'],
      'Bearer fresh-access',
    );
    // The rotated pair is persisted, so the next cold start uses it.
    expect(tokens.cached?.access, 'fresh-access');
  });

  test('concurrent 401s coalesce onto a single refresh', () async {
    // The wallet screen fires several requests at once; independent refreshes
    // would rotate the refresh token out from under each other.
    final env = build(
      handler: (options) async {
        final isRetry = options.headers['Authorization'] == 'Bearer fresh-access';
        return isRetry ? _json(200, '{"ok":true}') : _json(401, '{}');
      },
    );

    await Future.wait([
      env.dio.get<dynamic>('/wallet/my-wallet'),
      env.dio.get<dynamic>('/wallet/transactions'),
      env.dio.get<dynamic>('/me/platform-tasks'),
    ]);

    expect(env.refreshCalls, hasLength(1));
  });

  test('a failed refresh clears the session and surfaces the 401', () async {
    final env = build(
      handler: (_) async => _json(401, '{}'),
      refresh: (_) async => throw DioException(
        requestOptions: RequestOptions(path: '/auth/token/refresh'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/auth/token/refresh'),
          statusCode: 401,
        ),
      ),
    );

    await expectLater(
      env.dio.get<dynamic>('/wallet/my-wallet'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(tokens.cached, isNull);
    expect(storage.values, isEmpty);
  });

  test('a 401 on the replay does not start a second refresh', () async {
    // Guards against an infinite refresh loop when the fresh token is also
    // rejected.
    final env = build(handler: (_) async => _json(401, '{}'));

    await expectLater(
      env.dio.get<dynamic>('/wallet/my-wallet'),
      throwsA(isA<DioException>()),
    );
    expect(env.refreshCalls, hasLength(1));
  });

  test('non-401 errors pass through untouched', () async {
    final env = build(handler: (_) async => _json(500, '{}'));

    await expectLater(
      env.dio.get<dynamic>('/wallet/my-wallet'),
      throwsA(isA<DioException>()),
    );
    expect(env.refreshCalls, isEmpty);
    expect(tokens.cached?.access, 'stale-access');
  });

  test('signed out: a 401 cannot refresh and is passed straight through',
      () async {
    await tokens.clear();
    final env = build(handler: (_) async => _json(401, '{}'));

    await expectLater(
      env.dio.get<dynamic>('/wallet/my-wallet'),
      throwsA(isA<DioException>()),
    );
    expect(env.refreshCalls, isEmpty);
  });

  group('TokenStore', () {
    test('round-trips through storage and caches in memory', () async {
      final fresh = TokenStore(storage);
      expect(fresh.cached, isNull, reason: 'not loaded yet');
      final read = await fresh.read();
      expect(read?.access, 'stale-access');
      expect(fresh.cached?.refresh, 'good-refresh');
      expect(await fresh.hasSession(), isTrue);
    });

    test('clear removes both keys and reports no session', () async {
      await tokens.clear();
      expect(await tokens.hasSession(), isFalse);
      expect(storage.values, isEmpty);
    });

    test('a half-written pair reads as no session', () async {
      storage.values.remove('skiflux.auth.refresh');
      expect(await TokenStore(storage).read(), isNull);
    });
  });
}
