import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../playlists/data/playlists_store.dart';
import 'buy_coins_screen.dart';
import 'data/wallet_store.dart';
import 'transaction_details_screen.dart';
import 'withdraw_screen.dart';

// Figma: **Profile Flow 11/02** (`1256:24678` / `1256:24006`) — SkillCoin
// Wallet hub. Brand balance card (Total Balance, coin figure, ₦ approx,
// Withdraw + Buy coins), Earned/Spent/Withdrawn stat strip, and the
// transaction list with All/Earned/Spent filter pills.

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

/// Transaction filter pills. `null` = All.
enum _TxnFilter { all, earned, spent }

class _WalletScreenState extends ConsumerState<WalletScreen> {
  _TxnFilter _filter = _TxnFilter.all;

  @override
  void initState() {
    super.initState();
    // Refresh ledger when the screen opens (session may already exist).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).refreshFromBackend();
    });
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(playlistsProvider).skillCoins;
    final wallet = ref.watch(walletProvider);
    final txns = switch (_filter) {
      _TxnFilter.all => wallet.transactions,
      _TxnFilter.earned =>
        wallet.transactions.where((t) => t.type == CoinTxnType.earned).toList(),
      _TxnFilter.spent =>
        wallet.transactions.where((t) => t.type != CoinTxnType.earned).toList(),
    };

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'SkillCoin Wallet',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 24px spacer mirrors the leading icon to keep the title centered.
        trailing: const SizedBox(width: SkifluxSpacing.spaceXl),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
          children: [
            _BalanceHero(coins: coins),
            const SizedBox(height: SkifluxSpacing.spaceL),
            _StatStrip(wallet: wallet),
            const SizedBox(height: SkifluxSpacing.spaceL),
            _transactionsHeader(),
            const SizedBox(height: SkifluxSpacing.spaceL),
            _TxnCard(txns: txns),
          ],
        ),
      ),
    );
  }

  /// "Transactions" heading + All / Earned / Spent filter pills.
  Widget _transactionsHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Transactions',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SkifluxTypography.headingH9Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
        ),
        const SizedBox(width: SkifluxSpacing.spaceS),
        // Pills hug their content — three size-S pills fit beside the
        // heading at the 393pt frame, so no scroll view (which clipped
        // the "All" pill when reversed).
        for (final f in _TxnFilter.values) ...[
          if (f != _TxnFilter.values.first)
            const SizedBox(width: SkifluxSpacing.spaceXs),
          SkifluxButton(
            label: switch (f) {
              _TxnFilter.all => 'All',
              _TxnFilter.earned => 'Earned',
              _TxnFilter.spent => 'Spent',
            },
            size: SkifluxButtonSize.s,
            type: f == _filter
                ? SkifluxButtonType.primary
                : SkifluxButtonType.secondary,
            onPressed: () => setState(() => _filter = f),
          ),
        ],
      ],
    );
  }
}

/// Brand-tinted balance card (`1256:24685`): "Total Balance", coin glyph +
/// H6-scale amber figure, "≈ ₦N · 1 coin = ₦6", Withdraw + Buy coins.
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    final naira = coins * kCoinRateNaira;
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundSelected,
        borderRadius: SkifluxRadii.borderX,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          Row(
            children: [
              const Icon(
                RemixIcons.copper_coin_fill,
                size: SkifluxUnit.u32,
                color: SkifluxColors.contentNotice,
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              Text(
                CoinPack.thousands(coins),
                style: SkifluxTypography.headingH6ExtraBold.copyWith(
                  color: SkifluxColors.contentNotice,
                ),
              ),
            ],
          ),
          const SizedBox(height: SkifluxSpacing.spaceXs),
          Text(
            '≈ ₦${CoinPack.thousands(naira)} · 1 coin = ₦$kCoinRateNaira',
            style: SkifluxTypography.bodyP10Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceL),
          Row(
            children: [
              Expanded(
                child: SkifluxButton(
                  label: 'Withdraw',
                  expanded: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WithdrawScreen()),
                  ),
                ),
              ),
              const SizedBox(width: SkifluxSpacing.spaceS),
              Expanded(
                // White pill on the tinted card (Figma shows a filled white
                // secondary) — tertiaryMono gives white fill + primary label.
                child: SkifluxButton(
                  label: 'Buy coins',
                  type: SkifluxButtonType.tertiaryMono,
                  expanded: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BuyCoinsScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Earned / Spent / Withdrawn totals strip (`1256:24717`): bordered card,
/// three equal cells split by hairlines.
class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.wallet});

  final WalletState wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: SkifluxRadii.borderL,
        border: Border.all(
          color: SkifluxColors.borderTertiary,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: SkifluxSpacing.spaceM),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _cell('+${wallet.earnedTotal}', 'Earned'),
            _divider(),
            _cell('-${wallet.spentTotal}', 'Spent'),
            _divider(),
            _cell('-${wallet.withdrawnTotal}', 'Withdrawn'),
          ],
        ),
      ),
    );
  }

  Widget _cell(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: SkifluxColors.contentPrimary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceXs),
          Text(
            label,
            style: SkifluxTypography.bodyP11Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const VerticalDivider(
      width: SkifluxBorderWidth.xs,
      thickness: SkifluxBorderWidth.xs,
      color: SkifluxColors.borderTertiary,
    );
  }
}

/// Bordered card stacking transaction rows split by hairlines
/// (`1256:24106` list) — same stroke-outside-fills pattern as the
/// notifications card stack.
class _TxnCard extends StatelessWidget {
  const _TxnCard({required this.txns});

  final List<CoinTxn> txns;

  @override
  Widget build(BuildContext context) {
    if (txns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(SkifluxSpacing.space2xl),
        child: Center(
          child: Text(
            'No transactions yet',
            style: SkifluxTypography.bodyP8Regular.copyWith(
              color: SkifluxColors.contentTertiary,
            ),
          ),
        ),
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: SkifluxRadii.borderL),
      // Stroke as foregroundDecoration so card fills can't bleed over the
      // rounded corners (notifications-stack gotcha).
      foregroundDecoration: BoxDecoration(
        borderRadius: SkifluxRadii.borderL,
        border: Border.all(
          color: SkifluxColors.borderTertiary,
          width: SkifluxBorderWidth.xs,
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: txns.length,
        itemBuilder: (context, i) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0)
                const Divider(
                  height: SkifluxBorderWidth.xs,
                  thickness: SkifluxBorderWidth.xs,
                  color: SkifluxColors.borderTertiary,
                ),
              // Rows open the details frame (`3664:13258`).
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransactionDetailsScreen(txn: txns[i]),
                  ),
                ),
                child: _TxnRow(txn: txns[i]),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One ledger row: 32px tinted icon circle, title + subtitle, signed amount.
class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn});

  final CoinTxn txn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      child: Row(
        children: [
          Container(
            width: SkifluxUnit.u32,
            height: SkifluxUnit.u32,
            decoration: BoxDecoration(color: txn.tint, shape: BoxShape.circle),
            child: Icon(txn.icon, size: SkifluxIcons.sizeS, color: txn.glyph),
          ),
          const SizedBox(width: SkifluxSpacing.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.headingH10Bold.copyWith(
                    color: SkifluxColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: SkifluxSpacing.space2xs),
                Text(
                  txn.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkifluxTypography.bodyP11Regular.copyWith(
                    color: SkifluxColors.contentTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Text(
            txn.amountLabel,
            style: SkifluxTypography.headingH10Bold.copyWith(
              color: txn.amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
