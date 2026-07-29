import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

/// Fills of the four meter bars, left to right.
List<Color?> _barColors(WidgetTester tester) {
  return tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(SkifluxPasswordStrength),
          matching: find.byType(Container),
        ),
      )
      .map((c) => (c.decoration as BoxDecoration?)?.color)
      .toList();
}

Widget _host(SkifluxPasswordStrengthLevel level, {String? caption}) {
  return MaterialApp(
    home: Scaffold(
      body: SkifluxPasswordStrength(level: level, caption: caption),
    ),
  );
}

void main() {
  group('SkifluxPasswordStrength', () {
    testWidgets('default shows the neutral caption and no filled bars',
        (tester) async {
      await tester.pumpWidget(_host(SkifluxPasswordStrengthLevel.none));

      expect(find.text('Password strength'), findsOneWidget);
      expect(
        _barColors(tester),
        List.filled(
          SkifluxPasswordStrength.barCount,
          SkifluxColors.backgroundHover,
        ),
      );
    });

    testWidgets('too short keeps the bars empty but changes the caption',
        (tester) async {
      await tester.pumpWidget(_host(SkifluxPasswordStrengthLevel.tooShort));

      expect(find.text('Password too short'), findsOneWidget);
      expect(
        _barColors(tester),
        List.filled(
          SkifluxPasswordStrength.barCount,
          SkifluxColors.backgroundHover,
        ),
      );
    });

    testWidgets('fair fills two bars in Content/Notice', (tester) async {
      await tester.pumpWidget(_host(SkifluxPasswordStrengthLevel.fair));

      expect(find.text('Fair password'), findsOneWidget);
      expect(_barColors(tester), const [
        SkifluxColors.contentNotice,
        SkifluxColors.contentNotice,
        SkifluxColors.backgroundHover,
        SkifluxColors.backgroundHover,
      ]);
    });

    testWidgets('strong fills every bar in Background/Positive',
        (tester) async {
      await tester.pumpWidget(_host(SkifluxPasswordStrengthLevel.strong));

      expect(find.text('Strong password'), findsOneWidget);
      expect(
        _barColors(tester),
        List.filled(
          SkifluxPasswordStrength.barCount,
          SkifluxColors.backgroundPositive,
        ),
      );
    });

    testWidgets('caption override replaces the Figma copy', (tester) async {
      await tester.pumpWidget(
        _host(
          SkifluxPasswordStrengthLevel.weak,
          caption: 'Add a number to get stronger',
        ),
      );

      expect(find.text('Add a number to get stronger'), findsOneWidget);
      expect(find.text('Weak password'), findsNothing);
    });

    testWidgets('every level fills the bars its variant declares',
        (tester) async {
      for (final level in SkifluxPasswordStrengthLevel.values) {
        await tester.pumpWidget(_host(level));
        final filled = _barColors(tester)
            .where((c) => c != SkifluxColors.backgroundHover)
            .length;
        expect(filled, level.filledBars, reason: '$level');
      }
    });
  });
}
