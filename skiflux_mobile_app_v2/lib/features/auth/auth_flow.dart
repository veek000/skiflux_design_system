import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/data/session_email_store.dart';
import '../../shared/error_handling/error_display.dart';
import '../../shared/network/api_client.dart';
import '../../shared/network/token_store.dart';
import '../../shared/notifications/fcm_service.dart';
import '../../shared/notifications/notification_permission.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../home/data/home_feed_store.dart';
import '../home/home_screen.dart';
import '../notifications/data/notifications_store.dart';
import '../profile/data/devices_repository.dart';
import '../profile/data/profile_store.dart';
import '../profile/data/skill_world_store.dart';
import '../settings/data/settings_store.dart';
import '../tasks/data/tasks_store.dart';
import '../wallet/data/wallet_store.dart';
import 'data/auth_store.dart';
import 'data/biometric_store.dart';
import 'data/legal_documents.dart';
import 'data/social_auth.dart';
import 'screens/biometric_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/legal_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/signup_screen.dart';

/// Fallback address on the biometric frame when nothing is cached yet.
const _demoEmail = 'veek@nexacorp.io';

class AuthFlow extends ConsumerStatefulWidget {
  const AuthFlow({super.key, this.startAt = AuthStage.splash});

  /// Where this stack should land instead of the brand splash.
  ///
  /// Used when the in-app auth guard kicks the user out for an expired
  /// session — they already saw the splash on cold start; bouncing through it
  /// again before the password form just delays re-auth.
  final AuthStage startAt;

