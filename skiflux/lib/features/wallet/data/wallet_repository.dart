import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import '../../../shared/network/json_envelope.dart';
import 'models/skillcoin_transaction.dart';
import 'models/supported_bank.dart';
import 'models/user_wallet.dart';
import 'models/wallet_financial_summary.dart';
import 'models/withdrawal_account.dart';
import 'models/withdrawal_method.dart';
import 'models/withdrawal_request.dart';

/// `GET /wallet/my-wallet` — the calling user's balance + suspension status.
const kMyWalletPath = '/wallet/my-wallet';

/// `GET /wallet/my-transactions` — Skillcoin ledger feed.
const kMyTransactionsPath = '/wallet/my-transactions';

/// `GET /wallet/summary` — total earned / spent / withdrawn.
const kWalletSummaryPath = '/wallet/summary';

/// `GET /wallet/withdrawals/accounts/list` — saved payout destinations.
const kWithdrawalAccountsListPath = '/wallet/withdrawals/accounts/list';

/// `POST /wallet/withdrawals/accounts` — add a destination; the backend
/// performs the bank-name verification and returns the resolved
/// `WithdrawalAccount` (201).
const kWithdrawalAccountsCreatePath = '/wallet/withdrawals/accounts';

/// `DELETE /wallet/withdrawals/accounts/{id}` — remove a destination.
String withdrawalAccountPath(String id) => '/wallet/withdrawals/accounts/$id';

/// `GET /wallet/withdrawals/banks?gateway=` — the gateway's supported-bank
/// list (untyped response; defaults to paystack server-side).
const kWithdrawalBanksPath = '/wallet/withdrawals/banks';

/// `GET /wallet/withdrawals/methods` — enabled withdrawal methods; the
/// frontend switches on `flow` (`bank_form` vs `hosted_redirect`).
const kWithdrawalMethodsPath = '/wallet/withdrawals/methods';

/// `POST /wallet/withdrawals/request` — body
/// `{account_id, amount: "<string decimal>"}`; 201 returns the created
/// `WithdrawalRequest` with backend-computed `fee` / `net_amount`.
const kWithdrawalRequestPath = '/wallet/withdrawals/request';

/// Wallet read surface (balance, ledger, summary, banks) plus the withdrawal
/// writes. Reads fall back to [SkifluxErrorKind.contentLoadFailed]; each
/// write passes its own money-modal kind per call.
class WalletRepository extends ApiRepository {
  const WalletRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  Future<UserWallet> getMyWallet() => getObject(
    kMyWalletPath,
    parse: UserWallet.fromJson,
  );

  Future<List<SkillcoinTransaction>> getMyTransactions() => getList(
    kMyTransactionsPath,
    parse: SkillcoinTransaction.fromJson,
  );

  Future<WalletFinancialSummary> getSummary() => getObject(
    kWalletSummaryPath,
    parse: WalletFinancialSummary.fromJson,
  );

  Future<List<WithdrawalAccount>> getWithdrawalAccounts() => getList(
    kWithdrawalAccountsListPath,
    parse: WithdrawalAccount.fromJson,
  );

  /// Supported banks for [gateway] (server default: paystack). The payload is
  /// untyped, so the list is located tolerantly and unusable entries dropped.
  ///
  /// Uses a dynamic response type: some gateways/envelopes return a bare list
  /// (or `{data: [...]}`) and a typed `Map` decode used to throw before the
  /// picker could render — which is what showed the Add Bank error state.
  Future<List<SupportedBank>> getSupportedBanks({String? gateway}) => guard(
    () async {
      final normalized = gateway?.trim().toLowerCase();
      final response = await dio.get<dynamic>(
        kWithdrawalBanksPath,
        queryParameters: {
          if (normalized != null && normalized.isNotEmpty) 'gateway': normalized,
        },
      );
      return parseSupportedBanks(response.data);
    },
    kind: SkifluxErrorKind.contentLoadFailed,
  );

