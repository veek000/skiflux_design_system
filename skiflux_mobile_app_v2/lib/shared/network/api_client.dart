/// The app's single configured [Dio] instance and its Riverpod wiring.
///
/// Repositories depend on [apiClientProvider], never on `Dio` directly, so the
/// base URL, timeouts, auth and logging are configured exactly once.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env_config.dart';
import 'auth_interceptor.dart';
import 'auth_tokens.dart';
import 'connectivity_store.dart';
import 'token_store.dart';

/// Path of the refresh endpoint, per the OpenAPI spec.
const refreshPath = '/auth/token/refresh';

/// Every mobile operation in the spec is mounted under this prefix. Applied
/// once here rather than repeated in ~40 endpoint constants, so a backend that
/// remounts is a single edit. `API_BASE_URL` in `config/env/*.json` is the
/// origin only.
const apiPathPrefix = '/api/v1';

/// Stand-in origin for a build that compiled no `API_BASE_URL`.
///
/// [BaseOptions] rejects a relative URL outright, so the empty origin cannot
/// simply be passed through: `'/api/v1'` throws while the provider is being
/// *created*, turning a build-configuration mistake into a provider-in-error
/// that every repository inherits, with no request ever attempted.
///
/// `.invalid` is reserved by RFC 2606 and can never resolve, so the client is
/// still built and its requests fail as ordinary connection errors — the
/// degraded path release builds already take. Debug builds never get here:
/// [EnvConfig.validate] throws at startup, naming the missing define.
const _unconfiguredOrigin = 'https://unconfigured.invalid';

BaseOptions _baseOptions() => BaseOptions(
  baseUrl:
      '${EnvConfig.isApiBaseUrlConfigured ? EnvConfig.apiBaseUrl : _unconfiguredOrigin}'
      '$apiPathPrefix',
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 20),
  sendTimeout: const Duration(seconds: 30),
  contentType: Headers.jsonContentType,
  // Non-2xx must throw so ApiException.fromDio is the only place status codes
  // are interpreted.
  validateStatus: (status) => status != null && status >= 200 && status < 300,
);

/// Bare client with no auth interceptor. Two jobs: performing the token
/// refresh itself (which must not recurse through [AuthInterceptor]), and
/// replaying a request after a successful refresh.
final rawDioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  _attachConnectivity(ref, dio);
  _attachLogger(dio);
  return dio;
});

/// The client every repository uses.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  final raw = ref.watch(rawDioProvider);
  final tokens = ref.watch(tokenStoreProvider);

  dio.interceptors.add(
    AuthInterceptor(
      tokenStore: tokens,
      retryClient: raw,
      refresh: (current) => _refreshTokens(raw, current),
      onSessionLost: () => ref.read(sessionLostProvider.notifier).signal(),
    ),
  );
  _attachConnectivity(ref, dio);
  _attachLogger(dio);
  return dio;
});

/// Feeds the offline bar from this client's traffic.
///
/// Added after [AuthInterceptor] so a request replayed on a fresh token is
/// seen once, on its final outcome, rather than reported as a failure on the
/// 401 that triggered the refresh.
void _attachConnectivity(Ref ref, Dio dio) {
  dio.interceptors.add(
    // Read lazily: the notifier must not be built while this provider is.
    ConnectivityInterceptor(() => ref.read(connectivityProvider.notifier)),
  );
}

/// Increments whenever a refresh fails terminally. The app shell listens and
/// routes to sign-in; a counter rather than a bool so a second expiry after a
/// re-login still notifies.
///
/// [Notifier], not `StateProvider` — the latter is gone in Riverpod 3.x, and
/// every other store in the app is on this pattern.
class SessionLostNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void signal() => state++;
}

final sessionLostProvider = NotifierProvider<SessionLostNotifier, int>(
  SessionLostNotifier.new,
);

/// `POST /auth/token/refresh` — the one call that must bypass the auth
/// interceptor. Response shape is undocumented (tracker 61b), so parsing goes
/// through [AuthTokens.fromJson]; a body that omits the refresh token keeps
/// the current one.
Future<AuthTokens> _refreshTokens(Dio raw, AuthTokens current) async {
  final response = await raw.post<Map<String, dynamic>>(
    refreshPath,
    data: current.refreshPayload,
    options: Options(extra: {noAuthExtra: true}),
  );
  final body = response.data;
  if (body == null) {
    throw const FormatException('Empty token refresh response');
  }
  return AuthTokens.fromJson(body, fallbackRefresh: current.refresh);
}

/// Debug-only request logging. Headers are omitted deliberately — the
/// Authorization header carries live token material.
void _attachLogger(Dio dio) {
  if (!kDebugMode) return;
  dio.interceptors.add(
    LogInterceptor(
      request: false,
      requestHeader: false,
      requestBody: false,
      responseHeader: false,
      responseBody: false,
      logPrint: (line) => debugPrint('[api] $line'),
    ),
  );
}
