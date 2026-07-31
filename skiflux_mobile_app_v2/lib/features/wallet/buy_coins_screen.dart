import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../shared/error_handling/error_display.dart';
import '../../shared/error_handling/error_handler.dart';
import '../../shared/sheets/skiflux_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/utils/external_link.dart';
import '../playlists/data/playlists_store.dart';
import 'data/topup_repository.dart';
import 'data/wallet_store.dart';
import 'widgets/coin_widgets.dart';

// Figma: **Profile Flow 10 / 01** (`1256:24781` / `1256:25179`) — the
// full-screen Buy Coins reached from the wallet hub.
//
// Real money flow: `POST /wallet/topup/initiate` → open the gateway
// checkout URL → the user pays in the browser → "I've completed payment"
// → `POST /wallet/topup/verify`. The success sheet appears only when
// verify confirms; a pending gateway shows an honest status, and a failure
// shows the coin-purchase modal. No coins are ever credited client-side.

class BuyCoinsScreen extends ConsumerStatefulWidget {
  const BuyCoinsScreen({super.key});

  @override
  ConsumerState<BuyCoinsScreen> createState() => BuyCoinsScreenState();
}

class BuyCoinsScreenState extends ConsumerState<BuyCoinsScreen> {
  CoinPack? _selected;
  bool _cardPayment = true;

  /// True while initiate or verify is in flight.
  bool _busy = false;

