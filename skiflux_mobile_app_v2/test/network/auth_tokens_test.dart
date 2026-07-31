import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/shared/network/auth_tokens.dart';

void main() {
  group('AuthTokens.fromJson', () {
    // Tracker 61b is answered: `AuthTokenResponse` documents
    // `{access_token, refresh_token, user}`. The other spellings below are kept
    // as tolerance, not as guesses.
    test('reads the documented AuthTokenResponse', () {
      final tokens = AuthTokens.fromJson({
        'access_token': 'a-token',
        'refresh_token': 'r-token',
        'user': {
          'id': 'u-1',
          'email': 'veek@skiflux.app',
          'first_name': 'Veek',
          'last_name': 'O',
          'is_onboarded': true,
          'username': 'veek',
          'avatar_url': 'https://cdn/veek.png',
        },
      });

      expect(tokens.access, 'a-token');
      expect(tokens.refresh, 'r-token');
      expect(tokens.user?.id, 'u-1');
      expect(tokens.user?.email, 'veek@skiflux.app');
      expect(tokens.user?.username, 'veek');
      expect(tokens.user?.isOnboarded, isTrue);
      expect(tokens.needsOnboarding, isFalse);
    });

    test('is_onboarded false is what routes a sign-in into the wizard', () {
      final tokens = AuthTokens.fromJson({
        'access_token': 'a',
        'refresh_token': 'r',
        'user': {
          'id': 'u-2',
          'email': 'new@skiflux.app',
          'first_name': 'New',
          'last_name': 'User',
          'is_onboarded': false,
        },
      });

      expect(tokens.needsOnboarding, isTrue);
      expect(tokens.user?.username, isNull);
    });

    test('a missing user object never means "not onboarded"', () {
      // A refresh sends no user, and a wobble in the login shape must not march
      // an existing learner back through the wizard.
      final refresh = AuthTokens.fromJson({
        'access_token': 'a',
        'refresh_token': 'r',
      });
      expect(refresh.user, isNull);
      expect(refresh.needsOnboarding, isFalse);

      // Same for a user object too malformed to identify.
      final malformed = AuthTokens.fromJson({
        'access_token': 'a',
        'refresh_token': 'r',
        'user': {'email': 'no-id@skiflux.app'},
      });
      expect(malformed.user, isNull);
      expect(malformed.needsOnboarding, isFalse);
    });

    test('finds the user beside nested tokens', () {
      final tokens = AuthTokens.fromJson({
        'data': {
          'access_token': 'a',
          'refresh_token': 'r',
          'user': {
            'id': 'u-3',
            'email': 'n@skiflux.app',
            'first_name': 'N',
            'last_name': 'O',
            'is_onboarded': false,
          },
        },
      });
      expect(tokens.needsOnboarding, isTrue);
    });

    test('copyWith keeps the user', () {
      final tokens = AuthTokens.fromJson({
        'access_token': 'a',
        'refresh_token': 'r',
        'user': {
          'id': 'u-4',
          'email': 'e@skiflux.app',
          'first_name': 'E',
          'last_name': 'O',
          'is_onboarded': false,
        },
      });
      expect(tokens.copyWith(access: 'a2').needsOnboarding, isTrue);
    });

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
