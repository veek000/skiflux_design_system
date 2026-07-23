import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skiflux_mobile_app_v2/features/tasks/submission_task_screen.dart';

void main() {
  group('Task submission flow', () {
    testWidgets('task screen renders with correct title and submit button',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SubmissionTaskScreen(taskId: 'learn-2'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Design a hero section'), findsOneWidget);
      expect(find.text('Submission Method'), findsOneWidget);
      expect(find.text('Submit Task & Earn 25 coins'), findsOneWidget);
    });

    testWidgets('enter valid link and submit shows success dialog',
        (tester) async {
      // Use a taller viewport so the ListView renders scroll-fold children.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SubmissionTaskScreen(taskId: 'learn-2'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Input field is now rendered.
      final inputField = find.byKey(const ValueKey('link_input'));
      expect(inputField, findsOneWidget);

      await tester.enterText(inputField, 'https://figma.com/file/test');
      await tester.pump();

      // Tap submit.
      await tester.tap(find.text('Submit Task & Earn 25 coins'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Success dialog appears.
      expect(find.text('Task Submitted!'), findsOneWidget);
    });

    testWidgets('submit with invalid http link shows error modal',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SubmissionTaskScreen(taskId: 'learn-2'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final inputField = find.byKey(const ValueKey('link_input'));
      expect(inputField, findsOneWidget);

      await tester.enterText(inputField, 'not-a-url');
      await tester.pump();

      await tester.tap(find.text('Submit Task & Earn 25 coins'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Error modal with full classification copy.
      expect(
        find.textContaining("Your submission didn't go through."),
        findsOneWidget,
      );
    });

    testWidgets('task not found shows error fallback', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SubmissionTaskScreen(taskId: 'nonexistent'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Task not found'), findsOneWidget);
    });
  });
}
