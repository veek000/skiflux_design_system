import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../features/auth/auth_flow.dart';
import '../features/profile/data/devices_repository.dart';
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
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Skiflux Mobile App V2',
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

  Future<void> _attachFcm() async {
    final fcm = ref.read(fcmServiceProvider);
    fcm.onForegroundDisplay = (message) {
      final navContext = rootNavigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;
      SkifluxToast.info(navContext, message);
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
