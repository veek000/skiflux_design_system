/// Wallet top-up (buy SkillCoins) via hosted gateway checkout.
///
/// The real money flow per the OpenAPI spec: `initiate` returns a checkout
/// URL + transaction reference, the user pays in the browser, and `verify`
/// is the only thing allowed to declare the purchase successful. Nothing in
/// this repository ever credits coins client-side.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error_handling/error_handler.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/network/api_repository.dart';

/// `GET /wallet/topup/methods` — active currencies and the gateways that
/// support them ("drives the frontend's add-money screen with no
/// hardcoding"). Untyped (`additionalProperties: {}`) in the spec.
const kTopupMethodsPath = '/wallet/topup/methods';

/// `POST /wallet/topup/initiate` — body `TopupInitiateRequest` (only
/// `amount_fiat` is required); response is untyped in the spec but carries
/// the gateway checkout URL and our `tx_ref`.
const kTopupInitiatePath = '/wallet/topup/initiate';

/// `POST /wallet/topup/verify` — body `VerifyPaymentRequest` (`tx_ref`
/// required); untyped response carrying the verification status.
const kTopupVerifyPath = '/wallet/topup/verify';

/// `POST /wallet/topup/charge-card` — body `ChargeSavedCardRequest`
/// (`saved_card_id` + `amount_fiat` required); returns `PaymentTransaction`.
const kTopupChargeCardPath = '/wallet/topup/charge-card';

/// The currency and gateway every top-up in this app is sent with.
///
/// Named rather than inlined at each call site because the pre-payment
/// confirmation sheet quotes them back to the user: a sheet that says
/// "Paystack · NGN" over a request carrying something else would be a lie
/// about money, and two screens each with their own literal is how that
/// happens.
///
/// TODO(backend, tracker #36): payment-flows.md §1.1 says the real axis is
/// currency + gateway from [kTopupMethodsPath] and "the frontend must never
/// hardcode gateways". Until Buy Coins is reworked onto that payload, these
/// two are the app's single source of truth.
const kTopupCurrency = 'NGN';
const kTopupGateway = 'paystack';

/// Result of `POST /wallet/topup/initiate`.
///
/// The spec leaves the body untyped, so parsing is tolerant about key names
/// — but it never invents values: a body with no reference or no checkout
/// URL is a contract failure, not a success.
class TopupInitiation {
  const TopupInitiation({required this.txRef, required this.checkoutUrl});

  /// Our internal reference (`PaymentTransaction.tx_ref`) — what `verify`
  /// takes back.
  final String txRef;

  /// The gateway's hosted payment page.
  final Uri checkoutUrl;

  factory TopupInitiation.fromJson(Map<String, dynamic> json) {
    final txRef = _firstString(json, const [
      'tx_ref',
      'reference',
      'transaction_reference',
      'trx_ref',
    ]);
    final rawUrl = _firstString(json, const [
      'checkout_url',
      'authorization_url',
      'payment_url',
      'payment_link',
      'link',
      'url',
    ]);
    final url = rawUrl == null ? null : Uri.tryParse(rawUrl);
    if (txRef == null || url == null || !url.hasScheme) {
      throw const FormatException(
        'Top-up initiate response missing tx_ref/checkout URL',
      );
    }
    return TopupInitiation(txRef: txRef, checkoutUrl: url);
  }
}

/// Verification outcome. Anything not explicitly successful or failed is
/// [pending] — the honest default while the gateway settles.
enum TopupVerificationStatus { successful, pending, failed }

/// Result of `POST /wallet/topup/verify`.
class TopupVerification {
  const TopupVerification({required this.status, this.amountSkillcoins});

  final TopupVerificationStatus status;

  /// Coins credited, when the body carries `PaymentTransaction`-style fields.
  /// Null means "not reported", never zero.
  final Decimal? amountSkillcoins;

