import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/token_store.dart';
import 'notification_prefs_repository.dart';

// App-wide preference state for the Settings flow — notification toggles,
// security switches, download quality, app language, and privacy toggles.
//
// Figma: **Settings Flow** (`1256:21198` and detail frames). Device-side
// preferences persist to SharedPreferences; the seven notification switches
// additionally sync with `GET/PATCH /me/notification-preferences` (the
// SharedPreferences copy is only the offline cache of the server's answer).

/// Mirrors [SessionEmailStore]'s test gate: under `flutter test` the
/// SharedPreferences platform channel has no implementation, so persistence is
/// skipped and every future here completes immediately.
bool get _useMemoryOnly {
  if (kIsWeb) return false;
  return Platform.environment['FLUTTER_TEST'] == 'true';
}

/// The notification switches on the Notifications frame (`1256:20787`),
/// grouped Activity / Coins & Rewards / Platform.
///
/// [wireName] is the field name in the OpenAPI `NotificationPreferences`
/// schema — the GET body and the PATCH request both use exactly these seven.
enum NotificationPref {
  newEpisodes('new_episodes'),
  taskUpdates('task_updates'),
  commentReplies('comment_replies'),
  commentLikes('comment_likes'),
  coinEarnings('coin_earnings'),
  badges('badges'),
  platformAnnouncements('platform_announcements');

  const NotificationPref(this.wireName);

  final String wireName;
}

/// Download-quality choices (`1256:20009`). Label + per-episode size caption.
enum DownloadQuality {
  sd480('SD 480p', '~110 MB per episode · saves storage'),
  hd720('HD 720p', '~250 MB per episode · recommended'),
  fullHd1080('Full HD 1080p', '~480 MB per episode · best quality');

  const DownloadQuality(this.label, this.caption);

  final String label;
  final String caption;
}

/// App-language choices (`1256:20068`).
enum AppLanguage {
  enUs('English (US)'),
  enUk('English (UK)'),
  french('Français'),
  spanish('Español'),
  portuguese('Português');

  const AppLanguage(this.label);

  final String label;
}

@immutable
class SettingsState {
  const SettingsState({
    required this.notifications,
    required this.biometricLogin,
    required this.twoFactorAuth,
    required this.autoPlayNext,
    required this.downloadQuality,
    required this.downloadOnWifiOnly,
    required this.appLanguage,
    required this.saveWatchHistory,
    required this.personalisedRecommendations,
  });

  final Map<NotificationPref, bool> notifications;
  final bool biometricLogin;
  final bool twoFactorAuth;
  final bool autoPlayNext;
  final DownloadQuality downloadQuality;
  final bool downloadOnWifiOnly;
  final AppLanguage appLanguage;
  final bool saveWatchHistory;
  final bool personalisedRecommendations;

