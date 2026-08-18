/// Central auth gate — the **only** owner of session validity and re-auth intent.
///
/// Every path that used to race (biometric unlock, cold-start entry, 401
/// interceptor, load-failure panels) funnels here:
///
/// - [ensureValidSession] — fingerprint / cold-start: refresh once, return a
///   result. Never navigates.
/// - [tryRefresh] — shared refresh used by the Dio interceptor so concurrent
///   401s and an unlock share one network call.
/// - [declareSessionLost] — interceptor only, after a terminal refresh failure
///   while the user is *in* the app. Sets [AuthGateState.needsReauth] once.
///
/// The app shell is the only navigator: it listens to [authGateProvider] and
/// replaces the stack with the password form. Screens never push auth routes
/// themselves on expiry.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_interceptor.dart';
import 'auth_tokens.dart';
import 'network_config.dart';
import 'token_store.dart';

/// Path of the refresh endpoint, per the OpenAPI spec.
const refreshPath = '/auth/token/refresh';

/// Result of [AuthGate.ensureValidSession] before opening the app.
enum SessionValidation {
  /// No token pair on the device.
  none,

  /// Refresh succeeded; safe to enter Home.
  valid,

  /// Refresh failed; keychain is empty. Caller stays on the auth stack.
  invalid,
}

/// What the shell should do — single signal, no competing navigators.
@immutable
class AuthGateState {
  const AuthGateState._({
    required this.needsReauth,
    required this.generation,
    this.reauthMessage,
  });

  const AuthGateState.active()
      : this._(needsReauth: false, generation: 0);

  const AuthGateState.reauthRequired({
    String message = 'Your session expired. Please sign in again.',
    required int generation,
  }) : this._(
          needsReauth: true,
          generation: generation,
          reauthMessage: message,
        );

  /// When true the shell must replace the stack with the password form.
  final bool needsReauth;

  /// Bumps on every reauth request so [ref.listen] always sees a change.
  final int generation;

  final String? reauthMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthGateState &&
          needsReauth == other.needsReauth &&
          generation == other.generation &&
          reauthMessage == other.reauthMessage;

  @override
  int get hashCode => Object.hash(needsReauth, generation, reauthMessage);
}

/// Single owner of refresh coalescing + re-auth intent.
class AuthGate extends Notifier<AuthGateState> {
  @override
  AuthGateState build() => const AuthGateState.active();

  TokenStore get _tokens => ref.read(tokenStoreProvider);
  Dio get _raw => ref.read(rawDioProvider);

  /// In-flight refresh shared by interceptor 401s and [ensureValidSession].
  Future<AuthTokens?>? _refreshInFlight;

  /// In-flight unlock. While set, [declareSessionLost] does **not** arm
  /// reauth navigation — the unlock caller owns the next screen.
  Future<SessionValidation>? _unlockInFlight;

  /// True while [AuthFlow] is the foreground stack. 401s from avatar / probe
  /// calls on the biometric screen must not push a second AuthFlow.
  var _onAuthStack = false;

  var _generation = 0;

  /// AuthFlow is visible — suppress shell reauth routing.
  void enterAuthStack() => _onAuthStack = true;

  /// User left AuthFlow for Home (or the shell took over reauth).
  void leaveAuthStack() => _onAuthStack = false;

  /// Coalesced `POST /auth/token/refresh`. Returns null on any failure;
  /// does **not** clear the keychain and does **not** declare session lost —
  /// the interceptor / [ensureValidSession] decide what failure means.
  Future<AuthTokens?> tryRefresh(AuthTokens current) {
    return _refreshInFlight ??= _runRefresh(current).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<AuthTokens?> _runRefresh(AuthTokens current) async {
    try {
      final next = await refreshTokens(_raw, current);
      await _tokens.write(next);
      return next;
    } on Object {
      return null;
    }
  }

  /// Biometric unlock and cold-start entry: prove the stored pair still works.
  ///
  /// Concurrent calls share one refresh. Never sets [AuthGateState.needsReauth]
  /// — the auth stack stays in place and the caller shows the password form.
  Future<SessionValidation> ensureValidSession() {
    return _unlockInFlight ??= _runEnsureValidSession().whenComplete(() {
      _unlockInFlight = null;
    });
  }

  Future<SessionValidation> _runEnsureValidSession() async {
    final current = await _tokens.read();
    if (current == null) return SessionValidation.none;

    final next = await tryRefresh(current);
    if (next != null) return SessionValidation.valid;

    await _tokens.clear();
    return SessionValidation.invalid;
  }

  /// Interceptor path after a terminal refresh failure.
  ///
  /// Idempotent: concurrent 401s call this many times; only the first arms
  /// [needsReauth]. Suppressed while unlocking or while the auth stack is
  /// already showing (no navigation race / double AuthFlow).
  void declareSessionLost() {
    unawaited(_tokens.clear());

    if (_unlockInFlight != null || _onAuthStack) {
      return;
    }
    if (state.needsReauth) return;

    _generation += 1;
    state = AuthGateState.reauthRequired(generation: _generation);
  }

  /// Shell finished routing to the password form — allow a future expiry to
  /// signal again after the user re-authenticates.
  void markReauthHandled() {
    if (!state.needsReauth) return;
    state = const AuthGateState.active();
  }
}

final authGateProvider = NotifierProvider<AuthGate, AuthGateState>(
  AuthGate.new,
);

/// `POST /auth/token/refresh` — wire format only; [AuthGate.tryRefresh] is the
/// entry point that coalesces and persists.
Future<AuthTokens> refreshTokens(Dio raw, AuthTokens current) async {
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
