import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../l10n/app_localizations.dart';

import '../features/auth/auth_flow.dart';
import '../features/auth/data/auth_store.dart';
import '../features/notifications/data/notifications_store.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/data/devices_repository.dart';
import '../features/profile/data/profile_store.dart';
import '../shared/network/api_client.dart';
import '../shared/network/connectivity_banner.dart';
import '../shared/network/token_store.dart';
import '../shared/notifications/fcm_service.dart';
import '../shared/notifications/local_notifications.dart';
import '../shared/toast/skiflux_toast.dart';

/// Shared navigator key so FCM foreground toasts can resolve a
/// [BuildContext] under [MaterialApp] even across route changes.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Root widget: wires the Skiflux theme to the screen flow.
///
/// **Auth reauth is central.** [authGateProvider] is the only signal that
/// routes the user back to the password form after an in-app session death.
/// Screens never push auth routes on 401 — that raced with this listener and
/// left users staring at "couldn't load video" instead of sign-in.
class SkifluxMobileAppV2 extends ConsumerStatefulWidget {
  const SkifluxMobileAppV2({super.key});

  @override
  ConsumerState<SkifluxMobileAppV2> createState() => _SkifluxMobileAppV2State();
}

class _SkifluxMobileAppV2State extends ConsumerState<SkifluxMobileAppV2> {
  var _fcmAttached = false;

  /// One in-flight reauth navigation — concurrent 401s only arm the gate once,
  /// but the listen can still fire while a push is already underway.
  var _routingToSignIn = false;

  @override
  Widget build(BuildContext context) {
    // THE single reauth listener. [AuthGate.declareSessionLost] is the only
    // writer of needsReauth; biometric/cold-start never set it.
    ref.listen<AuthGateState>(authGateProvider, (previous, next) {
      if (!next.needsReauth) return;
      if (previous?.generation == next.generation && previous?.needsReauth == true) {
        return;
      }
      _routeToSignIn(next.reauthMessage);
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
        if (!_fcmAttached) {
          _fcmAttached = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_attachFcm());
          });
        }
        return ConnectivityBanner(child: child ?? const SizedBox.shrink());
      },
    );
  }

  /// Replace the whole stack with the password form. Idempotent.
  void _routeToSignIn(String? message) {
    if (_routingToSignIn) return;
    _routingToSignIn = true;

    final navigator = rootNavigatorKey.currentState;
    final navContext = rootNavigatorKey.currentContext;
    if (navigator == null || navContext == null || !navContext.mounted) {
      _routingToSignIn = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _routeToSignIn(message),
      );
      return;
    }

    ref.invalidate(meProfileProvider);
    final gate = ref.read(authGateProvider.notifier);
    // Auth stack is about to own the UI — suppress further reauth arms until
    // the user is back in the app after a successful sign-in.
    gate.enterAuthStack();
    gate.markReauthHandled();

    final copy = message ?? 'Your session expired. Please sign in again.';
    SkifluxToast.info(navContext, copy);

    unawaited(
      navigator
          .pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const AuthFlow(startAt: AuthStage.signIn),
            ),
            (route) => false,
          )
          .whenComplete(() => _routingToSignIn = false),
    );
  }

  Future<void> _attachFcm() async {
    final fcm = ref.read(fcmServiceProvider);
    final local = ref.read(localNotificationsProvider);

    fcm.onForegroundDisplay = ({required title, required body}) {
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        SkifluxToast.info(navContext, body);
      }
      // Android tray while foregrounded — FCM alone only surfaces a toast
      // here, so the shade stayed empty for in-app arrivals.
      unawaited(local.showPush(title: title, body: body));
      unawaited(ref.read(notificationsProvider.notifier).refreshFromBackend());
    };
    fcm.onNotificationTap = (_) => _openNotificationsScreen();
    fcm.onTokenRefresh = (token) {
      unawaited(_registerDeviceToken(token));
    };

    // Local tray taps for general/push lines only — download progress
    // notifications carry no payload and must not hijack this route.
    local.onNotificationTap = (payload) {
      if (payload == LocalNotifications.openNotificationsPayload) {
        _openNotificationsScreen();
      }
    };
    // Ensure the plugin is initialised so cold-start tap details are read.
    unawaited(local.requestPermission());

    await fcm.attachListeners();
    await fcm.getToken();
    await _maybeRegisterDevice(fcm);
  }

  /// Opens [NotificationsScreen] without stacking duplicates when the user
  /// already has it on top (bell + tray tap + FCM tap can race).
  void _openNotificationsScreen() {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    unawaited(ref.read(notificationsProvider.notifier).refreshFromBackend());
    if (NotificationsScreen.isOpen) return;
    navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: NotificationsScreen.routeName),
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  Future<void> _maybeRegisterDevice(FcmService fcm) async {
    if (!await ref.read(tokenStoreProvider).hasSession()) return;
    await fcm.registerTokenWithBackend(_registerDeviceToken);
  }

  Future<void> _registerDeviceToken(String token) async {
    if (!await ref.read(tokenStoreProvider).hasSession()) return;
    try {
      await ref.read(devicesRepositoryProvider).registerDevice(token: token);
    } catch (e, st) {
      debugPrint('Device token register failed: $e\n$st');
    }
  }
}
