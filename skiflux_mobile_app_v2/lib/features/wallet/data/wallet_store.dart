import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../playlists/data/playlists_store.dart' show playlistsProvider;
import 'models/skillcoin_transaction.dart';
import 'models/user_wallet.dart';
import 'models/wallet_financial_summary.dart';
import 'models/withdrawal_account.dart';
import 'models/withdrawal_request.dart';
import 'wallet_repository.dart';

// SkillCoin Wallet data — transaction history + saved bank accounts.
//
// Figma: **Profile Flow 02** (`1256:24006`). [refreshFromBackend] loads
// `GET /wallet/my-wallet`, `my-transactions`, `summary`, and withdrawal
// accounts when a session exists.
//
// Money honesty: the fetched [UserWallet]'s Decimal `balance` is the source
// of truth for every coin figure. The int exposed through
// [playlistsProvider.skillCoins] is a floor-derived display view of it.
// Locally-recorded ledger rows are always [CoinTxnStatus.pending] and are
// replaced wholesale by the backend ledger on every successful refresh —
// including by an *empty* backend ledger.

/// Ledger bucket — drives the wallet's All / Earned / Spent filter tabs and
/// the row's icon + amount color.
enum CoinTxnType { earned, spent, withdrawn }

/// The specific event behind a transaction — picks the leading icon.
enum CoinTxnKind { taskApproved, unlocked, withdrawalProcessed, topUp }

/// Where a ledger entry is in its lifecycle. Drives the status pill on the
/// details screen (`3664:13489`).
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
    this.isLocal = false,
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
      // Real updated_at when the backend sent one; never aliased to
      // createdAt — the details screen drops the row instead.
      updatedAt: txn.updatedAt,
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
  /// Null for locally-recorded rows — a reference is never fabricated.
  final String? reference;

  /// True for rows recorded client-side while the backend confirms. They are
  /// always [CoinTxnStatus.pending] and vanish on the next ledger refresh.
  final bool isLocal;

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

/// Ledger-row display form of a signed amount — rounds half-away-from-zero.
/// Only for transaction deltas and stat totals; a *spendable balance* must go
/// through [wholeCoinFloor] instead so it is never rounded up.
int _decimalToDisplayInt(Decimal d) {
  return int.parse(d.round().toString());
}

/// Whole-coin view of a balance: floor, so "100.50" displays as 100 coins —
/// never 101 coins the user doesn't have.
int wholeCoinFloor(Decimal d) => d.floor().toBigInt().toInt();

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

CoinTxnStatus _mapWithdrawalStatus(WithdrawalRequestStatus s) {
  return switch (s) {
    WithdrawalRequestStatus.pending ||
    WithdrawalRequestStatus.processing =>
      CoinTxnStatus.pending,
    WithdrawalRequestStatus.completed => CoinTxnStatus.completed,
    WithdrawalRequestStatus.failed ||
    WithdrawalRequestStatus.cancelled ||
    WithdrawalRequestStatus.rejected =>
      CoinTxnStatus.failed,
  };
}

