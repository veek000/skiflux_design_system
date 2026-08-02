import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../config/env_config.dart';
import '../../../shared/error_handling/error_display.dart';
import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/sheets/skiflux_sheet.dart';
import '../../../shared/toast/skiflux_toast.dart';
import '../../../shared/webview/checkout_screen.dart';
import '../../../shared/widgets/loading_skeletons.dart';
import '../../playlists/data/playlists_store.dart';
import '../../settings/data/payment_store.dart';
import '../../wallet/buy_coins_screen.dart'
    show CoinPacksErrorState, TopupPendingBanner;
import '../../wallet/data/topup_repository.dart';
import '../../wallet/data/wallet_store.dart';
import '../../wallet/widgets/coin_widgets.dart';

// Figma: Other Video Player Flow 04 → 03 → 02
// (`1256:27567` packs → `1256:27688` payment → `1256:27814` success).
//
// Four-phase headerless sheet backed by the real top-up endpoints: pick a
// pack → confirm payment method → `POST /wallet/topup/initiate` + gateway
// checkout hand-off → `POST /wallet/topup/verify`. The success phase renders
// only after verify confirms; no coins are ever credited client-side.

// The payment method is the shared `TopupMethod` rather than a local enum, so
// this sheet and the full Buy Coins screen offer the same three spec paths.

enum _BuyPhase { packs, payment, pendingCheckout, success }

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
  TopupMethod _method = TopupMethod.card;
  bool _busy = false;
  TopupInitiation? _handOff;

  /// Backend-reported coins credited by verify, when it said.
  Decimal? _coinsCredited;

  /// The card a one-tap charge would use — the vault's default, or its first
  /// entry. Null when the vault is empty or still loading, which hides the
  /// saved-card row entirely.
  SavedCard? get _defaultCard {
    final cards = ref.watch(savedCardsProvider).value;
    if (cards == null || cards.isEmpty) return null;
    return cards.firstWhere((c) => c.isDefault, orElse: () => cards.first);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _BuyPhase.packs => _packsView(),
      _BuyPhase.payment => _paymentView(),
      _BuyPhase.pendingCheckout => _pendingView(),
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
            ref.watch(coinPacksProvider).when(
              // Four cards in the two-up grid the packs land in, so the
              // sheet's height and the Continue button below don't jump.
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
                          bottom: i + 2 < packs.length ? SkifluxSpacing.spaceL : 0,
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
            SkifluxButton(
              label: _selected == null ? 'Choose a coin pack' : 'Continue',
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
              selected: _method,
              savedCard: _defaultCard,
              onChanged: (m) => setState(() => _method = m),
            ),
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
            const SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxButton(
              label: _busy
                  ? 'Contacting payment provider…'
                  : 'Pay ${pack.priceLabel} · Get ${pack.coins} coins',
              expanded: true,
              onPressed: _busy ? null : _startCheckout,
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxButton(
              label: 'Back',
              type: SkifluxButtonType.secondary,
              expanded: true,
              onPressed: _busy
                  ? null
                  : () => setState(() => _phase = _BuyPhase.packs),
            ),
          ],
        ),
      ),
    );
  }

  /// `POST /wallet/topup/initiate`, then the gateway's hosted checkout inside
  /// the app — or, for a saved card, `POST /wallet/topup/charge-card`, which
  /// the spec describes as one-tap with no checkout redirect at all.
  Future<void> _startCheckout() async {
    final pack = _selected!;
    setState(() => _busy = true);
    try {
      if (_method == TopupMethod.savedCard) {
        await _chargeSavedCard(pack);
        return;
      }
      final handOff = await ref.read(topupRepositoryProvider).initiateTopup(
            amountFiat: pack.amountFiatWire,
            currency: 'NGN',
            paymentMethod: _method.wireValue,
            // The app's own return URL — see [EnvConfig.paymentReturnUrl].
            redirectUrl: EnvConfig.paymentReturnUrl,
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _handOff = handOff;
        _phase = _BuyPhase.pendingCheckout;
      });

      final outcome = await showCheckout(
        context,
        checkoutUrl: handOff.checkoutUrl,
        redirectUrlPrefix: EnvConfig.paymentReturnUrl,
        txRef: handOff.txRef,
        returnHost: EnvConfig.apiHost,
        title: 'Buy Skillcoins',
      );
      if (!mounted) return;
      // The gateway finished; whether it succeeded is `verify`'s to say. An
      // abandoned checkout falls through to the pending phase, which still
      // offers a manual "I've paid" check.
      if (outcome == CheckoutOutcome.completed) await _verify();
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      await ErrorDisplay.show(context, ref, e, stackTrace: st);
    }
  }

  /// One-tap charge against a stored token. Only a `successful` transaction
  /// credits coins; `pending`/`initiated` drops into the same verify path as
  /// hosted checkout, so the user is never asked to pay twice.
  Future<void> _chargeSavedCard(CoinPack pack) async {
    final card = _defaultCard;
    if (card == null) {
      throw const SkifluxFailure(SkifluxErrorKind.coinPurchaseFailed);
    }
    final result = await ref.read(topupRepositoryProvider).chargeCard(
          amountFiat: pack.amountFiatWire,
          savedCardId: card.id,
          currency: 'NGN',
        );
    if (!mounted) return;

    final status = result['status']?.toString().toLowerCase();
    final txRef = result['tx_ref']?.toString();

    if (status == 'successful') {
      await ref.read(walletProvider.notifier).refreshFromBackend();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _coinsCredited =
            Decimal.tryParse(result['amount_skillcoins']?.toString() ?? '') ??
                Decimal.fromInt(pack.coins);
        _phase = _BuyPhase.success;
      });
      return;
    }

    if ((status == 'pending' || status == 'initiated') &&
        txRef != null &&
        txRef.isNotEmpty) {
      setState(() {
        _busy = false;
        _handOff = TopupInitiation(checkoutUrl: Uri.parse(''), txRef: txRef);
        _phase = _BuyPhase.pendingCheckout;
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

  // --- Phase 3: waiting for the gateway ---------------------------------

  Widget _pendingView() {
    final handOff = _handOff!;
    return SkifluxSheetShell(
      title: 'Complete your payment',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceL,
          0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TopupPendingBanner(reference: handOff.txRef),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxButton(
              label: _busy ? 'Checking payment…' : "I've completed payment",
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
                  : () => setState(() {
                        _handOff = null;
                        _phase = _BuyPhase.payment;
                      }),
            ),
          ],
        ),
      ),
    );
  }

  /// `POST /wallet/topup/verify` — the only path into the success phase.
  Future<void> _verify() async {
    final handOff = _handOff;
    if (handOff == null) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(topupRepositoryProvider)
          .verifyTopup(txRef: handOff.txRef);
      if (!mounted) return;
      switch (result.status) {
        case TopupVerificationStatus.successful:
          // Real balance + ledger before the success view renders.
          await ref.read(walletProvider.notifier).refreshFromBackend();
          if (!mounted) return;
          setState(() {
            _busy = false;
            _coinsCredited = result.amountSkillcoins;
            _phase = _BuyPhase.success;
          });
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
            _phase = _BuyPhase.payment;
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

  // --- Phase 4: success (verify-confirmed only) -------------------------

  Widget _successView() {
    final coins = ref.watch(playlistsProvider).skillCoins;
    final pack = _selected!;
    final credited = _coinsCredited == null
        ? pack.coins
        : wholeCoinFloor(_coinsCredited!);
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
              onPressed: () => Navigator.of(context).pop(credited),
            ),
          ],
        ),
      ),
    );
  }
}
