import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_card.freezed.dart';
part 'saved_card.g.dart';

/// One entry of `GET /wallet/cards` (payment-flows.md §2.1). Display metadata
/// only — by design no endpoint ever accepts or returns a full card number.
///
/// Required fields match the spec's SavedCard schema exactly (created_at /
/// gateway_name / id / last4 / masked_number); the rest default to empty so
/// a gateway that omits them (documented for Stripe) can't crash fromJson.
@freezed
abstract class SavedCard with _$SavedCard {
  const factory SavedCard({
    required String id,
    required String gatewayName,

    /// Pre-masked by the backend, e.g. `**** **** **** 4081`.
    required String maskedNumber,
    required String last4,
    required DateTime createdAt,

    // Empty string (not absent) in the documented Stripe example; optional
    // per the spec either way.
    @Default('') String cardBrand,
    @Default('') String expMonth,
    @Default('') String expYear,
    @Default(false) bool isDefault,
    @Default('') String bankName,
    @Default('') String cardType,
  }) = _SavedCard;

  factory SavedCard.fromJson(Map<String, dynamic> json) =>
      _$SavedCardFromJson(json);
}
