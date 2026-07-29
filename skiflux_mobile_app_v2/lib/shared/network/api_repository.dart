/// Base class for feature repositories.
///
/// The contract every Tier 1 integration follows: repositories return parsed
/// models or throw [SkifluxFailure]. No [DioException] escapes this layer, and
/// no widget ever sees one.
library;

import 'package:dio/dio.dart';

import '../error_handling/error_handler.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';
import 'json_envelope.dart';

/// DRF's paginated envelope: `{count, next, previous, results}`.
class Paginated<T> {
  const Paginated({
    required this.results,
    this.count = 0,
    this.next,
    this.previous,
  });

  final List<T> results;
  final int count;
  final String? next;
  final String? previous;

  bool get hasMore => next != null;
}

abstract class ApiRepository {
  const ApiRepository(this.dio);

  final Dio dio;

  /// The kind a failure gets when the transport layer can't classify it more
  /// precisely. Subclasses override so a 500 on a withdrawal surfaces as the
  /// withdrawal modal rather than a generic toast.
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.unknown;

  /// What a 401 means here. Correct for every authenticated endpoint: the token
  /// was rejected, so the session is over. The auth repository overrides it —
  /// its endpoints are public, so a 401 is a rejected credential rather than an
  /// expiry, and routing the sign-in screen to "session expired" would be
  /// nonsense.
  SkifluxErrorKind get unauthorizedKind => SkifluxErrorKind.sessionExpired;

  /// Runs [request] and converts any [DioException] into a [SkifluxFailure].
  ///
  /// [kind] overrides [fallbackKind] for one call — useful where a repository
  /// spans flows, e.g. the wallet's read (contentLoadFailed) vs its withdrawal
  /// submit (skillCoinWithdrawal).
  Future<T> guard<T>(
    Future<T> Function() request, {
    SkifluxErrorKind? kind,
  }) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException.fromDio(
        error,
        fallback: kind ?? fallbackKind,
        unauthorizedKind: unauthorizedKind,
      ).toFailure();
    } on FormatException catch (error, stackTrace) {
      // A response that parsed as JSON but didn't match the model — a real
      // contract mismatch. Reported to Sentry via the kind's classification.
      throw SkifluxFailure(
        kind ?? fallbackKind,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// GET returning a single object.
  Future<T> getObject<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parse,
    Map<String, dynamic>? query,
    SkifluxErrorKind? kind,
    bool authenticated = true,
  }) => guard(() async {
    final response = await dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
      options: _options(authenticated),
    );
    return parse(unwrapObject(_requireBody(response.data, path)));
  }, kind: kind);

  /// GET returning a list, tolerating both a bare JSON array and DRF's
  /// paginated envelope. Discards pagination metadata — use [getPage] when the
  /// caller needs it.
  Future<List<T>> getList<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parse,
    Map<String, dynamic>? query,
    SkifluxErrorKind? kind,
    bool authenticated = true,
  }) async => (await getPage(
    path,
    parse: parse,
    query: query,
    kind: kind,
    authenticated: authenticated,
  )).results;

  /// GET a paginated collection, keeping `count`/`next`/`previous`.
  Future<Paginated<T>> getPage<T>(
    String path, {
    required T Function(Map<String, dynamic> json) parse,
    Map<String, dynamic>? query,
    SkifluxErrorKind? kind,
    bool authenticated = true,
  }) => guard(() async {
    final response = await dio.get<dynamic>(
      path,
      queryParameters: query,
      options: _options(authenticated),
    );
    return _readPage(_normalizeListBody(response.data), path, parse);
  }, kind: kind);

  /// POST with an optional parsed response. Pass [parse] as null for endpoints
  /// that return 204 or a body the caller ignores.
  Future<T?> post<T>(
    String path, {
    Object? body,
    T Function(Map<String, dynamic> json)? parse,
    Map<String, dynamic>? query,
    SkifluxErrorKind? kind,
    bool authenticated = true,
  }) => guard(() async {
    final response = await dio.post<dynamic>(
      path,
      data: body,
      queryParameters: query,
      options: _options(authenticated),
    );
    if (parse == null) return null;
    return parse(unwrapObject(_requireBody(_asMap(response.data), path)));
  }, kind: kind);

  /// PATCH — used by profile update and the default-card/account setters.
  Future<T?> patch<T>(
    String path, {
    Object? body,
    T Function(Map<String, dynamic> json)? parse,
    SkifluxErrorKind? kind,
    bool authenticated = true,
    Options? options,
  }) => guard(() async {
    final response = await dio.patch<dynamic>(
      path,
      data: body,
      options: options ?? _options(authenticated),
    );
    if (parse == null) return null;
    return parse(unwrapObject(_requireBody(_asMap(response.data), path)));
  }, kind: kind);

  Future<void> delete(
    String path, {
    Object? body,
    SkifluxErrorKind? kind,
    bool authenticated = true,
  }) => guard(() async {
    await dio.delete<dynamic>(
      path,
      data: body,
      options: _options(authenticated),
    );
  }, kind: kind);

  /// Public endpoints must not carry an Authorization header; the interceptor
  /// reads this flag.
  Options _options(bool authenticated) =>
      Options(extra: authenticated ? null : {noAuthExtra: true});

  Map<String, dynamic>? _asMap(Object? data) =>
      data is Map<String, dynamic>
          ? data
          : data is Map
          ? Map<String, dynamic>.from(data)
          : null;

  Map<String, dynamic> _requireBody(Map<String, dynamic>? body, String path) {
    if (body == null) {
      throw FormatException('Expected a JSON object body from $path');
    }
    return body;
  }

  /// Peel `{data: [...]}` so list endpoints match [unwrapList].
  Object? _normalizeListBody(Object? data) {
    if (data is List) return data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final inner = map['data'];
      if (inner is List ||
          (inner is Map && (inner['results'] is List || inner['count'] != null))) {
        return inner;
      }
      return map;
    }
    return data;
  }

  Paginated<T> _readPage<T>(
    Object? data,
    String path,
    T Function(Map<String, dynamic> json) parse,
  ) {
    if (data is List) {
      return Paginated(results: _parseAll(data, parse), count: data.length);
    }
    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) {
        return Paginated(
          results: _parseAll(results, parse),
          count: data['count'] is int ? data['count'] as int : results.length,
          next: data['next'] as String?,
          previous: data['previous'] as String?,
        );
      }
      // Some list endpoints return `{data: [...]}` after normalize failed.
      try {
        final list = unwrapList(data);
        return Paginated(results: _parseAll(list, parse), count: list.length);
      } on FormatException {
        // fall through
      }
    }
    throw FormatException('Expected a list or paginated body from $path');
  }

  List<T> _parseAll<T>(
    List<dynamic> raw,
    T Function(Map<String, dynamic> json) parse,
  ) => raw
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList(growable: false);
}
