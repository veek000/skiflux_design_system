/// The provider retry policy.
///
/// Riverpod 3 retries a failed provider automatically, ten times, backing off
/// to 6.4s. Two consequences the app cannot live with: the failure is invisible
/// for the whole backoff (a retrying provider is `AsyncLoading`, and every
/// screen renders a skeleton for that), and a 401 is retried like anything
/// else — each attempt re-entering the auth interceptor and burning another
/// refresh.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';
import 'package:skiflux_mobile_app_v2/shared/network/api_exception.dart';
import 'package:skiflux_mobile_app_v2/shared/network/provider_retry.dart';

ApiException _api(int? status) => ApiException(
  kind: SkifluxErrorKind.unknown,
  statusCode: status,
);

DioException _dio(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: type,
);

void main() {
  group('skifluxRetry', () {
    test('gives up after two attempts', () {
      final timeout = _dio(DioExceptionType.connectionTimeout);
      expect(skifluxRetry(0, timeout), isNotNull);
      expect(skifluxRetry(1, timeout), isNotNull);
      expect(skifluxRetry(2, timeout), isNull);
      expect(skifluxRetry(9, timeout), isNull);
    });

    test('both attempts land inside two seconds', () {
      // The whole point: the error has to reach the screen while the user is
      // still looking at it, not after 40s of skeleton.
      final timeout = _dio(DioExceptionType.connectionTimeout);
      final total = skifluxRetry(0, timeout)! + skifluxRetry(1, timeout)!;
      expect(total, lessThan(const Duration(seconds: 2)));
    });

    test('never retries a 401', () {
      // The interceptor has already tried a refresh and failed. Retrying only
      // spends more refresh tokens against a session already declared dead —
      // on a backend that rotates them, that can destroy a recoverable session.
      expect(skifluxRetry(0, _api(401)), isNull);
    });

    test('never retries other 4xx', () {
      for (final status in [400, 403, 404, 409, 422]) {
        expect(
          skifluxRetry(0, _api(status)),
          isNull,
          reason: '$status will be just as wrong the second time',
        );
      }
    });

    test('retries the 4xx that do change on their own', () {
      expect(skifluxRetry(0, _api(408)), isNotNull);
      expect(skifluxRetry(0, _api(429)), isNotNull);
    });

    test('retries 5xx', () {
      for (final status in [500, 502, 503, 504]) {
        expect(skifluxRetry(0, _api(status)), isNotNull, reason: '$status');
      }
    });

    test('retries a request that never reached the server', () {
      // No status at all — DNS, a dropped connection, a backend still waking up.
      expect(skifluxRetry(0, _api(null)), isNotNull);
      expect(skifluxRetry(0, _dio(DioExceptionType.connectionError)), isNotNull);
      expect(skifluxRetry(0, _dio(DioExceptionType.receiveTimeout)), isNotNull);
      expect(skifluxRetry(0, _dio(DioExceptionType.sendTimeout)), isNotNull);
    });

    test('never retries a cancelled request or a bad response', () {
      expect(skifluxRetry(0, _dio(DioExceptionType.cancel)), isNull);
      expect(skifluxRetry(0, _dio(DioExceptionType.badResponse)), isNull);
    });

    test('never retries a programming error', () {
      // A parse bug or a bad cast will not fix itself, and retrying it hides
      // the stack trace behind a skeleton.
      expect(skifluxRetry(0, StateError('bad')), isNull);
      expect(skifluxRetry(0, const FormatException('bad json')), isNull);
    });
  });
}
