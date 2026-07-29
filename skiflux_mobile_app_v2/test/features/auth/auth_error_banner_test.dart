/// The inline auth error banner, and the one message it must not print.
///
/// A dropped connection surfaces in two places at once: the app-wide offline
/// bar, and this banner via `_signInMessage`. Both carried the identical
/// sentence, so a failed sign-in on a dead network read as two separate faults
/// stacked on one screen. The bar wins — it is the one that knows when the
/// condition ends — and the banner stands down for that message only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/auth/screens/auth_chrome.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';
import 'package:skiflux_mobile_app_v2/shared/network/connectivity_store.dart';

/// Pins the status without the probe machinery. The banner's whole contract is
/// "what does the bar currently say" — driving it through `reportFailure` would
/// only start retry timers this test has no server to answer.
class _FixedConnectivity extends ConnectivityNotifier {
  _FixedConnectivity(this.status);

  final ConnectivityStatus status;

  @override
  ConnectivityStatus build() => status;
}

Future<void> _pump(
  WidgetTester tester, {
  required String message,
  required bool offline,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectivityProvider.overrideWith(
          () => _FixedConnectivity(
            offline ? ConnectivityStatus.offline : ConnectivityStatus.online,
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: AuthErrorBanner(message: message)),
      ),
    ),
  );
}

void main() {
  testWidgets('the offline copy is suppressed while the bar is showing it', (
    tester,
  ) async {
    await _pump(tester, message: kNoConnectionMessage, offline: true);

    expect(find.text(kNoConnectionMessage), findsNothing);
  });

  testWidgets('the same copy still prints when the app believes it is online', (
    tester,
  ) async {
    // A single request can fail on a link the probe still considers up — the
    // user has to be told something, and no bar is covering it.
    await _pump(tester, message: kNoConnectionMessage, offline: false);

    expect(find.text(kNoConnectionMessage), findsOneWidget);
  });

  testWidgets('an action-specific failure prints even while offline', (
    tester,
  ) async {
    // The bar says the network is down; it cannot say the password was wrong.
    await _pump(tester, message: 'Incorrect password', offline: true);

    expect(find.text('Incorrect password'), findsOneWidget);
  });
}
