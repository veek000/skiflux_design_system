/// The single place that knows what an auth response looks like.
///
/// **Tracker 61b is answered.** `POST /auth/login` and both mobile social
/// logins now document `AuthTokenResponse` — `{access_token, refresh_token,
/// user}` — and `/auth/token/refresh` documents `RefreshTokenResponse`
/// (`{access_token, refresh_token}`, no user). The documented spelling is
/// tried first below; the other spellings are kept because they cost a list
/// entry and a backend still in motion may yet move.
library;

/// The learner the tokens belong to — `AuthTokenUser`, sent alongside a login
/// or social sign-in but **not** by a refresh.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isOnboarded,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;

  /// Whether `POST /profile/complete-onboarding/` has run for this account.
  ///
  /// False means the account exists but has no username, goal or skillworld —
  /// so signing in must land in the wizard, not on a Home built around a
  /// profile that isn't there.
  final bool isOnboarded;

  final String? username;
  final String? avatarUrl;

  static AuthUser? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    return AuthUser(
      id: id,
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      // Absent is NOT "not onboarded" — see [AuthTokens.needsOnboarding].
      isOnboarded: json['is_onboarded'] as bool? ?? true,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// An access/refresh token pair, plus whoever it belongs to.
class AuthTokens {
  const AuthTokens({required this.access, required this.refresh, this.user});

  final String access;
  final String refresh;

  /// Null on a refresh, and on any response that omits the object.
  final AuthUser? user;

  /// Whether this sign-in should be routed into the onboarding wizard.
  ///
  /// Only an explicit `is_onboarded: false` counts. A missing `user` object
  /// must mean "carry on as before" — reading absence as "not onboarded" would
  /// march every existing learner back through the wizard the first time a
  /// response shape wobbled.
  bool get needsOnboarding => user?.isOnboarded == false;

  /// Candidate key names, documented spelling first.
  static const _accessKeys = ['access_token', 'access', 'accessToken', 'token'];
  static const _refreshKeys = ['refresh_token', 'refresh', 'refreshToken'];

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
    // `user` sits beside the tokens, so read it from whichever level they came
    // from — and fall back to the outer body in case only the pair was nested.
    return AuthTokens(
      access: access,
      refresh: refresh,
      user: AuthUser.tryFromJson(source['user']) ??
          AuthUser.tryFromJson(json['user']),
    );
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

  AuthTokens copyWith({String? access, String? refresh}) => AuthTokens(
    access: access ?? this.access,
    refresh: refresh ?? this.refresh,
    user: user,
  );

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
