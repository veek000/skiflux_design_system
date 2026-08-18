/// The mapping layer around the two social SDKs.
///
/// The platform seams on [SocialAuthService] are overridden rather than mocked
/// through a method channel: what is worth testing here is the translation of
/// each SDK's error vocabulary into the app's, and above all that a cancelled
/// picker is not treated as a failure.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:skiflux/features/auth/data/social_auth.dart';
import 'package:skiflux/shared/error_handling/error_handler.dart';

/// A service whose four platform calls are scripted.
class _FakeSocialAuth extends SocialAuthService {
  _FakeSocialAuth({
    super.googleServerClientId = 'web-client-id.apps.googleusercontent.com',
    this.googleResult,
    this.googleError,
    this.appleResult,
    this.appleError,
    this.appleIsAvailable = true,
    this.appleAvailabilityThrows = false,
    this.applePlatform = true,
  });

  final String? googleResult;
  final Object? googleError;
  final AuthorizationCredentialAppleID? appleResult;
  final Object? appleError;
  final bool appleIsAvailable;
  final bool appleAvailabilityThrows;

  /// What `defaultTargetPlatform` would say. Defaults to an Apple platform so
  /// the tests below are about the plugin probe; the platform gate itself has
  /// its own cases.
  @override
  final bool applePlatform;

  int initializeCount = 0;

  @override
  Future<void> initializeGoogle() async => initializeCount++;

  @override
  Future<String?> authenticateGoogle() async {
    if (googleError != null) throw googleError!;
    return googleResult;
  }

  @override
  Future<AuthorizationCredentialAppleID> requestAppleCredential() async {
    if (appleError != null) throw appleError!;
    return appleResult!;
  }

  @override
  Future<bool> checkAppleAvailable() async {
    if (appleAvailabilityThrows) throw StateError('plugin unavailable');
    return appleIsAvailable;
  }
}

AuthorizationCredentialAppleID _appleCredential({String? identityToken}) =>
    AuthorizationCredentialAppleID(
      userIdentifier: 'user-1',
      givenName: null,
      familyName: null,
      email: null,
      identityToken: identityToken,
      authorizationCode: 'code',
      state: null,
    );

void main() {
  group('SocialAuthService — Google', () {
    test('returns the id_token from a completed flow', () async {
      final service = _FakeSocialAuth(googleResult: 'google-id-token');
      expect(await service.googleIdToken(), 'google-id-token');
    });

    test('initializes once across repeated sign-ins', () async {
      final service = _FakeSocialAuth(googleResult: 'google-id-token');
      await service.googleIdToken();
      await service.googleIdToken();
      expect(service.initializeCount, 1);
    });

    test('returns null when the user dismisses the picker', () async {
      final service = _FakeSocialAuth(
        googleError: const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        ),
      );
      expect(await service.googleIdToken(), isNull);
    });

    test('maps a real SDK failure to authFailed', () async {
      final service = _FakeSocialAuth(
        googleError: const GoogleSignInException(
          code: GoogleSignInExceptionCode.providerConfigurationError,
        ),
      );
      await expectLater(
        service.googleIdToken(),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.authFailed,
          ),
        ),
      );
    });

    test('fails rather than posting an empty token when none is minted', () {
      // The picker succeeding with a null id_token means the server client ID
      // is wrong — a silent null here would send `{"id_token": ""}`.
      final service = _FakeSocialAuth(googleResult: null);
      expect(
        service.googleIdToken(),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.authFailed,
          ),
        ),
      );
    });

    test('an unconfigured build reports a failure, not a cancel', () async {
      final service = _FakeSocialAuth(
        googleServerClientId: '',
        googleResult: 'unused',
      );
      expect(service.googleConfigured, isFalse);
      await expectLater(
        service.googleIdToken(),
        throwsA(isA<SkifluxFailure>()),
      );
      // Never reached the SDK.
      expect(service.initializeCount, 0);
    });
  });

  group('SocialAuthService — Apple', () {
    test('returns the identityToken from a completed flow', () async {
      final service = _FakeSocialAuth(
        appleResult: _appleCredential(identityToken: 'apple-id-token'),
      );
      expect(await service.appleIdToken(), 'apple-id-token');
    });

    test('returns null when the user cancels the dialog', () async {
      final service = _FakeSocialAuth(
        appleError: const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'cancelled',
        ),
      );
      expect(await service.appleIdToken(), isNull);
    });

    test('maps other authorization errors to authFailed', () async {
      final service = _FakeSocialAuth(
        appleError: const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.failed,
          message: 'failed',
        ),
      );
      await expectLater(
        service.appleIdToken(),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.authFailed,
          ),
        ),
      );
    });

    test('maps the non-authorization exceptions too', () async {
      final service = _FakeSocialAuth(
        appleError: const SignInWithAppleCredentialsException(
          message: 'no credentials',
        ),
      );
      await expectLater(
        service.appleIdToken(),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.authFailed,
          ),
        ),
      );
    });

    test('a credential with no token fails', () async {
      final service = _FakeSocialAuth(appleResult: _appleCredential());
      await expectLater(
        service.appleIdToken(),
        throwsA(isA<SkifluxFailure>()),
      );
    });

    test('availability is reported, and a broken probe reads as unavailable', () async {
      expect(await _FakeSocialAuth().appleAvailable(), isTrue);
      expect(
        await _FakeSocialAuth(appleIsAvailable: false).appleAvailable(),
        isFalse,
      );
      expect(
        await _FakeSocialAuth(appleAvailabilityThrows: true).appleAvailable(),
        isFalse,
      );
    });

    test('a non-Apple platform is unavailable even when the plugin says yes',
        () async {
      // `SignInWithApple.isAvailable()` returns true on Android — the plugin
      // counts its web-redirect fallback, which needs a Service ID we do not
      // have. Trusting it would run a flow that can only fail; the button is
      // still shown, and `auth_flow.dart` answers the tap with "coming soon".
      expect(
        await _FakeSocialAuth(applePlatform: false, appleIsAvailable: true)
            .appleAvailable(),
        isFalse,
      );
    });

    test('the real gate follows defaultTargetPlatform', () {
      // Guards the production getter itself, which the fake replaces above.
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(SocialAuthService().applePlatform, isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(SocialAuthService().applePlatform, isTrue);
    });
  });

  group('SocialAuthService — Google availability', () {
    test('reports whether a server client ID was compiled in', () {
      // Never hidden in the UI: `auth_flow.dart` swaps the tap for a "coming
      // soon" message instead of removing the control.
      expect(_FakeSocialAuth().googleConfigured, isTrue);
      expect(
        SocialAuthService(googleServerClientId: '').googleConfigured,
        isFalse,
      );
    });
  });
}

