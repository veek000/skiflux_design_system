import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

// Saved payment cards for the Payment Methods frame (`1256:19943`) — the
// debit/credit cards used to buy SkillCoins. No real card vault yet; this is a
// session-local Riverpod store seeded with the two cards shown in the frame.
// TODO(backend, blocking): replace with tokenized cards from the payment processor (never store PANs) — expects: {cards: List<{brand: String, last4: String, expiry: String}>}

/// Card network — picks the row's tint + glyph.
enum CardBrand {
  visa('Visa'),
  mastercard('Mastercard'),
  verve('Verve');

  const CardBrand(this.label);

  final String label;
}

@immutable
class SavedCard {
  const SavedCard({
    required this.brand,
    required this.last4,
    required this.expiry,
  });

  final CardBrand brand;
  final String last4;

  /// "MM/YY".
  final String expiry;

  /// "Mastercard ending in 8810".
  String get title => '${brand.label} ending in $last4';

  /// "Expires 09/27".
  String get subtitle => 'Expires $expiry';

  Color get tint => switch (brand) {
        CardBrand.visa => SkifluxColors.backgroundInfoSubtle,
        CardBrand.mastercard => SkifluxColors.backgroundNoticeSubtle,
        CardBrand.verve => SkifluxColors.backgroundPositiveSubtle,
      };

  Color get glyph => switch (brand) {
        CardBrand.visa => SkifluxColors.contentInfoBold,
        CardBrand.mastercard => SkifluxColors.contentNoticeBold,
        CardBrand.verve => SkifluxColors.contentPositiveBold,
      };
}

final paymentCardsProvider =
    NotifierProvider<PaymentCardsNotifier, List<SavedCard>>(
  PaymentCardsNotifier.new,
);

class PaymentCardsNotifier extends Notifier<List<SavedCard>> {
  @override
  List<SavedCard> build() {
    return const [
      SavedCard(brand: CardBrand.mastercard, last4: '8810', expiry: '09/27'),
      SavedCard(brand: CardBrand.visa, last4: '4242', expiry: '03/26'),
    ];
  }

  void addCard(SavedCard card) => state = [...state, card];

  void removeCard(SavedCard card) =>
      state = state.where((c) => c != card).toList();
}
