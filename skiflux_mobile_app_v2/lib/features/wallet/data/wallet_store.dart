import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../playlists/data/playlists_store.dart' show CoinPack;

// SkillCoin Wallet data — transaction history + saved bank account.
//
// Figma: **Profile Flow 02** (`1256:24006`) — the wallet's transaction list
// and the Earned/Spent/Withdrawn summary cells. No backend yet, so the store
// seeds the demo rows shown in the frame and appends live entries as the user
// unlocks episodes, tops up, or withdraws. Coin balance itself stays owned by
// [PlaylistsNotifier]; this store only records the ledger + destination bank.

/// Ledger bucket — drives the wallet's All / Earned / Spent filter tabs and
/// the row's icon + amount color.
enum CoinTxnType { earned, spent, withdrawn }

/// The specific event behind a transaction — picks the leading icon.
enum CoinTxnKind { taskApproved, unlocked, withdrawalProcessed, topUp }

/// One row in the wallet's transaction list (`1256:24107`…).
@immutable
class CoinTxn {
  const CoinTxn({
    required this.title,
    required this.subtitle,
    required this.delta,
    required this.type,
    required this.kind,
  });

  final String title;

  /// "Today · 9:41 AM" / "2 days ago · ₦1,200 sent".
  final String subtitle;

  /// Signed coin change: +70, -200. Sign drives the amount color.
  final int delta;
  final CoinTxnType type;
  final CoinTxnKind kind;

  /// "+70" / "-200".
  String get amountLabel => '${delta >= 0 ? '+' : ''}$delta';

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
  });

  final List<CoinTxn> transactions;

  /// All saved withdrawal destinations (Settings → Withdrawal accounts,
  /// `1256:19981`). [defaultBank] is the one the Withdraw screen pays into.
  final List<BankAccount> banks;
  final BankAccount? defaultBank;

  int _sum(CoinTxnType type) => transactions
      .where((t) => t.type == type)
      .fold(0, (sum, t) => sum + t.delta.abs());

  int get earnedTotal => _sum(CoinTxnType.earned);
  int get spentTotal => _sum(CoinTxnType.spent);
  int get withdrawnTotal => _sum(CoinTxnType.withdrawn);

  WalletState copyWith({
    List<CoinTxn>? transactions,
    List<BankAccount>? banks,
    BankAccount? defaultBank,
  }) {
    return WalletState(
      transactions: transactions ?? this.transactions,
      banks: banks ?? this.banks,
      defaultBank: defaultBank ?? this.defaultBank,
    );
  }
}

/// Riverpod [NotifierProvider] — matches the app's other stores (playlists,
/// notifications). Seeded with the demo ledger + the demo Access Bank account
/// shown as the default withdrawal destination.
// TODO(backend, blocking): replace static seeded transaction ledger and bank account with real backend wallet history and withdrawal destination — expects: {transactions: List<{title: String, subtitle: String, delta: int, type: CoinTxnType, kind: CoinTxnKind}>, defaultBank: {bankName: String, accountNumber: String, holderName: String}?}
final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    const seedBank = BankAccount(
      bankName: 'Access Bank',
      accountNumber: '0123454521',
      holderName: 'Amara Design',
    );
    return WalletState(
      transactions: _seedTransactions(),
      banks: const [seedBank],
      defaultBank: seedBank,
    );
  }

  /// Records a coins-spent entry when an episode is unlocked.
  void recordUnlock(String epTag, int cost) {
    _prepend(CoinTxn(
      title: 'Unlocked $epTag',
      subtitle: 'Today',
      delta: -cost,
      type: CoinTxnType.spent,
      kind: CoinTxnKind.unlocked,
    ));
  }

  /// Records a coins-earned entry when a wallet top-up completes.
  void recordTopUp(int coins, int naira) {
    _prepend(CoinTxn(
      title: 'Coin top-up · $coins coins',
      subtitle: 'Today · ₦${CoinPack.thousands(naira)} paid',
      delta: coins,
      type: CoinTxnType.earned,
      kind: CoinTxnKind.topUp,
    ));
  }

  /// Records a withdrawal entry.
  void recordWithdrawal(int coins, int naira, String bankLast4) {
    _prepend(CoinTxn(
      title: 'Withdrawal processed',
      subtitle: 'Today · ₦${CoinPack.thousands(naira)} sent',
      delta: -coins,
      type: CoinTxnType.withdrawn,
      kind: CoinTxnKind.withdrawalProcessed,
    ));
  }

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

  /// Demo ledger from Profile Flow 02 (`1256:24107`…).
  static List<CoinTxn> _seedTransactions() {
    return const [
      CoinTxn(
        title: 'EP 04 task approved',
        subtitle: 'Today · 9:41 AM',
        delta: 70,
        type: CoinTxnType.earned,
        kind: CoinTxnKind.taskApproved,
      ),
      CoinTxn(
        title: 'Unlocked EP 03',
        subtitle: 'Today · 9:41 AM',
        delta: -200,
        type: CoinTxnType.spent,
        kind: CoinTxnKind.unlocked,
      ),
      CoinTxn(
        title: 'Withdrawal processed',
        subtitle: '2 days ago · ₦1,200 sent',
        delta: -200,
        type: CoinTxnType.withdrawn,
        kind: CoinTxnKind.withdrawalProcessed,
      ),
      CoinTxn(
        title: 'EP 03 task approved',
        subtitle: '3 days ago',
        delta: 50,
        type: CoinTxnType.earned,
        kind: CoinTxnKind.taskApproved,
      ),
      CoinTxn(
        title: 'Coin top-up · 200 coins',
        subtitle: '4 days ago · ₦1,100 paid',
        delta: 200,
        type: CoinTxnType.earned,
        kind: CoinTxnKind.topUp,
      ),
    ];
  }
}
