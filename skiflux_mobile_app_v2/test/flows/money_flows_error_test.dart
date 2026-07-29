import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'package:skiflux_mobile_app_v2/features/settings/data/payment_store.dart';
import 'package:skiflux_mobile_app_v2/features/settings/payment_methods_screen.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/add_bank_sheet.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/buy_coins_screen.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/withdraw_screen.dart';

class _SingleCardPaymentNotifier extends PaymentCardsNotifier {
  @override
  List<SavedCard> build() {
    return const [
      SavedCard(brand: CardBrand.mastercard, last4: '8810', expiry: '09/27'),
    ];
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

        // Enter 10-character non-numeric account number (passes local UI length check, fails format validation)
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
      'payment_methods_screen displays error modal when attempting to remove the only saved card',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              paymentCardsProvider.overrideWith(_SingleCardPaymentNotifier.new),
            ],
            child: const MaterialApp(home: PaymentMethodsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the delete icon button for the single card
        final deleteIcon = find.byIcon(RemixIcons.delete_bin_fill);
        expect(deleteIcon, findsOneWidget);
        await tester.tap(deleteIcon);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Expect error modal for paymentMethodActionFailed
        expect(
          find.textContaining("We couldn't update your payment methods."),
          findsOneWidget,
        );
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
        await tester.pumpAndSettle();

        // Launch withdraw(3000) asynchronously (modal sheet stays open until dismissed)
        final state = tester.state<WithdrawScreenState>(
          find.byType(WithdrawScreen),
        );
        unawaited(state.withdraw(3000));
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
        await tester.pumpAndSettle();

        // Launch pay(null) asynchronously on state to exercise coinPurchaseFailed error handling
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
