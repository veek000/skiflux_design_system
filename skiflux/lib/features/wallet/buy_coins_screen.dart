import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../config/env_config.dart';
import '../../shared/error_handling/error_display.dart';
import '../../shared/error_handling/error_handler.dart';
import '../../shared/sheets/skiflux_sheet.dart';
import '../../shared/toast/skiflux_toast.dart';
import '../../shared/webview/checkout_screen.dart';
import '../../shared/widgets/loading_skeletons.dart';
import '../playlists/data/playlists_store.dart';
import '../settings/data/payment_store.dart';
import 'data/topup_repository.dart';
import 'data/wallet_store.dart';
import 'widgets/coin_widgets.dart';
import 'widgets/payment_handoff_sheet.dart';

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
  TopupMethod _method = TopupMethod.card;

  /// True while initiate or verify is in flight.
  bool _busy = false;

  /// Set after a successful initiate: we handed off to the gateway and are
  /// waiting for the user to finish paying there.
  TopupInitiation? _handOff;

  /// The card a one-tap charge would use — the vault's default, or its first
  /// entry when none is flagged. Null when the vault is empty or still
  /// loading, which hides the saved-card option rather than offering one that
  /// might not resolve.
  SavedCard? get _defaultCard {
    final cards = ref.watch(savedCardsProvider).value;
    if (cards == null || cards.isEmpty) return null;
    return cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
  }

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
                    // The same two-up grid the packs land in — see the sheet.
                    loading: () => const CardGridSkeleton(
                      count: 4,
                      aspectRatio: 1.1,
                      padding: EdgeInsets.zero,
                    ),
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
                    selected: _method,
                    savedCard: _defaultCard,
                    onChanged: (m) => setState(() => _method = m),
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

  /// Starts the real top-up. Nothing is credited here — only `verify` (or the
  /// charge response's own `successful` status) does that.
  ///
  /// Both branches confirm first ([confirmTopupPayment]): this is the point of
  /// no return in either direction, since hosted checkout hands the user to a
  /// gateway page and the saved-card branch charges a stored token outright.
  ///
  /// The spec gives two shapes:
  ///
  ///  * **Hosted checkout** (`POST /wallet/topup/initiate`) for a new card or a
  ///    bank transfer. `payment_method` narrows what the gateway's page offers
  ///    (`card` / `bank_transfer` from `PaymentMethodEnum`); the page opens in
  ///    an in-app WebView and `verify` confirms afterwards.
  ///  * **Saved card** (`POST /wallet/topup/charge-card`) — "one-tap top-up…
  ///    no checkout redirect needed". No WebView, no `verify` round trip
  ///    unless the returned transaction is still pending.
  Future<void> pay(CoinPack? pack) async {
    try {
      if (pack == null) {
        throw const SkifluxFailure(SkifluxErrorKind.coinPurchaseFailed);
      }
      final confirmed = await confirmTopupPayment(
        context,
        pack: pack,
        method: _method,
        savedCard: _defaultCard,
        gatewayName: kTopupGateway,
        currency: kTopupCurrency,
      );
      if (!mounted || !confirmed) return;
      if (_method == TopupMethod.savedCard) {
        await _chargeSavedCard(pack);
        return;
      }
      setState(() => _busy = true);
      final handOff = await ref.read(topupRepositoryProvider).initiateTopup(
            amountFiat: pack.amountFiatWire,
            amountSkillcoins: pack.coins.toString(),
            currency: kTopupCurrency,
            gatewayName: kTopupGateway,
            paymentMethod: _method.wireValue,
            // "`redirect_url` — where the gateway sends the user afterwards
            // (your app page)" — payment-flows.md §1.2. The page does not
            // exist; the WebView intercepts the navigation to it. Sending
            // nothing (the previous behaviour) left the gateway returning to
            // the backend's own `PAYMENT_REDIRECT_URL`, which is a web page on
            // a host the app has no reason to recognise.
            redirectUrl: EnvConfig.paymentReturnUrl,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _handOff = handOff;
      });

      final outcome = await showCheckout(
        context,
        checkoutUrl: handOff.checkoutUrl,
        redirectUrlPrefix: EnvConfig.paymentReturnUrl,
        // Belt and braces: the gateway appends `?…&tx_ref=…` to whichever
        // return URL it was actually given, so this still fires if the
        // backend substituted its own.
        txRef: handOff.txRef,
        returnHost: EnvConfig.apiHost,
        title: 'Buy Skillcoins',
      );
      if (!mounted) return;
      // Reaching the redirect means the gateway finished, not that it
      // succeeded — `verify` is still the only thing that credits coins. An
      // abandoned checkout leaves the pending banner so the user can verify
      // by hand if they did in fact pay.
      if (outcome == CheckoutOutcome.completed) await _verify();
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  /// One-tap charge against the stored token. The response is a
  /// `PaymentTransaction`, and its `status` decides everything: only
  /// `successful` credits coins, `pending`/`initiated` means the gateway is
  /// still working (so fall back to the same verify path as hosted checkout),
  /// and anything else is a failure.
  Future<void> _chargeSavedCard(CoinPack pack) async {
    final card = _defaultCard;
    if (card == null) {
      throw const SkifluxFailure(SkifluxErrorKind.coinPurchaseFailed);
    }
    setState(() => _busy = true);
    final result = await ref.read(topupRepositoryProvider).chargeCard(
          amountFiat: pack.amountFiatWire,
          amountSkillcoins: pack.coins.toString(),
          savedCardId: card.id,
          currency: kTopupCurrency,
        );
    if (!mounted) return;

    final status = result['status']?.toString().toLowerCase();
    final txRef = result['tx_ref']?.toString();

    if (status == 'successful') {
      setState(() => _busy = false);
      await ref.read(walletProvider.notifier).refreshFromBackend();
      if (!mounted) return;
      await showPurchaseSuccessSheet(
        context,
        pack: pack,
        coinsCredited: _coinsFrom(result) ?? Decimal.fromInt(pack.coins),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    if ((status == 'pending' || status == 'initiated') &&
        txRef != null &&
        txRef.isNotEmpty) {
      // Same waiting state as an abandoned hosted checkout: the reference is
      // real, so the user can confirm it rather than paying twice.
      setState(() {
        _busy = false;
        _handOff = TopupInitiation(
          checkoutUrl: Uri.parse(''),
          txRef: txRef,
        );
      });
      await _verify();
      return;
    }

    setState(() => _busy = false);
    await ErrorDisplay.show(
      context,
      ref,
      const SkifluxFailure(SkifluxErrorKind.coinPurchaseFailed),
    );
  }

  /// Coins actually credited, per the `PaymentTransaction.amount_skillcoins`
  /// decimal. Null when the field is missing or unparseable — the caller then
  /// falls back to the pack's own figure rather than showing nothing.
  Decimal? _coinsFrom(Map<String, dynamic> json) {
    final raw = json['amount_skillcoins'];
    if (raw == null) return null;
    return Decimal.tryParse(raw.toString());
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