/// A saved withdrawal destination (`1256:24390` — Add New Bank Account).
@immutable
class BankAccount {
  const BankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.holderName,
    this.id,
  });

  /// Backend `WithdrawalAccount.id` — what `POST /wallet/withdrawals/request`
  /// takes as `account_id`. Null only for rows that never came from the
  /// backend; such rows cannot be withdrawn to.
  final String? id;

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

  // ── Real balances (source of truth) ────────────────────────────────

  /// The wallet's exact spendable balance. Null until the backend payload
  /// has loaded — callers show a loading/zero state, never a fake figure.
  Decimal? get balance => remoteWallet?.balance;

  /// Hold-aware withdrawable balance, exactly as the backend computed it.
  Decimal? get withdrawableBalance => remoteWallet?.withdrawableBalance;

  /// Locked wallets can't transact; the withdraw screen gates on this.
  bool get isLocked => remoteWallet?.isLocked ?? false;

  /// True once a real wallet payload has been loaded this session.
  bool get balanceKnown => remoteWallet != null;

  /// Whole-coin display form of [balance] (floor); 0 while unknown.
  int get wholeCoins {
    final b = balance;
    return b == null ? 0 : wholeCoinFloor(b);
  }

  /// Whole-coin ceiling for withdrawals (floor of the withdrawable balance;
  /// zero when the wallet is locked or unknown).
  int get wholeWithdrawableCoins {
    if (isLocked) return 0;
    final w = withdrawableBalance;
    return w == null ? 0 : wholeCoinFloor(w);
  }

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
/// notifications). Starts empty; [refreshFromBackend] fills it when the
/// session can reach the API.
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
  /// Keeps the current state on failure. On success the backend ledger
  /// replaces the local one entirely — locally-recorded pending rows are
  /// dropped, and an empty backend ledger clears the list.
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
        // The backend list wins outright — an empty list means the user has
        // no saved destinations, so stale local rows are cleared too.
        banks = accounts.map(_bankFromAccount).toList(growable: false);
        if (accounts.isEmpty) {
          defaultBank = null;
        } else {
          final preferred = accounts.cast<WithdrawalAccount?>().firstWhere(
            (a) => a!.isDefault,
            orElse: () => accounts.first,
          );
          defaultBank = _bankFromAccount(preferred!);
        }
      } catch (_) {
        // Accounts read failed — keep whatever we had; never fabricate.
      }

      final mapped = txns.map(CoinTxn.fromSkillcoin).toList(growable: false);
      state = WalletState(
        // The backend ledger is authoritative, even when empty.
        transactions: mapped,
        banks: banks,
        defaultBank: defaultBank,
        remoteWallet: wallet,
        summary: summary,
        fromBackend: true,
        loading: false,
      );

      // Keep the skill-coin pill / unlock balance in sync. Floor — a
      // spendable balance of 100.50 is 100 whole coins, never 101.
      ref
          .read(playlistsProvider.notifier)
          .setSkillCoins(wholeCoinFloor(wallet.balance));
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  static BankAccount _bankFromAccount(WithdrawalAccount a) {
    return BankAccount(
      id: a.id,
      bankName: a.bankName.isNotEmpty ? a.bankName : a.displayName,
      accountNumber: a.accountNumber.isNotEmpty
          ? a.accountNumber
          : a.displayName,
      holderName: a.accountName.isNotEmpty ? a.accountName : a.displayName,
    );
  }

  /// Records a local *pending* row after `POST /episodes/purchase` returned
  /// 2xx, purely as immediate feedback. No reference is fabricated; the row
  /// is replaced by the backend's own record on the next ledger refresh.
  void recordUnlock(String epTag, int cost) {
    _prepend(
      CoinTxn(
        title: 'Unlocked $epTag',
        subtitle: 'Just now · syncing with your wallet',
        delta: -cost,
        type: CoinTxnType.spent,
        kind: CoinTxnKind.unlocked,
        status: CoinTxnStatus.pending,
        createdAt: DateTime.now(),
        isLocal: true,
      ),
    );
  }

  /// Records the ledger row for a 201 from `POST /wallet/withdrawals/request`
  /// using the backend's own response data (amount, status, id, timestamps) —
  /// nothing is invented. Replaced by the ledger feed on the next refresh.
  void recordWithdrawalRequest(WithdrawalRequest request) {
    final coins = _decimalToDisplayInt(request.amount);
    _prepend(
      CoinTxn(
        title: 'Withdrawal requested',
        subtitle: request.account.displayName.isNotEmpty
            ? 'To ${request.account.displayName}'
            : 'Bank withdrawal',
        delta: -coins,
        type: CoinTxnType.withdrawn,
        kind: CoinTxnKind.withdrawalProcessed,
        status: _mapWithdrawalStatus(request.status),
        paymentMethod: 'Bank Transfer',
        createdAt: request.createdAt,
        reference: request.id,
        isLocal: true,
      ),
    );
  }

  /// Appends a saved withdrawal destination and makes it the new default.
  /// Call with accounts returned by the backend (carrying an [BankAccount.id]).
  void addBank(BankAccount account) {
    state = state.copyWith(
      banks: [...state.banks, account],
      defaultBank: account,
    );
  }

  /// Removes a saved bank from local state. If it was the default, the first
  /// remaining bank (if any) becomes the new default. (The backend delete is
  /// `WalletRepository.deleteWithdrawalAccount`; callers run it first.)
  void removeBank(BankAccount account) {
    final banks = state.banks.where((b) => b != account).toList();
    final wasDefault = state.defaultBank == account;
    state = WalletState(
      transactions: state.transactions,
      banks: banks,
      defaultBank: wasDefault
          ? (banks.isEmpty ? null : banks.first)
          : state.defaultBank,
      remoteWallet: state.remoteWallet,
      summary: state.summary,
      fromBackend: state.fromBackend,
    );
  }

  void _prepend(CoinTxn txn) {
    state = state.copyWith(transactions: [txn, ...state.transactions]);
  }
}