  /// Set after a successful initiate: we handed off to the gateway and are
  /// waiting for the user to finish paying there.
  TopupInitiation? _handOff;

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
                  ref.watch(coinPacksProvider).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => CoinPacksErrorState(
                      onRetry: () => ref.invalidate(coinPacksProvider),
                    ),
                    data: (packs) {
                      if (packs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(SkifluxSpacing.spaceL),
                            child: Text('No coin packs available right now.'),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (var i = 0; i < packs.length; i += 2)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i + 2 < packs.length
                                    ? SkifluxSpacing.spaceL
                                    : 0,
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _packCard(packs[i])),
                                    const SizedBox(width: SkifluxSpacing.spaceL),
                                    if (i + 1 < packs.length)
                                      Expanded(child: _packCard(packs[i + 1]))
                                    else
                                      const Expanded(child: SizedBox.shrink()),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
                        CoinSummaryRow('Rate', pack.approxRateLabel),
                        CoinSummaryRow(
                          "You're Buying",
                          '${pack.coins}',
                          emphasizeCoins: true,
                        ),
                      ],
                      total: pack.priceLabel,
                    ),
                  ],
                  if (_handOff != null) ...[
                    const SizedBox(height: SkifluxSpacing.spaceL),
                    TopupPendingBanner(reference: _handOff!.txRef),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
              child: _handOff == null
                  ? SkifluxButton(
                      label: _busy
                          ? 'Contacting payment provider…'
                          : pack == null
                              ? 'Choose a coin pack'
                              : 'Pay ${pack.priceLabel} · Get ${pack.coins} coins',
                      expanded: true,
                      onPressed:
                          pack == null || _busy ? null : () => pay(pack),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SkifluxButton(
                          label: _busy
                              ? 'Checking payment…'
                              : "I've completed payment",
                          expanded: true,
                          onPressed: _busy ? null : _verify,
                        ),
                        const SizedBox(height: SkifluxSpacing.spaceS),
                        SkifluxButton(
                          label: 'Cancel',
                          type: SkifluxButtonType.secondary,
                          expanded: true,
                          onPressed: _busy
                              ? null
                              : () => setState(() => _handOff = null),
                        ),
                      ],
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
      onTap: _handOff != null
          ? () {}
          : () => setState(() => _selected = pack),
    );
  }

  /// Starts the real top-up: initiate on the backend, then hand off to the
  /// gateway's checkout page. Nothing is credited here.
  Future<void> pay(CoinPack? pack) async {
    try {
      if (pack == null) {
        throw const SkifluxFailure(SkifluxErrorKind.coinPurchaseFailed);
      }
      setState(() => _busy = true);
      final handOff = await ref.read(topupRepositoryProvider).initiateTopup(
            amountFiat: pack.amountFiatWire,
            currency: 'NGN',
            paymentMethod: _cardPayment ? 'card' : 'bank_transfer',
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _handOff = handOff;
      });
      await openExternalUrl(context, handOff.checkoutUrl);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  /// Confirms with the backend. Success UI only on a verified payment.
  Future<void> _verify() async {
    final handOff = _handOff;
    final pack = _selected;
    if (handOff == null || pack == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(topupRepositoryProvider)
          .verifyTopup(txRef: handOff.txRef);
      if (!mounted) return;
      switch (result.status) {
        case TopupVerificationStatus.successful:
          setState(() {
            _busy = false;
            _handOff = null;
          });
          // Pull the real balance + ledger; the success sheet's "New
          // balance" watches the synced provider.
          await ref.read(walletProvider.notifier).refreshFromBackend();
          if (!mounted) return;
          await showPurchaseSuccessSheet(
            context,
            pack: pack,
            coinsCredited: result.amountSkillcoins,
          );
          if (!mounted) return;
          Navigator.of(context).pop();
        case TopupVerificationStatus.pending:
          setState(() => _busy = false);
          SkifluxToast.info(
            context,
            'Payment not confirmed yet. Finish paying in your browser, '
            'then try again.',
          );
        case TopupVerificationStatus.failed:
          setState(() {
            _busy = false;
            _handOff = null;
          });
          await ErrorDisplay.show(
            context,
            ref,
            const SkifluxFailure(SkifluxErrorKind.coinPurchaseFailed),
          );
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }
}

/// Packs failed to load — named error state with retry; never shows raw
/// exception text.
class CoinPacksErrorState extends StatelessWidget {
  const CoinPacksErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNegativeSubtle,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Column(
        children: [
          Text(
            "We couldn't load coin packs. Please try again.",
            textAlign: TextAlign.center,
            style: SkifluxTypography.bodyP10Regular.copyWith(
              color: SkifluxColors.contentSecondary,
            ),
          ),
          const SizedBox(height: SkifluxSpacing.spaceS),
          SkifluxButton(
            label: 'Retry',
            size: SkifluxButtonSize.s,
            type: SkifluxButtonType.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// "Finish paying in your browser" banner shown while a top-up hand-off is
/// outstanding, with the gateway reference for support.
class TopupPendingBanner extends StatelessWidget {
  const TopupPendingBanner({super.key, required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SkifluxSpacing.spaceL),
      decoration: BoxDecoration(
        color: SkifluxColors.backgroundNoticeSubtle,
        borderRadius: SkifluxRadii.borderL,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            RemixIcons.time_fill,
            size: SkifluxUnit.u20,
            color: SkifluxColors.contentNoticeBold,
          ),
          const SizedBox(width: SkifluxSpacing.spaceS),
          Expanded(
            child: Text(
              'Complete your payment on the secure checkout page, then tap '
              '"I\'ve completed payment". Reference: $reference',
              style: SkifluxTypography.bodyP10Regular.copyWith(
                color: SkifluxColors.contentSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Purchase Successful" sheet (`1256:25294`): headerless card — green check
/// circle, title, body, amount/coins/new-balance summary, Done. Shown only
/// after `topup/verify` confirmed; [coinsCredited] is the backend-reported
/// figure when the verify body carried one.
Future<void> showPurchaseSuccessSheet(
  BuildContext context, {
  required CoinPack pack,
  Decimal? coinsCredited,
}) {
  return showSkifluxSheet<void>(
    context: context,
    builder: (_) =>
        _PurchaseSuccessSheet(pack: pack, coinsCredited: coinsCredited),
  );
}

class _PurchaseSuccessSheet extends ConsumerWidget {
  const _PurchaseSuccessSheet({required this.pack, this.coinsCredited});

  final CoinPack pack;

  /// Backend-reported coins credited; null when verify didn't include it,
  /// in which case the pack's advertised figure is shown.
  final Decimal? coinsCredited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(playlistsProvider).skillCoins;
    final credited = coinsCredited == null
        ? pack.coins
        : wholeCoinFloor(coinsCredited!);
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
              'Your wallet has been topped up with $credited SkillCoins. '
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
                CoinSummaryRow('Coins Purchased', '+$credited'),
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
