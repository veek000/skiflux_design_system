import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/app/app.dart';
import 'package:skiflux_mobile_app_v2/features/home/home_screen.dart';

void main() {
  testWidgets('App loads root widget', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SkifluxMobileAppV2(),
      ),
    );
    expect(find.byType(SkifluxMobileAppV2), findsOneWidget);
  });

  testWidgets('Home screen loads', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProviderScope(
          child: HomeScreen(),
        ),
      ),
    );
    expect(find.text('Amara Design'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
