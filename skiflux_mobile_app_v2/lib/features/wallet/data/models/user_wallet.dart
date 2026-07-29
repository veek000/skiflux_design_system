import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/data/decimal_converter.dart';

part 'user_wallet.freezed.dart';
part 'user_wallet.g.dart';

/// `GET /wallet/my-wallet` — field set per the OpenAPI spec's UserWallet
/// schema (which supersedes withdrawal-flows.md where they disagree).
@freezed
abstract class UserWallet with _$UserWallet {
  const factory UserWallet({
    required String id,
    @DecimalConverter() required Decimal balance,

    /// Non-withdrawable registration bonus.
    @DecimalConverter() required Decimal bonusBalance,

    /// Returned by the API already hold-aware (balance − bonus_balance −
    /// active_holds) — trusted as sent, never recomputed client-side.
    /// Spec quirk: this one arrives as a JSON *number* (`format: double`),
    /// not a decimal string like the other money fields.
    @DecimalFromNumConverter() required Decimal withdrawableBalance,

    /// Locked wallets have an effective withdrawable balance of zero.
    required bool isLocked,
    required DateTime updatedAt,
    @Default(false) bool isPlatformWallet,
  }) = _UserWallet;

  factory UserWallet.fromJson(Map<String, dynamic> json) =>
      _$UserWalletFromJson(json);
}
