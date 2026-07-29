import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_card.freezed.dart';
part 'saved_card.g.dart';

/// One entry of `GET /wallet/cards` (payment-flows.md §2.1). Display metadata
/// only — by design no endpoint ever accepts or returns a full card number.
@freezed
abstract class SavedCard with _$SavedCard {
  const factory SavedCard({
    required String id,
    required String gatewayName,
    required String cardBrand,

    /// Pre-masked by the backend, e.g. `**** **** **** 4081`.
    required String maskedNumber,
    required String last4,
    required String expMonth,
    required String expYear,
    required bool isDefault,
    required DateTime createdAt,

    // Empty string (not absent) in the documented Stripe example.
    @Default('') String bankName,
    @Default('') String cardType,
  }) = _SavedCard;

  factory SavedCard.fromJson(Map<String, dynamic> json) =>
      _$SavedCardFromJson(json);
}
