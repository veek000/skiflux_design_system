/// Shared Dio base options and the raw (no-auth) client.
///
/// Split out of [api_client] so [auth_gate] can refresh tokens without a
/// circular import (api_client → auth_gate → api_client).
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/env_config.dart';
import 'connectivity_store.dart';

/// Every mobile operation in the spec is mounted under this prefix.
const apiPathPrefix = '/api/v1';

const _unconfiguredOrigin = 'https://unconfigured.invalid';

BaseOptions skifluxBaseOptions() => BaseOptions(
  baseUrl:
      '${EnvConfig.isApiBaseUrlConfigured ? EnvConfig.apiBaseUrl : _unconfiguredOrigin}'
      '$apiPathPrefix',
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 20),
  sendTimeout: const Duration(seconds: 30),
  contentType: Headers.jsonContentType,
  validateStatus: (status) => status != null && status >= 200 && status < 300,
);

/// Bare client with no auth interceptor — token refresh + post-refresh replay.
final rawDioProvider = Provider<Dio>((ref) {
  final dio = Dio(skifluxBaseOptions());
  dio.interceptors.add(
    ConnectivityInterceptor(() => ref.read(connectivityProvider.notifier)),
  );
  if (kDebugMode) {
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
  return dio;
});
