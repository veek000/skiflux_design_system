/// The last stop before real money moves: a confirmation sheet that states
/// what is about to be charged, by whom, and in what currency.
///
/// Every other money surface in this app is reversible up to this point — a
/// pack can be re-picked, a method re-chosen. Tapping the pay button is not:
/// hosted checkout hands the user to a gateway page, and the saved-card path
/// charges a stored token immediately with no page at all. So both go through
/// here first.
///
/// Built from the same pieces as the existing confirm sheet
/// (`shared/sheets/confirm_sheet.dart`) — headerless [SkifluxSheetShell], 72px
/// tinted avatar circle around a 36px glyph, centred bold title, then a
/// full-width primary action over a secondary Cancel — with the plain body
/// paragraph swapped for a [CoinSummaryCard] breakdown, which is the design
/// system's existing money-summary card (Flow 03 payment / Flow 02 success).
///
/// **No gateway fee row.** The reference design shows one, but the app has no
/// honest source for it: `GET /wallet/topup/methods` is untyped in the spec and
/// carries currencies and gateway names only, and the fee rules
/// (`GatewayFeeConfig`, `pass_gateway_fees_to_customer`) live behind
/// admin-only endpoints. Printing a computed or guessed fee next to a real
/// charge would be worse than omitting it, so the sheet states the amount it
/// actually knows and says where the final figure is confirmed. If
/// `topup/initiate` ever returns a fee breakdown, it belongs as extra
/// [CoinSummaryRow]s above the total.
library;

import 'package:flutter/material.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/sheets/skiflux_sheet.dart';
import '../../playlists/data/playlists_store.dart';
import '../data/models/saved_card.dart';
import 'coin_widgets.dart';

/// Matches `confirm_sheet.dart` so the two headerless cards read as one family.
const double _avatarSize = 72;
const double _glyphSize = 36;

/// Which of the two pay paths the user is about to take. They differ in what
/// happens next, so they say different things.
enum PaymentHandoffKind {
  /// `POST /wallet/topup/initiate` → the gateway's own page in a WebView.
  hostedCheckout,

  /// `POST /wallet/topup/charge-card` — the stored token is charged now.
  savedCard,
}

/// The confirmation both Buy Coins surfaces show before they charge anything.
///
/// Takes the same values the caller is about to put on the wire, so the sheet
/// can never describe a different payment from the one that follows: the pack's
/// own `priceLabel`, the selected [TopupMethod], the `gateway_name` being sent,
/// and the `currency`. Resolves `true` only on an explicit confirm.
Future<bool> confirmTopupPayment(
  BuildContext context, {
  required CoinPack pack,
  required TopupMethod method,
  required SavedCard? savedCard,
  required String gatewayName,
  required String currency,
}) {
  final isSaved = method == TopupMethod.savedCard;
  // charge-card sends no gateway of its own — the stored token belongs to the
  // gateway that vaulted it, which is the card's own `gateway_name`.
  final gateway = isSaved ? (savedCard?.gatewayName ?? '') : gatewayName;
  return showPaymentHandoffSheet(
    context,
    kind: isSaved
        ? PaymentHandoffKind.savedCard
        : PaymentHandoffKind.hostedCheckout,
    gatewayLabel: _titleCase(gateway),
    methodLabel: switch (method) {
      TopupMethod.card => 'Card',
      TopupMethod.bankTransfer => 'Bank transfer',
      TopupMethod.savedCard => _cardLabel(savedCard),
    },
    amountLabel: pack.priceLabel,
    coins: pack.coins,
    currency: currency.toUpperCase(),
  );
}

