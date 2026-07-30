library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

/// Repository for wallet top-up operations.
///
/// Endpoints:
/// - `GET  /wallet/topup/methods`     — available currencies & gateways
/// - `POST /wallet/topup/initiate`    — start a top-up
/// - `POST /wallet/topup/verify`      — confirm after payment
/// - `POST /wallet/topup/charge-card` — one-tap charge a saved card
class TopupRepository extends ApiRepository {
  const TopupRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.coinPurchaseFailed;

  /// Returns the server's available currencies and payment gateways.
  /// Response shape is untyped (additionalProperties: {}) in the OpenAPI spec,
  /// so we return the raw JSON and let callers parse as needed.
  Future<Map<String, dynamic>> getTopupMethods() => getObject(
        '/wallet/topup/methods',
        parse: (json) => json,
      );

  /// Initiates a wallet top-up. Returns a checkout URL or transaction
  /// reference from the payment gateway.
  Future<Map<String, dynamic>> initiateTopup({
    required String amountFiat,
    required String currency,
    required String gatewayName,
    String? idempotencyKey,
    String? redirectUrl,
  }) =>
      post(
        '/wallet/topup/initiate',
        body: {
          'amount_fiat': amountFiat,
          'currency': currency,
          'gateway_name': gatewayName,
          // ignore: use_null_aware_elements
          if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
          // ignore: use_null_aware_elements
          if (redirectUrl != null) 'redirect_url': redirectUrl,
        },
        parse: (json) => json,
      ).then((v) => v ?? {});

  /// Verifies a completed top-up after user returns from the payment gateway.
  Future<Map<String, dynamic>> verifyTopup({
    required String txRef,
  }) =>
      post(
        '/wallet/topup/verify',
        body: {'tx_ref': txRef},
        parse: (json) => json,
      ).then((v) => v ?? {});

  /// One-tap charge a previously saved card token.
  Future<Map<String, dynamic>> chargeCard({
    required String amountFiat,
    required String currency,
    required String cardId,
  }) =>
      post(
        '/wallet/topup/charge-card',
        body: {
          'amount_fiat': amountFiat,
          'currency': currency,
          'card_id': cardId,
        },
        parse: (json) => json,
      ).then((v) => v ?? {});
}

final topupRepositoryProvider = Provider<TopupRepository>(
  (ref) => TopupRepository(ref.watch(apiClientProvider)),
);

/// Cached top-up methods from the backend.
final topupMethodsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(topupRepositoryProvider).getTopupMethods();
});
