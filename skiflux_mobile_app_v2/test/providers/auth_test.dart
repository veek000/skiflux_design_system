import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skiflux_mobile_app_v2/features/auth/data/auth_store.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('authFlowProvider initial state', () {
    test('build returns splash stage', () {
      final state = container.read(authFlowProvider);
      expect(state.stage, AuthStage.splash);
    });

    test('initial username is empty', () {
      final state = container.read(authFlowProvider);
      expect(state.username, isEmpty);
    });

    test('initial goal and skillworld are null', () {
      final state = container.read(authFlowProvider);
      expect(state.goal, isNull);
      expect(state.skillworld, isNull);
    });

    test('initial signInError is null', () {
      final state = container.read(authFlowProvider);
      expect(state.signInError, isNull);
    });
  });

  group('show() transitions to any stage', () {
    test('show(createAccount) moves from splash to createAccount', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.createAccount);
      expect(container.read(authFlowProvider).stage, AuthStage.createAccount);
    });

    test('show(signIn) moves from splash to signIn', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      expect(container.read(authFlowProvider).stage, AuthStage.signIn);
    });

    test('show(onboardingOne) moves from splash to onboardingOne', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.onboardingOne);
      expect(container.read(authFlowProvider).stage, AuthStage.onboardingOne);
    });

    test('show(verifyEmail) moves from splash to verifyEmail', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.verifyEmail);
      expect(container.read(authFlowProvider).stage, AuthStage.verifyEmail);
    });

    test('show(terms) transitions to terms, then back to createAccount', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.terms);
      expect(container.read(authFlowProvider).stage, AuthStage.terms);
      notifier.show(AuthStage.createAccount);
      expect(container.read(authFlowProvider).stage, AuthStage.createAccount);
    });

    test('show(claimIdentity) then onContinue path through to chooseSkillworld',
        () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.claimIdentity);
      notifier.setUsername('veek');
      expect(container.read(authFlowProvider).username, 'veek');

      notifier.show(AuthStage.whatBringsYouHere);
      notifier.setGoal('Build a verified portfolio');
      expect(container.read(authFlowProvider).goal,
          'Build a verified portfolio');

      notifier.show(AuthStage.chooseSkillworld);
      notifier.setSkillworld('Design');
      expect(container.read(authFlowProvider).skillworld, 'Design');
    });
  });

  group('signIn() credential validation', () {
    test('empty email sets signInError for missing account', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      notifier.signIn('', 'anyPassword');
      final state = container.read(authFlowProvider);
      expect(state.signInError, 'No account found with this email');
      expect(state.stage, AuthStage.signIn); // stays on sign-in stage
    });

    test('email containing "missing" sets signInError', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      notifier.signIn('missing@email.com', 'anyPassword');
      expect(container.read(authFlowProvider).signInError,
          'No account found with this email');
    });

    test('wrong password sets signInError for incorrect password', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      notifier.signIn('veek@nexacorp.io', 'wrongPassword');
      final state = container.read(authFlowProvider);
      expect(state.signInError, 'Incorrect password');
      expect(state.stage, AuthStage.signIn); // stays on sign-in stage
    });

    test('correct demo credentials transition to fingerprint', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      notifier.signIn('veek@nexacorp.io', 'skiflux');
      final state = container.read(authFlowProvider);
      expect(state.stage, AuthStage.fingerprint);
      expect(state.signInError, isNull);
    });

    test('correct credentials clear previous signInError', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);

      // Trigger error first.
      notifier.signIn('veek@nexacorp.io', 'wrong');
      expect(container.read(authFlowProvider).signInError, isNotNull);

      // Then succeed — error must be cleared.
      notifier.signIn('veek@nexacorp.io', 'skiflux');
      expect(container.read(authFlowProvider).signInError, isNull);
    });

    test('whitespace-only email treated as empty', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      notifier.signIn('   ', 'anyPassword');
      expect(container.read(authFlowProvider).signInError,
          'No account found with this email');
    });
  });

  group('clearError() removes signInError', () {
    test('clearError sets signInError to null', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      notifier.signIn('', 'any'); // trigger error.
      expect(container.read(authFlowProvider).signInError, isNotNull);

      notifier.clearError();
      expect(container.read(authFlowProvider).signInError, isNull);
    });

    test('clearError on clean state is idempotent', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.clearError();
      expect(container.read(authFlowProvider).signInError, isNull);
    });
  });

  group('setUsername / setGoal / setSkillworld', () {
    test('setUsername updates username field', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.setUsername('Amara');
      expect(container.read(authFlowProvider).username, 'Amara');
    });

    test('setGoal updates goal field', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.setGoal('Build a verified portfolio');
      expect(container.read(authFlowProvider).goal,
          'Build a verified portfolio');
    });

    test('setSkillworld updates skillworld field', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.setSkillworld('Design');
      expect(container.read(authFlowProvider).skillworld, 'Design');
    });

    test('all three setters preserve other state', () {
      final notifier = container.read(authFlowProvider.notifier);

      notifier.setUsername('testuser');
      notifier.setGoal('Testing');
      notifier.setSkillworld('Engineering');

      final state = container.read(authFlowProvider);
      expect(state.username, 'testuser');
      expect(state.goal, 'Testing');
      expect(state.skillworld, 'Engineering');
      expect(state.stage, AuthStage.splash); // stage unchanged
      expect(state.signInError, isNull);
    });
  });

  group('copyWith immutability', () {
    test('copyWith returns new instance without mutating original', () {
      const original =
          AuthFlowState(stage: AuthStage.signIn, username: 'original');

      final updated =
          original.copyWith(stage: AuthStage.createAccount, username: 'updated');

      // Updated has new values.
      expect(updated.stage, AuthStage.createAccount);
      expect(updated.username, 'updated');

      // Original is unchanged.
      expect(original.stage, AuthStage.signIn);
      expect(original.username, 'original');
    });

    test('copyWith clearError=true forces signInError to null', () {
      const original =
          AuthFlowState(stage: AuthStage.signIn, signInError: 'bad');

      final updated = original.copyWith(clearError: true);

      expect(updated.signInError, isNull);
      expect(updated.stage, AuthStage.signIn); // unchanged
    });

    test('copyWith clearError=false with new signInError keeps the new value',
        () {
      const original =
          AuthFlowState(stage: AuthStage.signIn, signInError: 'old');

      final updated = original.copyWith(signInError: 'new');

      expect(updated.signInError, 'new');
    });
  });

  group('onboarding → auth entry points', () {
    test('onboardingOne can advance to onboardingTwo then signIn', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.onboardingOne);
      notifier.show(AuthStage.onboardingTwo);
      notifier.show(AuthStage.onboardingThree);
      notifier.show(AuthStage.signIn);
      expect(container.read(authFlowProvider).stage, AuthStage.signIn);
    });

    test('onboardingOne can jump directly to createAccount', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.onboardingOne);
      notifier.show(AuthStage.createAccount);
      expect(container.read(authFlowProvider).stage, AuthStage.createAccount);
    });
  });
}
