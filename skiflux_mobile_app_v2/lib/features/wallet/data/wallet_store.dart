import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../playlists/data/playlists_store.dart' show CoinPack, playlistsProvider;
import 'models/skillcoin_transaction.dart';
import 'models/user_wallet.dart';
import 'models/wallet_financial_summary.dart';
import 'models/withdrawal_account.dart';
import 'wallet_repository.dart';

// SkillCoin Wallet data — transaction history + saved bank account.
//
// Figma: **Profile Flow 02** (`1256:24006`). [refreshFromBackend] loads
// `GET /wallet/my-wallet`, `my-transactions`, `summary`, and withdrawal
// accounts when a session exists. Demo seed remains the offline fallback.
// Coin balance display is synced into [playlistsProvider].

/// Ledger bucket — drives the wallet's All / Earned / Spent filter tabs and
/// the row's icon + amount color.
enum CoinTxnType { earned, spent, withdrawn }

/// The specific event behind a transaction — picks the leading icon.
enum CoinTxnKind { taskApproved, unlocked, withdrawalProcessed, topUp }

/// Where a ledger entry is in its lifecycle. Drives the status pill on the
/// details screen (`3664:13489`). Only [completed] appears in the demo seed —
/// the other two exist because the backend's transaction record has them and
/// the pill already has to render a colour per state.
enum CoinTxnStatus {
  completed,
  pending,
  failed;

  String get label => switch (this) {
    CoinTxnStatus.completed => 'Completed',
    CoinTxnStatus.pending => 'Pending',
    CoinTxnStatus.failed => 'Failed',
  };

  Color get background => switch (this) {
    CoinTxnStatus.completed => SkifluxColors.backgroundPositiveSubtle,
    CoinTxnStatus.pending => SkifluxColors.backgroundNoticeSubtle,
    CoinTxnStatus.failed => SkifluxColors.backgroundNegativeSubtle,
  };

  Color get foreground => switch (this) {
    CoinTxnStatus.completed => SkifluxColors.contentPositiveBold,
    CoinTxnStatus.pending => SkifluxColors.contentNoticeBold,
    CoinTxnStatus.failed => SkifluxColors.contentNegativeBold,
  };
}

/// One row in the wallet's transaction list (`1256:24107`…).
@immutable
class CoinTxn {
  const CoinTxn({
    required this.title,
    required this.subtitle,
    required this.delta,
    required this.type,
    required this.kind,
    this.status = CoinTxnStatus.completed,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
    this.reference,
  });

  /// Adapter from OpenAPI [SkillcoinTransaction] → UI ledger row.
  factory CoinTxn.fromSkillcoin(SkillcoinTransaction txn) {
    final amountInt = _decimalToDisplayInt(txn.amount);
    final type = _mapType(txn.transactionType, amountInt);
    final kind = _mapKind(txn.transactionType);
    return CoinTxn(
      title: txn.transactionTypeLabel.isNotEmpty
          ? txn.transactionTypeLabel
          : txn.description,
      subtitle: txn.description,
      delta: amountInt,
      type: type,
      kind: kind,
      status: _mapStatus(txn.status),
      createdAt: txn.createdAt,
      updatedAt: txn.createdAt,
      reference: txn.referenceId ?? txn.id,
    );
  }

  final String title;

  /// "Today · 9:41 AM" / "2 days ago · ₦1,200 sent".
  final String subtitle;

  /// Signed coin change: +70, -200. Sign drives the amount color.
  ///
  /// Sourced from [SkillcoinTransaction.amount] via [Decimal] (never
  /// `double.parse`). Whole-skillcoin display uses rounded integer form.
  final int delta;
  final CoinTxnType type;
  final CoinTxnKind kind;

  // ── Detail-only fields (`3664:13258`) ──────────────────────────────
  // The list row never shows these; they exist for the details screen. All
  // nullable so a row can be constructed without them, in which case the
  // details screen omits that line rather than inventing a value.

