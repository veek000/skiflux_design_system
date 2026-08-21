import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'models/user_profile.dart';

/// Learner profile read/update — `/me/profile`, `/me/update`,
/// `/profile/complete-onboarding/`.
class ProfileRepository extends ApiRepository {
  const ProfileRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  static const profilePath = '/me/profile';
  static const updatePath = '/me/update';

  /// `POST /profile/complete-onboarding/` — trailing slash per the spec.
  static const completeOnboardingPath = '/profile/complete-onboarding/';

  Future<UserProfile> getProfile() => getObject(
    profilePath,
    parse: UserProfile.fromJson,
  );

  /// `POST /profile/complete-onboarding/` — hands the sign-up wizard's answers
  /// to the backend and marks the account as onboarded.
  ///
  /// The spec's `CompleteOnboardingRequest` is multipart-only: `username`,
  /// `goal[]` and `skillworld[]` required (wire enum values, e.g.
  /// `build_portfolio`, `design`), `avatar` an optional binary, `country` an
  /// optional ISO alpha-2 the wizard never collects — so it is omitted, which
  /// the schema allows. Always multipart, even without an avatar, because
  /// that is the only request content type the spec documents for this path.
  ///
  /// Response is `200 Onboarding complete` with no documented schema, so
  /// nothing is parsed; callers refresh `GET /me/profile` for the result.
  Future<void> completeOnboarding({
    required String username,
    required List<String> goal,
    required List<String> skillworld,
    String? avatarPath,
  }) async {
    final form = FormData.fromMap({
      'username': username,
      'goal': goal,
      'skillworld': skillworld,
      if (avatarPath != null && avatarPath.isNotEmpty)
        'avatar': await MultipartFile.fromFile(
          avatarPath,
          filename: avatarPath.split(RegExp(r'[/\\]')).last,
        ),
    });
    await post<void>(
      completeOnboardingPath,
      body: form,
      // A dropped onboarding payload leaves the account half-made — the
      // blocking retry modal, not a passing toast.
      kind: SkifluxErrorKind.taskSubmission,
    );
  }

  /// Multipart when [avatarPath] is set; otherwise JSON fields only.
  Future<UserProfile?> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    String? country,
    String? phone,
    List<String>? skillworld,
    List<String>? goal,
    String? avatarPath,
  }) async {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      final form = FormData.fromMap({
        'first_name': ?firstName,
        'last_name': ?lastName,
        'username': ?username,
        'bio': ?bio,
        'country': ?country,
        'phone': ?phone,
        'skillworld': ?skillworld,
        'goal': ?goal,
        'avatar': await MultipartFile.fromFile(
          avatarPath,
          filename: avatarPath.split(RegExp(r'[/\\]')).last,
        ),
      });
      return patch<UserProfile>(
        updatePath,
        body: form,
        parse: UserProfile.fromJson,
        options: Options(
        ),
      );
    }

    return patch<UserProfile>(
      updatePath,
      body: {
        'first_name': ?firstName,
        'last_name': ?lastName,
        'username': ?username,
        'bio': ?bio,
        'country': ?country,
        'phone': ?phone,
        'skillworld': ?skillworld,
        'goal': ?goal,
      },
      parse: UserProfile.fromJson,
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