  SettingsState copyWith({
    Map<NotificationPref, bool>? notifications,
    bool? biometricLogin,
    bool? twoFactorAuth,
    bool? autoPlayNext,
    DownloadQuality? downloadQuality,
    bool? downloadOnWifiOnly,
    AppLanguage? appLanguage,
    bool? saveWatchHistory,
    bool? personalisedRecommendations,
  }) {
    return SettingsState(
      notifications: notifications ?? this.notifications,
      biometricLogin: biometricLogin ?? this.biometricLogin,
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      downloadOnWifiOnly: downloadOnWifiOnly ?? this.downloadOnWifiOnly,
      appLanguage: appLanguage ?? this.appLanguage,
      saveWatchHistory: saveWatchHistory ?? this.saveWatchHistory,
      personalisedRecommendations:
          personalisedRecommendations ?? this.personalisedRecommendations,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<SettingsState> {
  static const _biometricKey = 'skiflux.biometric_login';
  static const _twoFactorKey = 'skiflux.two_factor_auth';
  static const _autoPlayKey = 'skiflux.auto_play_next';
  static const _downloadQualityKey = 'skiflux.download_quality';
  static const _wifiOnlyKey = 'skiflux.download_on_wifi_only';
  static const _languageKey = 'skiflux.app_language';
  static const _saveHistoryKey = 'skiflux.save_watch_history';
  static const _recommendationsKey = 'skiflux.personalised_recommendations';

  /// Offline cache of the server's notification preferences, one bool per
  /// [NotificationPref.wireName].
  static const _notificationKeyPrefix = 'skiflux.notification.';

  late Future<void> _ready;

  @override
  SettingsState build() {
    _ready = _hydrate();
    return const SettingsState(
      notifications: {
        NotificationPref.newEpisodes: true,
        NotificationPref.taskUpdates: false,
        NotificationPref.commentReplies: false,
        NotificationPref.commentLikes: false,
        NotificationPref.coinEarnings: true,
        NotificationPref.badges: false,
        NotificationPref.platformAnnouncements: true,
      },
      biometricLogin: false,
      twoFactorAuth: false,
      autoPlayNext: true,
      downloadQuality: DownloadQuality.hd720,
      downloadOnWifiOnly: true,
      appLanguage: AppLanguage.enUk,
      saveWatchHistory: true,
      personalisedRecommendations: true,
    );
  }

  /// Completes once persisted preferences have been applied to [state].
  ///
  /// [build] must return synchronously, so hydration runs detached — which
  /// means an early read (the auth flow's biometric gate decision, session
  /// restore at the splash) would otherwise see the compiled-in defaults and
  /// never the user's real preference. Await this before any decision that
  /// depends on a persisted value. Never throws; an unreadable store just
  /// leaves the defaults in place.
  Future<void> get ready => _ready;

  Future<void> _hydrate() async {
    if (_useMemoryOnly) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final bio = prefs.getBool(_biometricKey);
      final twoFa = prefs.getBool(_twoFactorKey);
      final autoPlay = prefs.getBool(_autoPlayKey);
      final qualName = prefs.getString(_downloadQualityKey);
      final wifiOnly = prefs.getBool(_wifiOnlyKey);
      final langName = prefs.getString(_languageKey);
      final saveHist = prefs.getBool(_saveHistoryKey);
      final recs = prefs.getBool(_recommendationsKey);

      DownloadQuality? qual;
      if (qualName != null) {
        qual = DownloadQuality.values.firstWhere(
          (e) => e.name == qualName,
          orElse: () => DownloadQuality.hd720,
        );
      }

      AppLanguage? lang;
      if (langName != null) {
        lang = AppLanguage.values.firstWhere(
          (e) => e.name == langName,
          orElse: () => AppLanguage.enUk,
        );
      }

      state = state.copyWith(
        notifications: {
          for (final pref in NotificationPref.values)
            pref:
                prefs.getBool('$_notificationKeyPrefix${pref.wireName}') ??
                state.notifications[pref] ??
                false,
        },
        biometricLogin: bio ?? state.biometricLogin,
        twoFactorAuth: twoFa ?? state.twoFactorAuth,
        autoPlayNext: autoPlay ?? state.autoPlayNext,
        downloadQuality: qual ?? state.downloadQuality,
        downloadOnWifiOnly: wifiOnly ?? state.downloadOnWifiOnly,
        appLanguage: lang ?? state.appLanguage,
        saveWatchHistory: saveHist ?? state.saveWatchHistory,
        personalisedRecommendations: recs ?? state.personalisedRecommendations,
      );
    } catch (_) {
      // Unreadable prefs — keep the in-memory defaults.
    }
  }

  /// Pulls `GET /me/notification-preferences` into [state] and the offline
  /// cache. Call when the Notifications screen opens.
  ///
  /// A read: a failure degrades to whatever was hydrated from the cache rather
  /// than surfacing — the screen keeps rendering the last known truth. Skipped
  /// entirely when no session exists (the endpoint needs a bearer token).
  Future<void> syncNotificationPrefs() async {
    // Hydration first, so a slow cache read can't land after the server's
    // fresher answer and overwrite it.
    await _ready;
    try {
      if (!await ref.read(tokenStoreProvider).hasSession()) return;
      final remote = await ref
          .read(notificationPrefsRepositoryProvider)
          .getPreferences();
      final merged = {
        for (final pref in NotificationPref.values)
          pref: remote[pref.wireName] ?? state.notifications[pref] ?? false,
      };
      state = state.copyWith(notifications: merged);
      for (final entry in merged.entries) {
        _cacheNotificationPref(entry.key, entry.value);
      }
    } catch (_) {
      // Includes SkifluxFailure and an unreadable keychain — cached values
      // stay on screen.
    }
  }

  /// One notification switch: optimistic flip, `PATCH
  /// /me/notification-preferences/update`, rollback when the server refuses.
  ///
  /// Rethrows the [SkifluxFailure] after rolling back so the screen surfaces
  /// it (ErrorDisplay); success needs no extra UI — the switch staying put
  /// *is* the confirmation.
  Future<void> setNotificationPref(NotificationPref pref, bool value) async {
    await _ready;
    final previous = state.notifications[pref] ?? false;
    if (previous == value) return;
    state = state.copyWith(
      notifications: {...state.notifications, pref: value},
    );
    _cacheNotificationPref(pref, value);
    try {
      await ref
          .read(notificationPrefsRepositoryProvider)
          .updatePreference(field: pref.wireName, value: value);
    } on SkifluxFailure {
      state = state.copyWith(
        notifications: {...state.notifications, pref: previous},
      );
      _cacheNotificationPref(pref, previous);
      rethrow;
    }
  }

  void setBiometricLogin(bool value) {
    state = state.copyWith(biometricLogin: value);
    _saveBool(_biometricKey, value);
  }

  void setTwoFactorAuth(bool value) {
    state = state.copyWith(twoFactorAuth: value);
    _saveBool(_twoFactorKey, value);
  }

  void setAutoPlayNext(bool value) {
    state = state.copyWith(autoPlayNext: value);
    _saveBool(_autoPlayKey, value);
  }

  void setDownloadQuality(DownloadQuality quality) {
    state = state.copyWith(downloadQuality: quality);
    _saveString(_downloadQualityKey, quality.name);
  }

  void setDownloadOnWifiOnly(bool value) {
    state = state.copyWith(downloadOnWifiOnly: value);
    _saveBool(_wifiOnlyKey, value);
  }

  void setAppLanguage(AppLanguage language) {
    state = state.copyWith(appLanguage: language);
    _saveString(_languageKey, language.name);
  }

  void setSaveWatchHistory(bool value) {
    state = state.copyWith(saveWatchHistory: value);
    _saveBool(_saveHistoryKey, value);
  }

  void setPersonalisedRecommendations(bool value) {
    state = state.copyWith(personalisedRecommendations: value);
    _saveBool(_recommendationsKey, value);
  }

  void _cacheNotificationPref(NotificationPref pref, bool value) =>
      _saveBool('$_notificationKeyPrefix${pref.wireName}', value);

  void _saveBool(String key, bool value) {
    if (_useMemoryOnly) return;
    SharedPreferences.getInstance()
        .then((p) => p.setBool(key, value))
        .catchError((_) => false);
  }

  void _saveString(String key, String value) {
    if (_useMemoryOnly) return;
    SharedPreferences.getInstance()
        .then((p) => p.setString(key, value))
        .catchError((_) => false);
  }
}
