import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

void main() {
  group('SkifluxComposeBar idle state', () {
    testWidgets('renders hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxComposeBar(hintText: 'Add a comment...'),
          ),
        ),
      );
      expect(find.text('Add a comment...'), findsOneWidget);
    });

    testWidgets('shows mic and send button in idle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxComposeBar(),
          ),
        ),
      );
      expect(find.byIcon(RemixIcons.mic_fill), findsOneWidget);
      expect(find.byIcon(RemixIcons.send_plane_2_fill), findsOneWidget);
    });

    testWidgets('onMicTap fires', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxComposeBar(onMicTap: () => tapped = true),
          ),
        ),
      );
      await tester.tap(find.byIcon(RemixIcons.mic_fill));
      expect(tapped, isTrue);
    });

    testWidgets('onSend fires when text is entered', (tester) async {
      var sent = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxComposeBar(onSend: () => sent = true),
          ),
        ),
      );
      // Type some text in the TextField.
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      // Send button should now be active.
      await tester.tap(find.byIcon(RemixIcons.send_plane_2_fill));
      expect(sent, isTrue);
    });
  });

  group('SkifluxComposeBar recording state', () {
    testWidgets('shows delete and timer in recording state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkifluxComposeBar(state: SkifluxComposeState.recording),
          ),
        ),
      );
      // Should show delete button (not mic) and timer start.
      expect(find.byIcon(RemixIcons.delete_bin_5_fill), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);
      // Send button should still be present.
      expect(find.byIcon(RemixIcons.send_plane_2_fill), findsOneWidget);
    });

    testWidgets('onDeleteTap fires in recording state', (tester) async {
      var deleted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxComposeBar(
              state: SkifluxComposeState.recording,
              onDeleteTap: () => deleted = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(RemixIcons.delete_bin_5_fill));
      expect(deleted, isTrue);
    });
  });

  group('SkifluxComposeBar with external controller', () {
    testWidgets('uses provided text controller', (tester) async {
      final controller = TextEditingController(text: 'Prefilled');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkifluxComposeBar(controller: controller),
          ),
        ),
      );
      expect(find.text('Prefilled'), findsOneWidget);
      controller.dispose();
    });
  });
}
