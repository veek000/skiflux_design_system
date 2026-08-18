import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import '../../../shared/network/auth_interceptor.dart';
import '../../../shared/network/auth_tokens.dart';
import '../../../shared/network/token_store.dart';
import 'auth_endpoints.dart';

/// Network calls for the auth flow.
///
/// Follows the [ApiRepository] contract: returns parsed values, throws
/// [SkifluxFailure] on any expected failure. Every endpoint here except
/// [logout] is public, so each passes `authenticated: false`.
///
/// On a successful login / social sign-in the token pair is persisted to the
/// keychain before the future completes, so no caller has to remember to store
/// it.
///
/// Response bodies for login, signup, refresh and both social logins are
/// **undocumented in the spec** (description-only, no schema). Every read of
/// them goes through [AuthTokens.fromJson], the single adapter — when the
/// backend dev confirms the real field names, that one file changes and this
/// class does not.
class AuthRepository extends ApiRepository {
  const AuthRepository(super.dio, this._tokens);

  final TokenStore _tokens;

  /// Bad credentials and expired OTPs are the expected outcome here, not an
  /// infrastructure fault — they surface as the auth error kinds the flow
  /// already renders inline.
  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.authFailed;

  /// Every endpoint here except [logout] is public, so a 401 is a rejected
  /// credential, not an expired session — the sign-in screen must show
  /// "incorrect password", never route itself to sign-in again.
  @override
  SkifluxErrorKind get unauthorizedKind => SkifluxErrorKind.authFailed;

  /// `POST /auth/login`. Persists the pair on success.
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) => _authenticate(
    AuthEndpoints.login,
    AuthRequests.login(email: email, password: password),
  );

  /// `POST /auth/signup`. Yields no session — the spec's flow is signup then
  /// OTP verification, and only [verifyEmail] can mint tokens.
  Future<void> signup({
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
    String? username,
  }) => post<void>(
    AuthEndpoints.signup,
    body: AuthRequests.signup(
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      firstName: firstName,
      lastName: lastName,
      username: username,
    ),
    authenticated: false,
  );

  /// `POST /auth/verify-register-email`.
  ///
  /// The spec documents no response schema, and backends split on whether OTP
  /// verification mints a session or expects a follow-up login. Both work:
  /// tokens are persisted when present, and their absence returns null rather
  /// than failing, so the caller routes to sign-in.
  Future<AuthTokens?> verifyEmail({
    required String email,
    required String otp,
  }) => guard(() async {
    // Deliberately not routed through [post]: that helper treats a missing
    // JSON object as a contract violation, and here an empty 204 is a valid
    // "verified, now sign in" answer.
    final response = await dio.post<dynamic>(
      AuthEndpoints.verifyRegisterEmail,
      data: AuthRequests.verifyEmail(email: email, otp: otp),
      options: Options(extra: {noAuthExtra: true}),
    );
    final data = response.data;
    final tokens = AuthTokens.tryFromJson(
      data is Map<String, dynamic> ? data : null,
    );
    if (tokens != null) await _tokens.write(tokens);
    return tokens;
  });

  /// `POST /auth/resend-register-otp`.
  Future<void> resendOtp({required String email}) => post<void>(
    AuthEndpoints.resendRegisterOtp,
    body: AuthRequests.resendOtp(email: email),
    authenticated: false,
  );

  /// `POST /auth/forgot-password` — sends the reset OTP.
  Future<void> forgotPassword({required String email}) => post<void>(
    AuthEndpoints.forgotPassword,
    body: AuthRequests.forgotPassword(email: email),
    authenticated: false,
  );

  /// `POST /auth/verify-forgot-password-otp` — checks the reset code alone.
  ///
  /// The code screen used to accept whatever was typed and hand it to
  /// [resetPassword] two screens later, so a wrong or expired code surfaced as
  /// a failure on the *new password* form, which reads as "the password was
  /// rejected". This is the endpoint that belongs to that screen.
  // TODO(backend, blocking): confirm this check does not consume the reset code
  // — `POST /auth/reset-password` requires the same `otp` a moment later, and
  // its summary ("verify otp and reset password") reads as though it verifies
  // the code itself. If it does consume, every reset fails at the last step and
  // the app can only send the user back for another code, forever — expects:
  // confirmation that a code may be verified and then spent, or the endpoint
  // that returns a one-shot reset token instead
  Future<void> verifyResetOtp({
    required String email,
    required String otp,
  }) => post<void>(
    AuthEndpoints.verifyForgotPasswordOtp,
    body: AuthRequests.verifyResetOtp(email: email, otp: otp),
    authenticated: false,
  );

  /// `POST /auth/reset-password` — OTP-based, not token-based.
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) => post<void>(
    AuthEndpoints.resetPassword,
    body: AuthRequests.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    ),
    authenticated: false,
  );

  /// `POST /auth/change-password` — signed-in change, current password known.
  ///
  /// Authenticated (the only path here besides [logout] that is): the spec
  /// secures it with bearer auth alone, so the default interceptor header is
  /// exactly right and `authenticated: false` must NOT be passed. 200 with no
  /// documented body on success.
  ///
  /// [SkifluxErrorKind.settingsSaveFailed] rather than
  /// [SkifluxErrorKind.authFailed]: this is not a sign-in, and the authFailed
  /// modal's "We couldn't sign you in" copy would be wrong on the Change
  /// Password screen.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) => post<void>(
    AuthEndpoints.changePassword,
    body: AuthRequests.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmNewPassword: confirmNewPassword,
    ),
    kind: SkifluxErrorKind.settingsSaveFailed,
  );

  /// `POST /auth/social/mobile/google` — [idToken] comes from the native SDK.
  Future<AuthTokens> googleSignIn({required String idToken}) => _authenticate(
    AuthEndpoints.googleMobile,
    AuthRequests.socialLogin(idToken: idToken),
  );

  /// `POST /auth/social/mobile/apple`.
  Future<AuthTokens> appleSignIn({required String idToken}) => _authenticate(
    AuthEndpoints.appleMobile,
    AuthRequests.socialLogin(idToken: idToken),
  );

  /// `POST /auth/logout` — blacklists the refresh token server-side, then
  /// clears the keychain.
  ///
  /// The local clear runs even when the network call fails: a user who taps
  /// sign out must end up signed out on this device regardless. The failure is
  /// swallowed for that reason — a blacklist that didn't happen is a
  /// server-side concern the user can do nothing about, and the token is gone
  /// locally either way.
  Future<void> logout() async {
    final current = _tokens.cached ?? await _tokens.read();
    try {
      if (current != null) {
        await post<void>(AuthEndpoints.logout, body: current.refreshPayload);
      }
    } on SkifluxFailure {
      // Intentionally ignored — see above.
    } finally {
      await _tokens.clear();
    }
  }

  /// True when a token pair is on this device — the cheap check the profile
  /// auth gate and the biometric path use. Does not validate with the server.
  Future<bool> hasSession() => _tokens.hasSession();

  /// Shared POST-then-persist for the three endpoints that mint a session.
  Future<AuthTokens> _authenticate(String path, Map<String, dynamic> body) =>
      guard(() async {
        final tokens = await post<AuthTokens>(
          path,
          body: body,
          parse: AuthTokens.fromJson,
          authenticated: false,
        );
        if (tokens == null) {
          throw const FormatException('Auth response had no JSON body');
        }
        await _tokens.write(tokens);
        return tokens;
      });
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  ),
);
