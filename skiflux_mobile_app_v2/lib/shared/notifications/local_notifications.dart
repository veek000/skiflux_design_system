/// Notifications the app posts itself, as opposed to the ones FCM delivers.
///
/// Two users so far:
///
///  * **Download progress** — the Netflix pattern. While an episode is
///    transferring, a single silent, ongoing notification carries a
///    determinate bar that advances with the bytes; when the transfer resolves
///    it becomes a normal, dismissible "Downloaded" (or "Download failed")
///    line. Before this the only sign a download was running was the row
///    inside the app, so backgrounding it made the transfer invisible.
///  * **[sendTest]** — a real notification, on demand, from the debug
///    diagnostics panel. A *push* cannot be exercised from inside the app (the
///    message has to come from Firebase, and Android only draws one in the
///    tray when the app is backgrounded), so the diagnostics panel could only
///    ever show the token and the permission state. This posts locally
///    instead, which exercises everything except the FCM transport: the
///    runtime permission, the channel, and the monochrome tray icon.
///
/// **Android only.** iOS has no progress-notification API — the closest thing
/// is re-posting a banner per update, which would be a stream of alerts rather
/// than one quiet bar — so every method here is a no-op off Android. Nothing
/// throws: a notification is a courtesy on top of the thing it describes,
/// never a reason for that thing to fail.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalNotifications {
  LocalNotifications({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Its own channel, so a user who wants transfer noise gone can silence it
  /// without losing episode and reward notifications.
  static const _channelId = 'skiflux.downloads';
  static const _channelName = 'Downloads';
  static const _channelDescription = 'Progress for episodes saved for offline';

  /// Where anything that is not a download lands. Matches the channel FCM's
  /// own messages fall back to, so silencing one silences both.
  static const _generalChannelId = 'skiflux.general';
  static const _generalChannelName = 'General';
  static const _generalChannelDescription = 'Episodes, tasks, rewards';

  /// Payload stamped on general/push tray lines so a tap opens Notifications.
  static const openNotificationsPayload = 'open_notifications';

  /// Fixed id so repeated taps replace the test rather than stack ten of them.
  static const _testId = 424242;

  /// Whether the platform can show a progress notification at all.
  static bool get supported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  var _initialised = false;

  /// Fired when the user taps a local notification (foreground or cold start).
  /// The app shell opens the Notifications screen for [openNotificationsPayload].
  void Function(String? payload)? onNotificationTap;

  Future<bool> requestPermission() async {
    if (!supported) return false;
    try {
      await _ensureInitialised();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureInitialised() async {
    if (_initialised || !supported) return;
    // The same monochrome tray glyph FCM uses (`@drawable/ic_notification`);
    // Android renders a solid grey square without one.
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );
    // Cold start from a tray tap (app was killed).
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      onNotificationTap?.call(launch!.notificationResponse?.payload);
    }
    _initialised = true;
  }

  /// Post (or update) the ongoing bar for [episodeId] at [progress] (0–1).
  ///
  /// `onlyAlertOnce` is what keeps this quiet: without it every percentage
  /// update would buzz. `ongoing` + `autoCancel: false` stop the user swiping
  /// away a transfer that is still running.
  Future<void> showProgress(
    String episodeId,
    String title,
    double progress,
  ) async {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    await _post(
      episodeId,
      title: title,
      body: 'Downloading… $percent%',
      details: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: percent,
      ),
    );
  }

  /// Replace the bar with a finished, dismissible line.
  Future<void> showComplete(String episodeId, String title) => _post(
        episodeId,
        title: title,
        body: 'Downloaded — available offline',
        details: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: true,
        ),
      );

  Future<void> showFailed(String episodeId, String title) => _post(
        episodeId,
        title: title,
        body: 'Download failed — tap the episode to try again',
        details: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          onlyAlertOnce: true,
        ),
      );

  /// Post a real notification to the tray, now.
  ///
  /// Returns false when nothing could be posted — an unsupported platform, or
  /// a permission the user has not granted — so the caller can say *why*
  /// rather than claiming it sent one. That distinction is the whole point:
  /// "nothing happened" is exactly the report this is meant to explain.
  ///
  /// Uses the app's general channel rather than the downloads one, so it is
  /// silenced by the same switch a real notification would be.
  Future<bool> sendTest() => showPush(
        title: 'Test notification',
        body: 'If you can read this, notifications are working.',
        id: _testId,
      );

  /// Tray line for a push that arrived while the app is in the foreground
  /// (or a data-only FCM message in the background isolate).
  ///
  /// Android only — iOS still relies on APNs presentation. Returns false when
  /// nothing could be posted so callers can fall back to an in-app toast.
  Future<bool> showPush({
    required String title,
    required String body,
    int? id,
    String? payload,
  }) async {
    if (!supported) return false;
    try {
      await _ensureInitialised();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.areNotificationsEnabled() ?? true;
      if (!granted) return false;

      await _plugin.show(
        id: id ?? DateTime.now().millisecondsSinceEpoch & 0x3FFFFFFF,
        title: title,
        body: body,
        payload: payload ?? openNotificationsPayload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _generalChannelId,
            _generalChannelName,
            channelDescription: _generalChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      return true;
    } catch (error) {
      debugPrint('Push notification not shown: $error');
      return false;
    }
  }

  /// Pull the notification, for a download the user cancelled or deleted.
  Future<void> cancel(String episodeId) async {
    if (!supported) return;
    try {
      await _ensureInitialised();
      await _plugin.cancel(id: _idFor(episodeId));
    } catch (error) {
      debugPrint('Download notification not cancelled: $error');
    }
  }

  Future<void> _post(
    String episodeId, {
    required String title,
    required String body,
    required AndroidNotificationDetails details,
  }) async {
    if (!supported) return;
    try {
      await _ensureInitialised();
      await _plugin.show(
        id: _idFor(episodeId),
        title: title,
        body: body,
        notificationDetails: NotificationDetails(android: details),
      );
    } catch (error) {
      // A tray that refuses the post (permission denied, channel blocked) must
      // not take the download down with it.
      debugPrint('Download notification not shown: $error');
    }
  }

  /// One stable notification id per episode, so updates replace rather than
  /// stack. Episode ids are UUID strings; `hashCode` is masked into the
  /// positive 31-bit range Android's `notify()` accepts.
  static int _idFor(String episodeId) => episodeId.hashCode & 0x3FFFFFFF;
}

final localNotificationsProvider = Provider<LocalNotifications>(
  (ref) => LocalNotifications(),
);
