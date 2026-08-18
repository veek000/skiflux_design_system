/// Firebase Cloud Messaging — client receive/display side.
///
/// Platform capability wrapper, same shape as [BiometricAuthenticator]:
/// narrow surface, non-throwing probes, provider-overridable for tests.
/// The Firebase plugin has no implementation under the test binding, so
/// production call sites must go through [fcmServiceProvider] and tests
/// must override it with a fake.
///
/// **Three app states**
/// - Foreground: [FirebaseMessaging.onMessage] → [onForegroundDisplay]
///   (wired to [SkifluxToast.info] by the app shell).
/// - Background: top-level [firebaseMessagingBackgroundHandler] (must stay
///   top-level — a method/closure silently fails to register).
/// - Terminated: [getInitialMessage] on attach (tap deep-link routing is
///   out of scope — tracker #58).
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../firebase_options.dart';
import 'local_notifications.dart';

/// Background isolate entry point for FCM.
///
/// **Must remain a top-level function** (not a method or closure) — Firebase
/// Messaging looks it up by tear-off identity across isolates. Annotate with
/// `@pragma('vm:entry-point')` so tree-shaking cannot drop it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate does not share the main isolate's Firebase app.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Already initialized in this isolate, or init failed — still log below.
  }
  debugPrint(
    'FCM background: id=${message.messageId} '
    'title=${message.notification?.title} '
    'body=${message.notification?.body}',
  );

  // Data-only messages never get an OS tray line. Mirror them locally so
  // background delivery is still visible. Messages that already carry a
  // `notification` payload are left to the system to avoid duplicates.
  if (message.notification != null) return;
  final title = (message.data['title'] as String?)?.trim();
  final body = (message.data['body'] as String?)?.trim() ??
      (message.data['message'] as String?)?.trim();
  if (body == null || body.isEmpty) return;
  try {
    await LocalNotifications().showPush(
      title: (title != null && title.isNotEmpty) ? title : 'Skiflux',
      body: body,
    );
  } catch (e, st) {
    debugPrint('FCM background local notify failed: $e\n$st');
  }
}

/// Thin wrapper around [FirebaseMessaging].
///
/// All public methods catch and degrade — a permission/token probe must never
/// lock the app the way an uncaught biometric probe once did.
class FcmService {
  /// Prefer injecting [messaging] only in production-adjacent tests that
  /// still talk to the plugin. Unit tests should subclass and override
  /// methods so [FirebaseMessaging.instance] is never touched.
  FcmService({FirebaseMessaging? messaging}) : _injected = messaging;

  final FirebaseMessaging? _injected;

  /// Lazy so constructing an override/fake never touches the plugin.
  FirebaseMessaging get _messaging => _injected ?? FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _tokenRefreshSub;

  /// Called when a notification arrives while the app is in the foreground.
  /// The app shell sets this to [SkifluxToast.info]; tests set it to a list
  /// collector. Null = drop the message (still debug-logged).
  ///
  /// [title] / [body] are both filled so the tray can show a proper heading
  /// instead of a generic "Skiflux" over the body alone.
  void Function({required String title, required String body})?
      onForegroundDisplay;

  /// Called when the user taps a notification, from background or a cold
  /// launch. The app shell sets this to open the Notifications screen.
  /// Null = the tap only opens the app, which is the pre-routing behaviour.
  void Function(RemoteMessage message)? onNotificationTap;

  /// Called whenever FCM rotates the registration token. The app shell
  /// re-POSTs to `POST /me/devices` so the backend does not keep pushing to a
  /// dead token after an app reinstall / OS refresh.
  void Function(String token)? onTokenRefresh;

  /// Last known FCM registration token, if any.
  String? lastToken;

  /// Whether the last [requestPermission] call granted alert/banner display.
  /// `null` until permission has been probed at least once.
  bool? permissionGranted;

