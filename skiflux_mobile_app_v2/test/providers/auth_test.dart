import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skiflux_mobile_app_v2/features/auth/data/auth_repository.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/auth_store.dart';
import 'package:skiflux_mobile_app_v2/features/auth/data/biometric_store.dart';
import 'package:skiflux_mobile_app_v2/features/settings/data/settings_store.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';
import 'package:skiflux_mobile_app_v2/shared/network/api_exception.dart';
import 'package:skiflux_mobile_app_v2/shared/network/token_store.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('returningSignInStage (biometric is alternative, not post-password)', () {
    test('biometric disabled → password signIn even if device capable', () {
      expect(
        AuthFlowNotifier.returningSignInStage(
          biometricLoginEnabled: false,
          deviceCanBiometric: true,
        ),
        AuthStage.signIn,
      );
    });

    test('biometric enabled + device capable → fingerprint stage', () {
      expect(
        AuthFlowNotifier.returningSignInStage(
          biometricLoginEnabled: true,
          deviceCanBiometric: true,
        ),
        AuthStage.fingerprint,
      );
    });

    test('biometric enabled but device incapable → password signIn', () {
      expect(
        AuthFlowNotifier.returningSignInStage(
          biometricLoginEnabled: true,
          deviceCanBiometric: false,
        ),
        AuthStage.signIn,
      );
    });

    test('enterReturningSignIn writes the chosen stage', () async {
      final notifier = container.read(authFlowProvider.notifier);
      await notifier.enterReturningSignIn(
        biometricLoginEnabled: false,
        availableMode: () async => BiometricMode.fingerprint,
      );
      expect(container.read(authFlowProvider).stage, AuthStage.signIn);

      await notifier.enterReturningSignIn(
        biometricLoginEnabled: true,
        availableMode: () async => BiometricMode.fingerprint,
      );
      expect(container.read(authFlowProvider).stage, AuthStage.fingerprint);

      await notifier.enterReturningSignIn(
        biometricLoginEnabled: true,
        availableMode: () async => null,
      );
      expect(container.read(authFlowProvider).stage, AuthStage.signIn);
    });

    test('settings default biometricLogin is off (opt-in)', () {
      expect(container.read(settingsProvider).biometricLogin, isFalse);
    });
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

    test('show(onboarding) moves from splash to onboarding', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.onboarding);
      expect(container.read(authFlowProvider).stage, AuthStage.onboarding);
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

    test(
      'show(claimIdentity) then onContinue path through to chooseSkillworld',
      () {
        final notifier = container.read(authFlowProvider.notifier);
        notifier.show(AuthStage.claimIdentity);
        notifier.setUsername('veek');
        expect(container.read(authFlowProvider).username, 'veek');

        notifier.show(AuthStage.whatBringsYouHere);
        notifier.setGoal('Build a verified portfolio');
        expect(
          container.read(authFlowProvider).goal,
          'Build a verified portfolio',
        );

        notifier.show(AuthStage.chooseSkillworld);
        notifier.setSkillworld('Design');
        expect(container.read(authFlowProvider).skillworld, 'Design');
      },
    );
  });

  group('signIn() local validation (network failures covered by repository tests)', () {
    test('empty email sets signInError and stays on signIn', () async {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      final ok = await notifier.signIn('', 'anyPassword');
      final state = container.read(authFlowProvider);
      expect(ok, isFalse);
      expect(state.signInError, signInEmailError);
      // Password success must never advance to fingerprint (biometric is
      // an alternative entry path, not a post-password stage).
      expect(state.stage, AuthStage.signIn);
    });

    test('whitespace-only email treated as empty', () async {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.signIn);
      await notifier.signIn('   ', 'anyPassword');
      expect(
        container.read(authFlowProvider).signInError,
        signInEmailError,
      );
      expect(container.read(authFlowProvider).stage, AuthStage.signIn);
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
      expect(
        container.read(authFlowProvider).goal,
        'Build a verified portfolio',
      );
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
      const original = AuthFlowState(
        stage: AuthStage.signIn,
        username: 'original',
      );

      final updated = original.copyWith(
        stage: AuthStage.createAccount,
        username: 'updated',
      );

      // Updated has new values.
      expect(updated.stage, AuthStage.createAccount);
      expect(updated.username, 'updated');

      // Original is unchanged.
      expect(original.stage, AuthStage.signIn);
      expect(original.username, 'original');
    });

    test('copyWith clearError=true forces signInError to null', () {
      const original = AuthFlowState(
        stage: AuthStage.signIn,
        signInError: 'bad',
      );

      final updated = original.copyWith(clearError: true);

      expect(updated.signInError, isNull);
      expect(updated.stage, AuthStage.signIn); // unchanged
    });

    test(
      'copyWith clearError=false with new signInError keeps the new value',
      () {
        const original = AuthFlowState(
          stage: AuthStage.signIn,
          signInError: 'old',
        );

        final updated = original.copyWith(signInError: 'new');

        expect(updated.signInError, 'new');
      },
    );
  });

  group('showLegal() / closeLegal() remember the caller', () {
    test('closeLegal returns to the stage that opened the document', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.onboarding);

      notifier.showLegal(AuthStage.terms);
      expect(container.read(authFlowProvider).stage, AuthStage.terms);

      notifier.closeLegal();
      expect(container.read(authFlowProvider).stage, AuthStage.onboarding);
    });

    test('opening from createAccount returns to createAccount', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.createAccount);

      notifier.showLegal(AuthStage.privacy);
      notifier.closeLegal();

      expect(container.read(authFlowProvider).stage, AuthStage.createAccount);
    });

    test('legalReturn defaults to onboarding', () {
      expect(
        container.read(authFlowProvider).legalReturn,
        AuthStage.onboarding,
      );
    });
  });

  group('onboarding → auth entry points', () {
    test('onboarding can advance to signIn', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.onboarding);
      notifier.show(AuthStage.signIn);
      expect(container.read(authFlowProvider).stage, AuthStage.signIn);
    });

    test('onboarding can jump directly to createAccount', () {
      final notifier = container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.onboarding);
      notifier.show(AuthStage.createAccount);
      expect(container.read(authFlowProvider).stage, AuthStage.createAccount);
    });
  });

  group('forgot-password → reset', () {
    /// A container whose auth calls all succeed, or all fail with [failure].
    ({ProviderContainer container, _FakeAuthRepository repo}) withRepo({
      SkifluxFailure? failure,
      SkifluxFailure? resetFailure,
    }) {
      final repo = _FakeAuthRepository(
        failure: failure,
        resetFailure: resetFailure,
      );
      final c = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      return (container: c, repo: repo);
    }

    test('the code screen checks the code before the password screen', () async {
      final env = withRepo();
      final notifier = env.container.read(authFlowProvider.notifier);

      await notifier.forgotPassword('rider@skiflux.com');
      expect(env.container.read(authFlowProvider).stage, AuthStage.verifyReset);

      expect(await notifier.verifyResetOtp('654321'), isTrue);
      expect(env.repo.verifiedOtps, ['654321']);
      expect(
        env.container.read(authFlowProvider).stage,
        AuthStage.resetPassword,
      );
    });

    test('a rejected code keeps the user on the code screen', () async {
      final env = withRepo(
        failure: const SkifluxFailure(SkifluxErrorKind.authFailed),
      );
      final notifier = env.container.read(authFlowProvider.notifier);
      notifier.show(AuthStage.verifyReset);

      expect(await notifier.verifyResetOtp('000000'), isFalse);

      // The regression this whole change is about: the code used to be accepted
      // here and rejected on the *password* screen, where the error read as a
      // rejected password.
      final state = env.container.read(authFlowProvider);
      expect(state.stage, AuthStage.verifyReset);
      expect(state.signInError, isNotNull);
    });

    test('the verified code is spent by the reset, and only once', () async {
      final env = withRepo();
      final notifier = env.container.read(authFlowProvider.notifier);

      await notifier.forgotPassword('rider@skiflux.com');
      await notifier.verifyResetOtp('654321');
      expect(
        await notifier.resetPassword(
          password: 'Sk1flux!pass',
          confirmPassword: 'Sk1flux!pass',
        ),
        isTrue,
      );

      expect(env.repo.resets.single, (
        email: 'rider@skiflux.com',
        otp: '654321',
        password: 'Sk1flux!pass',
      ));
      expect(
        env.container.read(authFlowProvider).stage,
        AuthStage.passwordUpdated,
      );
    });

    test('never posts an empty otp', () async {
      final env = withRepo();
      final notifier = env.container.read(authFlowProvider.notifier);
      // Straight to the password screen with no code held — the spec requires
      // exactly six characters, so an empty one is a 400 that would read as a
      // rejected password.
      notifier.show(AuthStage.resetPassword);

      expect(
        await notifier.resetPassword(
          password: 'Sk1flux!pass',
          confirmPassword: 'Sk1flux!pass',
        ),
        isFalse,
      );

      expect(env.repo.resets, isEmpty);
      final state = env.container.read(authFlowProvider);
      expect(state.stage, AuthStage.verifyReset);
      expect(state.signInError, isNotNull);
    });

    test('a code the reset rejects sends the user back for a new one', () async {
      // The reported dead end: the password screen has no field for the code,
      // so a code error left there cannot be acted on — retyping the password
      // repeats the same rejection forever.
      final env = withRepo(
        resetFailure: _fieldError({
          'otp': ['This code has expired.'],
        }),
      );
      final notifier = env.container.read(authFlowProvider.notifier);

      await notifier.forgotPassword('rider@skiflux.com');
      await notifier.verifyResetOtp('654321');
      expect(
        await notifier.resetPassword(
          password: 'Sk1flux!pass',
          confirmPassword: 'Sk1flux!pass',
        ),
        isFalse,
      );

      final state = env.container.read(authFlowProvider);
      expect(state.stage, AuthStage.verifyReset);
      expect(state.signInError, contains('no longer valid'));
    });

    test('the rejected code is dropped, not resent', () async {
      final env = withRepo(
        resetFailure: _fieldError({
          'otp': ['This code has expired.'],
        }),
      );
      final notifier = env.container.read(authFlowProvider.notifier);

      await notifier.forgotPassword('rider@skiflux.com');
      await notifier.verifyResetOtp('654321');
      await notifier.resetPassword(
        password: 'Sk1flux!pass',
        confirmPassword: 'Sk1flux!pass',
      );

      // Second attempt without re-entering a code: nothing to send, so the
      // store must refuse locally rather than post the dead code again.
      notifier.show(AuthStage.resetPassword);
      expect(
        await notifier.resetPassword(
          password: 'Sk1flux!pass',
          confirmPassword: 'Sk1flux!pass',
        ),
        isFalse,
      );
      expect(env.container.read(authFlowProvider).stage, AuthStage.verifyReset);
    });

    test('a rejected password stays on the password screen', () async {
      // The other half of the split: this one the user can act on where they
      // are, so moving them would lose what they typed for no reason.
      final env = withRepo(
        resetFailure: _fieldError({
          'new_password': ['This password is too common.'],
        }),
      );
      final notifier = env.container.read(authFlowProvider.notifier);

      await notifier.forgotPassword('rider@skiflux.com');
      await notifier.verifyResetOtp('654321');
      expect(
        await notifier.resetPassword(
          password: 'Password1!',
          confirmPassword: 'Password1!',
        ),
        isFalse,
      );

      final state = env.container.read(authFlowProvider);
      expect(state.stage, AuthStage.resetPassword);
      expect(state.signInError, 'This password is too common.');
    });
  });
}

