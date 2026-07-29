/// Auth endpoint paths and request bodies, exactly as the OpenAPI spec defines
/// them.
///
/// The spec's names differ from what the app's `TODO(backend)` tags guessed —
/// verify is `verify-register-email`, reset is OTP-based rather than
/// token-based, signup requires `password_confirm`, and social sign-in is two
/// endpoints rather than one with a `provider` field. Those corrections live
/// here so no screen carries a stale assumption.
///
/// Every path below is public (`- {}` security in the spec) except
/// [logout], which needs a valid access token to blacklist the refresh token.
library;

abstract final class AuthEndpoints {
  static const signup = '/auth/signup';
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const refresh = '/auth/token/refresh';

  /// Spec name: NOT `/auth/verify`.
  static const verifyRegisterEmail = '/auth/verify-register-email';
  static const resendRegisterOtp = '/auth/resend-register-otp';

  static const forgotPassword = '/auth/forgot-password';

  /// Checks the reset code on its own. Distinct from
  /// [verifyRegisterEmail] — `resend-register-otp` and the register verify only
  /// ever handle the *signup* code, and sending a reset code to them fails.
  static const verifyForgotPasswordOtp = '/auth/verify-forgot-password-otp';

  /// OTP-based, not token-based — the app's original expectation was wrong.
  static const resetPassword = '/auth/reset-password';

  /// Two distinct endpoints, each taking an `id_token` from the native SDK.
  static const googleMobile = '/auth/social/mobile/google';
  static const appleMobile = '/auth/social/mobile/apple';
}

/// Request bodies. snake_case is the wire format; these builders are the only
/// place that mapping happens for auth.
abstract final class AuthRequests {
  /// `POST /auth/signup`. `password_confirm` is required by the spec — the app
  /// already collects it, it simply wasn't being sent.
  static Map<String, dynamic> signup({
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
    String? username,
  }) => {
    'email': email.trim(),
    'password': password,
    'password_confirm': passwordConfirm,
    if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
    if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
    if (username != null && username.isNotEmpty) 'username': username,
  };

  static Map<String, dynamic> login({
    required String email,
    required String password,
  }) => {'email': email.trim(), 'password': password};

  static Map<String, dynamic> verifyEmail({
    required String email,
    required String otp,
  }) => {'email': email.trim(), 'otp': otp};

  static Map<String, dynamic> resendOtp({required String email}) => {
    'email': email.trim(),
  };

  static Map<String, dynamic> forgotPassword({required String email}) => {
    'email': email.trim(),
  };

  /// `POST /auth/verify-forgot-password-otp` — same two fields as
  /// [verifyEmail], against the reset code rather than the signup one.
  static Map<String, dynamic> verifyResetOtp({
    required String email,
    required String otp,
  }) => {'email': email.trim(), 'otp': otp};

  /// `POST /auth/reset-password` — OTP plus both password fields.
  static Map<String, dynamic> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) => {
    'email': email.trim(),
    'otp': otp,
    'new_password': newPassword,
    'confirm_new_password': confirmNewPassword,
  };

  static Map<String, dynamic> socialLogin({required String idToken}) => {
    'id_token': idToken,
  };
}