  final CoinTxnStatus status;

  /// "Bank Transfer" / "Card". Only money-moving kinds have one — a task
  /// reward or an unlock was never paid for.
  final String? paymentMethod;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// The processor's reference, shown (and copyable) as "Transaction ID".
  final String? reference;

  /// "+70" / "-200".
  String get amountLabel => '${delta >= 0 ? '+' : ''}$delta';

  /// The "Transaction type" line — the human name for [kind]. Figma's example
  /// row reads "Purchase" for a top-up.
  String get typeLabel => switch (kind) {
    CoinTxnKind.taskApproved => 'Task Reward',
    CoinTxnKind.unlocked => 'Episode Unlock',
    CoinTxnKind.withdrawalProcessed => 'Withdrawal',
    CoinTxnKind.topUp => 'Purchase',
  };

  IconData get icon => switch (kind) {
    CoinTxnKind.taskApproved => RemixIcons.checkbox_circle_fill,
    CoinTxnKind.unlocked => RemixIcons.lock_unlock_fill,
    CoinTxnKind.withdrawalProcessed => RemixIcons.bank_card_fill,
    CoinTxnKind.topUp => RemixIcons.coins_fill,
  };

  /// Icon circle tint + glyph color, by ledger bucket.
  Color get tint => switch (type) {
    CoinTxnType.earned => SkifluxColors.backgroundPositiveSubtle,
    CoinTxnType.spent => SkifluxColors.backgroundNegativeSubtle,
    CoinTxnType.withdrawn => SkifluxColors.backgroundNegativeSubtle,
  };

  Color get glyph => switch (type) {
    CoinTxnType.earned => SkifluxColors.contentPositive,
    CoinTxnType.spent => SkifluxColors.contentNegative,
    CoinTxnType.withdrawn => SkifluxColors.contentNegative,
  };

  /// Amount text color: earned = positive, spent/withdrawn = negative.
  Color get amountColor => type == CoinTxnType.earned
      ? SkifluxColors.contentPositive
      : SkifluxColors.contentNegative;
}

int _decimalToDisplayInt(Decimal d) {
  // Skillcoins are typically whole; round half-away-from-zero for display.
  return int.parse(d.round().toString());
}

CoinTxnType _mapType(SkillcoinTransactionType t, int amount) {
  switch (t) {
    case SkillcoinTransactionType.withdrawal:
    case SkillcoinTransactionType.withdrawalFee:
      return CoinTxnType.withdrawn;
    case SkillcoinTransactionType.debitPurchase:
    case SkillcoinTransactionType.platformCashbackDebit:
      return CoinTxnType.spent;
    case SkillcoinTransactionType.deposit:
    case SkillcoinTransactionType.topup:
    case SkillcoinTransactionType.cashbackReward:
    case SkillcoinTransactionType.refund:
    case SkillcoinTransactionType.registrationBonus:
    case SkillcoinTransactionType.creatorRevenue:
    case SkillcoinTransactionType.adminAdjustment:
    case SkillcoinTransactionType.creatorRevenueReversal:
    case SkillcoinTransactionType.platformRevenue:
    case SkillcoinTransactionType.unknown:
      return amount < 0 ? CoinTxnType.spent : CoinTxnType.earned;
  }
}

CoinTxnKind _mapKind(SkillcoinTransactionType t) {
  return switch (t) {
    SkillcoinTransactionType.withdrawal ||
    SkillcoinTransactionType.withdrawalFee =>
      CoinTxnKind.withdrawalProcessed,
    SkillcoinTransactionType.topup ||
    SkillcoinTransactionType.deposit =>
      CoinTxnKind.topUp,
    SkillcoinTransactionType.debitPurchase => CoinTxnKind.unlocked,
    _ => CoinTxnKind.taskApproved,
  };
}

