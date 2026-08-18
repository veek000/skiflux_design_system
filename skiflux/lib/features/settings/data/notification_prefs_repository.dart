/// Notification-preference sync — `/me/notification-preferences`.
///
/// The wire schema (`NotificationPreferences`) is seven booleans named exactly
/// like `NotificationPref.wireName` plus a read-only `updated_at`; the PATCH
/// body (`PatchedNotificationPreferencesRequest`) takes any subset of the
/// seven. This repository speaks wire names only — the enum mapping lives in
/// `settings_store.dart`, so the two files don't import each other in a cycle.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

class NotificationPrefsRepository extends ApiRepository {
  const NotificationPrefsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  /// `GET /me/notification-preferences` — the user's current switches.
  static const preferencesPath = '/me/notification-preferences';

  /// `PATCH /me/notification-preferences/update` — partial update; send only
  /// the fields being changed.
  static const updatePath = '/me/notification-preferences/update';

  /// Every boolean field in the response, keyed by its wire name. Non-boolean
  /// fields (`updated_at`) are dropped rather than parsed.
  Future<Map<String, bool>> getPreferences() => getObject(
    preferencesPath,
    parse: (json) => <String, bool>{
      for (final entry in json.entries)
        if (entry.value is bool) entry.key: entry.value as bool,
    },
  );

  /// Flips one switch. [field] is a `NotificationPref.wireName`.
  ///
  /// Failure kind is a toast rather than a blocking modal — a preference
  /// toggle that didn't stick is recoverable in place.
  Future<void> updatePreference({
    required String field,
    required bool value,
  }) => patch<void>(
    updatePath,
    body: {field: value},
    kind: SkifluxErrorKind.settingsSaveFailed,
  );
}

final notificationPrefsRepositoryProvider = Provider<NotificationPrefsRepository>(
  (ref) => NotificationPrefsRepository(ref.watch(apiClientProvider)),
);
