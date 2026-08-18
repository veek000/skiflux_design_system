import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/app/app.dart';
import 'package:skiflux/features/home/home_screen.dart';
import 'package:skiflux/shared/notifications/fcm_service.dart';

import 'providers/fcm_service_test.dart' show FakeFcmService;

void main() {
  testWidgets('App loads root widget', (tester) async {
    // Override FCM so the post-frame attach path never touches the plugin.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fcmServiceProvider.overrideWithValue(FakeFcmService()),
        ],
        child: const SkifluxMobileAppV2(),
      ),
    );
    await tester.pump(); // flush post-frame FCM attach
    expect(find.byType(SkifluxMobileAppV2), findsOneWidget);
  });

  testWidgets('Home screen loads with no invented content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProviderScope(child: HomeScreen())),
    );
    // Not pumpAndSettle: the loading skeleton shimmers on a repeating
    // controller, so there is no "settled" frame to wait for.
    await tester.pump();

    // Chrome is up regardless of whether recommendations arrived.
    expect(find.text('Home'), findsOneWidget);
    // With no backend the feed has nothing in it, and it must stay that way —
    // "Amara Design" was one of the seeded creators that used to appear here.
    expect(find.text('Amara Design'), findsNothing);
  });
}

