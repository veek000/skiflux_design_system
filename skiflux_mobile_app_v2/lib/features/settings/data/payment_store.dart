/// Saved payment cards for the Payment Methods frame (`1256:19943`), backed
/// by the wallet card vault (`GET /wallet/cards`).
///
/// The demo in-memory card list is gone: cards exist only as the backend's
/// masked [SavedCard] records (gateway token + brand + last4 — never a PAN).
/// Signed out there is nothing to fetch, so the list resolves empty; a failed
/// request stays an `AsyncError` so the screen offers a retry instead of
/// quietly showing sample cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skiflux_design_system/skiflux_design_system.dart';

import '../../../shared/network/token_store.dart';
import '../../wallet/data/cards_repository.dart';
import '../../wallet/data/models/saved_card.dart';

export '../../wallet/data/models/saved_card.dart' show SavedCard;

/// Display adapters for the freezed [SavedCard] — row title, subtitle, and
/// scheme logo, derived only from backend-provided masked metadata.
extension SavedCardDisplay on SavedCard {
  /// "Mastercard ending in 8810" (brand falls back to the card type or a
  /// generic label when the gateway omitted it).
  String get title => '$brandLabel ending in $last4';

  /// "Expires 09/27" — dropped by callers when the gateway omitted expiry.
  String? get subtitle {
    if (expMonth.isEmpty || expYear.isEmpty) return null;
    final year = expYear.length == 4 ? expYear.substring(2) : expYear;
    return 'Expires ${expMonth.padLeft(2, '0')}/$year';
  }

  String get brandLabel {
    if (cardBrand.trim().isNotEmpty) {
      final b = cardBrand.trim();
      return b[0].toUpperCase() + b.substring(1);
    }
    return cardType.trim().isNotEmpty ? cardType.trim() : 'Card';
  }

  /// Figma `1256:20596` puts the scheme's own logo in the badge — Mastercard
  /// uses the filled mark, Visa the line mark, anything else the generic
  /// card glyph.
  IconData get logo {
    final b = cardBrand.toLowerCase();
    if (b.contains('visa')) return RemixIcons.visa_line;
    if (b.contains('master')) return RemixIcons.mastercard_fill;
    return RemixIcons.bank_card_fill;
  }
}

/// `GET /wallet/cards`.
final savedCardsProvider =
    AsyncNotifierProvider<SavedCardsNotifier, List<SavedCard>>(
      SavedCardsNotifier.new,
    );

class SavedCardsNotifier extends AsyncNotifier<List<SavedCard>> {
  @override
  Future<List<SavedCard>> build() => _load();

  Future<List<SavedCard>> _load() async {
    if (!await ref.read(tokenStoreProvider).hasSession()) return const [];
    return ref.read(cardsRepositoryProvider).getMyCards();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// `DELETE /wallet/cards/{id}` — optimistic removal with rollback, so a
  /// failed delete never leaves the list lying about what the vault holds.
  Future<void> remove(SavedCard card) async {
    final before = state.value ?? const <SavedCard>[];
    state = AsyncData(before.where((c) => c.id != card.id).toList());
    try {
      await ref.read(cardsRepositoryProvider).deleteCard(card.id);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}
