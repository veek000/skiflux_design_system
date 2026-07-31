/// Auth flow state, and the seam between the Figma flow and the real backend.
///
/// [AuthFlowNotifier] owns the stage machine and calls [AuthRepository] for
/// every step that talks to the server. The screens stay dumb: they hand up
/// what the user typed and render [AuthFlowState.signInError] / [AuthFlowState
/// .submitting], and they never see a `Dio` type or an HTTP status.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/data/session_email_store.dart';
import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/network/auth_tokens.dart';
import '../../profile/data/profile_repository.dart';
import 'auth_repository.dart';
import 'biometric_store.dart';
import 'social_auth.dart';

/// The stages of the Figma onboarding and authentication flow.
enum AuthStage {
  splash,

  /// All three Figma onboarding frames — they are a single swipeable screen.
  onboarding,
  createAccount,
  verifyEmail,
  emailVerified,
  signIn,
  forgottenPassword,
  verifyReset,
  resetPassword,
  passwordUpdated,
  fingerprint,
  faceId,
  claimIdentity,
  whatBringsYouHere,
  chooseSkillworld,

  /// "Welcome to Skiflux" (`2902:12537`) — the sign-up payoff screen, shown
  /// after a world is chosen and before the app itself.
  welcome,
  terms,
  privacy,
}

@immutable
class AuthFlowState {
  const AuthFlowState({
    required this.stage,
    this.username = '',
    this.avatarPath,
    this.goal,
    this.skillworld,
    this.signInError,
    this.legalReturn = AuthStage.onboarding,
    this.passwordOnly = false,
    this.email = '',
    this.submitting = false,
    this.needsOnboarding = false,
  });

  final AuthStage stage;
  final String username;

  /// Local file path of the avatar picked on "Claim your identity"
  /// (`198:16222`). Null until the user uploads one — that is what switches the
  /// frame from its default to its filled variant.
  final String? avatarPath;
  final String? goal;
  final String? skillworld;
  final String? signInError;

  /// Where the back chevron on a legal document returns to. The legal pages are
  /// reachable from both onboarding and sign-up, so the stage that opened them
  /// has to be remembered rather than assumed — see [AuthFlowNotifier.showLegal].
  final AuthStage legalReturn;

  /// Set when the user chooses "Login with Password" on the biometric gate.
  /// The gate is then skipped for the rest of this attempt — without it, the
  /// password they are being sent to type would just hand them straight back
  /// to the gate they were trying to leave.
  final bool passwordOnly;

  /// The address the user actually signed up or signed in with.
  ///
  /// Carried through the flow because the verify, reset and biometric frames
  /// print it, and because `verify-register-email`, `resend-register-otp` and
  /// `reset-password` all take the email in the body rather than a token.
  final String email;

  /// A request is in flight. Screens disable their CTA on this so a second tap
  /// can't fire a duplicate signup or spend an OTP twice.
  final bool submitting;

  /// The account that just signed in has never completed the wizard —
  /// `AuthTokenResponse.user.is_onboarded` was explicitly `false`.
  ///
  /// It has no username, goal or skillworld, so the flow sends it through
  /// "Claim your identity" instead of into an app whose profile screens have
  /// nothing to render. Absence of the flag leaves this false: see
  /// [AuthTokens.needsOnboarding].
  final bool needsOnboarding;

  AuthFlowState copyWith({
    AuthStage? stage,
    String? username,
    String? avatarPath,
    String? goal,
    String? skillworld,
    String? signInError,
    AuthStage? legalReturn,
    bool? passwordOnly,
    String? email,
    bool? submitting,
    bool? needsOnboarding,
    bool clearError = false,
  }) => AuthFlowState(
    stage: stage ?? this.stage,
    username: username ?? this.username,
    avatarPath: avatarPath ?? this.avatarPath,
    goal: goal ?? this.goal,
    skillworld: skillworld ?? this.skillworld,
    signInError: clearError ? null : signInError ?? this.signInError,
    legalReturn: legalReturn ?? this.legalReturn,
    passwordOnly: passwordOnly ?? this.passwordOnly,
    email: email ?? this.email,
    submitting: submitting ?? this.submitting,
    needsOnboarding: needsOnboarding ?? this.needsOnboarding,
  );
}

