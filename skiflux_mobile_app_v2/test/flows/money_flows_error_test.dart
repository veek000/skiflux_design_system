import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'package:skiflux/features/settings/data/payment_store.dart';
import 'package:skiflux/features/settings/payment_methods_screen.dart';
import 'package:skiflux/features/wallet/add_bank_sheet.dart';
import 'package:skiflux/features/wallet/buy_coins_screen.dart';
import 'package:skiflux/features/wallet/data/models/supported_bank.dart';
import 'package:skiflux/features/wallet/data/wallet_repository.dart';
import 'package:skiflux/features/wallet/withdraw_screen.dart';
import 'package:skiflux/shared/error_handling/error_handler.dart';

/// One saved card, so removal flows have something to remove. The vault's
/// delete always fails here — the screen must roll back and show the
/// payment-methods modal, never a success sheet.
class _FailingRemoveCardsNotifier extends SavedCardsNotifier {
  @override
  Future<List<SavedCard>> build() async => [
    SavedCard(
      id: 'card-1',
      gatewayName: 'paystack',
      cardBrand: 'mastercard',
      maskedNumber: '**** **** **** 8810',
      last4: '8810',
      expMonth: '09',
      expYear: '2027',
      isDefault: true,
      createdAt: DateTime.utc(2026, 7, 1),
    ),
  ];

  @override
  Future<void> remove(SavedCard card) async {
    throw const SkifluxFailure(SkifluxErrorKind.paymentMethodActionFailed);
  }
}

void main() {
  group('Money-adjacent flows error handling', () {
    testWidgets(
      'add_bank_sheet displays error modal when non-numeric account number is saved',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              // Real-shaped bank options so Verify & Save is reachable; the
              // format failure below is client-side and hits no network.
              addBankOptionsProvider.overrideWith(
                (ref) async => const AddBankOptions(
                  gatewayName: 'paystack',
                  banks: [
                    SupportedBank(name: 'GT Bank', code: '058'),
                    SupportedBank(name: 'Access Bank', code: '044'),
                  ],
                ),
              ),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => showAddBankSheet(context),
                    child: const Text('Open Sheet'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Pick a bank from the backend-provided list.
        await tester.tap(find.text('Choose your bank'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('GT Bank').last);
        await tester.pumpAndSettle();

        // Enter 10-character non-numeric account number (passes local UI
        // length check, fails format validation before any request).
        final inputField = find.byType(SkifluxInputField);
        expect(inputField, findsOneWidget);
        await tester.enterText(inputField, '12345ABCDE');
        await tester.pumpAndSettle();

        // Tap Verify & Save
        await tester.tap(find.text('Verify & Save'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Expect error modal for bankVerificationFailed
        expect(
          find.textContaining("We couldn't save your bank account."),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'payment_methods_screen shows error modal and keeps the card when the '
      'backend delete fails',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              savedCardsProvider.overrideWith(_FailingRemoveCardsNotifier.new),
            ],
            child: const MaterialApp(home: PaymentMethodsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Real vault row is shown (no demo seeds).
        expect(find.text('Mastercard ending in 8810'), findsOneWidget);

        // Tap the delete icon, then confirm on the "Remove Card?" sheet.
        final deleteIcon = find.byIcon(RemixIcons.delete_bin_fill);
        expect(deleteIcon, findsOneWidget);
        await tester.tap(deleteIcon);
        await tester.pumpAndSettle();
        expect(find.text('Remove Card?'), findsOneWidget);
        await tester.tap(find.text('Remove'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Expect error modal for paymentMethodActionFailed — and no
        // fabricated "Card Removed" success.
        expect(
          find.textContaining("We couldn't update your payment methods."),
          findsOneWidget,
        );
        expect(find.text('Card Removed'), findsNothing);
      },
    );

    testWidgets(
      'withdraw_screen displays error modal when withdrawal fails balance validation',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: WithdrawScreen())),
        );
        // No pumpAndSettle: with no wallet payload the screen shows a loading
        // spinner, whose animation never settles.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // No wallet payload has loaded (and no saved bank exists), so the
        // guard throws before any request. Launch withdraw() asynchronously
        // (modal sheet stays open until dismissed).
        final state = tester.state<WithdrawScreenState>(
          find.byType(WithdrawScreen),
        );
        unawaited(state.withdraw());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Expect error modal for skillCoinWithdrawal
        expect(
          find.textContaining(
            "We couldn't process your withdrawal. No coins were deducted.",
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'buy_coins_screen displays error modal when purchase fails validation',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: BuyCoinsScreen())),
        );
        // No pumpAndSettle: the packs/balance loading spinners animate
        // indefinitely in the test environment.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Launch pay(null) asynchronously on state to exercise
        // coinPurchaseFailed error handling
        final state = tester.state<BuyCoinsScreenState>(
          find.byType(BuyCoinsScreen),
        );
        unawaited(state.pay(null));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Expect error modal for coinPurchaseFailed
        expect(
          find.textContaining(
            "We couldn't process your coin purchase. No charges were made.",
          ),
          findsOneWidget,
        );
      },
    );
  });
}

