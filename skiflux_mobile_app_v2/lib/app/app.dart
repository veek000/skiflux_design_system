import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../l10n/app_localizations.dart';

import '../features/auth/auth_flow.dart';
import '../features/notifications/data/notifications_store.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/data/devices_repository.dart';
import '../features/profile/data/profile_store.dart';
import '../shared/network/api_client.dart';
import '../shared/network/connectivity_banner.dart';
import '../shared/network/token_store.dart';
import '../shared/notifications/fcm_service.dart';
import '../shared/toast/skiflux_toast.dart';

/// Shared navigator key so FCM foreground toasts can resolve a
/// [BuildContext] under [MaterialApp] even across route changes.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Root widget: wires the Skiflux theme to the screen flow.
///
/// [ConsumerStatefulWidget] so the FCM shell can attach listeners once a
/// [BuildContext] with a [ScaffoldMessenger] is available (foreground toasts).
class SkifluxMobileAppV2 extends ConsumerStatefulWidget {
  const SkifluxMobileAppV2({super.key});

  @override
  ConsumerState<SkifluxMobileAppV2> createState() => _SkifluxMobileAppV2State();
}

class _SkifluxMobileAppV2State extends ConsumerState<SkifluxMobileAppV2> {
  var _fcmAttached = false;

  @override
  Widget build(BuildContext context) {
    // The session ended while the app was open — the access token expired and
    // the refresh was rejected, so [AuthInterceptor] cleared the keychain.
    //
    // Nothing listened to this signal before, which is why an expired session
    // was invisible: the tokens were gone but the app stayed on Home, every
    // provider quietly took its "no session" branch, and the user was left
    // looking at empty states and skeletons with no way to understand why.
    ref.listen(sessionLostProvider, (previous, next) {
      // The provider is created at 0; only an actual increment is an expiry.
      if (previous == null || next <= previous) return;
      _onSessionLost();
    });

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Skiflux Mobile App V2',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: SkifluxAppTheme.light,
      home: const AuthFlow(),
      builder: (context, child) {
        // Attach after the first frame so ScaffoldMessenger is reachable.
        // Permission is intentionally NOT requested here — iOS prompt is
        // once-ever; product still picks the moment (see FcmService).
        if (!_fcmAttached) {
          _fcmAttached = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_attachFcm());
          });
        }
        // Above every route, so the offline bar survives navigation — the
        // condition it reports is not tied to one screen.
        return ConnectivityBanner(child: child ?? const SizedBox.shrink());
      },
    );
  }

  /// Guards against a burst: several screens can 401 at once, and each one
  /// signals. One trip to sign-in is enough.
  var _routingToSignIn = false;

  /// Send the user back to sign-in, saying why.
  ///
  /// The keychain is already clear by the time this runs — the interceptor
  /// does that before signalling — so this is navigation and cleanup, not
  /// sign-out. The cached profile goes with it: leaving it would greet the
  /// next sign-in with the previous account's name.
  void _onSessionLost() {
    if (_routingToSignIn) return;
    _routingToSignIn = true;
    final navigator = rootNavigatorKey.currentState;
    final navContext = rootNavigatorKey.currentContext;
    if (navigator == null || navContext == null || !navContext.mounted) {
      _routingToSignIn = false;
      return;
    }
    ref.invalidate(meProfileProvider);
    SkifluxToast.info(navContext, 'Your session expired. Please sign in again.');
    unawaited(
      navigator
          .pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const AuthFlow()),
            (route) => false,
          )
          .whenComplete(() => _routingToSignIn = false),
    );
  }

  Future<void> _attachFcm() async {
    final fcm = ref.read(fcmServiceProvider);
    fcm.onForegroundDisplay = (message) {
      final navContext = rootNavigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      SkifluxToast.info(navContext, message);
    };
    fcm.onNotificationTap = (_) {
      final navContext = rootNavigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      // The list is the honest destination for every notification type: the
      // tapped one is in it, and the ones with nowhere else to go ("Welcome
      // to Skiflux") belong there and nowhere else. The payload is logged but
      // not switched on — `NotificationItem.data` is typed `{}` in the spec,
      // so per-type deep links would be guesswork.
      unawaited(ref.read(notificationsProvider.notifier).refreshFromBackend());
      Navigator.of(navContext).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
    };
    await fcm.attachListeners();
    // Token probe only — no permission prompt at cold start.
    await fcm.getToken();
    // Register with backend when a session already exists (cold start).
    await _maybeRegisterDevice(fcm);
  }

  Future<void> _maybeRegisterDevice(FcmService fcm) async {
    if (!await ref.read(tokenStoreProvider).hasSession()) return;
    await fcm.registerTokenWithBackend((token) {
      return ref.read(devicesRepositoryProvider).registerDevice(token: token);
    });
  }
}
