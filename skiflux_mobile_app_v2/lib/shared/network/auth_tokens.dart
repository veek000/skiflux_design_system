/// The single place that knows what an auth response looks like.
///
/// Tracker item 61b: `POST /auth/login`, `/auth/signup`, `/auth/token/refresh`
/// and both mobile social logins have description-only responses in the OpenAPI
/// spec — no schema. The descriptions promise an access and a refresh token but
/// not the field names. [AuthTokens.fromJson] therefore accepts every plausible
/// spelling; when the backend dev confirms the real shape, correcting it is an
/// edit to this one file and nothing else moves.
library;

/// An access/refresh token pair.
class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;

  /// Candidate key names, most-likely first. `access`/`refresh` is
  /// SimpleJWT's default (the spec is DRF), `access_token`/`refresh_token` is
  /// the OAuth-style spelling the endpoint descriptions use in prose.
  static const _accessKeys = ['access', 'access_token', 'accessToken', 'token'];
  static const _refreshKeys = ['refresh', 'refresh_token', 'refreshToken'];

  /// Reads a token pair out of a login/signup/refresh body.
  ///
  /// Tolerates the pair being nested under a `tokens`, `data` or `session`
  /// wrapper, since the prose doesn't say whether it's flat. A refresh
  /// response legitimately omits the refresh token (SimpleJWT only rotates it
  /// when configured to), so [fallbackRefresh] keeps the stored one alive.
  static AuthTokens fromJson(
    Map<String, dynamic> json, {
    String? fallbackRefresh,
  }) {
    final source = _unwrap(json);
    final access = _firstString(source, _accessKeys);
    if (access == null) {
      throw const FormatException(
        'Auth response contained no recognisable access token',
      );
    }
    final refresh = _firstString(source, _refreshKeys) ?? fallbackRefresh;
    if (refresh == null) {
      throw const FormatException(
        'Auth response contained no recognisable refresh token',
      );
    }
    return AuthTokens(access: access, refresh: refresh);
  }

  /// Like [fromJson] but returns null instead of throwing when the body holds
  /// no token pair.
  ///
  /// For endpoints where a session is legitimately optional — the spec
  /// documents no schema for `verify-register-email`, and backends split on
  /// whether OTP verification mints a session or expects a follow-up login.
  /// Absence is a routing decision there, not a parse error.
  static AuthTokens? tryFromJson(
    Map<String, dynamic>? json, {
    String? fallbackRefresh,
  }) {
    if (json == null) return null;
    try {
      return fromJson(json, fallbackRefresh: fallbackRefresh);
    } on FormatException {
      return null;
    }
  }

  /// Returns the nested map holding the tokens, or [json] itself when flat.
  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    if (_firstString(json, _accessKeys) != null) return json;
    for (final key in const ['tokens', 'data', 'session', 'result']) {
      final nested = json[key];
      if (nested is Map<String, dynamic> &&
          _firstString(nested, _accessKeys) != null) {
        return nested;
      }
    }
    return json;
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Body for `POST /auth/token/refresh` and `POST /auth/logout`, both of
  /// which take the refresh token per the spec.
  Map<String, dynamic> get refreshPayload => {'refresh_token': refresh};

  AuthTokens copyWith({String? access, String? refresh}) =>
      AuthTokens(access: access ?? this.access, refresh: refresh ?? this.refresh);

  @override
  bool operator ==(Object other) =>
      other is AuthTokens && other.access == access && other.refresh == refresh;

  @override
  int get hashCode => Object.hash(access, refresh);

  /// Deliberately opaque — token material must never reach a log or Sentry
  /// breadcrumb.
  @override
  String toString() => 'AuthTokens(access: ***, refresh: ***)';
}
