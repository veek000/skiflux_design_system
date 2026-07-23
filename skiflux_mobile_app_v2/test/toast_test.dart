import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';
import 'package:skiflux_mobile_app_v2/shared/toast/skiflux_toast.dart';

void main() {
  group('SkifluxToast', () {
    testWidgets('success shows message with checkbox icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    SkifluxToast.success(context, 'Task completed'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(find.text('Task completed'), findsOneWidget);
      expect(
        find.byIcon(RemixIcons.checkbox_circle_fill),
        findsOneWidget,
      );
    });

    testWidgets('error shows message with warning icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    SkifluxToast.error(context, 'Something went wrong'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(
        find.byIcon(RemixIcons.error_warning_fill),
        findsOneWidget,
      );
    });

    testWidgets('info shows message with info icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    SkifluxToast.info(context, 'Download started'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pump();
      expect(find.text('Download started'), findsOneWidget);
      expect(
        find.byIcon(RemixIcons.information_fill),
        findsOneWidget,
      );
    });
  });
}
