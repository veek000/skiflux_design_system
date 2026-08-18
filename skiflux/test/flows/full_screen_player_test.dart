import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'package:skiflux/features/home/full_screen_player_screen.dart';
import 'package:skiflux/features/playlists/data/playlists_store.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: FullScreenPlayerScreen()),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  group('FullScreenPlayerScreen', () {
    testWidgets('renders only the close and speed controls', (tester) async {
      await _pump(tester);

      expect(find.byIcon(RemixIcons.close_fill), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
      // The frame strips the feed card's chrome: no EP chip or action rail.
      expect(find.byIcon(RemixIcons.heart_3_fill), findsNothing);
      expect(find.byIcon(RemixIcons.more_fill), findsNothing);
    });

    testWidgets('speed control follows playerPrefs, without a trailing .0', (
      tester,
    ) async {
      final container = await _pump(tester);

      container.read(playerPrefsProvider.notifier).setSpeed(1.5);
      await tester.pump();
      expect(find.text('1.5x'), findsOneWidget);

      container.read(playerPrefsProvider.notifier).setSpeed(2);
      await tester.pump();
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('2.0x'), findsNothing);
    });

    testWidgets('close pops the route', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FullScreenPlayerScreen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(FullScreenPlayerScreen), findsOneWidget);

      await tester.tap(find.byIcon(RemixIcons.close_fill));
      await tester.pumpAndSettle();
      expect(find.byType(FullScreenPlayerScreen), findsNothing);
    });
  });
}

