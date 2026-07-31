/// Saved cards via the spec's hosted save-card flow.
///
/// The client never sees a PAN or CVV: `POST /wallet/cards/add` returns a
/// gateway checkout URL where the card is entered (Paystack charges a small
/// refunded verification amount; Stripe uses a no-charge setup session), and
/// only the token + masked details ever come back through `GET /wallet/cards`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';
import 'models/saved_card.dart';

/// `GET /wallet/cards` — list of masked [SavedCard]s.
const kCardsListPath = '/wallet/cards';

/// `POST /wallet/cards/add` — body `AddCardRequest` (`gateway_name`
/// required, `redirect_url` optional); untyped response carrying the hosted
/// checkout URL.
const kCardsAddPath = '/wallet/cards/add';

/// `DELETE /wallet/cards/{id}` — remove a saved card.
String cardPath(String id) => '/wallet/cards/$id';

/// `POST /wallet/cards/{id}/set-default` — mark a card default.
String cardSetDefaultPath(String id) => '/wallet/cards/$id/set-default';

class CardsRepository extends ApiRepository {
  const CardsRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind =>
      SkifluxErrorKind.paymentMethodActionFailed;

  Future<List<SavedCard>> getMyCards() => getList(
    kCardsListPath,
    parse: SavedCard.fromJson,
    kind: SkifluxErrorKind.contentLoadFailed,
  );

  /// Starts the hosted save-card flow and returns the checkout URL to open.
  /// The response is untyped in the spec; a body without a usable URL is a
  /// contract failure, never silently "successful".
  Future<Uri> startAddCard({
    required String gatewayName,
    String? redirectUrl,
  }) => post(
    kCardsAddPath,
    body: {
      'gateway_name': gatewayName,
      'redirect_url': ?redirectUrl,
    },
    parse: (json) {
      for (final key in const [
        'checkout_url',
        'authorization_url',
        'setup_url',
        'payment_url',
        'link',
        'url',
      ]) {
        final value = json[key];
        if (value is String && value.isNotEmpty) {
          final uri = Uri.tryParse(value);
          if (uri != null && uri.hasScheme) return uri;
        }
      }
      throw const FormatException('Add-card response carried no checkout URL');
    },
  ).then((v) => v!);

  Future<void> deleteCard(String id) => delete(cardPath(id));

  Future<SavedCard> setDefaultCard(String id) => post(
    cardSetDefaultPath(id),
    parse: SavedCard.fromJson,
  ).then((v) => v!);
}

final cardsRepositoryProvider = Provider<CardsRepository>(
  (ref) => CardsRepository(ref.watch(apiClientProvider)),
);