final authFlowProvider = NotifierProvider<AuthFlowNotifier, AuthFlowState>(
  AuthFlowNotifier.new,
);

/// Where a cold start lands once the splash has played — see
/// [AuthFlowNotifier.resolveColdStart].
enum ColdStartDestination {
  /// No session on the device: the marketing carousel, exactly as before.
  marketingOnboarding,

  /// A session exists and the user opted into biometric login on a device
  /// that can offer it: quick unlock guards the stored session.
  biometricGate,

  /// A session exists with no biometric gate to pass: straight to Home.
  enterApp,
}

/// The copy the login frames match on to decide which field wears the error
/// treatment (`24:4068` email, `24:1497` password).
///
/// Kept here rather than in the screen because this notifier produces them and
/// `login_screen.dart` only compares against them.
const signInEmailError = 'No account found with this email';
const signInPasswordError = 'Incorrect password';

class AuthFlowNotifier extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthFlowState(stage: AuthStage.splash);

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  void show(AuthStage stage) => state = state.copyWith(stage: stage);

  /// Opens [stage] ([AuthStage.terms] or [AuthStage.privacy]) and records the
  /// current stage so the back chevron returns where the user came from.
  void showLegal(AuthStage stage) =>
      state = state.copyWith(stage: stage, legalReturn: state.stage);

  /// Leaves a legal document for the stage that opened it.
  void closeLegal() => state = state.copyWith(stage: state.legalReturn);

  void setUsername(String value) => state = state.copyWith(username: value);
  void setAvatarPath(String value) => state = state.copyWith(avatarPath: value);
  void setGoal(String value) => state = state.copyWith(goal: value);
  void setSkillworld(String value) => state = state.copyWith(skillworld: value);
  void clearError() => state = state.copyWith(clearError: true);

  /// "Login with Password" on the biometric gate — back to the form, with the
  /// gate disarmed so a correct password finishes the sign-in instead of
  /// returning to the screen the user just opted out of.
  void usePasswordInstead() => state = state.copyWith(
    stage: AuthStage.signIn,
    passwordOnly: true,
    clearError: true,
  );

  /// "Switch accounts" — a different user, so the gate preference applies
  /// again from scratch.
  void switchAccount() => state = state.copyWith(
    stage: AuthStage.signIn,
    passwordOnly: false,
    clearError: true,
  );

  /// Where onboarding "Login" should land for a returning user.
  ///
  /// Biometric is an **alternative** to password entry, never a step after it:
  /// - preference on **and** device can offer biometrics → biometric screen
  /// - otherwise → password [AuthStage.signIn]
  ///
  /// Pure decision helper — unit-tested without the plugin or network.
  static AuthStage returningSignInStage({
    required bool biometricLoginEnabled,
    required bool deviceCanBiometric,
  }) {
    if (biometricLoginEnabled && deviceCanBiometric) {
      return AuthStage.fingerprint;
    }
    return AuthStage.signIn;
  }

  /// Opens the returning-user sign-in path (onboarding "Login").
  ///
  /// Checks settings + device capability **before** showing a screen — does
  /// not chain biometrics after a successful password.
  Future<void> enterReturningSignIn({
    required bool biometricLoginEnabled,
    required Future<BiometricMode?> Function() availableMode,
  }) async {
    BiometricMode? mode;
    if (biometricLoginEnabled) {
      mode = await availableMode();
    }
    final stage = returningSignInStage(
      biometricLoginEnabled: biometricLoginEnabled,
      deviceCanBiometric: mode != null,
    );
    final cachedEmail = await ref.read(sessionEmailStoreProvider).read();
    state = state.copyWith(
      stage: stage,
      // Fresh entry: the password-only disarm from a prior attempt must not
      // stick across a new "Login" tap from onboarding.
      passwordOnly: false,
      clearError: true,
      email: cachedEmail ?? state.email,
    );
  }

  /// `POST /auth/login`. On success the token pair is already in the keychain
  /// (the repository persists it). Stage stays on [AuthStage.signIn] — the UI
  /// navigates to Home. Biometrics are never chained after password success.
  ///
  /// Returns true when the credentials were accepted, so the caller can tell a
  /// rejected sign-in from a successful one without re-reading the stage.
  Future<bool> signIn(String email, String password) async {
    if (state.submitting) return false;
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(signInError: signInEmailError);
      return false;
    }
    state = state.copyWith(submitting: true, clearError: true, email: trimmed);
    try {
      final tokens = await _repo.login(email: trimmed, password: password);
      await ref.read(sessionEmailStoreProvider).write(trimmed);
      state = state.copyWith(
        submitting: false,
        clearError: true,
        // Routed on by the flow: an account that never finished the wizard
        // goes to "Claim your identity", not to Home.
        needsOnboarding: tokens.needsOnboarding,
      );
      return true;
    } on SkifluxFailure catch (failure) {
      state = state.copyWith(
        submitting: false,
        signInError: _signInMessage(failure),
      );
      return false;
    }
  }

  /// `POST /auth/signup`, then the OTP stage.
  ///
  /// The spec's signup mints no session — verification does — so this only
  /// advances the flow. [email] is remembered because every following step
  /// (verify, resend) takes it in the body.
  Future<bool> signUp({
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) => _submit(
    email: email,
    action: () => _repo.signup(
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      firstName: firstName,
      lastName: lastName,
    ),
    next: AuthStage.verifyEmail,
  );

  /// `POST /auth/verify-register-email`.
  ///
  /// Whether verification hands back a session is undocumented and backends
  /// differ, so both are handled: with tokens the user is signed in and the
  /// flow continues to the payoff screen; without, they land on sign-in — which
  /// is also what the "Email Verified" screen's CTA leads to, so the difference
  /// is invisible.
  Future<bool> verifyEmail(String otp) => _submit(
    action: () => _repo.verifyEmail(email: state.email, otp: otp),
    next: AuthStage.emailVerified,
  );

  /// `POST /auth/resend-register-otp`. Used by both verify frames.
  Future<bool> resendOtp() => _submit(
    action: () => _repo.resendOtp(email: state.email),
  );

  /// Reissues a *reset* code. The same forgot-password call, without moving the
  /// stage — `resend-register-otp` only reissues the signup OTP.
  Future<bool> resendResetOtp() => _submit(
    action: () => _repo.forgotPassword(email: state.email),
  );

  /// `POST /auth/forgot-password` — sends the reset OTP, then the verify stage.
  Future<bool> forgotPassword(String email) => _submit(
    email: email,
    action: () => _repo.forgotPassword(email: email),
    next: AuthStage.verifyReset,
  );

  /// Holds the OTP the reset flow verified, since `POST /auth/reset-password`
  /// takes the code *and* the new password in one call — the app collects them
  /// on two consecutive screens.
  String? _resetOtp;

  /// The reset flow's verify step — `POST /auth/verify-forgot-password-otp`.
  ///
  /// The code screen used to advance unconditionally, holding whatever was
  /// typed for [resetPassword] to spend. A wrong or expired code then failed on
  /// the *new password* screen, which is the "it just shows an error and
  /// doesn't proceed" the flow was reported for: the message belonged two
  /// screens earlier and said nothing about the code. Checking it here keeps
  /// the rejection on the screen that can fix it.
  ///
  /// The code is still held and sent again by [resetPassword] — the spec
  /// requires `otp` in that body, and its own summary is "verify otp and reset
  /// password", so this call is a check rather than a step that consumes it.
  Future<bool> verifyResetOtp(String otp) {
    _resetOtp = otp;
    return _submit(
      action: () => _repo.verifyResetOtp(email: state.email, otp: otp),
      next: AuthStage.resetPassword,
    );
  }

  /// `POST /auth/reset-password` — OTP-based, not token-based.
  ///
  /// Never posts an empty `otp`: the spec requires exactly six characters, so
  /// a missing code is a 400 that reads as a rejected password. Sends the user
  /// back to the code screen instead.
  ///
  /// A code the server rejects goes the same way. This screen has no field for
  /// it, so leaving that message here is the dead end the flow was reported
  /// for — "the button just shows an error and doesn't proceed" — and it stays
  /// a dead end however many times the password is retyped. The code screen is
  /// the one that can fix it, and it carries the resend.
  Future<bool> resetPassword({
    required String password,
    required String confirmPassword,
  }) async {
    final otp = _resetOtp;
    if (otp == null || otp.isEmpty) {
      state = state.copyWith(
        stage: AuthStage.verifyReset,
        signInError: 'Enter the code we emailed you, then set a new password.',
      );
      return false;
    }
    final ok = await _submit(
      action: () => _repo.resetPassword(
        email: state.email,
        otp: otp,
        newPassword: password,
        confirmNewPassword: confirmPassword,
      ),
      next: AuthStage.passwordUpdated,
      onFailure: (failure, failed) {
        if (!_isResetCodeRejection(failure)) return failed;
        // Whatever the server thought of it, this device must stop resending
        // it — otherwise every retry repeats the same rejection.
        _resetOtp = null;
        return failed.copyWith(
          stage: AuthStage.verifyReset,
          signInError:
              'That code is no longer valid. Send a new one, then set your '
              'password.',
        );
      },
    );
    // Spent — a second attempt has to start from a fresh code.
    if (ok) _resetOtp = null;
    return ok;
  }

  /// True when the server refused the *code* rather than the password.
  ///
  /// DRF reports it under the field it belongs to, so an `otp` key is the
  /// reliable signal. The message sweep is for backends that answer with a
  /// non-field `detail` instead; it only ever widens what gets routed back to
  /// the code screen, which is recoverable, never what gets reported as a
  /// password problem.
  bool _isResetCodeRejection(SkifluxFailure failure) {
    final cause = failure.cause;
    if (cause is! ApiException) return false;
    if (cause.fieldErrors.containsKey('otp')) return true;
    final text = [
      cause.detail,
      ...cause.fieldErrors.values.expand((messages) => messages),
    ].whereType<String>().join(' ').toLowerCase();
    return text.contains('otp') ||
        text.contains('code has expired') ||
        text.contains('invalid code') ||
        text.contains('expired code');
  }

  /// `POST /auth/social/mobile/google`, preceded by the native account picker.
  ///
  /// Returns true only when a session now exists. A dismissed picker returns
  /// false with **no error on screen** — the user chose to stop, and a banner
  /// would read as a failure they need to act on.
  Future<bool> signInWithGoogle() =>
      _social(() => ref.read(socialAuthServiceProvider).googleIdToken(),
          _repo.googleSignIn);

  /// `POST /auth/social/mobile/apple`. Same contract as [signInWithGoogle].
  Future<bool> signInWithApple() =>
      _social(() => ref.read(socialAuthServiceProvider).appleIdToken(),
          _repo.appleSignIn);

  /// The shared shape of both social paths: mint a token natively, exchange it
  /// for a session, hold [AuthFlowState.submitting] across the whole thing.
  ///
  /// Not routed through [_submit] because of the cancel case — `_submit` has no
  /// way to say "stopped, but nothing went wrong", and the null token must not
  /// leave an error behind.
  Future<bool> _social(
    Future<String?> Function() mintToken,
    Future<Object?> Function({required String idToken}) exchange,
  ) async {
    if (state.submitting) return false;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final idToken = await mintToken();
      if (idToken == null) {
        state = state.copyWith(submitting: false, clearError: true);
        return false;
      }
      final result = await exchange(idToken: idToken);
      state = state.copyWith(
        submitting: false,
        clearError: true,
        // Social sign-in returns the same `AuthTokenResponse`, so a first-time
        // Google/Apple account lands in the wizard exactly like a password one.
        needsOnboarding: result is AuthTokens && result.needsOnboarding,
      );
      return true;
    } on SkifluxFailure catch (failure) {
      state = state.copyWith(
        submitting: false,
        signInError: _stepMessage(failure),
      );
      return false;
    }
  }

  /// `POST /auth/logout` — "Switch accounts" on the biometric gate, and the
  /// app's sign-out. Always ends locally signed out, even if the server call
  /// fails; see [AuthRepository.logout].
  ///
  /// The provider's own cached account goes too: without that, Google reuses
  /// the last account silently and "Switch accounts" switches nothing. The
  /// cached "Welcome back" email likewise — leaving it would greet the next
  /// account with the previous one's address on the biometric frame.
  Future<void> signOut() async {
    await _repo.logout();
    await ref.read(socialAuthServiceProvider).signOut();
    await ref.read(sessionEmailStoreProvider).clear();
    state = state.copyWith(
      stage: AuthStage.signIn,
      passwordOnly: false,
      submitting: false,
      clearError: true,
    );
  }

  /// True when a token pair is on this device — no server round-trip.
  Future<bool> hasSession() => _repo.hasSession();

  /// The wizard's goal copy (`198:16142`) → the spec's `UserGoalEnum` values.
  /// Kept as an explicit table because the two sets share no derivable shape.
  static const goalWireValues = <String, String>{
    'Build a verified portfolio': 'build_portfolio',
    'Learn a new technical skill': 'learn_skill',
    'Earn income through tasks': 'earn_income',
    'Network with creators': 'network',
  };

  /// The skillworld card label (`2897:12161`) → `UserSkillworldEnum`. Every
  /// world the app offers lowercases straight onto its wire value ("AI" →
  /// `ai`); the spec's extra values (`code`, `writing`) have no card and can
  /// never be selected.
  static String skillworldWireValue(String label) => label.trim().toLowerCase();

  /// `POST /profile/complete-onboarding/` — sends what the sign-up wizard
  /// collected (username, goal, skillworld, optional avatar) and marks the
  /// account onboarded. Without this call every field the wizard gathered was
  /// silently dropped and the user landed with an empty profile.
  ///
  /// Country is not sent: no screen collects it and the spec marks it
  /// optional. Holds [AuthFlowState.submitting] so the Welcome CTA shows its
  /// spinner, and **rethrows** the [SkifluxFailure] instead of storing it —
  /// the Welcome frame has no inline error slot, so the caller surfaces the
  /// failure (ErrorDisplay) and stays put for a retry.
  Future<void> completeOnboarding() async {
    if (state.submitting) return;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      final goalWire = goalWireValues[state.goal?.trim()];
      final skillworld = state.skillworld?.trim();
      await ref.read(profileRepositoryProvider).completeOnboarding(
        username: state.username.trim(),
        goal: [?goalWire],
        skillworld: [
          if (skillworld != null && skillworld.isNotEmpty)
            skillworldWireValue(skillworld),
        ],
        avatarPath: state.avatarPath,
      );
      state = state.copyWith(submitting: false, clearError: true);
    } catch (_) {
      // Not just SkifluxFailure: an avatar file deleted between pick and
      // submit throws before the request exists, and the spinner must not
      // stay wedged on for that either.
      state = state.copyWith(submitting: false);
      rethrow;
    }
  }

  /// What a finished splash should do for this device — the cold-start
  /// session restore decision.
  ///
  /// - no token pair on the device → the marketing carousel, as today;
  /// - a session **and** the (hydrated) biometric preference on, on a device
  ///   that can actually offer biometrics → the biometric gate, so quick
  ///   unlock guards the stored session;
  /// - a session otherwise → straight into the app.
  ///
  /// [settingsReady] is awaited before the preference is read: the settings
  /// notifier hydrates SharedPreferences after its first build, so an
  /// unawaited read here would always see the compiled-in `false` and the
  /// gate would never show (the cold-start race this exists to fix).
  ///
  /// Pure and static — unit-tested without the plugin, keychain or widgets.
  /// Every probe is failure-tolerant: an unanswerable question must degrade
  /// to a safe screen, never wedge the splash.
  static Future<ColdStartDestination> resolveColdStart({
    required Future<bool> Function() hasSession,
    required Future<void> Function() settingsReady,
    required bool Function() biometricLoginEnabled,
    required Future<BiometricMode?> Function() availableMode,
  }) async {
    bool session;
    try {
      session = await hasSession();
    } catch (_) {
      // Unreadable keychain — indistinguishable from signed out, and the
      // marketing flow is the only screen that works with no session.
      session = false;
    }
    if (!session) return ColdStartDestination.marketingOnboarding;
    try {
      await settingsReady();
    } catch (_) {
      // Defaults it is — biometric stays opt-in.
    }
    if (!biometricLoginEnabled()) return ColdStartDestination.enterApp;
    BiometricMode? mode;
    try {
      mode = await availableMode();
    } catch (_) {
      mode = null;
    }
    return mode != null
        ? ColdStartDestination.biometricGate
        : ColdStartDestination.enterApp;
  }

  /// Runs [action] with the submitting flag held, advancing to [next] on
  /// success. Returns false when it failed, and rethrows nothing: the failure
  /// is stored on [AuthFlowState.signInError] so the current screen renders it
  /// rather than the caller having to catch.
  ///
  /// [onFailure] gets the failure and the state this would otherwise settle on,
  /// and returns what to settle on instead — for a step whose rejection belongs
  /// on a different screen than the one that submitted it.
  Future<bool> _submit({
    required Future<Object?> Function() action,
    AuthStage? next,
    String? email,
    AuthFlowState Function(SkifluxFailure failure, AuthFlowState failed)?
    onFailure,
  }) async {
    if (state.submitting) return false;
    state = state.copyWith(
      submitting: true,
      clearError: true,
      email: email?.trim(),
    );
    try {
      await action();
      state = state.copyWith(
        stage: next ?? state.stage,
        submitting: false,
        clearError: true,
      );
      return true;
    } on SkifluxFailure catch (failure) {
      final failed = state.copyWith(
        submitting: false,
        signInError: _stepMessage(failure),
      );
      state = onFailure?.call(failure, failed) ?? failed;
      return false;
    }
  }

  /// Copy for a failed signup / OTP / reset step.
  ///
  /// DRF puts per-field validation messages in the body, and they are the
  /// useful ones here — "that email is already registered", "this code has
  /// expired" — so the first is surfaced verbatim. Anything else falls back to
  /// the classifier's copy for the kind, which is already plain-language and
  /// free of raw exception text.
  String _stepMessage(SkifluxFailure failure) {
    final cause = failure.cause;
    if (cause is ApiException) {
      final first = cause.fieldErrors.values
          .expand((messages) => messages)
          .firstOrNull;
      if (first != null && first.isNotEmpty) return first;
    }
    return const ErrorHandler().classify(failure).message;
  }

  /// Maps a rejected sign-in onto one of the two Figma error states.
  ///
  /// DRF reports an unknown address under an `email` key and a wrong password
  /// as a non-field `detail`, so the field map is the signal. A transport
  /// failure (no connection, timeout) is neither: it wears the password
  /// caption's slot rather than falsely claiming the account doesn't exist,
  /// because the app genuinely cannot tell which of the two it was.
  String _signInMessage(SkifluxFailure failure) {
    final cause = failure.cause;
    if (cause is ApiException && cause.fieldErrors.containsKey('email')) {
      return signInEmailError;
    }
    if (failure.kind == SkifluxErrorKind.networkTimeout ||
        failure.kind == SkifluxErrorKind.noConnection) {
      return "Couldn't connect. Check your internet and try again.";
    }
    return signInPasswordError;
  }
}
