/// The app's single configured [Dio] instance and its Riverpod wiring.
///
/// Repositories depend on [apiClientProvider], never on `Dio` directly, so the
/// base URL, timeouts, auth and logging are configured exactly once.
///
/// **Session death is centralised in [authGateProvider].** The interceptor only
/// refreshes via [AuthGate.tryRefresh] and declares loss via
/// [AuthGate.declareSessionLost]. No screen navigates on 401.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_gate.dart';
import 'auth_interceptor.dart';
import 'connectivity_store.dart';
import 'network_config.dart';
import 'token_store.dart';

export 'auth_gate.dart' show authGateProvider, AuthGate, AuthGateState, SessionValidation, refreshPath;
export 'network_config.dart' show apiPathPrefix, rawDioProvider;

/// The client every repository uses.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(skifluxBaseOptions());
  final raw = ref.watch(rawDioProvider);
  final tokens = ref.watch(tokenStoreProvider);
  // Read the notifier (stable) — not the state — so the client is not rebuilt
  // every time reauth is armed.
  final gate = ref.read(authGateProvider.notifier);

  dio.interceptors.add(
    AuthInterceptor(
      tokenStore: tokens,
      retryClient: raw,
      refresh: (current) async {
        final next = await gate.tryRefresh(current);
        if (next == null) {
          throw StateError('Token refresh failed');
        }
        return next;
      },
      onSessionLost: gate.declareSessionLost,
    ),
  );
  // Connectivity after auth so a replayed request is reported once, on its
  // final outcome, rather than as a failure on the 401 that triggered refresh.
  dio.interceptors.add(
    ConnectivityInterceptor(() => ref.read(connectivityProvider.notifier)),
  );
  if (kDebugMode) {
    // dio.interceptors.add(
    //   LogInterceptor(
    //     request: false,
    //     requestHeader: false,
    //     requestBody: false,
    //     responseHeader: false,
    //     responseBody: false,
    //     logPrint: (line) => debugPrint('[api] $line'),
    //   ),
    // );
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (line) => debugPrint('[api] $line'),
      ),
    );
  }
  return dio;
});
