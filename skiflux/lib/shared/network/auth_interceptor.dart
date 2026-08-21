/// Bearer-token attach and refresh-on-401, in one place.
///
/// Every mobile endpoint in the spec is `bearerAuth`, so this is the only
/// reason `dio` was chosen over `package:http`: the token lifecycle lives here
/// instead of at ~40 call sites.
///
/// The spec also defines a separate `adminBearerAuth` scheme. This interceptor
/// never touches it, and the app must never call an admin endpoint.
library;

import 'package:dio/dio.dart';

import 'auth_tokens.dart';
import 'token_store.dart';

/// Marks a request as not needing (and not tolerating) an Authorization header:
/// signup, login, OTP verify/resend, forgot/reset password, social logins,
/// token refresh, and `GET /skillworlds`.
const noAuthExtra = 'skiflux.noAuth';

/// Set internally on a retry so a second 401 can't start a refresh loop.
const _retriedExtra = 'skiflux.retried';

/// Attaches the access token, and on a 401 refreshes once and replays the
/// original request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required Dio retryClient,
    required Future<AuthTokens> Function(AuthTokens current) refresh,
    this.onSessionLost,
  }) : _tokens = tokenStore,
       _retryClient = retryClient,
       _refresh = refresh;

  final TokenStore _tokens;

  /// A second Dio with no auth interceptor, used to replay the failed request.
  /// Replaying through the main client would re-enter this interceptor.
  final Dio _retryClient;

  /// Performs `POST /auth/token/refresh`. Injected rather than called directly
  /// so this file stays free of endpoint knowledge.
  final Future<AuthTokens> Function(AuthTokens current) _refresh;

  /// Fired once when the session is unrecoverable — the refresh itself was
  /// rejected. The app should route to sign-in.
  final void Function()? onSessionLost;

  /// In-flight refresh. Concurrent 401s (the wallet screen fires several
  /// requests at once) await this rather than each starting their own, which
  /// would rotate the refresh token out from under one another.
  Future<AuthTokens?>? _inFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[noAuthExtra] == true) return handler.next(options);

    final tokens = _tokens.cached ?? await _tokens.read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.access}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final statusCode = err.response?.statusCode;

    final shouldRefresh =
        (statusCode == 401 || statusCode == 403) &&
            options.extra[noAuthExtra] != true &&
            options.extra[_retriedExtra] != true;
    // final shouldRefresh =
    //     err.response?.statusCode == 401 &&
    //     options.extra[noAuthExtra] != true &&
    //     options.extra[_retriedExtra] != true;

    if (!shouldRefresh) return handler.next(err);

    final current = _tokens.cached ?? await _tokens.read();
    if (current == null) return handler.next(err);

    // The token this request actually carried. If the store has since moved on,
    // a concurrent request already refreshed and this 401 is simply stale —
    // replay with the current token instead of refreshing again, which would
    // spend an already-rotated refresh token.
    final sent = _bearerOf(options);
    final refreshed = sent != null && sent != current.access
        ? current
        : await _refreshOnce(current);
    if (refreshed == null) {
      // Refresh rejected: the session is genuinely over. Surfaces to the user
      // as sessionExpired via ApiException's 401 mapping.
      await _tokens.clear();
      onSessionLost?.call();
      return handler.next(err);
    }

    try {
      final replayed = await _retryClient.fetch<dynamic>(
        options
          ..extra[_retriedExtra] = true
          ..headers['Authorization'] = 'Bearer ${refreshed.access}',
      );
      return handler.resolve(replayed);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// The access token a request was sent with, or null if it had none.
  static String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length);
  }

  /// Coalesces concurrent refreshes onto one network call.
  Future<AuthTokens?> _refreshOnce(AuthTokens current) {
    return _inFlight ??= _runRefresh(current).whenComplete(() {
      _inFlight = null;
    });
  }

  Future<AuthTokens?> _runRefresh(AuthTokens current) async {
    try {
      final tokens = await _refresh(current);
      await _tokens.write(tokens);
      return tokens;
    } on Object {
      // Any failure here is terminal for the session — including a network
      // blip, which is safe to treat as sign-out because the user can retry
      // signing in, whereas serving a stale token would fail silently forever.
      return null;
    }
  }
}
