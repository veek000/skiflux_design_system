import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/tasks/data/models/platform_task.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/models/saved_card.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/models/skillcoin_transaction.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/models/user_wallet.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/models/withdrawal_account.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/models/withdrawal_method.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/models/withdrawal_request.dart';
import 'package:skiflux_mobile_app_v2/shared/data/decimal_converter.dart';

void main() {
  group('DecimalConverter', () {
    test('parses backend decimal strings without floating-point loss', () {
      const converter = DecimalConverter();
      // The classic binary-float trap: 0.1 + 0.2 must be exactly 0.3.
      expect(
        converter.fromJson('0.10') + converter.fromJson('0.20'),
        Decimal.parse('0.3'),
      );
    });

    test('serializes back to the 2dp string format the backend sends', () {
      const converter = DecimalConverter();
      expect(converter.toJson(converter.fromJson('500.00')), '500.00');
      expect(converter.toJson(converter.fromJson('10.50')), '10.50');
      // Extra real precision is preserved, not rounded away.
      expect(converter.toJson(Decimal.parse('12.345')), '12.345');
    });
  });

  group('DecimalFromNumConverter', () {
    test('parses JSON numbers into exact Decimals', () {
      const converter = DecimalFromNumConverter();
      expect(converter.fromJson(1400.5), Decimal.parse('1400.5'));
      expect(converter.fromJson(1400), Decimal.fromInt(1400));
      // The shortest-decimal render of the double is what gets parsed —
      // no binary-float artifacts like 1400.4999999... leak through.
      expect(
        converter.fromJson(0.1) + converter.fromJson(0.2),
        Decimal.parse('0.3'),
      );
    });
  });

  group('UserWallet', () {
    // Field set per the OpenAPI UserWallet schema: balance/bonus_balance are
    // decimal STRINGS, withdrawable_balance is a JSON NUMBER (format: double).
    const json = {
      'id': 'w-001',
      'balance': '1500.50',
      'bonus_balance': '50.00',
      'withdrawable_balance': 1400.5,
      'is_locked': false,
      'is_platform_wallet': false,
      'updated_at': '2026-07-23T15:00:00Z',
    };

    test('round-trips from/to JSON with Decimal money fields', () {
      final wallet = UserWallet.fromJson(json);
      expect(wallet.id, 'w-001');
      expect(wallet.balance, Decimal.parse('1500.50'));
      expect(wallet.bonusBalance, Decimal.parse('50.00'));
      expect(wallet.withdrawableBalance, Decimal.parse('1400.5'));
      expect(wallet.isLocked, false);
      expect(wallet.isPlatformWallet, false);

      final out = wallet.toJson();
      expect(out['balance'], '1500.50');
      // Spec quirk holds on the way out too: this field is a number.
      expect(out['withdrawable_balance'], 1400.5);
      expect(UserWallet.fromJson(out), wallet);
    });

    test('is_platform_wallet defaults to false when absent', () {
      final wallet = UserWallet.fromJson(
        Map.of(json)..remove('is_platform_wallet'),
      );
      expect(wallet.isPlatformWallet, false);
    });

    test('freezed gives value equality', () {
      expect(UserWallet.fromJson(json), UserWallet.fromJson(json));
    });
  });

  group('SavedCard', () {
    test('parses the documented GET /wallet/cards entry', () {
      // payment-flows.md §2.1 step 4, verbatim.
      final json =
          jsonDecode('''
      {
        "id": "7a6b5c4d-3e2f-1a0b-9c8d-7e6f5a4b3c2d",
        "gateway_name": "stripe",
        "card_brand": "visa",
        "masked_number": "**** **** **** 4242",
        "last4": "4242",
        "exp_month": "12",
        "exp_year": "2030",
        "bank_name": "",
        "card_type": "credit",
        "is_default": true,
        "created_at": "2026-07-23T14:30:00Z"
      }''')
              as Map<String, dynamic>;
      final card = SavedCard.fromJson(json);
      expect(card.gatewayName, 'stripe');
      expect(card.maskedNumber, '**** **** **** 4242');
      expect(card.bankName, '');

      expect(SavedCard.fromJson(card.toJson()), card);
    });
  });

  group('WithdrawalMethod', () {
    test('parses the documented GET /wallet/withdrawals/methods entry', () {
      // withdrawal-flows.md §3, verbatim.
      final json =
          jsonDecode('''
      {
        "method": "stripe_connect",
        "gateway": "stripe",
        "flow": "hosted_redirect",
        "label": "International bank account or debit card (Stripe)"
      }''')
              as Map<String, dynamic>;
      final method = WithdrawalMethod.fromJson(json);
      expect(method.flow, 'hosted_redirect');

      expect(WithdrawalMethod.fromJson(method.toJson()), method);
    });
  });

  group('WithdrawalAccount', () {
    test('parses the documented accounts/list entry', () {
      // withdrawal-flows.md / payment-flows.md §3.1 step 4, verbatim — note
      // there is no gateway_name in the documented response.
      final json =
          jsonDecode('''
      {
        "id": "c9d8e7f6-a5b4-3210-9876-543210fedcba",
        "destination_type": "stripe_connect",
        "display_name": "Stripe — bank/card on file",
        "bank_code": "",
        "bank_name": "stripe",
        "account_number": "",
        "account_name": "Jane Doe",
        "status": "verified",
        "is_default": true,
        "created_at": "2026-07-23T14:45:00Z"
      }''')
              as Map<String, dynamic>;
      final account = WithdrawalAccount.fromJson(json);
      expect(account.destinationType, WithdrawalDestinationType.stripeConnect);
      expect(account.status, WithdrawalAccountStatus.verified);
      expect(account.accountName, 'Jane Doe');
      expect(account.gatewayName, isNull);

      expect(WithdrawalAccount.fromJson(account.toJson()), account);
    });
  });

  group('WithdrawalRequest', () {
    test('parses the documented request response with its partial nested '
        'account', () {
      // payment-flows.md §3.1 step 5, verbatim. The nested account carries
      // only 5 of the full account fields — parsing this exact payload is the
      // regression test for the earlier model, which required created_at and
      // crashed here.
      final json =
          jsonDecode('''
      {
        "id": "e1f2a3b4-c5d6-7890-abcd-ef0987654321",
        "amount": "500.00",
        "fee": "10.00",
        "net_amount": "490.00",
        "status": "pending",
        "gateway_name": null,
        "failure_reason": null,
        "processed_at": null,
        "created_at": "2026-07-23T15:10:00Z",
        "account": {
          "id": "c9d8e7f6-a5b4-3210-9876-543210fedcba",
          "destination_type": "stripe_connect",
          "display_name": "Stripe — bank/card on file",
          "status": "verified",
          "is_default": true
        }
      }''')
              as Map<String, dynamic>;
      final request = WithdrawalRequest.fromJson(json);
      expect(request.amount, Decimal.parse('500.00'));
      expect(request.fee, Decimal.parse('10.00'));
      expect(request.netAmount, Decimal.parse('490.00'));
      expect(request.status, WithdrawalRequestStatus.pending);
      expect(request.account.displayName, 'Stripe — bank/card on file');
      expect(request.account.createdAt, isNull);
      expect(request.account.bankCode, '');

      final out = request.toJson();
      expect(out['amount'], '500.00');
      expect(out['net_amount'], '490.00');
      expect(out['account'], isA<Map<String, dynamic>>());
      expect(WithdrawalRequest.fromJson(out), request);
    });

    test('tolerates the spec-minimal payload (only 5 required fields)', () {
      // Per the OpenAPI schema only account/amount/created_at/id/net_amount
      // are required.
      const json = {
        'id': 'wd-min',
        'amount': '100.00',
        'net_amount': '98.00',
        'created_at': '2026-07-23T15:10:00Z',
        'account': {
          'id': 'acct-1',
          'destination_type': 'bank',
          'display_name': 'GTBank ****1234',
          'status': 'verified',
          'is_default': true,
        },
      };
      final request = WithdrawalRequest.fromJson(json);
      expect(request.fee, isNull);
      expect(request.status, WithdrawalRequestStatus.pending);
    });

    test('parses the cancelled status the spec defines', () {
      const json = {
        'id': 'wd-c',
        'amount': '100.00',
        'net_amount': '98.00',
        'status': 'cancelled',
        'created_at': '2026-07-23T15:10:00Z',
        'account': {
          'id': 'acct-1',
          'destination_type': 'bank',
          'display_name': 'GTBank ****1234',
          'status': 'verified',
          'is_default': true,
        },
      };
      expect(
        WithdrawalRequest.fromJson(json).status,
        WithdrawalRequestStatus.cancelled,
      );
    });
  });

  group('SkillcoinTransaction', () {
    test('round-trips the spec schema shape', () {
      const json = {
        'id': 'txn-001',
        'amount': '1000.00',
        'transaction_type': 'topup',
        'transaction_type_label': 'Top-up via Payment Gateway',
        'status': 'posted',
        'description': 'Wallet top-up via Paystack',
        'reference_id': null,
        'created_at': '2026-07-23T15:00:00Z',
      };
      final txn = SkillcoinTransaction.fromJson(json);
      expect(txn.amount, Decimal.parse('1000.00'));
      expect(txn.transactionType, SkillcoinTransactionType.topup);
      expect(txn.transactionTypeLabel, 'Top-up via Payment Gateway');
      expect(txn.status, SkillcoinTransactionStatus.posted);
      expect(txn.referenceId, isNull);

      final out = txn.toJson();
      expect(out['amount'], '1000.00');
      expect(out['transaction_type'], 'topup');
      expect(SkillcoinTransaction.fromJson(out), txn);
    });

    test('unknown future values degrade instead of crashing fromJson', () {
      const json = {
        'amount': '5.00',
        'transaction_type': 'some_future_type',
        'transaction_type_label': 'Some Future Thing',
        'status': 'some_future_status',
        'description': 'forward-compat check',
        'created_at': '2026-07-23T15:00:00Z',
      };
      final txn = SkillcoinTransaction.fromJson(json);
      expect(txn.transactionType, SkillcoinTransactionType.unknown);
      expect(txn.status, isNull);
      // The label still gives the UI something correct to display.
      expect(txn.transactionTypeLabel, 'Some Future Thing');
    });
  });

  group('PlatformTask', () {
    test('parses the documented GET /me/platform-tasks entry', () {
      // platform-tasks.md §4 list response shape, verbatim (no is_active —
      // the model must default it).
      final json =
          jsonDecode('''
      {
        "id": "pt-001",
        "slug": "follow-instagram",
        "title": "Follow & Earn",
        "description": "Follow our Instagram page and earn instant rewards",
        "category": "social",
        "trigger_type": "",
        "action_type": "",
        "verification_mode": "manual",
        "progress_target": 1,
        "progress_current": 0,
        "duration_minutes": null,
        "external_url": "https://instagram.com/skiflux",
        "icon": "instagram",
        "metadata": {},
        "sort_order": 0,
        "xp_reward": 25,
        "skillcoin_reward": "25.00",
        "status": "not_started",
        "claimable": false,
        "completed": false,
        "started_at": null,
        "claimable_at": null,
        "claimed_at": null,
        "completed_at": null
      }''')
              as Map<String, dynamic>;
      final task = PlatformTask.fromJson(json);
      expect(task.title, 'Follow & Earn');
      expect(task.skillcoinReward, Decimal.parse('25.00'));
      expect(task.status, PlatformTaskStatus.notStarted);
      expect(task.xpReward, 25);
      expect(task.claimable, false);
      expect(task.isActive, true); // defaulted when absent
      expect(task.externalUrl, 'https://instagram.com/skiflux');

      final out = task.toJson();
      expect(out['skillcoin_reward'], '25.00');
      expect(out['status'], 'not_started');
      expect(PlatformTask.fromJson(out), task);
    });

    test('honours an explicit is_active from the spec response', () {
      final json =
          jsonDecode('''
      {
        "id": "pt-002",
        "slug": "hot-streak-challenge",
        "title": "Hot Streak Challenge",
        "description": "Complete this task before the timer runs out",
        "category": "flash",
        "trigger_type": "",
        "action_type": "",
        "verification_mode": "manual",
        "progress_target": 1,
        "progress_current": 0,
        "duration_minutes": 20,
        "external_url": null,
        "icon": "fire",
        "metadata": {},
        "sort_order": 1,
        "xp_reward": 30,
        "skillcoin_reward": "30.00",
        "status": "not_started",
        "claimable": false,
        "completed": false,
        "is_active": false,
        "started_at": null,
        "claimable_at": null,
        "claimed_at": null,
        "completed_at": null
      }''')
              as Map<String, dynamic>;
      final task = PlatformTask.fromJson(json);
      expect(task.isActive, false);
      expect(task.durationMinutes, 20);
      expect(
        task.skillcoinReward * Decimal.fromInt(3),
        Decimal.parse('90.00'),
      );

      final claimed = task.copyWith(
        status: PlatformTaskStatus.claimed,
        completed: true,
      );
      expect(claimed.status, PlatformTaskStatus.claimed);
      expect(claimed.id, task.id);
      expect(claimed, isNot(task));
    });
  });
}
