/// Native social sign-in — the `id_token` producers behind
/// `AuthRepository.googleSignIn` / `appleSignIn`.
///
/// The backend's two mobile social endpoints each take a provider `id_token`
/// and nothing else, so this layer's whole job is: run the platform's account
/// picker, hand back the token, and translate the SDKs' error vocabularies into
/// the app's own. It never talks to the API and never persists anything — that
/// stays in [AuthRepository].
///
/// Three rules the callers depend on:
///  * **Cancel is not an error.** A dismissed sheet returns `null`, so the UI
///    just re-enables the button instead of showing a failure.
///  * **Everything else is [SkifluxErrorKind.authFailed]**, including missing
///    client-ID config — a build without credentials must not reach the network
///    and get a confusing 400 back.
///  * **No token material is ever logged.** The SDK exception's `description`
///    is deliberately not interpolated into any message; it is attached as
///    [SkifluxFailure.cause] for the crash reporter's scrubbed path only.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../config/env_config.dart';
import '../../../shared/error_handling/error_handler.dart';

/// Obtains provider `id_token`s for the two social endpoints.
///
/// Split into overridable seams ([initializeGoogle], [authenticateGoogle],
/// [requestAppleCredential], [checkAppleAvailable]) rather than mocking the
/// plugins: the mapping logic above them is the part worth testing, and it can
/// then be exercised without a platform channel. See
/// `test/features/auth/social_auth_test.dart`.
class SocialAuthService {
  SocialAuthService({String? googleServerClientId, String? googleIosClientId})
    : _serverClientId = googleServerClientId ?? EnvConfig.googleServerClientId,
      _iosClientId = googleIosClientId ?? EnvConfig.googleIosClientId;

  final String _serverClientId;
  final String _iosClientId;

  /// `initialize()` is once-per-process in google_sign_in 7.x, and calling
  /// `authenticate()` before it completes throws. Holding the future (not a
  /// bool) makes two buttons tapped in quick succession await the same call.
  Future<void>? _googleInitialization;

  /// Whether the Google flow can actually mint an `id_token` on this build.
  ///
  /// Never hides the button — `auth_flow.dart` draws both providers always and
  /// swaps the tap for a "coming soon" toast. This only decides which of the
  /// two a tap gets.
  ///
  /// When no server client ID was compiled in the SDK returns an access token
  /// but a **null `idToken`**, which the endpoint cannot use, so running the
  /// flow anyway would spend the user's attention on a picker and end in a
  /// generic sign-in failure.
  bool get googleConfigured => _serverClientId.isNotEmpty;

  /// Whether Sign in with Apple can actually complete on this platform.
  ///
  /// **Not** `SignInWithApple.isAvailable()` — that returns `true` on Android,
  /// where the plugin falls back to a web redirect that needs a Service ID and
  /// return URL we do not have yet (see the `TODO(backend)` below). Gate on the
  /// platform instead: iOS and macOS offer the native sheet, and the plugin's
  /// own check still has the last word there for the OS-version floor (iOS 13 /
  /// macOS 10.15).
  ///
  /// Like [googleConfigured] this decides what the tap does, not whether the
  /// button exists.
  Future<bool> appleAvailable() async {
    if (!applePlatform) return false;
    try {
      return await checkAppleAvailable();
    } on Object {
      // Availability is a nice-to-have: a plugin that cannot answer means the
      // user is told "coming soon", never that sign-in breaks.
      return false;
    }
  }

