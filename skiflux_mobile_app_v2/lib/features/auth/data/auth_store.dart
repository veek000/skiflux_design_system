/// Auth flow state — session-only representation of the Figma onboarding
/// and authentication flow. Backend authentication is intentionally left
/// for the API integration.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-only representation of the Figma onboarding and authentication
/// flow. Backend authentication is intentionally left for the API integration.
enum AuthStage {
  splash,
  onboardingOne,
  onboardingTwo,
  onboardingThree,
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
  terms,
  privacy,
}

@immutable
class AuthFlowState {
  const AuthFlowState({
    required this.stage,
    this.username = '',
    this.goal,
    this.skillworld,
    this.signInError,
  });

  final AuthStage stage;
  final String username;
  final String? goal;
  final String? skillworld;
  final String? signInError;

  AuthFlowState copyWith({
    AuthStage? stage,
    String? username,
    String? goal,
    String? skillworld,
    String? signInError,
    bool clearError = false,
  }) =>
      AuthFlowState(
        stage: stage ?? this.stage,
        username: username ?? this.username,
        goal: goal ?? this.goal,
        skillworld: skillworld ?? this.skillworld,
        signInError: clearError
            ? null
            : signInError ?? this.signInError,
      );
}

final authFlowProvider =
    NotifierProvider<AuthFlowNotifier, AuthFlowState>(AuthFlowNotifier.new);

class AuthFlowNotifier extends Notifier<AuthFlowState> {
  @override
  AuthFlowState build() => const AuthFlowState(stage: AuthStage.splash);

  void show(AuthStage stage) => state = state.copyWith(stage: stage);
  void setUsername(String value) => state = state.copyWith(username: value);
  void setGoal(String value) => state = state.copyWith(goal: value);
  void setSkillworld(String value) =>
      state = state.copyWith(skillworld: value);
  void clearError() => state = state.copyWith(clearError: true);

  void signIn(String email, String password) {
    if (email.trim().isEmpty || email.contains('missing')) {
      state =
          state.copyWith(signInError: 'No account found with this email');
    } else if (password != 'skiflux') {
      state = state.copyWith(signInError: 'Incorrect password');
    } else {
      state =
          state.copyWith(stage: AuthStage.fingerprint, clearError: true);
    }
  }
}