  @override
  ConsumerState<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends ConsumerState<AuthFlow> {
  /// Whether Sign in with Apple can actually run here. Resolved once,
  /// asynchronously — it is a platform + OS-version check. It decides what the
  /// Apple button *does*, never whether it is drawn: both providers are always
  /// offered so the user picks, and an unusable one says so on tap.
  bool _appleAvailable = false;

  @override
  void initState() {
    super.initState();
    // Tell the central gate we own the stack: in-app 401 reauth must not
    // push a second AuthFlow over biometric / password screens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(authGateProvider.notifier).enterAuthStack();
      if (widget.startAt != AuthStage.splash) {
        ref.read(authFlowProvider.notifier).show(widget.startAt);
      }
    });
    unawaited(_resolveAppleAvailability());
  }

  @override
  void dispose() {
    // Best-effort: if this AuthFlow is replaced by another AuthFlow (session
    // lost → sign-in), the new instance re-enters the stack. If it is replaced
    // by Home, leaveAuthStack runs in _enterApp before push.
    super.dispose();
  }

  Future<void> _resolveAppleAvailability() async {
    final available = await ref.read(socialAuthServiceProvider).appleAvailable();
    if (!mounted || available == _appleAvailable) return;
    setState(() => _appleAvailable = available);
  }

  /// Social sign-in ends exactly where the password path does. A cancelled
  /// picker returns false with no error set, so this simply does nothing.
  Future<void> _onSocial(Future<bool> Function() signIn) async {
    if (!await signIn()) return;
    if (!mounted) return;
    _enterAppOrOnboard();
  }

  /// Tapped when a provider is offered but cannot complete on this build —
  /// no OAuth client ID compiled in, or a platform Apple does not serve.
  ///
  /// The credentials are pending, not the feature, so this says "coming soon"
  /// rather than removing the button: a row that changes shape between builds is
  /// harder to reason about than one whose tap is honest about the state. When
  /// the IDs land, the gates below flip and the same buttons run the real flow.
  Future<void> _onSocialUnavailable(String provider) async {
    if (!mounted) return;
    SkifluxToast.info(
      context,
      '$provider sign-in is coming soon. Use your email and password for now.',
    );
  }

  /// Where a fresh sign-in lands: the app, or the wizard it never finished.
  ///
  /// `AuthTokenResponse.user.is_onboarded` is the only thing that can tell us —
  /// an account can be created on one device and signed into on another, and
  /// the wizard can be abandoned halfway. Without this, such a user reached a
  /// Home built around a username, goal and skillworld they had never given.
  ///
  /// Deliberately *not* `_enterApp`'s job: that also invalidates
  /// [authFlowProvider], which would wipe the wizard's state the moment we
  /// entered it.
  //
  // TODO(backend, minor): `GET /me/profile` carries no `is_onboarded`, so a
  // cold start on a stored session cannot make this same decision and goes
  // straight to Home — expects: is_onboarded: bool on UserProfile
  void _enterAppOrOnboard() {
    if (ref.read(authFlowProvider).needsOnboarding) {
      ref.read(authFlowProvider.notifier).show(AuthStage.claimIdentity);
      return;
    }
    _enterApp();
  }

  /// Leaves the flow for the app itself, dropping the auth state on the way so
  /// a later sign-out starts from the splash rather than mid-flow.
  void _enterApp() {
    // In-app 401s must be allowed to arm reauth again.
    ref.read(authGateProvider.notifier).leaveAuthStack();
    // Kick off Tier-1 remote loads (profile, wallet, feed, missions, FCM).
    unawaited(_bootstrapSessionData());
    ref.invalidate(authFlowProvider);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _bootstrapSessionData() async {
    if (!await ref.read(tokenStoreProvider).hasSession()) return;
    unawaited(ref.read(meProfileProvider.notifier).refresh());
    unawaited(ref.read(walletProvider.notifier).refreshFromBackend());
    unawaited(ref.read(homeFeedProvider.notifier).refresh());
    unawaited(ref.read(tasksProvider.notifier).refreshMissionsFromBackend());
    // The bell's dot is derived from this list, so it has to be fetched
    // before the user opens the Notifications screen — otherwise the badge
    // stays dark until the one place that would have shown it is visited.
    unawaited(ref.read(notificationsProvider.notifier).refreshFromBackend());
    // Ask *after* sign-in, never at cold start: the iOS prompt is once-ever,
    // and a soft pre-prompt guards it (see maybeAskForNotificationPermission).
    // Deferred a beat so it lands on the home screen this flow just pushed,
    // rather than over the auth screen that is on its way out.
    //
    // Do **not** call [FcmService.requestPermission] before the soft sheet —
    // that used to spend the once-ever OS prompt with no explainer.
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await maybeAskForNotificationPermission(context, ref);

    final fcm = ref.read(fcmServiceProvider);
    await fcm.getToken();
    await fcm.registerTokenWithBackend((token) {
      return ref.read(devicesRepositoryProvider).registerDevice(token: token);
    });
  }

  /// Onboarding "Login" — branch on settings + capability **before** any
  /// screen. Never password → biometric.
  ///
  /// The preference read waits for [SettingsNotifier.ready]: hydration runs
  /// detached after the notifier's first build, so a synchronous read on a
  /// cold start always saw the default `false` and the biometric gate never
  /// showed, whatever the user had chosen.
  Future<void> _onLogin() async {
    await ref.read(settingsProvider.notifier).ready;
    if (!mounted) return;
    final biometricOn = ref.read(settingsProvider).biometricLogin;
    await ref.read(authFlowProvider.notifier).enterReturningSignIn(
      biometricLoginEnabled: biometricOn,
      availableMode: () =>
          ref.read(biometricAuthenticatorProvider).availableMode(),
    );
  }

  /// The splash has played out — decide where this device resumes.
  ///
  /// A device that already holds a token pair must not re-run the marketing
  /// carousel: it either passes the biometric gate (preference on + hardware
  /// present) or goes straight into the app on the stored session. The stage
  /// guard runs after every await so a user who already navigated (or a
  /// second `onFinished` from the watchdog) is never yanked elsewhere.
  Future<void> _onSplashFinished() async {
    if (ref.read(authFlowProvider).stage != AuthStage.splash) return;
    final destination = await AuthFlowNotifier.resolveColdStart(
      hasSession: () => ref.read(tokenStoreProvider).hasSession(),
      settingsReady: () => ref.read(settingsProvider.notifier).ready,
      biometricLoginEnabled: () => ref.read(settingsProvider).biometricLogin,
      availableMode: () =>
          ref.read(biometricAuthenticatorProvider).availableMode(),
      getCachedEmail: () => ref.read(sessionEmailStoreProvider).read(),
    );
    if (!mounted || ref.read(authFlowProvider).stage != AuthStage.splash) {
      return;
    }
    switch (destination) {
      case ColdStartDestination.marketingOnboarding:
        ref.read(authFlowProvider.notifier).show(AuthStage.onboarding);
      case ColdStartDestination.biometricGate:
        // Reuses the returning-sign-in path so the cached "Welcome back"
        // email is loaded and "Switch accounts" / "Login with Password" keep
        // their existing behaviour.
        await ref.read(authFlowProvider.notifier).enterReturningSignIn(
          biometricLoginEnabled: true,
          availableMode: () =>
              ref.read(biometricAuthenticatorProvider).availableMode(),
        );
      case ColdStartDestination.enterApp:
        // Same gate as biometric: keychain presence is not a live session.
        unawaited(_enterAppIfSessionValid());
    }
  }

  /// Cold-start / non-biometric path into Home — only after the **central**
  /// [AuthGate] proves the stored pair still works. Dead tokens stay on the
  /// auth stack (password form); the gate does not navigate.
  Future<void> _enterAppIfSessionValid() async {
    final validation =
        await ref.read(authGateProvider.notifier).ensureValidSession();
    if (!mounted) return;
    switch (validation) {
      case SessionValidation.valid:
        _enterApp();
      case SessionValidation.none:
      case SessionValidation.invalid:
        SkifluxToast.info(
          context,
          'Your session expired. Please sign in again.',
        );
        ref.read(authFlowProvider.notifier).show(AuthStage.signIn);
    }
  }

  /// Welcome's "Start Learning" — the wizard's payoff CTA, and the moment the
  /// collected profile actually leaves the device.
  ///
  /// `POST /profile/complete-onboarding/` runs **before** entering the app;
  /// a rejection surfaces and stays on Welcome so the tap can be retried —
  /// advancing anyway would silently discard the username, goal, skillworld
  /// and avatar the user just walked through four screens to provide. On
  /// success `_enterApp`'s bootstrap re-fetches `GET /me/profile`, so the
  /// profile screens render the server's copy of what was submitted.
  Future<void> _onStartLearning() async {
    final state = ref.read(authFlowProvider);
    if (state.submitting) return;
    final world = SkillWorld.fromLabel(state.skillworld);
    if (world != null) {
      ref.read(skillWorldProvider.notifier).select(world);
    }
    try {
      await ref.read(authFlowProvider.notifier).completeOnboarding();
    } catch (error, stackTrace) {
      if (!mounted) return;
      await ErrorDisplay.show(context, ref, error, stackTrace: stackTrace);
      return;
    }
    if (!mounted) return;
    // `_enterApp` → `_bootstrapSessionData` refreshes [meProfileProvider], so
    // the freshly-onboarded profile is fetched exactly once, not twice.
    _enterApp();
  }

  /// A successful biometric prompt.
  ///
  /// Biometrics authorise reuse of the session already on the device — the spec
  /// has no endpoint that trades a fingerprint for tokens. Validation goes
  /// through the **central** [AuthGate] only:
  /// - refresh OK → real login (fresh access token), then Home;
  /// - no tokens / refresh rejected → password form on this same stack.
  ///
  /// Never navigates to Home with dead tokens (that used to show as
  /// "couldn't load video" instead of session expired).
  Future<void> _onBiometricVerified() async {
    final notifier = ref.read(authFlowProvider.notifier);
    final validation =
        await ref.read(authGateProvider.notifier).ensureValidSession();
    if (!mounted) return;
    switch (validation) {
      case SessionValidation.valid:
        _enterApp();
      case SessionValidation.none:
        SkifluxToast.info(
          context,
          'Sign in once more to re-enable quick unlock.',
        );
        notifier.usePasswordInstead();
      case SessionValidation.invalid:
        SkifluxToast.info(
          context,
          'Your session expired. Please sign in with your password.',
        );
        notifier.usePasswordInstead();
    }
  }

  /// "Switch accounts" — ends the current session before offering the form, so
  /// the next user's first request can't go out on the previous user's token.
  /// [AuthFlowNotifier.signOut] already lands on the password form with the
  /// biometric preference re-armed, which is exactly what switching wants.
  Future<void> _onSwitchAccount() =>
      ref.read(authFlowProvider.notifier).signOut();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowProvider);
    final notifier = ref.read(authFlowProvider.notifier);
    // Both providers are drawn on every platform and every build, because the
    // choice is the user's to make and a row that gains and loses buttons
    // between devices reads as broken. Only the *tap* is conditional: with
    // credentials in place it runs the real flow, without them it says so.
    final social = ref.read(socialAuthServiceProvider);
    final onGoogle = social.googleConfigured
        ? () => _onSocial(notifier.signInWithGoogle)
        : () => _onSocialUnavailable('Google');
    final onApple = _appleAvailable
        ? () => _onSocial(notifier.signInWithApple)
        : () => _onSocialUnavailable('Apple');
    return switch (state.stage) {
      AuthStage.splash => _SplashScreen(
        onFinished: () {
          unawaited(_onSplashFinished());
        },
      ),
      AuthStage.onboarding => OnboardingScreen(
        onCreateAccount: () => notifier.show(AuthStage.createAccount),
        onLogin: () {
          unawaited(_onLogin());
        },
        onTerms: () => notifier.showLegal(AuthStage.terms),
        onPrivacy: () => notifier.showLegal(AuthStage.privacy),
      ),
      AuthStage.createAccount => CreateAccountScreen(
        error: state.signInError,
        submitting: state.submitting,
        onSubmit: notifier.signUp,
        onSignIn: () {
          unawaited(_onLogin());
        },
        onBack: () => notifier.show(AuthStage.onboarding),
        onGoogle: onGoogle,
        onApple: onApple,
      ),
      AuthStage.verifyEmail => VerifyEmailScreen(
        email: state.email,
        error: state.signInError,
        submitting: state.submitting,
        onSubmit: notifier.verifyEmail,
        onResend: notifier.resendOtp,
        onBack: () => notifier.show(AuthStage.createAccount),
      ),
      // Reset OTP reuses the signup verify frame with reset callbacks.
      AuthStage.verifyReset => VerifyEmailScreen(
        email: state.email,
        error: state.signInError,
        submitting: state.submitting,
        onSubmit: notifier.verifyResetOtp,
        onResend: notifier.resendResetOtp,
        onBack: () => notifier.show(AuthStage.forgottenPassword),
      ),
      AuthStage.emailVerified => EmailVerifiedScreen(
        onContinue: () => notifier.show(AuthStage.claimIdentity),
      ),
      AuthStage.signIn => LoginScreen(
        error: state.signInError,
        submitting: state.submitting,
        onSubmit: (email, password) async {
          // Password path ends at Home — never chains biometric after success.
          // An account that never finished the wizard goes there first.
          if (!await notifier.signIn(email, password)) return;
          if (!mounted) return;
          _enterAppOrOnboard();
        },
        onForgot: () => notifier.show(AuthStage.forgottenPassword),
        onSignUp: () => notifier.show(AuthStage.createAccount),
        onBack: () => notifier.show(AuthStage.onboarding),
        onGoogle: onGoogle,
        onApple: onApple,
      ),
      AuthStage.forgottenPassword => ForgotPasswordScreen(
        error: state.signInError,
        submitting: state.submitting,
        onSend: notifier.forgotPassword,
        onBack: () => notifier.show(AuthStage.signIn),
      ),
      AuthStage.resetPassword => ResetPasswordScreen(
        error: state.signInError,
        submitting: state.submitting,
        onSubmit: (password, confirmPassword) => notifier.resetPassword(
          password: password,
          confirmPassword: confirmPassword,
        ),
        onBack: () => notifier.show(AuthStage.verifyReset),
      ),
      AuthStage.passwordUpdated => PasswordUpdatedScreen(
        onBackToSignIn: () => notifier.show(AuthStage.signIn),
      ),
      // Returning-user biometric *is* the login screen when settings allow it.
      // "Login with Password" falls back to [AuthStage.signIn] (passwordOnly).
      AuthStage.fingerprint || AuthStage.faceId => BiometricScreen(
        email: state.email.isNotEmpty ? state.email : _demoEmail,
        mode: state.stage == AuthStage.faceId ? BiometricMode.face : null,
        onVerified: () {
          unawaited(_onBiometricVerified());
        },
        onPassword: notifier.usePasswordInstead,
        onSwitchAccount: () {
          unawaited(_onSwitchAccount());
        },
      ),
      AuthStage.claimIdentity => ClaimIdentityScreen(
        username: state.username,
        avatarPath: state.avatarPath,
        onUsernameChanged: notifier.setUsername,
        onAvatarPicked: notifier.setAvatarPath,
        onContinue: () => notifier.show(AuthStage.whatBringsYouHere),
        onBack: () => notifier.show(AuthStage.emailVerified),
      ),
      AuthStage.whatBringsYouHere => GoalsScreen(
        value: state.goal,
        onChanged: notifier.setGoal,
        onContinue: () => notifier.show(AuthStage.chooseSkillworld),
        onBack: () => notifier.show(AuthStage.claimIdentity),
      ),
      AuthStage.chooseSkillworld => ChooseSkillworldScreen(
        value: state.skillworld,
        onChanged: notifier.setSkillworld,
        onContinue: () => notifier.show(AuthStage.welcome),
        onBack: () => notifier.show(AuthStage.whatBringsYouHere),
      ),
      AuthStage.welcome => WelcomeScreen(
        submitting: state.submitting,
        onStart: () {
          unawaited(_onStartLearning());
        },
      ),
      AuthStage.terms => LegalScreen(
        document: termsOfUse,
        onBack: notifier.closeLegal,
      ),
      AuthStage.privacy => LegalScreen(
        document: privacyPolicy,
        onBack: notifier.closeLegal,
      ),
    };
  }
}

