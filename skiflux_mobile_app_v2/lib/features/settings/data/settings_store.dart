import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App-wide preference state for the Settings flow — notification toggles,
// security switches, download quality, app language, and privacy toggles.
//
// Figma: **Settings Flow** (`1256:21198` and detail frames). No backend yet,
// so this is a session-local Riverpod store seeded with the defaults shown in
// the frames (which toggles start on/off, which quality/language is selected).
// TODO(backend, blocking): persist and sync these preferences with the backend user-settings record — expects: {notifications: Map<String,bool>, biometricLogin: bool, twoFactorAuth: bool, autoPlayNext: bool, downloadQuality: String, downloadOnWifiOnly: bool, appLanguage: String, saveWatchHistory: bool, personalisedRecommendations: bool}

/// The notification switches on the Notifications frame (`1256:20787`),
/// grouped Activity / Coins & Rewards / Platform.
enum NotificationPref {
  newEpisodes,
  taskUpdates,
  commentReplies,
  commentLikes,
  coinEarnings,
  badges,
  platformAnnouncements,
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

  @override
  SettingsState build() {
    // Load persisted settings
    SharedPreferences.getInstance().then((prefs) {
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
        biometricLogin: bio ?? state.biometricLogin,
        twoFactorAuth: twoFa ?? state.twoFactorAuth,
        autoPlayNext: autoPlay ?? state.autoPlayNext,
        downloadQuality: qual ?? state.downloadQuality,
        downloadOnWifiOnly: wifiOnly ?? state.downloadOnWifiOnly,
        appLanguage: lang ?? state.appLanguage,
        saveWatchHistory: saveHist ?? state.saveWatchHistory,
        personalisedRecommendations: recs ?? state.personalisedRecommendations,
      );
    }).catchError((_) => null);

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

  void toggleNotification(NotificationPref pref, bool value) {
    state = state.copyWith(
      notifications: {...state.notifications, pref: value},
    );
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
    SharedPreferences.getInstance().then((p) => p.setString(_downloadQualityKey, quality.name)).catchError((_) => false);
  }

  void setDownloadOnWifiOnly(bool value) {
    state = state.copyWith(downloadOnWifiOnly: value);
    _saveBool(_wifiOnlyKey, value);
  }

  void setAppLanguage(AppLanguage language) {
    state = state.copyWith(appLanguage: language);
    SharedPreferences.getInstance().then((p) => p.setString(_languageKey, language.name)).catchError((_) => false);
  }

  void setSaveWatchHistory(bool value) {
    state = state.copyWith(saveWatchHistory: value);
    _saveBool(_saveHistoryKey, value);
  }

  void setPersonalisedRecommendations(bool value) {
    state = state.copyWith(personalisedRecommendations: value);
    _saveBool(_recommendationsKey, value);
  }

  void _saveBool(String key, bool value) {
    SharedPreferences.getInstance().then((p) => p.setBool(key, value)).catchError((_) => false);
  }
}
