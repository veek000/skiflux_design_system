/// The Google / Apple row on the two auth forms.
///
/// The row briefly hid whichever provider could not complete, which on an
/// Android build meant Google alone — and, before that, Apple alone. Both are
/// drawn now regardless: the credentials are what is pending, not the feature,
/// and the choice belongs to the user. These tests pin that, and pin that the
/// tap is honest about the state instead of running a flow that can only fail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux/features/auth/auth_flow.dart';
import 'package:skiflux/features/auth/data/auth_store.dart';

/// Mounts the flow on a form that carries the social row.
///
/// `flutter test` reports `TargetPlatform.android` and compiles no
/// `--dart-define`s, so this is exactly the build the user is holding: no
/// Google OAuth client ID, and a platform Apple does not serve. Both providers
/// are therefore in their unavailable state, which is the case worth pinning.
Future<void> _pumpAt(WidgetTester tester, AuthStage stage) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(authFlowProvider.notifier).show(stage);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AuthFlow()),
    ),
  );
  await tester.pump();
}

Finder _button(String provider) => find.bySemanticsLabel('Continue with $provider');

void main() {
  for (final stage in [AuthStage.createAccount, AuthStage.signIn]) {
    group('${stage.name} social row', () {
      testWidgets('offers both providers', (tester) async {
        await _pumpAt(tester, stage);

        expect(_button('Google'), findsOneWidget);
        expect(_button('Apple'), findsOneWidget);
      });

      testWidgets('each unconfigured provider says so on tap', (tester) async {
        await _pumpAt(tester, stage);

        for (final provider in ['Google', 'Apple']) {
          await tester.tap(_button(provider));
          await tester.pump();

          expect(
            find.text(
              '$provider sign-in is coming soon. '
              'Use your email and password for now.',
            ),
            findsOneWidget,
            reason: 'the button must not silently do nothing',
          );

          // Clear the queue before the next one — the messenger shows toasts in
          // sequence, so a leftover would satisfy the next assertion.
          ScaffoldMessenger.of(
            tester.element(_button(provider)),
          ).clearSnackBars();
          await tester.pump();
        }
      });
    });
  }
}

