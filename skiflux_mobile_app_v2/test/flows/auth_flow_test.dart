import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'package:skiflux_mobile_app_v2/features/auth/auth_flow.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/auth_store.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/biometric_store.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/legal_documents.dart';
import 'package:skiflux_mobile_app_v2/features/settings/data/settings_store.dart';

/// Stands in for the platform plugin, which has no implementation under the
/// test binding. [mode] null means "this device cannot offer biometrics" —
/// the state a stock emulator with nothing enrolled is in.
class _FakeBiometrics extends BiometricAuthenticator {
  _FakeBiometrics(this.mode) : super(LocalAuthentication());

  final BiometricMode? mode;

  @override
  Future<BiometricMode?> availableMode() async => mode;

  @override
  Future<bool> authenticate() async => true;
}

/// Mounts [AuthFlow] already past the splash.
///
/// The splash now runs a 5s Lottie composition and advances on *its*
/// completion, so tests about onboarding and sign-in seed the stage directly
/// rather than waiting out an animation they aren't exercising. Splash
/// behaviour has its own group below.
///
/// [biometrics] is what the device reports it can do. It defaults to an
/// enrolled fingerprint so the sign-in tests reach the gate; pass null for the
/// no-biometrics device.
Future<ProviderContainer> _pumpAtOnboarding(
  WidgetTester tester, {
  BiometricMode? biometrics = BiometricMode.fingerprint,
  bool biometricLoginEnabled = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      biometricAuthenticatorProvider.overrideWithValue(
        _FakeBiometrics(biometrics),
      ),
    ],
  );
  addTearDown(container.dispose);
  container.read(settingsProvider.notifier).setBiometricLogin(
        biometricLoginEnabled,
      );
  container.read(authFlowProvider.notifier).show(AuthStage.onboarding);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AuthFlow()),
    ),
  );
  return container;
}