/// The brand splash: the Bodymovin export in `assets/animations/
/// logo_splash.json` (1080×1920, 30fps, 5.5s), played once.
///
/// This is the app's *only* splash. The native launch windows on both platforms
/// are flat fills of the animation's opening colour with no artwork, so what the
/// user sees from the launcher tap onward is one continuous screen — see
/// `android/app/src/main/res/values/colors.xml` and iOS `LaunchScreen.storyboard`.
class _SplashScreen extends StatefulWidget {
  const _SplashScreen({required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _watchdog = Duration(seconds: 8);

  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });

  Timer? _watchdogTimer;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _watchdogTimer = Timer(_watchdog, _finish);
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    _watchdogTimer?.cancel();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The animation's own opening frame, not a theme token: this fills the
      // sliver of time before the composition has parsed, and it has to match
      // frame 0 rather than whatever the app's background happens to become.
      backgroundColor: SkifluxColors.white,
      body: SizedBox.expand(
        child: Lottie.asset(
          'assets/animations/logo_splash.json',
          controller: _controller,
          fit: BoxFit.cover,
          onLoaded: (composition) {
            if (!mounted) return;
            _controller
              ..duration = composition.duration
              ..forward();
          },
          errorBuilder: (context, error, stackTrace) {
            // Deferred: `errorBuilder` runs *during* build, and `_finish`
            // advances the flow — moving the stage from inside build throws.
            WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
