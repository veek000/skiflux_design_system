import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/shared/error_handling/error_handler.dart';
import 'package:skiflux/shared/network/api_exception.dart';

/// Builds a DioException for [type], optionally with a response.
DioException _error(
  DioExceptionType type, {
  int? status,
  Object? data,
  Object? cause,
}) {
  final options = RequestOptions(path: '/wallet/my-wallet');
  return DioException(
    requestOptions: options,
    type: type,
    error: cause,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: data,
          ),
  );
}

void main() {
  group('ApiException.fromDio kind mapping', () {
    test('every timeout flavour maps to networkTimeout', () {
      for (final type in const [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          ApiException.fromDio(_error(type)).kind,
          SkifluxErrorKind.networkTimeout,
          reason: '$type',
        );
      }
    });

    test('connection and certificate errors map to noConnection', () {
      expect(
        ApiException.fromDio(_error(DioExceptionType.connectionError)).kind,
        SkifluxErrorKind.noConnection,
      );
      expect(
        ApiException.fromDio(_error(DioExceptionType.badCertificate)).kind,
        SkifluxErrorKind.noConnection,
      );
    });

    test('a bare SocketException reads as noConnection', () {
      expect(
        ApiException.fromDio(
          _error(
            DioExceptionType.unknown,
            cause: const SocketException('failed host lookup'),
          ),
        ).kind,
        SkifluxErrorKind.noConnection,
      );
    });

    test('401 always maps to sessionExpired, overriding the fallback', () {
      // The one status with a fixed cross-endpoint meaning.
      final exception = ApiException.fromDio(
        _error(DioExceptionType.badResponse, status: 401),
        fallback: SkifluxErrorKind.skillCoinWithdrawal,
      );
      expect(exception.kind, SkifluxErrorKind.sessionExpired);
      expect(exception.isUnauthorized, isTrue);
    });

    test('other statuses defer to the caller-supplied fallback', () {
      // A 400 on a withdrawal and a 400 on a signup need different copy, so
      // only the caller decides.
      for (final status in const [400, 403, 404, 409, 500, 503]) {
        expect(
          ApiException.fromDio(
            _error(DioExceptionType.badResponse, status: status),
            fallback: SkifluxErrorKind.skillCoinWithdrawal,
          ).kind,
          SkifluxErrorKind.skillCoinWithdrawal,
          reason: 'status $status',
        );
      }
    });

    test('defaults to unknown when the caller gives no fallback', () {
      expect(
        ApiException.fromDio(
          _error(DioExceptionType.badResponse, status: 500),
        ).kind,
        SkifluxErrorKind.unknown,
      );
    });
  });

  group('body parsing', () {
    test("reads DRF's detail message", () {
      final exception = ApiException.fromDio(
        _error(
          DioExceptionType.badResponse,
          status: 400,
          data: {'detail': 'Insufficient withdrawable balance.'},
        ),
      );
      expect(exception.detail, 'Insufficient withdrawable balance.');
      expect(exception.fieldErrors, isEmpty);
    });

    test('reads per-field validation errors for form highlighting', () {
      final exception = ApiException.fromDio(
        _error(
          DioExceptionType.badResponse,
          status: 400,
          data: {
            'email': ['Already registered.'],
            'password': ['Too short.', 'Too common.'],
          },
        ),
      );
      expect(exception.fieldErrors['email'], ['Already registered.']);
      expect(exception.fieldErrors['password'], hasLength(2));
    });

    test('tolerates a single-string field error and a bare string body', () {
      expect(
        ApiException.fromDio(
          _error(
            DioExceptionType.badResponse,
            status: 400,
            data: {'amount': 'Must be greater than zero.'},
          ),
        ).fieldErrors['amount'],
        ['Must be greater than zero.'],
      );
      expect(
        ApiException.fromDio(
          _error(
            DioExceptionType.badResponse,
            status: 500,
            data: 'Internal Server Error',
          ),
        ).detail,
        'Internal Server Error',
      );
    });

    test('an HTML error page yields no detail rather than garbage', () {
      final exception = ApiException.fromDio(
        _error(DioExceptionType.badResponse, status: 502, data: null),
      );
      expect(exception.detail, isNull);
      expect(exception.fieldErrors, isEmpty);
    });
  });

  test('toFailure carries the kind into the app classifier', () {
    final failure = ApiException.fromDio(
      _error(DioExceptionType.receiveTimeout),
    ).toFailure();
    expect(failure, isA<SkifluxFailure>());
    expect(failure.kind, SkifluxErrorKind.networkTimeout);

    // And the classifier turns it into user-facing copy with no raw text.
    final classified = const ErrorHandler().classify(failure);
    expect(classified.uiType, ErrorUiType.toast);
    expect(classified.message, contains('Check your internet'));
  });

  test('a 401 classifies as the session-expired modal', () {
    final failure = ApiException.fromDio(
      _error(DioExceptionType.badResponse, status: 401),
    ).toFailure();
    final classified = const ErrorHandler().classify(failure);
    expect(classified.uiType, ErrorUiType.modal);
    expect(classified.actionLabel, 'Log In');
  });
}