  /// Request notification permission.
  ///
  /// **Do not call this at cold start.** On iOS the system prompt is shown
  /// **once ever** — if the user declines, recovery requires a trip to
  /// Settings. Call from a deliberate UX moment (soft pre-prompt after
  /// sign-in).
  ///
  /// Never throws: failure / plugin missing → `false` ("notifications
  /// unavailable").
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      permissionGranted = granted;
      // iOS otherwise swallows foreground pushes (no banner, no sound) even
      // when authorised — the toast alone is easy to miss.
      if (granted && !kIsWeb) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      debugPrint(
        'FCM permission: ${settings.authorizationStatus} granted=$granted',
      );
      return granted;
    } catch (e, st) {
      debugPrint('FCM permission probe failed: $e\n$st');
      permissionGranted = false;
      return false;
    }
  }

  /// Obtain the FCM registration token. Debug-logs only; does **not** POST
  /// to the Skiflux backend.
  ///
  /// On iOS, [FirebaseMessaging.getAPNSToken] may be null until APNs
  /// registration finishes (and is permanently null without an APNs auth
  /// key in Firebase + the Push capability). We still attempt [getToken]
  /// and degrade to null on failure.
  ///
  /// Never throws.
  Future<String?> getToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        final apns = await _messaging.getAPNSToken();
        if (apns == null) {
          debugPrint(
            'FCM: APNS token not yet available '
            '(APNs key / Push capability may still be pending).',
          );
        }
      }
      final token = await _messaging.getToken();
      lastToken = token;
      debugPrint('FCM token: $token');
      // Backend registration: [registerTokenWithBackend] after session exists.
      return token;
    } catch (e, st) {
      debugPrint('FCM token unavailable: $e\n$st');
      lastToken = null;
      return null;
    }
  }

  /// Wire the message surfaces + token refresh. Safe to call once after
  /// [Firebase.initializeApp]; idempotent re-attach cancels prior subs.
  ///
  /// Never throws.
  Future<void> attachListeners() async {
    try {
      await _foregroundSub?.cancel();
      await _openedSub?.cancel();
      await _tokenRefreshSub?.cancel();

      _foregroundSub = FirebaseMessaging.onMessage.listen(
        handleForegroundMessage,
        onError: (Object e, StackTrace st) {
          debugPrint('FCM onMessage error: $e\n$st');
        },
      );

      // Terminated → launched by tapping a notification.
      final initial = await _messaging.getInitialMessage();
      if (initial != null) handleNotificationTap(initial);

      // Background → resumed by tapping a notification.
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(
        handleNotificationTap,
        onError: (Object e, StackTrace st) {
          debugPrint('FCM onMessageOpenedApp error: $e\n$st');
        },
      );

      _tokenRefreshSub = _messaging.onTokenRefresh.listen(
        (token) {
          lastToken = token;
          debugPrint('FCM token refreshed');
          onTokenRefresh?.call(token);
        },
        onError: (Object e, StackTrace st) {
          debugPrint('FCM onTokenRefresh error: $e\n$st');
        },
      );
    } catch (e, st) {
      debugPrint('FCM attachListeners failed: $e\n$st');
    }
  }

  /// A notification was tapped, from background or a cold launch.
  ///
  /// Not every notification has somewhere specific to go — "Welcome to
  /// Skiflux" has no episode, no comment and no task behind it — so the
  /// default is the Notifications screen, which is right for all of them and
  /// wrong for none. Per-type deep links can be layered on top once the
  /// backend documents `NotificationItem.data`, which is typed `{}` today;
  /// until then a tap that lands somewhere sensible beats a tap that does
  /// nothing at all, which is what this used to do.
  void handleNotificationTap(RemoteMessage message) {
    debugPrint(
      'FCM notification tap: id=${message.messageId} data=${message.data}',
    );
    onNotificationTap?.call(message);
  }

  /// Display path for a foreground [RemoteMessage]. Public so fakes/tests can
  /// exercise the same copy selection without constructing a platform message.
  void handleForegroundMessage(RemoteMessage message) {
    deliverForegroundCopy(
      title: _titleFor(message),
      body: _bodyFor(message),
    );
  }

  /// Display path when the toast/tray copy is already known (tests / fakes).
  void deliverForegroundCopy({required String title, required String body}) {
    debugPrint('FCM foreground display: "$title" / "$body"');
    onForegroundDisplay?.call(title: title, body: body);
  }

  static String _titleFor(RemoteMessage message) {
    final title = message.notification?.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final dataTitle = (message.data['title'] as String?)?.trim();
    if (dataTitle != null && dataTitle.isNotEmpty) return dataTitle;
    return 'Skiflux';
  }

  static String _bodyFor(RemoteMessage message) {
    final body = message.notification?.body?.trim();
    if (body != null && body.isNotEmpty) return body;
    final dataBody = (message.data['body'] as String?)?.trim() ??
        (message.data['message'] as String?)?.trim();
    if (dataBody != null && dataBody.isNotEmpty) return dataBody;
    final title = message.notification?.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return 'You have a new notification';
  }

  /// POSTs [lastToken] (or a freshly fetched token) to `POST /me/devices`.
  ///
  /// No-ops when there is no token or no [register] callback. Never throws.
  Future<void> registerTokenWithBackend(
    Future<void> Function(String token) register,
  ) async {
    try {
      final token = lastToken ?? await getToken();
      if (token == null || token.isEmpty) return;
      await register(token);
      debugPrint('FCM: registered device token with backend');
    } catch (e, st) {
      debugPrint('FCM backend register failed: $e\n$st');
    }
  }

  /// Cancel stream subscriptions. Called from the provider dispose hook.
  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tokenRefreshSub?.cancel();
    _foregroundSub = null;
    _openedSub = null;
    _tokenRefreshSub = null;
  }
}

/// Real [FcmService] for production. Override in tests with a fake so the
/// Firebase plugin is never touched under the test binding.
final fcmServiceProvider = Provider<FcmService>((ref) {
  final service = FcmService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