CoinTxnStatus _mapStatus(SkillcoinTransactionStatus? s) {
  return switch (s) {
    SkillcoinTransactionStatus.pending => CoinTxnStatus.pending,
    SkillcoinTransactionStatus.failed ||
    SkillcoinTransactionStatus.cancelled =>
      CoinTxnStatus.failed,
    _ => CoinTxnStatus.completed,
  };
}

/// A saved withdrawal destination (`1256:24390` — Add New Bank Account).
@immutable
class BankAccount {
  const BankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.holderName,
  });

  final String bankName;
  final String accountNumber;
  final String holderName;

  /// Last four digits for the masked "Amara Design ⋯ 4521" line.
  String get last4 => accountNumber.length <= 4
      ? accountNumber
      : accountNumber.substring(accountNumber.length - 4);
}

/// Snapshot of the wallet ledger + saved withdrawal banks.
@immutable
class WalletState {
  const WalletState({
    required this.transactions,
    required this.banks,
    this.defaultBank,
    this.remoteWallet,
    this.summary,
    this.fromBackend = false,
    this.loading = false,
  });

  final List<CoinTxn> transactions;

  /// All saved withdrawal destinations (Settings → Withdrawal accounts,
  /// `1256:19981`). [defaultBank] is the one the Withdraw screen pays into.
  final List<BankAccount> banks;
  final BankAccount? defaultBank;

  /// Live balance payload when [fromBackend] is true.
  final UserWallet? remoteWallet;
  final WalletFinancialSummary? summary;
  final bool fromBackend;
  final bool loading;

  int _sum(CoinTxnType type) => transactions
      .where((t) => t.type == type)
      .fold(0, (sum, t) => sum + t.delta.abs());

  int get earnedTotal {
    final s = summary;
    if (s != null) return _decimalToDisplayInt(s.totalEarned);
    return _sum(CoinTxnType.earned);
  }

  int get spentTotal {
    final s = summary;
    if (s != null) return _decimalToDisplayInt(s.totalSpent);
    return _sum(CoinTxnType.spent);
  }

  int get withdrawnTotal {
    final s = summary;
    if (s != null) return _decimalToDisplayInt(s.totalWithdrawn);
    return _sum(CoinTxnType.withdrawn);
  }

  WalletState copyWith({
    List<CoinTxn>? transactions,
    List<BankAccount>? banks,
    BankAccount? defaultBank,
    UserWallet? remoteWallet,
    WalletFinancialSummary? summary,
    bool? fromBackend,
    bool? loading,
    bool clearDefaultBank = false,
  }) {
    return WalletState(
      transactions: transactions ?? this.transactions,
      banks: banks ?? this.banks,
      defaultBank: clearDefaultBank ? defaultBank : (defaultBank ?? this.defaultBank),
      remoteWallet: remoteWallet ?? this.remoteWallet,
      summary: summary ?? this.summary,
      fromBackend: fromBackend ?? this.fromBackend,
      loading: loading ?? this.loading,
    );
  }
}

