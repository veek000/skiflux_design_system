import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'models/skillcoin_transaction.dart';
import 'models/user_wallet.dart';
import 'models/wallet_financial_summary.dart';
import 'models/withdrawal_account.dart';

/// Wallet read surface for Tier 1 #36 (balance, ledger, summary, banks).
class WalletRepository extends ApiRepository {
  const WalletRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.contentLoadFailed;

  Future<UserWallet> getMyWallet() => getObject(
    '/wallet/my-wallet',
    parse: UserWallet.fromJson,
  );

  Future<List<SkillcoinTransaction>> getMyTransactions() => getList(
    '/wallet/my-transactions',
    parse: SkillcoinTransaction.fromJson,
  );

  Future<WalletFinancialSummary> getSummary() => getObject(
    '/wallet/summary',
    parse: WalletFinancialSummary.fromJson,
  );

  Future<List<WithdrawalAccount>> getWithdrawalAccounts() => getList(
    '/wallet/withdrawals/accounts/list',
    parse: WithdrawalAccount.fromJson,
  );
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(apiClientProvider)),
);
