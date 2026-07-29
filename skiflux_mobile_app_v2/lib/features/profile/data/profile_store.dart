/// Authenticated learner profile — `GET /me/profile`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/token_store.dart';
import 'models/user_profile.dart';
import 'profile_repository.dart';

/// Remote profile when a session exists; `null` when signed out.
final meProfileProvider =
    AsyncNotifierProvider<MeProfileNotifier, UserProfile?>(
      MeProfileNotifier.new,
    );

class MeProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() => _load();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<UserProfile?> _load() async {
    final hasSession = await ref.read(tokenStoreProvider).hasSession();
    if (!hasSession) return null;
    return ref.read(profileRepositoryProvider).getProfile();
  }

  Future<UserProfile?> save({
    String? firstName,
    String? lastName,
    String? username,
    String? avatarPath,
  }) async {
    final updated = await ref.read(profileRepositoryProvider).updateProfile(
      firstName: firstName,
      lastName: lastName,
      username: username,
      avatarPath: avatarPath,
    );
    if (updated != null) {
      state = AsyncData(updated);
      return updated;
    }
    // Some backends return 204 — re-fetch.
    await refresh();
    return state.value;
  }
}

/// Whether the keychain currently holds a token pair (cheap session gate).
final hasSessionProvider = FutureProvider<bool>((ref) {
  return ref.watch(tokenStoreProvider).hasSession();
});

/// Convenience: throws [SkifluxFailure] if a load failed (for ErrorDisplay).
void rethrowProfileFailure(AsyncValue<UserProfile?> value) {
  if (value.hasError) {
    final err = value.error;
    if (err is SkifluxFailure) throw err;
    throw SkifluxFailure(
      SkifluxErrorKind.contentLoadFailed,
      cause: err,
      stackTrace: value.stackTrace,
    );
  }
}