  /// Public so unit tests can exercise envelope shapes without Dio.
  static List<SupportedBank> parseSupportedBanks(Object? data) {
    final raw = _bankListFrom(data);
    final banks = <SupportedBank>[];
    final seen = <String>{};
    for (final entry in raw) {
      final bank = SupportedBank.tryParse(entry);
      if (bank == null) continue;
      // Paystack sometimes repeats a code under a different display name.
      if (!seen.add(bank.code)) continue;
      banks.add(bank);
    }
    return List.unmodifiable(banks);
  }

  /// Enabled withdrawal methods. Untyped payload; entries that don't carry
  /// the documented four fields are skipped.
  Future<List<WithdrawalMethod>> getWithdrawalMethods() => guard(() async {
    final response = await dio.get<Map<String, dynamic>>(
      kWithdrawalMethodsPath,
    );
    final body = unwrapObject(response.data ?? const <String, dynamic>{});
    final methods = <WithdrawalMethod>[];
    for (final entry in _bankList(body, keys: const [
      'methods',
      'results',
      'data',
    ])) {
      if (entry is! Map) continue;
      try {
        methods.add(
          WithdrawalMethod.fromJson(Map<String, dynamic>.from(entry)),
        );
      } catch (_) {
        // Tolerate additions we don't understand; never fabricate one.
      }
    }
    return methods;
  }, kind: SkifluxErrorKind.contentLoadFailed);

  /// Adds a payout destination. The backend does the account-name
  /// verification against the gateway — a rejection surfaces as
  /// [SkifluxErrorKind.bankVerificationFailed].
  Future<WithdrawalAccount> addWithdrawalAccount({
    required String bankCode,
    required String accountNumber,
    required String gatewayName,
    String? bankName,
  }) => post(
    kWithdrawalAccountsCreatePath,
    body: {
      'bank_code': bankCode,
      'account_number': accountNumber,
      'gateway_name': gatewayName,
      'bank_name': ?bankName,
    },
    parse: WithdrawalAccount.fromJson,
    kind: SkifluxErrorKind.bankVerificationFailed,
  ).then((v) => v!);

  /// Removes a saved payout destination.
  Future<void> deleteWithdrawalAccount(String id) => delete(
    withdrawalAccountPath(id),
    kind: SkifluxErrorKind.paymentMethodActionFailed,
  );

  /// Requests a withdrawal of [amount] Skillcoins (string decimal on the
  /// wire) to saved account [accountId]. Success is the 201 body only —
  /// callers must render its `amount` / `fee` / `net_amount`, never their
  /// own arithmetic.
  Future<WithdrawalRequest> requestWithdrawal({
    required String accountId,
    required Decimal amount,
  }) => post(
    kWithdrawalRequestPath,
    body: {
      'account_id': accountId,
      'amount': amount.scale <= 2 ? amount.toStringAsFixed(2) : '$amount',
    },
    parse: WithdrawalRequest.fromJson,
    kind: SkifluxErrorKind.skillCoinWithdrawal,
  ).then((v) => v!);

  /// Best-effort withdrawal fee discovery.
  ///
  /// The spec's only typed home for `withdrawal_fee_percentage` is the
  /// admin-scoped `SystemFinancialConfig` (`/admin/finance/financial-config`),
  /// which a learner token cannot read. `GET /wallet/withdrawals/methods` is
  /// untyped, so if the backend includes the percentage there it is used;
  /// otherwise this returns null and the UI says the fee is confirmed by the
  /// backend — the authoritative `fee` / `net_amount` always come from the
  /// `POST /wallet/withdrawals/request` response.
  Future<Decimal?> getWithdrawalFeePercent() => guard(() async {
    final response = await dio.get<Map<String, dynamic>>(
      kWithdrawalMethodsPath,
    );
    final body = unwrapObject(response.data ?? const <String, dynamic>{});
    final top = _feePercentIn(body);
    if (top != null) return top;
    for (final value in body.values) {
      if (value is Map) {
        final nested = _feePercentIn(Map<String, dynamic>.from(value));
        if (nested != null) return nested;
      }
    }
    return null;
  }, kind: SkifluxErrorKind.contentLoadFailed);

  static Decimal? _feePercentIn(Map<String, dynamic> json) {
    for (final key in const [
      'withdrawal_fee_percentage',
      'fee_percentage',
      'fee_percent',
    ]) {
      final value = json[key];
      if (value is String) {
        final parsed = Decimal.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is num) return Decimal.tryParse(value.toString());
    }
    return null;
  }

