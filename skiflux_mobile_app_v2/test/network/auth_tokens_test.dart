import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/shared/network/auth_tokens.dart';

void main() {
  group('AuthTokens.fromJson', () {
    // Tracker 61b: the spec documents these responses in prose only, so the
    // adapter accepts every plausible spelling. These tests pin that tolerance
    // — when the backend dev confirms the real shape, the extra cases become
    // harmless rather than wrong.
    test('reads SimpleJWT default access/refresh', () {
      final tokens = AuthTokens.fromJson({
        'access': 'a-token',
        'refresh': 'r-token',
      });
      expect(tokens.access, 'a-token');
      expect(tokens.refresh, 'r-token');
    });

    test('reads the OAuth-style access_token/refresh_token spelling', () {
      final tokens = AuthTokens.fromJson({
        'access_token': 'a-token',
        'refresh_token': 'r-token',
      });
      expect(tokens.access, 'a-token');
      expect(tokens.refresh, 'r-token');
    });

    test('reads camelCase', () {
      final tokens = AuthTokens.fromJson({
        'accessToken': 'a-token',
        'refreshToken': 'r-token',
      });
      expect(tokens.access, 'a-token');
    });

    test('unwraps a nested tokens/data envelope', () {
      final tokens = AuthTokens.fromJson({
        'user': {'id': 'u-1'},
        'tokens': {'access': 'a-token', 'refresh': 'r-token'},
      });
      expect(tokens.access, 'a-token');
      expect(tokens.refresh, 'r-token');
    });

    test('keeps the current refresh token when the response omits one', () {
      // SimpleJWT only returns a new refresh token when rotation is enabled.
      final tokens = AuthTokens.fromJson(
        {'access': 'fresh-access'},
        fallbackRefresh: 'kept-refresh',
      );
      expect(tokens.access, 'fresh-access');
      expect(tokens.refresh, 'kept-refresh');
    });

    test('throws when no access token is recognisable', () {
      expect(
        () => AuthTokens.fromJson({'detail': 'Invalid credentials'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when no refresh token is available at all', () {
      expect(
        () => AuthTokens.fromJson({'access': 'a-token'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('ignores empty-string tokens rather than accepting them', () {
      expect(
        () => AuthTokens.fromJson({'access': '', 'refresh': 'r'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('refreshPayload matches the spec body for refresh and logout', () {
    const tokens = AuthTokens(access: 'a', refresh: 'r');
    expect(tokens.refreshPayload, {'refresh_token': 'r'});
  });

  test('toString never leaks token material', () {
    const tokens = AuthTokens(access: 'secret-access', refresh: 'secret-r');
    expect(tokens.toString(), isNot(contains('secret')));
  });

  test('value equality', () {
    expect(
      const AuthTokens(access: 'a', refresh: 'r'),
      const AuthTokens(access: 'a', refresh: 'r'),
    );
  });
}
