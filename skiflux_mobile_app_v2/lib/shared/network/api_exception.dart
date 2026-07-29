/// Transport-level failure types and their mapping onto the app's existing
/// [SkifluxErrorKind] taxonomy.
///
/// The rule: nothing outside this file inspects a [DioException]. Repositories
/// catch [DioException] once, convert via [ApiException.fromDio], and rethrow
/// a [SkifluxFailure] so `ErrorDisplay` classifies it exactly like every
/// non-network failure already in the app.
library;

import 'dart:io';

import 'package:dio/dio.dart';

import '../error_handling/error_handler.dart';

/// A backend or transport failure, normalised away from Dio's own types.
///
/// [statusCode] is null for failures that never reached the server
/// (timeout, DNS, no route). [fieldErrors] carries DRF's per-field validation
/// map (`{"email": ["Already registered."]}`) so forms can highlight the
/// offending input rather than only showing a generic message.
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    this.statusCode,
    this.detail,
    this.fieldErrors = const {},
    this.cause,
    this.stackTrace,
  });

  final SkifluxErrorKind kind;
  final int? statusCode;

  /// Backend-supplied message, when it sent one. Diagnostic only — user-facing
  /// copy always comes from [ErrorHandler], never from the server.
  final String? detail;

  final Map<String, List<String>> fieldErrors;
  final Object? cause;
  final StackTrace? stackTrace;

  /// True when the access token was rejected — the signal the auth interceptor
  /// uses to decide whether a refresh-and-retry is worth attempting.
  bool get isUnauthorized => statusCode == HttpStatus.unauthorized;

  /// Maps a [DioException] onto the app's error taxonomy.
  ///
  /// [fallback] is the caller's domain-specific kind, used for any failure the
  /// transport layer can't classify more precisely — e.g. a withdrawal
  /// repository passes [SkifluxErrorKind.skillCoinWithdrawal] so a 500 surfaces
  /// as the withdrawal modal rather than a generic toast.
  /// [unauthorizedKind] is what a 401 means for this caller. It defaults to
  /// [SkifluxErrorKind.sessionExpired], true for every authenticated endpoint,
  /// but the auth repository overrides it: a 401 from `/auth/login` is wrong
  /// credentials, and there is no session to expire on the sign-in screen.
  factory ApiException.fromDio(
    DioException error, {
    SkifluxErrorKind fallback = SkifluxErrorKind.unknown,
    SkifluxErrorKind unauthorizedKind = SkifluxErrorKind.sessionExpired,
  }) {
    final status = error.response?.statusCode;
    final kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => SkifluxErrorKind.networkTimeout,
      DioExceptionType.connectionError => SkifluxErrorKind.noConnection,
      DioExceptionType.badCertificate => SkifluxErrorKind.noConnection,
      DioExceptionType.transformTimeout => SkifluxErrorKind.networkTimeout,
      DioExceptionType.cancel => fallback,
      DioExceptionType.badResponse => _kindForStatus(
        status,
        fallback,
        unauthorizedKind,
      ),
      DioExceptionType.unknown =>
        error.error is SocketException
            ? SkifluxErrorKind.noConnection
            : fallback,
    };

    return ApiException(
      kind: kind,
      statusCode: status,
      detail: _detailFrom(error.response?.data),
      fieldErrors: _fieldErrorsFrom(error.response?.data),
      cause: error,
      stackTrace: error.stackTrace,
    );
  }

  /// 401 gets its own slot because on an authenticated endpoint it always means
  /// the same thing — the token is gone or stale, so the session is over. It is
  /// still the caller's call via [unauthorizedKind], since on the public auth
  /// endpoints a 401 is a rejected credential and not an expiry. Every other
  /// status defers to [fallback] — a 400 on a withdrawal and a 400 on a signup
  /// deserve different copy, and only the caller knows which.
  static SkifluxErrorKind _kindForStatus(
    int? status,
    SkifluxErrorKind fallback,
    SkifluxErrorKind unauthorizedKind,
  ) {
    if (status == HttpStatus.unauthorized) return unauthorizedKind;
    return fallback;
  }

  /// DRF errors arrive as `{"detail": "..."}`, `{"message": "..."}`, or a bare
  /// string. Anything else is left to [fieldErrors].
  static String? _detailFrom(Object? data) {
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      for (final key in const ['detail', 'message', 'error']) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  /// Pulls DRF's `{"field": ["msg", ...]}` shape, tolerating single strings.
  static Map<String, List<String>> _fieldErrorsFrom(Object? data) {
    if (data is! Map) return const {};
    final out = <String, List<String>>{};
    for (final entry in data.entries) {
      final key = entry.key;
      if (key is! String) continue;
      if (const ['detail', 'message', 'error'].contains(key)) continue;
      final value = entry.value;
      if (value is List) {
        final messages = value.whereType<String>().toList();
        if (messages.isNotEmpty) out[key] = messages;
      } else if (value is String) {
        out[key] = [value];
      }
    }
    return out;
  }

  /// Hands this failure to the app's classifier.
  ///
  /// `this` travels as the cause rather than the underlying [DioException], so
  /// a caller that needs [fieldErrors] — the sign-in form deciding which input
  /// wears the error treatment — can reach them. The DioException is still
  /// available via [cause], so nothing is lost for crash reporting.
  SkifluxFailure toFailure() =>
      SkifluxFailure(kind, cause: this, stackTrace: stackTrace);

  @override
  String toString() =>
      'ApiException($kind, status: $statusCode, detail: $detail)';
}
