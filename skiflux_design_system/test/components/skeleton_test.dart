import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

Widget _host(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: child),
    ),
  );
}

/// Every ticker the test framework knows about, group-owned or self-owned.
int _tickerCount(WidgetTester tester) =>
    tester.binding.transientCallbackCount;

void main() {
  group('SkifluxSkeleton', () {
    testWidgets('a lone placeholder still animates', (tester) async {
      // It has no group above it, so it has to supply its own ticker —
      // otherwise a single skeleton would sit frozen.
      await tester.pumpWidget(_host(const SkifluxSkeleton(width: 80, height: 8)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkifluxSkeletonGroup), findsNothing);
      expect(_tickerCount(tester), 1);
    });

    testWidgets('a group drives its children from one ticker', (tester) async {
      await tester.pumpWidget(
        _host(
          const SkifluxSkeletonGroup(
            child: Column(
              children: [
                SkifluxSkeleton.text(width: 120),
                SkifluxSkeleton.text(width: 90),
                SkifluxSkeleton.circle(size: 40),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Three placeholders, one group — no child promoted itself.
      expect(find.byType(SkifluxSkeleton), findsNWidgets(3));
      expect(find.byType(SkifluxSkeletonGroup), findsOneWidget);
      expect(_tickerCount(tester), 1);
    });

    testWidgets('reduce motion stills the sweep, keeping the block',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const SkifluxSkeleton(width: 80, height: 8),
          disableAnimations: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // The placeholder is the message; the shimmer is decoration on top of
      // it, so only the shimmer goes.
      expect(find.byType(SkifluxSkeleton), findsOneWidget);
      expect(_tickerCount(tester), 0);
    });

    testWidgets('circle is round and text is tight-cornered', (tester) async {
      await tester.pumpWidget(
        _host(
          const SkifluxSkeletonGroup(
            child: Column(
              children: [
                SkifluxSkeleton.circle(size: 40),
                SkifluxSkeleton.text(width: 100),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final radii = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(SkifluxSkeleton),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((b) => (b.decoration as BoxDecoration).borderRadius)
          .toList();

      expect(radii.first, BorderRadius.circular(SkifluxRadii.pill));
      expect(radii.last, BorderRadius.circular(SkifluxRadii.xs));
      expect(tester.getSize(find.byType(SkifluxSkeleton).first),
          const Size(40, 40));
    });
  });
}
