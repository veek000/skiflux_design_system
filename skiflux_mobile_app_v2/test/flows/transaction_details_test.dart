import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import 'package:skiflux_mobile_app_v2/features/wallet/data/wallet_store.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/transaction_details_screen.dart';

/// The entry Figma details on `3664:13258`: a 1,240-coin purchase.
final _purchase = CoinTxn(
  title: 'Coin top-up · 1,240 coins',
  subtitle: '4 days ago · ₦7,440 paid',
  delta: 1240,
  type: CoinTxnType.earned,
  kind: CoinTxnKind.topUp,
  paymentMethod: 'Bank Transfer',
  createdAt: DateTime(2026, 7, 21, 18, 53, 20),
  updatedAt: DateTime(2026, 7, 21, 18, 53, 20),
  reference: '100000000017665040816876604180',
);

Future<void> _pump(WidgetTester tester, CoinTxn txn) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());

  await tester.pumpWidget(
    MaterialApp(home: TransactionDetailsScreen(txn: txn)),
  );
  await tester.pump();
}

void main() {
  group('TransactionDetailsScreen', () {
    testWidgets('summary card shows type, coin figure and naira conversion', (
      tester,
    ) async {
      await _pump(tester, _purchase);

      expect(find.text('Transaction details'), findsOneWidget);
      // "Purchase" appears twice: the summary heading and the type row.
      expect(find.text('Purchase'), findsNWidgets(2));
      expect(find.text('1,240'), findsOneWidget);
      // 1240 coins × ₦6 = ₦7,440, from kCoinRateNaira — not a literal.
      expect(find.text('≈ ₦7,440 · 1 coin = ₦6'), findsOneWidget);
    });

    testWidgets('detail rows render, with the timestamp in Figma format', (
      tester,
    ) async {
      await _pump(tester, _purchase);

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Payment method'), findsOneWidget);
      expect(find.text('Bank Transfer'), findsOneWidget);
      expect(find.text('Transaction ID'), findsOneWidget);
      expect(find.text('100000000017665040816876604180'), findsOneWidget);
      // 07/21/2026 06:53:20 PM — Created and Updated share the stamp.
      expect(find.text('07/21/2026 06:53:20 PM'), findsNWidgets(2));
      expect(find.text('Report Transaction'), findsOneWidget);
    });

    testWidgets('a row the entry has no value for is dropped, not blank', (
      tester,
    ) async {
      // A task reward was never paid for, so it has no payment method.
      await _pump(
        tester,
        const CoinTxn(
          title: 'EP 04 task approved',
          subtitle: 'Today',
          delta: 70,
          type: CoinTxnType.earned,
          kind: CoinTxnKind.taskApproved,
        ),
      );

      expect(find.text('Payment method'), findsNothing);
      expect(find.text('Created'), findsNothing);
      expect(find.text('Transaction ID'), findsNothing);
      // The rows that are always present still render. "Task Reward" is the
      // summary heading and the type row, as "Purchase" is above.
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Task Reward'), findsNWidgets(2));
    });

    testWidgets('copy control puts the reference on the clipboard', (
      tester,
    ) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await _pump(tester, _purchase);
      await tester.tap(find.byIcon(RemixIcons.checkbox_multiple_blank_line));
      await tester.pump();

      final copy = calls.where((c) => c.method == 'Clipboard.setData');
      expect(copy, hasLength(1));
      expect(
        (copy.first.arguments as Map)['text'],
        '100000000017665040816876604180',
      );
    });
  });
}