  /// Locates the bank/method array inside an untyped object body.
  static List<dynamic> _bankList(
    Map<String, dynamic> body, {
    List<String> keys = const ['banks', 'data', 'results'],
  }) {
    for (final key in keys) {
      final value = body[key];
      if (value is List) return value;
      if (value is Map) {
        final nested = Map<String, dynamic>.from(value);
        for (final innerKey in keys) {
          final inner = nested[innerKey];
          if (inner is List) return inner;
        }
      }
    }
    return const [];
  }

  /// Locates a bank array in any of the shapes the untyped banks endpoint
  /// has been seen to return: bare list, `{data:[…]}`, `{data:{banks:[…]}}`,
  /// `{banks:[…]}`, Paystack-style success envelopes, etc.
  static List<dynamic> _bankListFrom(Object? data) {
    if (data is List) return data;
    if (data is! Map) return const [];
    final map = Map<String, dynamic>.from(data);
    // Prefer peeling a success/`data` envelope when `data` is itself a map,
    // but keep looking when `data` is already the bank list.
    final direct = _bankList(map, keys: const [
      'banks',
      'bank_list',
      'supported_banks',
      'results',
      'data',
      'items',
    ]);
    if (direct.isNotEmpty) return direct;
    final inner = map['data'];
    if (inner is Map) {
      return _bankList(Map<String, dynamic>.from(inner), keys: const [
        'banks',
        'bank_list',
        'supported_banks',
        'results',
        'data',
        'items',
      ]);
    }
    return const [];
  }

  /// `POST /wallet/transactions/{transaction_ref}/report` — dispute / report a transaction.
  Future<Map<String, dynamic>> reportTransaction({
    required String transactionRef,
    String? reason,
  }) async {
    final response = await post(
      '/wallet/transactions/$transactionRef/report',
      body: {
        'reason': (reason != null && reason.trim().isNotEmpty) 
            ? reason.trim() 
            : 'User reported transaction from mobile app',
        'details': '',
      },
      parse: (json) => unwrapObject(json),
    );
    return response ?? {};
  }
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(apiClientProvider)),
);

/// The Add Bank sheet's inputs, resolved together: which gateway handles the
/// `bank_form` flow, and that gateway's bank list. Gateway discovery degrades
/// to the spec's documented default (paystack) when the methods payload is
/// unavailable; the bank list itself never falls back to fabricated entries.
class AddBankOptions {
  const AddBankOptions({required this.gatewayName, required this.banks});

  final String gatewayName;
  final List<SupportedBank> banks;
}

/// Fee percentage for the withdraw screen's pre-confirmation estimate.
/// Null = the backend didn't expose one; the UI then defers to the
/// response's `fee`/`net_amount`. Never a client-side default.
final withdrawalFeePercentProvider = FutureProvider<Decimal?>((ref) {
  return ref.watch(walletRepositoryProvider).getWithdrawalFeePercent();
});

final addBankOptionsProvider = FutureProvider<AddBankOptions>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  var gateway = 'paystack'; // Spec: banks endpoint "defaults to paystack".
  try {
    final methods = await repo.getWithdrawalMethods();
    final bankForm = methods.where((m) => m.flow == 'bank_form');
    if (bankForm.isNotEmpty && bankForm.first.gateway.trim().isNotEmpty) {
      gateway = bankForm.first.gateway.trim().toLowerCase();
    }
  } catch (_) {
    // Methods discovery is an optimisation; the banks call still decides.
  }
  var banks = await repo.getSupportedBanks(gateway: gateway);
  // A wrong/unknown gateway name can yield an empty list while the default
  // still works — retry once without a filter, then as plain paystack.
  if (banks.isEmpty && gateway != 'paystack') {
    banks = await repo.getSupportedBanks(gateway: 'paystack');
    if (banks.isNotEmpty) gateway = 'paystack';
  }
  if (banks.isEmpty) {
    banks = await repo.getSupportedBanks();
  }
  return AddBankOptions(gatewayName: gateway, banks: banks);
});
