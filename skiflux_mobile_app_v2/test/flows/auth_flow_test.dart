import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skiflux_mobile_app_v2/features/auth/auth_flow.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/auth_store.dart';

void main() {
  group('AuthFlow widget', () {
    testWidgets('splash renders brand mark', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlow(),
          ),
        ),
      );
      // Splash screen shows the brand mark.
      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('splash timer transitions to onboarding after 900ms',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlow(),
          ),
        ),
      );
      // Splash renders first.
      expect(find.text('S'), findsOneWidget);

      // Advance past the 900ms splash timer.
      await tester.pump(const Duration(milliseconds: 901));
      await tester.pump(const Duration(milliseconds: 50));

      // Onboarding screen renders with title.
      expect(find.text('Your CV is officially dead.'), findsOneWidget);
    });

    testWidgets('onboarding "Login" transitions to sign-in screen',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlow(),
          ),
        ),
      );
      // Advance past splash.
      await tester.pump(const Duration(milliseconds: 901));
      await tester.pump(const Duration(milliseconds: 50));

      // Tap "Login" on onboarding screen.
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Sign-in screen renders with email and password fields.
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('correct demo credentials transition to fingerprint screen',
        (tester) async {
      // Use tall viewport so the ListView renders all form children.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlow(),
          ),
        ),
      );
      // Advance past splash → onboarding → tap Login → sign-in.
      await tester.pump(const Duration(milliseconds: 901));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter demo credentials into the two TextFields.
      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(2));
      await tester.enterText(textFields.at(0), 'veek@nexacorp.io');
      await tester.enterText(textFields.at(1), 'skiflux');
      await tester.pump();

      // Tap "Sign in".
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Biometric (fingerprint) screen renders.
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Verify Identity'), findsOneWidget);
    });

    testWidgets('incorrect password shows inline error on the password field',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlow(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 901));
      await tester.pump(const Duration(milliseconds: 50));
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

    testWidgets('returning to sign-in from forgot password is possible',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlow(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 901));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Go to forgot password.
      await tester.tap(find.text('Forgot password?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Forgot your password?'), findsOneWidget);
    });

    testWidgets('create account screen renders from onboarding',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlow(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 901));
      await tester.pump(const Duration(milliseconds: 50));

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

      // Begin sign-in flow.
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      notifier.signIn('veek@nexacorp.io', 'skiflux');
      expect(container.read(authFlowProvider).stage, AuthStage.fingerprint);

      // Set some user data.
      notifier.setUsername('testuser');
      notifier.setGoal('goal');
      notifier.setSkillworld('Design');

      // Now invalidate — simulate what happens after successful login.
      container.invalidate(authFlowProvider);

      // Provider must return to initial state.
      final fresh = container.read(authFlowProvider);
      expect(fresh.stage, AuthStage.splash);
      expect(fresh.username, isEmpty);
      expect(fresh.goal, isNull);
      expect(fresh.skillworld, isNull);
      expect(fresh.signInError, isNull);
    });
  });
}