/// "paystack" → "Paystack"; already-cased names ("Stripe") are left alone.
/// Empty stays empty, which drops the Gateway row rather than printing a blank.
String _titleCase(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

/// The card as the vault describes it, falling back to the last four digits.
String _cardLabel(SavedCard? card) {
  if (card == null) return 'Saved card';
  if (card.maskedNumber.isNotEmpty) return card.maskedNumber;
  return card.last4.isEmpty ? 'Saved card' : '•••• ${card.last4}';
}

/// Shows the pre-payment confirmation and resolves to `true` only when the
/// user taps the confirm button.
///
/// Backdrop tap, drag-to-dismiss and Cancel all resolve `false`, so callers can
/// treat anything but `true` as "don't charge".
Future<bool> showPaymentHandoffSheet(
  BuildContext context, {
  required PaymentHandoffKind kind,
  required String gatewayLabel,
  required String methodLabel,
  required String amountLabel,
  required int coins,
  required String currency,
}) async {
  final confirmed = await showSkifluxSheet<bool>(
    context: context,
    builder: (_) => _PaymentHandoffSheet(
      kind: kind,
      gatewayLabel: gatewayLabel,
      methodLabel: methodLabel,
      amountLabel: amountLabel,
      coins: coins,
      currency: currency,
    ),
  );
  return confirmed ?? false;
}

class _PaymentHandoffSheet extends StatelessWidget {
  const _PaymentHandoffSheet({
    required this.kind,
    required this.gatewayLabel,
    required this.methodLabel,
    required this.amountLabel,
    required this.coins,
    required this.currency,
  });

  final PaymentHandoffKind kind;

  /// The gateway that will take the payment, title-cased for display —
  /// whatever `gateway_name` the caller is about to send. Empty when the caller
  /// genuinely doesn't know, which drops the row instead of printing a blank.
  final String gatewayLabel;

  /// How they're paying: "Card", "Bank transfer", or the masked card.
  final String methodLabel;

  /// Already-formatted fiat, e.g. "₦600" — the pack's own `priceLabel`, so the
  /// figure here is character-for-character the one on the pack tile.
  final String amountLabel;

  final int coins;

  /// ISO code sent as `currency`, e.g. "NGN".
  final String currency;

  bool get _isHosted => kind == PaymentHandoffKind.hostedCheckout;

  /// Names the gateway when we have one, and stays generic when we don't.
  String get _gatewayPhrase => gatewayLabel.isEmpty
      ? 'a secure payment page'
      : "$gatewayLabel's secure page";

  @override
  Widget build(BuildContext context) {
    return SkifluxSheetShell(
      title: '',
      showHeader: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SkifluxSpacing.spaceL,
          // Headerless card — clear the grabber pill (top 8px + 4px tall).
          SkifluxSpacing.space2xl,
          SkifluxSpacing.spaceL,
          SkifluxSpacing.spaceS,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: const BoxDecoration(
                  color: SkifluxColors.brand100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  // "You're leaving for a payment page" vs "this charges now".
                  _isHosted
                      ? RemixIcons.external_link_fill
                      : RemixIcons.secure_payment_fill,
                  size: _glyphSize,
                  color: SkifluxColors.contentBrand,
                ),
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceM),
            Text(
              _isHosted ? 'Continue to Payment' : 'Confirm Payment',
              textAlign: TextAlign.center,
              style: SkifluxTypography.headingH7Bold.copyWith(
                color: SkifluxColors.contentPrimary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              _isHosted
                  ? "You'll finish paying on $_gatewayPhrase, then come back "
                        'here to confirm.'
                  : 'Your saved card will be charged now. Coins are credited '
                        'once the payment is confirmed.',
              textAlign: TextAlign.center,
              style: SkifluxTypography.bodyP8Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            CoinSummaryCard(
              filled: true,
              rows: [
                if (gatewayLabel.isNotEmpty)
                  CoinSummaryRow('Gateway', gatewayLabel),
                CoinSummaryRow('Payment method', methodLabel),
                CoinSummaryRow('Currency', currency),
                CoinSummaryRow('Amount', amountLabel),
                CoinSummaryRow(
                  "You're buying",
                  CoinPack.thousands(coins),
                  emphasizeCoins: true,
                ),
              ],
              totalLabel: 'Total charge',
              total: amountLabel,
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            Text(
              _isHosted
                  ? 'The final amount is shown on the payment page before you '
                        'confirm.'
                  : 'No coins are credited until the payment is confirmed.',
              textAlign: TextAlign.center,
              style: SkifluxTypography.bodyP11Regular.copyWith(
                color: SkifluxColors.contentTertiary,
              ),
            ),
            const SizedBox(height: SkifluxSpacing.spaceL),
            SkifluxButton(
              label: _isHosted ? 'Continue' : 'Pay $amountLabel',
              expanded: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: SkifluxSpacing.spaceS),
            SkifluxButton(
              label: 'Cancel',
              type: SkifluxButtonType.secondary,
              expanded: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