void main() {
  group('AuthFlow splash', () {
    testWidgets('renders the brand Lottie composition', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AuthFlow())),
      );

      expect(find.byType(LottieBuilder), findsOneWidget);
      expect(find.text('Your CV is officially dead.'), findsNothing);
    });

    testWidgets('watchdog advances to onboarding if the animation never ends', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AuthFlow())),
      );
      expect(find.byType(LottieBuilder), findsOneWidget);

      // Past the 8s ceiling: the splash must hand off even when the
      // composition never reports completion.
      await tester.pump(const Duration(seconds: 9));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Your CV is officially dead.'), findsOneWidget);
    });
  });

  group('AuthFlow onboarding', () {
    testWidgets('swiping advances through all three pages', (tester) async {
      await _pumpAtOnboarding(tester);

      expect(find.text('Your CV is officially dead.'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(
        find.text('Build a portfolio that actually pays.'),
        findsOneWidget,
      );

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Learn it. Prove it. Earn it.'), findsOneWidget);
    });

    testWidgets('the footer buttons persist across pages', (tester) async {
      await _pumpAtOnboarding(tester);

      // Both CTAs belong to the sticky footer, not the paged content, so a
      // swipe must leave them untouched.
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });
  });

  group('AuthFlow legal documents', () {
    testWidgets('the onboarding legal links open each document', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await _pumpAtOnboarding(tester);

      // The two links are spans inside the legal line's RichText, so they are
      // reached by text range rather than by widget.
      await tester.tapOnText(find.textRange.ofSubstring('Terms of use'));
      await tester.pumpAndSettle();
      expect(find.text('Terms of Use'), findsOneWidget);
      expect(find.text('1. The Skiflux Ecosystem'), findsOneWidget);
      expect(find.text('Last Updated May 24th, 2026'), findsOneWidget);

      // The chevron returns to onboarding, not into sign-up.
      await tester.tap(find.byIcon(RemixIcons.arrow_left_s_line));
      await tester.pumpAndSettle();
      expect(find.text('Your CV is officially dead.'), findsOneWidget);

      await tester.tapOnText(find.textRange.ofSubstring('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.text('1. Information We Collect'), findsOneWidget);
    });

    testWidgets('a document renders every section heading', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(authFlowProvider.notifier).show(AuthStage.privacy);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AuthFlow()),
        ),
      );

      for (final section in privacyPolicy.sections) {
        // Long documents scroll, so headings past the fold need scrolling into
        // view before they are hit-testable.
        await tester.scrollUntilVisible(
          find.text(section.heading),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(section.heading), findsOneWidget);
      }
      expect(find.textContaining('support@skiflux.com'), findsOneWidget);
    });
  });

  group('AuthFlow widget', () {
    testWidgets(
      'biometric OFF: onboarding Login opens password sign-in (never biometric)',
      (tester) async {
        await _pumpAtOnboarding(tester, biometricLoginEnabled: false);

        await tester.tap(find.text('Login'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Sign in'), findsOneWidget);
        expect(find.text('Verify Identity'), findsNothing);
      },
    );

    testWidgets(
      'biometric ON + device capable: onboarding Login opens biometric first',
      (tester) async {
        await _pumpAtOnboarding(
          tester,
          biometricLoginEnabled: true,
          biometrics: BiometricMode.fingerprint,
        );

        await tester.tap(find.text('Login'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Biometric *is* the login screen — no password fields yet.
        expect(find.text('Verify Identity'), findsOneWidget);
        expect(find.text('Login with Password'), findsOneWidget);
        expect(find.text('Email Address'), findsNothing);
        expect(find.text('Password'), findsNothing);
      },
    );

    testWidgets(
      'biometric ON but no enrolled biometrics: Login falls back to password',
      (tester) async {
        await _pumpAtOnboarding(
          tester,
          biometricLoginEnabled: true,
          biometrics: null,
        );

        await tester.tap(find.text('Login'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Verify Identity'), findsNothing);
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Sign in'), findsOneWidget);
      },
    );

    testWidgets(
      'biometric ON: Login with Password fallback reaches password form',
      (tester) async {
        await _pumpAtOnboarding(
          tester,
          biometricLoginEnabled: true,
          biometrics: BiometricMode.fingerprint,
        );

        await tester.tap(find.text('Login'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Verify Identity'), findsOneWidget);

        await tester.tap(find.text('Login with Password'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Sign in'), findsOneWidget);
        expect(find.text('Verify Identity'), findsNothing);
      },
    );

    testWidgets('incorrect password shows inline error on the password field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await _pumpAtOnboarding(tester);
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter a valid email but wrong password.
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'veek@nexacorp.io');
      await tester.enterText(textFields.at(1), 'wrongPassword');
      await tester.pump();

      // Tap "Sign in".
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should stay on sign-in screen (not advance to fingerprint).
      expect(find.text('Welcome Back'), findsOneWidget);

      // The password field caption should show the error text.
      expect(find.textContaining('Incorrect password'), findsOneWidget);
    });

    testWidgets('returning to sign-in from forgot password is possible', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await _pumpAtOnboarding(tester);
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Go to forgot password.
      await tester.tap(find.text('Forgot password?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Forgot your password?'), findsOneWidget);
    });

    testWidgets('create account screen renders from onboarding', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await _pumpAtOnboarding(tester);

      // Tap "Create an account".
      await tester.tap(find.text('Create an account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.textContaining('Already have an account?'), findsOneWidget);
    });
  });

  group('authFlowProvider invalidation', () {
    test('after invalidation, provider returns fresh initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      notifier.setUsername('testuser');
      notifier.setGoal('goal');
      notifier.setSkillworld('Design');
      expect(container.read(authFlowProvider).stage, AuthStage.signIn);

      // Simulate what happens after successful login / _enterApp.
      container.invalidate(authFlowProvider);

      final fresh = container.read(authFlowProvider);
      expect(fresh.stage, AuthStage.splash);
      expect(fresh.username, isEmpty);
      expect(fresh.goal, isNull);
      expect(fresh.skillworld, isNull);
      expect(fresh.signInError, isNull);
    });
  });
}
