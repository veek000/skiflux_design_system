import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/sheets/skiflux_sheet.dart';
import '../../playlists/data/playlists_store.dart';
import '../../wallet/data/wallet_store.dart';
import '../../wallet/widgets/coin_widgets.dart';

// Figma: Other Video Player Flow 04 → 03 → 02
// (`1256:27567` packs → `1256:27688` payment → `1256:27814` success).
//
// Three-phase headerless sheet: pick a pack → confirm payment method →
// success. Tops up the SkillCoin wallet via [PlaylistsNotifier.topUp].

enum _PayMethod { card, bank }

enum _BuyPhase { packs, payment, success }

/// Opens Buy Coins. Resolves with the number of coins purchased (or null
/// if the user backed out) so callers can react (e.g. retry an unlock).
Future<int?> showBuyCoinsSheet(BuildContext context) {
  return showSkifluxSheet<int>(
    context: context,
    builder: (_) => const _BuyCoinsSheet(),
  );
}

class _BuyCoinsSheet extends ConsumerStatefulWidget {
  const _BuyCoinsSheet();

  @override
  ConsumerState<_BuyCoinsSheet> createState() => _BuyCoinsSheetState();
}

class _BuyCoinsSheetState extends ConsumerState<_BuyCoinsSheet> {
  _BuyPhase _phase = _BuyPhase.packs;
  CoinPack? _selected;
  _PayMethod _method = _PayMethod.card;

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _BuyPhase.packs => _packsView(),
      _BuyPhase.payment => _paymentView(),
      _BuyPhase.success => _successView(),
    };
  }

  // --- Phase 1: choose a pack -------------------------------------------

  Widget _packsView() {
    final coins = ref.watch(playlistsProvider).skillCoins;
    return SkifluxSheetShell(
      title: 'Buy Coins',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                // IntrinsicHeight bounds the stretch — a bare stretch Row
                // inside a scrollable forces infinite height and blanks the
                // whole sheet.
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
            SkifluxButton(
              label: _selected == null
                  ? 'Choose a coin pack'
                  : 'Continue',
              expanded: true,
              onPressed: _selected == null
                  ? null
                  : () => setState(() => _phase = _BuyPhase.payment),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxButton(
              label: 'Back',
              type: SkifluxButtonType.secondary,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(),
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

  // --- Phase 2: payment method + summary --------------------------------

  Widget _paymentView() {
    final coins = ref.watch(playlistsProvider).skillCoins;
    final pack = _selected!;
    return SkifluxSheetShell(
      title: 'Buy Coins',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoinBalanceCard(coins: coins),
            const SizedBox(height: SkifluxSpacing.spaceL),
            Text(
              'Payment method',
              style: SkifluxTypography.headingH9Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            PaymentMethodSelector(
              cardSelected: _method == _PayMethod.card,
              onChanged: (isCard) => setState(
                () => _method = isCard ? _PayMethod.card : _PayMethod.bank,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            CoinSummaryCard(
              rows: [
                CoinSummaryRow('Amount', pack.priceLabel),
                const CoinSummaryRow('Rate', '1 coin = ₦$kCoinRateNaira'),
                CoinSummaryRow(
                  "You're Buying",
                  '${pack.coins}',
                  emphasizeCoins: true,
                ),
              ],
              total: pack.priceLabel,
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxButton(
              label: 'Pay ${pack.priceLabel} · Get ${pack.coins} coins',
              expanded: true,
              onPressed: _confirmPurchase,
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxButton(
              label: 'Back',
              type: SkifluxButtonType.secondary,
              expanded: true,
              onPressed: () => setState(() => _phase = _BuyPhase.packs),
            ),
          ],
        ),
      ),
    );
  }

  // --- Phase 3: success --------------------------------------------------

  Future<void> _confirmPurchase() async {
    final pack = _selected!;
    ref.read(playlistsProvider.notifier).topUp(pack.coins);
    // Ledger entry for the wallet screen's transaction list.
    ref.read(walletProvider.notifier).recordTopUp(pack.coins, pack.priceNaira);
    if (!mounted) return;
    setState(() => _phase = _BuyPhase.success);
  }

  Widget _successView() {
    final coins = ref.watch(playlistsProvider).skillCoins;
    final pack = _selected!;
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
              onPressed: () => Navigator.of(context).pop(pack.coins),
            ),
          ],
        ),
      ),
    );
  }
}
