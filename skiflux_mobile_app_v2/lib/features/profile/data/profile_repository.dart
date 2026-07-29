import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'models/user_profile.dart';

/// Learner profile read/update — `/me/profile`, `/me/update`.
class ProfileRepository extends ApiRepository {
  const ProfileRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  static const profilePath = '/me/profile';
  static const updatePath = '/me/update';

  Future<UserProfile> getProfile() => getObject(
    profilePath,
    parse: UserProfile.fromJson,
  );

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
          contentType: 'multipart/form-data',
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