/// Records the reset flow's calls, and fails them all when [failure] is set.
///
/// [resetFailure] fails the reset step alone — the case where the code passed
/// the check on the previous screen and the server refuses it anyway.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.failure, this.resetFailure})
    : super(Dio(), TokenStore(_storage));

  static const _storage = FlutterSecureStorage();

  final SkifluxFailure? failure;
  final SkifluxFailure? resetFailure;
  final List<String> verifiedOtps = [];
  final List<({String email, String otp, String password})> resets = [];

  @override
  Future<void> forgotPassword({required String email}) async {
    final f = failure;
    if (f != null) throw f;
  }

  @override
  Future<void> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final f = failure;
    if (f != null) throw f;
    verifiedOtps.add(otp);
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final f = failure ?? resetFailure;
    if (f != null) throw f;
    resets.add((email: email, otp: otp, password: newPassword));
  }
}

/// A DRF-shaped 400 with per-field messages, which is what the store reads to
/// tell a rejected code from a rejected password.
SkifluxFailure _fieldError(Map<String, List<String>> fields) => SkifluxFailure(
  SkifluxErrorKind.authFailed,
  cause: ApiException(
    kind: SkifluxErrorKind.authFailed,
    statusCode: 400,
    fieldErrors: fields,
  ),
);
