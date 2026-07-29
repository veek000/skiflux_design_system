import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  SettingsState build() {
    return const SettingsState(
      // Defaults per the Notifications frame: New episodes, Coin earnings and
      // Platform announcements on; the rest off.
      notifications: {
        NotificationPref.newEpisodes: true,
        NotificationPref.taskUpdates: false,
        NotificationPref.commentReplies: false,
        NotificationPref.commentLikes: false,
        NotificationPref.coinEarnings: true,
        NotificationPref.badges: false,
        NotificationPref.platformAnnouncements: true,
      },
      // Opt-in: biometric is an alternative login path, not on by default.
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

  void setBiometricLogin(bool value) =>
      state = state.copyWith(biometricLogin: value);

  void setTwoFactorAuth(bool value) =>
      state = state.copyWith(twoFactorAuth: value);

  void setAutoPlayNext(bool value) =>
      state = state.copyWith(autoPlayNext: value);

  void setDownloadQuality(DownloadQuality quality) =>
      state = state.copyWith(downloadQuality: quality);

  void setDownloadOnWifiOnly(bool value) =>
      state = state.copyWith(downloadOnWifiOnly: value);

  void setAppLanguage(AppLanguage language) =>
      state = state.copyWith(appLanguage: language);

  void setSaveWatchHistory(bool value) =>
      state = state.copyWith(saveWatchHistory: value);

  void setPersonalisedRecommendations(bool value) =>
      state = state.copyWith(personalisedRecommendations: value);
}
