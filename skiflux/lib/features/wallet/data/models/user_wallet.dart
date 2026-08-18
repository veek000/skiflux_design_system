import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/data/decimal_converter.dart';

part 'user_wallet.freezed.dart';
part 'user_wallet.g.dart';

/// The spec's UserWallet schema marks only `id`, `updated_at`, and
/// `withdrawable_balance` as required — `balance` / `bonus_balance` /
/// `is_locked` may be omitted. This converter's JSON side is `Object?` so the
/// generated fromJson passes the raw value through with no hard cast: absent
/// keys read as zero instead of crashing with a TypeError.
class _DecimalOrZeroConverter implements JsonConverter<Decimal, Object?> {
  const _DecimalOrZeroConverter();

  @override
  Decimal fromJson(Object? json) {
    if (json == null) return Decimal.zero;
    // String is the documented wire format; a num is tolerated the same way
    // DecimalFromNumConverter adopts the encoder's shortest-decimal form.
    return Decimal.parse(json.toString());
  }

  @override
  Object? toJson(Decimal object) =>
      object.scale <= 2 ? object.toStringAsFixed(2) : object.toString();
}

/// `GET /wallet/my-wallet` — field set per the OpenAPI spec's UserWallet
/// schema (which supersedes withdrawal-flows.md where they disagree).
///
/// Required JSON fields match the spec exactly (id / updated_at /
/// withdrawable_balance); everything else parses with a safe default so a
/// minimal-but-valid payload cannot throw.
@freezed
abstract class UserWallet with _$UserWallet {
  const factory UserWallet({
    required String id,

    /// Optional in the spec — absent reads as zero via the converter.
    @_DecimalOrZeroConverter() required Decimal balance,

    /// Non-withdrawable registration bonus. Optional in the spec — absent
    /// reads as zero via the converter.
    @_DecimalOrZeroConverter() required Decimal bonusBalance,

    /// Returned by the API already hold-aware (balance − bonus_balance −
    /// active_holds) — trusted as sent, never recomputed client-side.
    /// Spec quirk: this one arrives as a JSON *number* (`format: double`),
    /// not a decimal string like the other money fields.
    @DecimalFromNumConverter() required Decimal withdrawableBalance,

    /// Locked wallets have an effective withdrawable balance of zero.
    /// Optional in the spec — absent reads as unlocked.
    @Default(false) bool isLocked,
    required DateTime updatedAt,
    @Default(false) bool isPlatformWallet,
  }) = _UserWallet;

  factory UserWallet.fromJson(Map<String, dynamic> json) =>
      _$UserWalletFromJson(json);
}
