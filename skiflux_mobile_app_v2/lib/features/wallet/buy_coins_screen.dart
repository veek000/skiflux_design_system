import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/sheets/skiflux_sheet.dart';
import '../playlists/data/playlists_store.dart';
import 'data/wallet_store.dart';
import 'widgets/coin_widgets.dart';

// Figma: **Profile Flow 10 / 01** (`1256:24781` / `1256:25179`) — the
// full-screen Buy Coins reached from the wallet hub. Same building blocks as
// the Other-Video-Player Buy Coins sheet (shared `coin_widgets.dart`), but on
// one page: balance, pack grid, payment method, live summary, and a pinned
// pay button. Success = headerless sheet ("Purchase Successful",
// `1256:25294`), then pops back to the wallet with balance + ledger updated.

class BuyCoinsScreen extends ConsumerStatefulWidget {
  const BuyCoinsScreen({super.key});

  @override
  ConsumerState<BuyCoinsScreen> createState() => _BuyCoinsScreenState();
}

class _BuyCoinsScreenState extends ConsumerState<BuyCoinsScreen> {
  CoinPack? _selected;
  bool _cardPayment = true;

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(playlistsProvider).skillCoins;
    final pack = _selected;

    return Scaffold(
      backgroundColor: SkifluxColors.backgroundPrimary,
      appBar: SkifluxTopNavBar(
        label: 'Buy Coins',
        labelStyle: SkifluxTypography.headingH8Bold,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(RemixIcons.arrow_left_s_line),
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: const SizedBox(width: SkifluxSpacing.spaceXl),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
                children: [
                  CoinBalanceCard(coins: coins),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  Text(
                    'Choose a coin pack',
                    style: SkifluxTypography.headingH9Bold.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  for (var i = 0; i < kCoinPacks.length; i += 2)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i + 2 < kCoinPacks.length
                            ? SkifluxSpacing.spaceL
                            : 0,
                      ),
                      // IntrinsicHeight bounds the stretch — a bare stretch
                      // Row inside a ListView forces infinite height and
                      // blanks the whole screen.
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _packCard(kCoinPacks[i])),
                            const SizedBox(width: SkifluxSpacing.spaceL),
                            if (i + 1 < kCoinPacks.length)
                              Expanded(child: _packCard(kCoinPacks[i + 1]))
                            else
                              const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  Text(
                    'Payment method',
                    style: SkifluxTypography.headingH9Bold.copyWith(
                      color: SkifluxColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: SkifluxSpacing.spaceL),
                  PaymentMethodSelector(
                    cardSelected: _cardPayment,
                    onChanged: (isCard) =>
                        setState(() => _cardPayment = isCard),
                  ),
                  if (pack != null) ...[
                    const SizedBox(height: SkifluxSpacing.spaceL),
                    CoinSummaryCard(
                      rows: [
                        CoinSummaryRow('Amount', pack.priceLabel),
                        const CoinSummaryRow(
                          'Rate',
                          '1 coin = ₦$kCoinRateNaira',
                        ),
                        CoinSummaryRow(
                          "You're Buying",
                          '${pack.coins}',
                          emphasizeCoins: true,
                        ),
                      ],
                      total: pack.priceLabel,
                    ),
                  ],
                ],
              ),
            ),
            // Pinned pay button — label mirrors the selection state
            // ("Choose a coin pack" disabled until one is picked).
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: SkifluxButton(
                label: pack == null
                    ? 'Choose a coin pack'
                    : 'Pay ${pack.priceLabel} · Get ${pack.coins} coins',
                expanded: true,
                onPressed: pack == null ? null : () => _pay(pack),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _packCard(CoinPack pack) {
    return CoinPackCard(
      pack: pack,
      selected: _selected == pack,
      onTap: () => setState(() => _selected = pack),
    );
  }

  Future<void> _pay(CoinPack pack) async {
    ref.read(playlistsProvider.notifier).topUp(pack.coins);
    ref
        .read(walletProvider.notifier)
        .recordTopUp(pack.coins, pack.priceNaira);
    if (!mounted) return;
    await showPurchaseSuccessSheet(context, pack: pack);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

/// "Purchase Successful" sheet (`1256:25294`): headerless card — green check
/// circle, title, body, amount/coins/new-balance summary, Done.
Future<void> showPurchaseSuccessSheet(
  BuildContext context, {
  required CoinPack pack,
}) {
  return showSkifluxSheet<void>(
    context: context,
    builder: (_) => _PurchaseSuccessSheet(pack: pack),
  );
}

class _PurchaseSuccessSheet extends ConsumerWidget {
  const _PurchaseSuccessSheet({required this.pack});

  final CoinPack pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(playlistsProvider).skillCoins;
    return SkifluxSheetShell(
      title: '',
      showHeader: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          // Headerless card — clear the grabber pill (top 8px + 4px tall).
          SkifluxSpacing.space2xl,
          SkifluxSpacing.spaceL,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 98,
                height: 98,
                decoration: const BoxDecoration(
                  color: SkifluxColors.backgroundPositiveSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  RemixIcons.check_fill,
                  size: 48,
                  color: SkifluxColors.contentPositive,
                ),
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              'Purchase Successful',
              textAlign: TextAlign.center,
              style: SkifluxTypography.headingH7Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceXs),
            Text(
              'Your wallet has been topped up with ${pack.coins} SkillCoins. '
              'You can now use them to unlock episodes.',
              textAlign: TextAlign.center,
              style: SkifluxTypography.bodyP8Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            CoinSummaryCard(
              filled: true,
              rows: [
                CoinSummaryRow('Amount', pack.priceLabel),
                CoinSummaryRow('Coins Purchased', '+${pack.coins}'),
              ],
              totalLabel: 'New balance',
              totalCoins: coins,
            ),
            const SizedBox(height: SkifluxSpacing.spaceXl),
            SkifluxButton(
              label: 'Done',
              expanded: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