  factory TopupVerification.fromJson(Map<String, dynamic> json) {
    final raw =
        (_firstString(json, const ['status', 'payment_status']) ?? 'pending')
            .toLowerCase();
    final status = switch (raw) {
      'successful' || 'success' || 'completed' || 'verified' =>
        TopupVerificationStatus.successful,
      'failed' || 'cancelled' || 'canceled' || 'rejected' =>
        TopupVerificationStatus.failed,
      _ => TopupVerificationStatus.pending,
    };
    final coins = _firstString(json, const [
      'amount_skillcoins',
      'skillcoins',
    ]);
    return TopupVerification(
      status: status,
      amountSkillcoins: coins == null ? null : Decimal.tryParse(coins),
    );
  }
}

/// First non-empty string under any of [keys], searching the top level and
/// then one level of nested objects (gateways differ on nesting).
String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    if (value is num) return value.toString();
  }
  for (final value in json.values) {
    if (value is Map) {
      final nested = Map<String, dynamic>.from(value);
      for (final key in keys) {
        final inner = nested[key];
        if (inner is String && inner.isNotEmpty) return inner;
        if (inner is num) return inner.toString();
      }
    }
  }
  return null;
}

/// Repository for wallet top-up operations.
class TopupRepository extends ApiRepository {
  const TopupRepository(super.dio);

  @override
  SkifluxErrorKind get fallbackKind => SkifluxErrorKind.coinPurchaseFailed;

  /// Returns the server's available currencies and payment gateways.
  /// Response shape is untyped (additionalProperties: {}) in the OpenAPI spec,
  /// so we return the raw JSON and let callers parse as needed.
  Future<Map<String, dynamic>> getTopupMethods() => getObject(
        kTopupMethodsPath,
        parse: (json) => json,
        kind: SkifluxErrorKind.contentLoadFailed,
      );

  /// Initiates a wallet top-up and returns the hosted checkout hand-off.
  ///
  /// [amountFiat] must be a string decimal ("500.00") per the money
  /// convention. [paymentMethod] restricts the hosted checkout to `card`,
  /// `bank_transfer`, or `all` (the spec's `PaymentMethodEnum`).
  Future<TopupInitiation> initiateTopup({
    required String amountFiat,
    String? currency,
    String? gatewayName,
    String? paymentMethod,
    bool? saveCard,
    String? idempotencyKey,
    String? redirectUrl,

    /// Pack size the user selected. Sent so the backend credits that many
    /// SkillCoins rather than recomputing from fiat alone (which broke
    /// discounted pack prices). Optional on the OpenAPI schema but accepted.
    String? amountSkillcoins,
  }) =>
      post(
        kTopupInitiatePath,
        body: {
          'amount_fiat': amountFiat,
          'amount_skillcoins': ?amountSkillcoins,
          'skillcoins': ?amountSkillcoins,
          'currency': ?currency,
          'gateway_name': ?gatewayName,
          'payment_method': ?paymentMethod,
          'channel': ?paymentMethod,
          'save_card': ?saveCard,
          'idempotency_key': ?idempotencyKey,
          'redirect_url': ?redirectUrl,
        },
        parse: TopupInitiation.fromJson,
      ).then((v) => v!);

  /// Verifies a top-up after the user returns from the payment gateway.
  /// Only a [TopupVerificationStatus.successful] result may drive success UI.
  Future<TopupVerification> verifyTopup({required String txRef}) => post(
        kTopupVerifyPath,
        body: {'tx_ref': txRef},
        parse: TopupVerification.fromJson,
      ).then((v) => v!);

  /// One-tap charge of a previously saved card token. Returns the
  /// `PaymentTransaction` body raw; callers must check `status` — an
  /// `initiated`/`pending` transaction is not yet money.
  ///
  /// Field name per the spec's `ChargeSavedCardRequest`: `saved_card_id`.
  Future<Map<String, dynamic>> chargeCard({
    required String amountFiat,
    required String savedCardId,
    String? currency,
    String? idempotencyKey,
    String? amountSkillcoins,
  }) =>
      post(
        kTopupChargeCardPath,
        body: {
          'amount_fiat': amountFiat,
          'saved_card_id': savedCardId,
          'amount_skillcoins': ?amountSkillcoins,
          'skillcoins': ?amountSkillcoins,
          'currency': ?currency,
          'idempotency_key': ?idempotencyKey,
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
