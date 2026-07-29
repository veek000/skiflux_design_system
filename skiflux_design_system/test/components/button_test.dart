import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

void main() {
  group('SkifluxButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxButton(label: 'Submit'),
          ),
        ),
      );
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('onPressed fires when enabled', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxButton(
              label: 'Tap me',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      expect(pressed, isTrue);
    });

    testWidgets('onPressed does not fire when disabled', (tester) async {
      const pressed = false;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxButton(
              label: 'Tap me',
              onPressed: null,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      expect(pressed, isFalse);
    });

    testWidgets('loading shows a spinner and keeps the label\'s space', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxButton(label: 'Sign in', loading: true),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SkifluxSpinner), findsOneWidget);
      // Still laid out, just invisible — otherwise the button would shrink to
      // the spinner's width the moment a request starts.
      expect(find.text('Sign in'), findsOneWidget);
      expect(
        tester.widget<Opacity>(find.byType(Opacity).first).opacity,
        0,
      );
    });

    testWidgets('loading blocks taps', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxButton(
              label: 'Sign in',
              loading: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SkifluxButton));
      expect(pressed, isFalse);
    });

    testWidgets('renders with leading icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxButton(
              label: 'Settings',
              leadingIcon: Icon(RemixIcons.settings_4_fill),
            ),
          ),
        ),
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(RemixIcons.settings_4_fill), findsOneWidget);
    });
  });
}
