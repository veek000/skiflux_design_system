import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/data/decimal_converter.dart';

part 'skillcoin_transaction.freezed.dart';
part 'skillcoin_transaction.g.dart';

/// The spec's 13 documented ledger types. An enum *with* an [unknown]
/// fallback rather than a raw String: the values are authoritative now
/// (an OpenAPI enum, not doc prose), but a ledger is exactly the kind of
/// list a backend extends — a new type must degrade to [unknown], not crash
/// fromJson. [SkillcoinTransaction.transactionTypeLabel] carries the
/// display string, so the UI never has to render [unknown] itself.
enum SkillcoinTransactionType {
  @JsonValue('deposit')
  deposit,
  @JsonValue('debit_purchase')
  debitPurchase,
  @JsonValue('creator_revenue')
  creatorRevenue,
  @JsonValue('creator_revenue_reversal')
  creatorRevenueReversal,
  @JsonValue('cashback_reward')
  cashbackReward,
  @JsonValue('refund')
  refund,
  @JsonValue('admin_adjustment')
  adminAdjustment,
  @JsonValue('topup')
  topup,
  @JsonValue('withdrawal')
  withdrawal,
  @JsonValue('withdrawal_fee')
  withdrawalFee,
  @JsonValue('platform_revenue')
  platformRevenue,
  @JsonValue('platform_cashback_debit')
  platformCashbackDebit,
  @JsonValue('registration_bonus')
  registrationBonus,

  /// Forward-compat fallback for types the spec gains later; never sent.
  unknown,
}

enum SkillcoinTransactionStatus {
  @JsonValue('posted')
  posted,
  @JsonValue('pending')
  pending,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('refunded')
  refunded,
  @JsonValue('failed')
  failed,
}

/// One Skillcoin ledger entry, per the spec's SkillcoinTransaction schema.
@freezed
abstract class SkillcoinTransaction with _$SkillcoinTransaction {
  const factory SkillcoinTransaction({
    @DecimalConverter() required Decimal amount,
    @JsonKey(unknownEnumValue: SkillcoinTransactionType.unknown)
    required SkillcoinTransactionType transactionType,

    /// Backend-rendered display string ("Top-up via Payment Gateway") —
    /// required in responses per the spec; show it verbatim.
    required String transactionTypeLabel,
    required String description,
    required DateTime createdAt,

    /// Optional in the spec; unknown future values read as null.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    SkillcoinTransactionStatus? status,
    String? id,
    String? referenceId,
  }) = _SkillcoinTransaction;

  factory SkillcoinTransaction.fromJson(Map<String, dynamic> json) =>
      _$SkillcoinTransactionFromJson(json);
}