/// Riverpod [NotifierProvider] — matches the app's other stores (playlists,
/// notifications). Seeded with the demo ledger; [refreshFromBackend] replaces
/// it when the session can reach the API.
final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    return const WalletState(
      transactions: [],
      banks: [],
    );
  }

  /// Loads wallet, transactions, summary, and bank accounts from the API.
  /// Keeps the current (demo or prior) state on failure.
  Future<void> refreshFromBackend() async {
    state = state.copyWith(loading: true);
    try {
      final repo = ref.read(walletRepositoryProvider);
      final wallet = await repo.getMyWallet();
      final txns = await repo.getMyTransactions();
      WalletFinancialSummary? summary;
      try {
        summary = await repo.getSummary();
      } catch (_) {
        // Optional strip — ledger alone is enough for the list.
      }
      List<BankAccount> banks = state.banks;
      BankAccount? defaultBank = state.defaultBank;
      try {
        final accounts = await repo.getWithdrawalAccounts();
        if (accounts.isNotEmpty) {
          banks = accounts.map(_bankFromAccount).toList(growable: false);
          final preferred = accounts.cast<WithdrawalAccount?>().firstWhere(
            (a) => a!.isDefault,
            orElse: () => accounts.first,
          );
          defaultBank = _bankFromAccount(preferred!);
        }
      } catch (_) {
        // Banks optional on first wallet open.
      }

      final mapped = txns.map(CoinTxn.fromSkillcoin).toList(growable: false);
      state = WalletState(
        transactions: mapped.isEmpty ? state.transactions : mapped,
        banks: banks,
        defaultBank: defaultBank,
        remoteWallet: wallet,
        summary: summary,
        fromBackend: true,
        loading: false,
      );

      // Keep the skill-coin pill / unlock balance in sync (whole coins).
      final balanceInt = _decimalToDisplayInt(wallet.balance);
      ref.read(playlistsProvider.notifier).setSkillCoins(balanceInt);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  static BankAccount _bankFromAccount(WithdrawalAccount a) {
    return BankAccount(
      bankName: a.bankName.isNotEmpty ? a.bankName : a.displayName,
      accountNumber: a.accountNumber.isNotEmpty
          ? a.accountNumber
          : a.displayName,
      holderName: a.accountName.isNotEmpty ? a.accountName : a.displayName,
    );
  }

  /// Records a coins-spent entry when an episode is unlocked.
  void recordUnlock(String epTag, int cost) {
    final now = DateTime.now();
    _prepend(
      CoinTxn(
        title: 'Unlocked $epTag',
        subtitle: 'Today',
        delta: -cost,
        type: CoinTxnType.spent,
        kind: CoinTxnKind.unlocked,
        createdAt: now,
        updatedAt: now,
        reference: _reference(now),
      ),
    );
  }

  /// Records a coins-earned entry when a wallet top-up completes.
  void recordTopUp(int coins, int naira) {
    final now = DateTime.now();
    _prepend(
      CoinTxn(
        title: 'Coin top-up · $coins coins',
        subtitle: 'Today · ₦${CoinPack.thousands(naira)} paid',
        delta: coins,
        type: CoinTxnType.earned,
        kind: CoinTxnKind.topUp,
        paymentMethod: 'Bank Transfer',
        createdAt: now,
        updatedAt: now,
        reference: _reference(now),
      ),
    );
  }

  /// Records a withdrawal entry.
  void recordWithdrawal(int coins, int naira, String bankLast4) {
    final now = DateTime.now();
    _prepend(
      CoinTxn(
        title: 'Withdrawal processed',
        subtitle: 'Today · ₦${CoinPack.thousands(naira)} sent',
        delta: -coins,
        type: CoinTxnType.withdrawn,
        kind: CoinTxnKind.withdrawalProcessed,
        paymentMethod: 'Bank Transfer ···$bankLast4',
        createdAt: now,
        updatedAt: now,
        reference: _reference(now),
      ),
    );
  }

  /// Stand-in reference for client-side optimistic rows. Backend rows use
  /// [SkillcoinTransaction.referenceId] via [CoinTxn.fromSkillcoin].
  static String _reference(DateTime at) =>
      '1000000000${at.microsecondsSinceEpoch}'.padRight(30, '0').substring(
        0,
        30,
      );

  /// Appends a saved withdrawal destination and makes it the new default.
  void addBank(BankAccount account) {
    state = state.copyWith(
      banks: [...state.banks, account],
      defaultBank: account,
    );
  }

  /// Removes a saved bank. If it was the default, the first remaining bank
  /// (if any) becomes the new default.
  void removeBank(BankAccount account) {
    final banks = state.banks.where((b) => b != account).toList();
    final wasDefault = state.defaultBank == account;
    state = WalletState(
      transactions: state.transactions,
      banks: banks,
      defaultBank: wasDefault
          ? (banks.isEmpty ? null : banks.first)
          : state.defaultBank,
    );
  }

  void _prepend(CoinTxn txn) {
    state = state.copyWith(transactions: [txn, ...state.transactions]);
  }


}
