/// How hard the app retries a provider that failed to load.
///
/// Riverpod 3 retries a throwing provider **automatically**, and that default
/// is wrong for this app in two ways.
///
/// **It hides the failure.** While a retry is pending the provider's state is
/// `AsyncLoading` (carrying the error, with `retrying: true`) — not
/// `AsyncError`. Every screen here matches `AsyncLoading()` before
/// `AsyncError()`, so for the whole backoff the user sees a shimmering
/// skeleton rather than "We couldn't load this · Retry". With the default ten
/// attempts backing off to 6.4s that is roughly 40 seconds of fake loading on
/// a fast failure, and minutes when each attempt has to burn a 15s connect
/// timeout first. That is exactly the "it just keeps showing the skeleton"
/// report.
///
/// Bounding the retries is the fix rather than teaching ~10 screens to
/// unpick a retrying-loading state: a *brief* skeleton while a bounded retry
/// runs is correct — flashing an error panel that a successful retry then
/// replaces would be worse. What was wrong was the length, not the skeleton.
///
/// **It spends refresh tokens.** A 401 is retried like anything else, and each
/// attempt re-enters [AuthInterceptor] and starts another
/// `POST /auth/token/refresh`. Ten retries is ten refreshes against a session
/// that has already been declared dead — on a backend that rotates refresh
/// tokens, the retries can invalidate a session that the first refresh would
/// have recovered.
library;

import 'package:dio/dio.dart';

import 'api_exception.dart';

/// The app's provider retry policy.
///
/// Transient transport failures are worth a couple of quick attempts — a
/// dropped packet on a train, a server that was mid-deploy. Everything else is
/// reported immediately, because a screen that says what went wrong and offers
/// a button is more useful than one that keeps pretending to load.
Duration? skifluxRetry(int retryCount, Object error) {
  if (retryCount >= _backoff.length) return null;
  if (!_isTransient(error)) return null;
  return _backoff[retryCount];
}

/// Both attempts are done inside two seconds, so the error reaches the screen
/// while the user is still looking at the thing that asked for it.
const _backoff = <Duration>[
  Duration(milliseconds: 400),
  Duration(milliseconds: 1200),
];

/// Whether [error] could plausibly succeed on a second attempt.
///
/// Deliberately narrow. A 401 is *not* transient: the interceptor has already
/// tried a refresh and failed, so retrying only spends more refresh tokens.
/// Nor is any 4xx — the request was wrong and will be wrong again.
bool _isTransient(Object error) {
  if (error is ApiException) {
    final status = error.statusCode;
    // No status at all means the request never reached the server.
    if (status == null) return true;
    // 408 Request Timeout and 429 Too Many Requests are the two 4xx that do
    // change on their own; 5xx generally does.
    return status == 408 || status == 429 || status >= 500;
  }
  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
  }
  // A parsing bug or a state error will not fix itself.
  return false;
}