  /// Split out so tests can drive the platform decision without a real one.
  ///
  /// Not `@protected` like the other seams: the test reads it directly to pin
  /// the production behaviour, rather than only overriding it.
  @visibleForTesting
  bool get applePlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Runs Google's account picker. Returns the `id_token`, or `null` if the
  /// user backed out.
  Future<String?> googleIdToken() async {
    if (!googleConfigured) {
      throw const SkifluxFailure(
        SkifluxErrorKind.authFailed,
        cause: 'GOOGLE_SERVER_CLIENT_ID missing from the build configuration.',
      );
    }
    try {
      await _ensureGoogleInitialized();
      final idToken = await authenticateGoogle();
      if (idToken == null || idToken.isEmpty) {
        // Reached when the server client ID is present but wrong (or belongs to
        // a different project): the picker succeeds and the token is empty.
        throw const SkifluxFailure(
          SkifluxErrorKind.authFailed,
          cause: 'Google returned no id_token — check GOOGLE_SERVER_CLIENT_ID '
              'is the backend project\'s **Web** OAuth client.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error, stackTrace) {
      // The enum is documented as open — new codes are not a breaking change —
      // so this matches the one benign code and treats the rest as failure.
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw SkifluxFailure(
        SkifluxErrorKind.authFailed,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Runs Sign in with Apple. Returns the identity token, or `null` on cancel.
  ///
  /// Apple only sends the name and email on the *first* authorization, so
  /// neither is read here: the backend has the same token and is the only place
  /// that can store them durably.
  Future<String?> appleIdToken() async {
    try {
      final credential = await requestAppleCredential();
      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw const SkifluxFailure(
          SkifluxErrorKind.authFailed,
          cause: 'Apple returned no identityToken.',
        );
      }
      return identityToken;
    } on SignInWithAppleAuthorizationException catch (error, stackTrace) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      throw SkifluxFailure(
        SkifluxErrorKind.authFailed,
        cause: error,
        stackTrace: stackTrace,
      );
    } on SignInWithAppleException catch (error, stackTrace) {
      throw SkifluxFailure(
        SkifluxErrorKind.authFailed,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Drops the cached Google account so the next tap shows the picker again.
  ///
  /// Called on sign-out: without it Google silently reuses the last account and
  /// "Switch accounts" cannot switch anything. Apple has no equivalent — its
  /// credential is not cached by the app.
  Future<void> signOut() async {
    if (!googleConfigured) return;
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } on Object catch (error) {
      // Sign-out must always succeed locally; a provider that refuses to clear
      // its cache cannot block it.
      debugPrint('[SocialAuth] Google signOut ignored: ${error.runtimeType}');
    }
  }

  Future<void> _ensureGoogleInitialized() =>
      _googleInitialization ??= initializeGoogle();

  // ── Platform seams (overridden in tests) ───────────────────────────

  /// `serverClientId` is what makes `idToken` non-null; `clientId` is the iOS
  /// OAuth client and is ignored on Android, which matches its own client by
  /// package name + signing SHA-1 instead.
  @protected
  @visibleForTesting
  Future<void> initializeGoogle() => GoogleSignIn.instance.initialize(
    clientId: _iosClientId.isEmpty ? null : _iosClientId,
    serverClientId: _serverClientId,
  );

  /// `authenticate()` replaced 7.x's removed `signIn()`. No `scopeHint`: the
  /// backend needs identity only, and every extra scope is another consent row.
  ///
  /// Returns the token rather than the [GoogleSignInAccount] it came on:
  /// `GoogleSignInAccount` has a private constructor, so a seam typed to it
  /// could not be faked in a test at all.
  @protected
  @visibleForTesting
  Future<String?> authenticateGoogle() async =>
      (await GoogleSignIn.instance.authenticate()).authentication.idToken;

  /// TODO(backend, minor): supply an Apple Service ID + redirect URI so Sign in with Apple can run on Android via WebAuthenticationOptions — expects: Service ID (e.g. com.skiflux.web) and the https return URL registered with Apple
  @protected
  @visibleForTesting
  Future<AuthorizationCredentialAppleID> requestAppleCredential() =>
      SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

  @protected
  @visibleForTesting
  Future<bool> checkAppleAvailable() => SignInWithApple.isAvailable();
}

/// Plain [Provider] — the service holds only the once-per-process Google
/// initialization future, no observable state.
final socialAuthServiceProvider = Provider<SocialAuthService>(
  (ref) => SocialAuthService(),
);
