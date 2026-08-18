/// Change Password is a real write: the success sheet may appear only after
/// `POST /auth/change-password` returned 2xx, and a rejection surfaces while
/// the form keeps what was typed.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skiflux/features/auth/data/auth_repository.dart';
import 'package:skiflux/features/settings/change_password_screen.dart';
import 'package:skiflux/shared/error_handling/error_handler.dart';
import 'package:skiflux/shared/network/token_store.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.failure})
    : super(Dio(), TokenStore(const FlutterSecureStorage()));

  final SkifluxFailure? failure;
  final List<({String current, String next, String confirm})> calls = [];

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final f = failure;
    if (f != null) throw f;
    calls.add((
      current: currentPassword,
      next: newPassword,
      confirm: confirmNewPassword,
    ));
  }
}

Future<_FakeAuthRepository> _pump(
  WidgetTester tester, {
  SkifluxFailure? failure,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  final repo = _FakeAuthRepository(failure: failure);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: ChangePasswordScreen()),
    ),
  );
  return repo;
}

Future<void> _fillForm(
  WidgetTester tester, {
  String current = 'oldpass1',
  String next = 'Newpass1!',
  String confirm = 'Newpass1!',
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), current);
  await tester.enterText(fields.at(1), next);
  await tester.enterText(fields.at(2), confirm);
  await tester.pump();
}

void main() {
  testWidgets('the CTA stays disabled until the form is valid', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('Update Password'), warnIfMissed: false);
    await tester.pump();
    expect(repo.calls, isEmpty);

    // Mismatched confirmation keeps it disabled too.
    await _fillForm(tester, confirm: 'different1!');
    await tester.tap(find.text('Update Password'), warnIfMissed: false);
    await tester.pump();
    expect(repo.calls, isEmpty);
  });

  testWidgets('a 2xx shows the success sheet, then pops', (tester) async {
    final repo = await _pump(tester);
    await _fillForm(tester);

    await tester.tap(find.text('Update Password'));
    await tester.pumpAndSettle();

    expect(repo.calls.single, (
      current: 'oldpass1',
      next: 'Newpass1!',
      confirm: 'Newpass1!',
    ));
    expect(find.text('Password Updated Successfully'), findsOneWidget);
  });

  testWidgets('a rejection surfaces an error and shows NO success sheet', (
    tester,
  ) async {
    // The screen used to celebrate unconditionally — the sheet appeared while
    // the password had never left the device.
    await _pump(
      tester,
      failure: const SkifluxFailure(SkifluxErrorKind.unknown),
    );
    await _fillForm(tester);

    await tester.tap(find.text('Update Password'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Password Updated Successfully'), findsNothing);
    // SkifluxErrorKind.unknown renders as the generic toast.
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    // Still on the screen, form intact, ready to retry.
    expect(find.text('Change Password'), findsOneWidget);
  });
}

