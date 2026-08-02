/// Wire-level tests for the money repositories: request bodies match the
/// OpenAPI spec, tolerant parsers accept the gateway variants, and every
/// failure leaves the repository as a typed [SkifluxFailure] with the right
/// money-modal kind (never a raw DioException/TypeError).
library;

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/cards_repository.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/episode_purchase_repository.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/topup_repository.dart';
import 'package:skiflux_mobile_app_v2/features/wallet/data/wallet_repository.dart';
import 'package:skiflux_mobile_app_v2/shared/error_handling/error_handler.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> received = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    received.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, String body) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Dio _dio(_StubAdapter adapter) => Dio(
  BaseOptions(
    baseUrl: 'https://api.test/api/v1',
    contentType: Headers.jsonContentType,
    validateStatus: (s) => s != null && s >= 200 && s < 300,
  ),
)..httpClientAdapter = adapter;

Map<String, dynamic> _bodyOf(RequestOptions options) => options.data is String
    ? jsonDecode(options.data as String) as Map<String, dynamic>
    : (options.data as Map).cast<String, dynamic>();

void main() {
  group('TopupRepository.initiateTopup', () {
    test('posts the spec body and parses checkout URL + tx_ref', () async {
      final adapter = _StubAdapter(
        (_) async => _json(
          200,
          '{"status":"success","data":{"tx_ref":"SKF-1","checkout_url":'
          '"https://checkout.paystack.com/abc"}}',
        ),
      );
      final repo = TopupRepository(_dio(adapter));

      final result = await repo.initiateTopup(
        amountFiat: '1100.00',
        currency: 'NGN',
        paymentMethod: 'card',
      );

      final request = adapter.received.single;
      expect(request.path, kTopupInitiatePath);
      expect(_bodyOf(request), {
        'amount_fiat': '1100.00',
        'currency': 'NGN',
        'payment_method': 'card',
      });
      expect(result.txRef, 'SKF-1');
      expect(result.checkoutUrl.toString(), 'https://checkout.paystack.com/abc');
    });

    test('accepts Paystack-style authorization_url + reference', () async {
      final adapter = _StubAdapter(
        (_) async => _json(
          200,
          '{"authorization_url":"https://pay.test/x","reference":"r-9"}',
        ),
      );
      final repo = TopupRepository(_dio(adapter));

      final result = await repo.initiateTopup(amountFiat: '600.00');
      expect(result.txRef, 'r-9');
      expect(result.checkoutUrl.host, 'pay.test');
    });

    test('a body with no checkout URL is coinPurchaseFailed, not success',
        () async {
      final adapter = _StubAdapter(
        (_) async => _json(200, '{"status":"success"}'),
      );
      final repo = TopupRepository(_dio(adapter));

      await expectLater(
        repo.initiateTopup(amountFiat: '600.00'),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.coinPurchaseFailed,
          ),
        ),
      );
    });

    test('an HTTP failure surfaces as coinPurchaseFailed', () async {
      final adapter = _StubAdapter(
        (_) async => _json(402, '{"detail":"insufficient"}'),
      );
      final repo = TopupRepository(_dio(adapter));

      await expectLater(
        repo.initiateTopup(amountFiat: '600.00'),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.coinPurchaseFailed,
          ),
        ),
      );
    });
  });

  group('TopupRepository.verifyTopup', () {
    Future<TopupVerification> verify(String body) {
      final adapter = _StubAdapter((_) async => _json(200, body));
      return TopupRepository(_dio(adapter)).verifyTopup(txRef: 'SKF-1');
    }

    test('successful status with credited coins', () async {
      final result = await verify(
        '{"data":{"status":"successful","amount_skillcoins":"200.00"}}',
      );
      expect(result.status, TopupVerificationStatus.successful);
      expect(result.amountSkillcoins, Decimal.parse('200.00'));
    });

    test('anything not explicitly successful/failed stays pending', () async {
      expect(
        (await verify('{"status":"initiated"}')).status,
        TopupVerificationStatus.pending,
      );
      expect(
        (await verify('{}')).status,
        TopupVerificationStatus.pending,
      );
    });

    test('failed maps to failed', () async {
      expect(
        (await verify('{"status":"failed"}')).status,
        TopupVerificationStatus.failed,
      );
    });

    test('sends tx_ref per VerifyPaymentRequest', () async {
      final adapter = _StubAdapter(
        (_) async => _json(200, '{"status":"pending"}'),
      );
      await TopupRepository(_dio(adapter)).verifyTopup(txRef: 'SKF-7');
      final request = adapter.received.single;
      expect(request.path, kTopupVerifyPath);
      expect(_bodyOf(request), {'tx_ref': 'SKF-7'});
    });
  });

  group('WalletRepository withdrawals', () {
    test('requestWithdrawal posts {account_id, amount} with a 2dp string '
        'decimal and parses the 201 WithdrawalRequest', () async {
      final adapter = _StubAdapter(
        (_) async => _json(201, '''
        {"data": {
          "id": "wr-1",
          "amount": "500.00",
          "fee": "7.50",
          "net_amount": "492.50",
          "status": "pending",
          "created_at": "2026-07-30T10:00:00Z",
          "account": {
            "id": "acct-1",
            "destination_type": "bank",
            "display_name": "GT Bank ····4521",
            "status": "verified",
            "is_default": true
          }
        }}'''),
      );
      final repo = WalletRepository(_dio(adapter));

      final result = await repo.requestWithdrawal(
        accountId: 'acct-1',
        amount: Decimal.fromInt(500),
      );

      final request = adapter.received.single;
      expect(request.path, kWithdrawalRequestPath);
      expect(_bodyOf(request), {'account_id': 'acct-1', 'amount': '500.00'});
      expect(result.amount, Decimal.parse('500.00'));
      expect(result.fee, Decimal.parse('7.50'));
      expect(result.netAmount, Decimal.parse('492.50'));
      expect(result.account.id, 'acct-1');
    });

    test('a rejected withdrawal is the skillCoinWithdrawal modal kind',
        () async {
      final adapter = _StubAdapter(
        (_) async => _json(400, '{"detail":"below minimum"}'),
      );
      final repo = WalletRepository(_dio(adapter));

      await expectLater(
        repo.requestWithdrawal(
          accountId: 'acct-1',
          amount: Decimal.fromInt(10),
        ),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.skillCoinWithdrawal,
          ),
        ),
      );
    });

    test('getSupportedBanks tolerates envelope nesting and drops unusable '
        'entries instead of inventing codes', () async {
      final adapter = _StubAdapter(
        (_) async => _json(200, '''
        {"status":"success","data":{"banks":[
          {"name":"GT Bank","code":"058"},
          {"name":"No Code Bank"},
          {"code":"000"},
          {"name":"Access Bank","code":"044"}
        ]}}'''),
      );
      final repo = WalletRepository(_dio(adapter));

      final banks = await repo.getSupportedBanks(gateway: 'paystack');
      expect(adapter.received.single.queryParameters, {'gateway': 'paystack'});
      expect(banks, hasLength(2));
      expect(banks.first.name, 'GT Bank');
      expect(banks.first.code, '058');
    });

    test('addWithdrawalAccount posts the spec body and failures map to '
        'bankVerificationFailed', () async {
      final adapter = _StubAdapter(
        (_) async => _json(400, '{"detail":"Account name does not match"}'),
      );
      final repo = WalletRepository(_dio(adapter));

      await expectLater(
        repo.addWithdrawalAccount(
          bankCode: '058',
          accountNumber: '0123456789',
          gatewayName: 'paystack',
          bankName: 'GT Bank',
        ),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.bankVerificationFailed,
          ),
        ),
      );
      expect(_bodyOf(adapter.received.single), {
        'bank_code': '058',
        'account_number': '0123456789',
        'gateway_name': 'paystack',
        'bank_name': 'GT Bank',
      });
    });

    test('getWithdrawalFeePercent reads the untyped methods payload and '
        'returns null when absent', () async {
      final withFee = _StubAdapter(
        (_) async =>
            _json(200, '{"data":{"withdrawal_fee_percentage":"1.50"}}'),
      );
      expect(
        await WalletRepository(_dio(withFee)).getWithdrawalFeePercent(),
        Decimal.parse('1.50'),
      );

      final withoutFee = _StubAdapter(
        (_) async => _json(200, '{"data":{"methods":[]}}'),
      );
      expect(
        await WalletRepository(_dio(withoutFee)).getWithdrawalFeePercent(),
        isNull,
      );
    });
  });

  group('guard contract', () {
    test('a payload violating the model surfaces as a typed failure, '
        'never a raw TypeError', () async {
      // Missing required id/updated_at → hard-cast TypeError inside
      // generated fromJson; guard must map it like a FormatException.
      final adapter = _StubAdapter(
        (_) async => _json(200, '{"balance":"10.00"}'),
      );
      final repo = WalletRepository(_dio(adapter));

      await expectLater(
        repo.getMyWallet(),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.contentLoadFailed,
          ),
        ),
      );
    });
  });

  group('EpisodePurchaseRepository', () {
    test('posts {episode_id} and resolves on the 201 envelope', () async {
      final adapter = _StubAdapter(
        (_) async => _json(
          201,
          '{"status":"success","data":{"episode_id":"ep-uuid-1"}}',
        ),
      );
      final repo = EpisodePurchaseRepository(_dio(adapter));

      final id = await repo.purchase('ep-uuid-1');
      expect(id, 'ep-uuid-1');
      final request = adapter.received.single;
      expect(request.path, kEpisodePurchasePath);
      expect(_bodyOf(request), {'episode_id': 'ep-uuid-1'});
    });

    test('a 402/400 maps to coinPurchaseFailed — no unlock on failure',
        () async {
      final adapter = _StubAdapter(
        (_) async => _json(400, '{"detail":"insufficient balance"}'),
      );
      final repo = EpisodePurchaseRepository(_dio(adapter));

      await expectLater(
        repo.purchase('ep-uuid-1'),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.coinPurchaseFailed,
          ),
        ),
      );
    });
  });

  group('CardsRepository', () {
    test('startAddCard posts gateway_name and returns the hosted checkout '
        'URL', () async {
      final adapter = _StubAdapter(
        (_) async => _json(
          200,
          '{"data":{"checkout_url":"https://checkout.paystack.com/save"}}',
        ),
      );
      final repo = CardsRepository(_dio(adapter));

      final handOff = await repo.startAddCard(gatewayName: 'paystack');
      expect(handOff.checkoutUrl.toString(), 'https://checkout.paystack.com/save');
      // Absent in this body — the flow still runs, it just cannot verify
      // before re-reading the vault.
      expect(handOff.txRef, isNull);
      final request = adapter.received.single;
      expect(request.path, kCardsAddPath);
      expect(_bodyOf(request), {'gateway_name': 'paystack'});
    });

    test('startAddCard keeps the tx_ref the verify step needs', () async {
      // `payment-flows.md` §2: after the hosted page, call
      // `POST /wallet/topup/verify` with this reference *then* re-read
      // `GET /wallet/cards`. Parsing only the URL — the previous behaviour —
      // left the app re-reading the vault and hoping a webhook had landed.
      final adapter = _StubAdapter(
        (_) async => _json(
          200,
          '{"data":{"checkout_url":"https://checkout.stripe.com/c/pay/cs_test",'
          '"tx_ref":"skf-card-9f8e7d6c5b4a","gateway":"stripe"}}',
        ),
      );
      final repo = CardsRepository(_dio(adapter));

      final handOff = await repo.startAddCard(gatewayName: 'stripe');
      expect(handOff.txRef, 'skf-card-9f8e7d6c5b4a');
    });

    test('a URL-less add-card body is paymentMethodActionFailed', () async {
      final adapter = _StubAdapter((_) async => _json(200, '{"ok":true}'));
      final repo = CardsRepository(_dio(adapter));

      await expectLater(
        repo.startAddCard(gatewayName: 'paystack'),
        throwsA(
          isA<SkifluxFailure>().having(
            (f) => f.kind,
            'kind',
            SkifluxErrorKind.paymentMethodActionFailed,
          ),
        ),
      );
    });

    test('deleteCard hits DELETE /wallet/cards/{id}', () async {
      final adapter = _StubAdapter((_) async => _json(200, '{}'));
      final repo = CardsRepository(_dio(adapter));

      await repo.deleteCard('card-9');
      final request = adapter.received.single;
      expect(request.method, 'DELETE');
      expect(request.path, '/wallet/cards/card-9');
    });
  });
}
