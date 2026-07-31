// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skillcoin_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SkillcoinTransaction _$SkillcoinTransactionFromJson(
  Map<String, dynamic> json,
) => _SkillcoinTransaction(
  amount: const DecimalConverter().fromJson(json['amount'] as String),
  transactionType: $enumDecode(
    _$SkillcoinTransactionTypeEnumMap,
    json['transaction_type'],
    unknownValue: SkillcoinTransactionType.unknown,
  ),
  transactionTypeLabel: json['transaction_type_label'] as String,
  description: json['description'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  status: $enumDecodeNullable(
    _$SkillcoinTransactionStatusEnumMap,
    json['status'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  id: json['id'] as String?,
  referenceId: json['reference_id'] as String?,
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$SkillcoinTransactionToJson(
  _SkillcoinTransaction instance,
) => <String, dynamic>{
  'amount': const DecimalConverter().toJson(instance.amount),
  'transaction_type':
      _$SkillcoinTransactionTypeEnumMap[instance.transactionType]!,
  'transaction_type_label': instance.transactionTypeLabel,
  'description': instance.description,
  'created_at': instance.createdAt.toIso8601String(),
  'status': _$SkillcoinTransactionStatusEnumMap[instance.status],
  'id': instance.id,
  'reference_id': instance.referenceId,
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$SkillcoinTransactionTypeEnumMap = {
  SkillcoinTransactionType.deposit: 'deposit',
  SkillcoinTransactionType.debitPurchase: 'debit_purchase',
  SkillcoinTransactionType.creatorRevenue: 'creator_revenue',
  SkillcoinTransactionType.creatorRevenueReversal: 'creator_revenue_reversal',
  SkillcoinTransactionType.cashbackReward: 'cashback_reward',
  SkillcoinTransactionType.refund: 'refund',
  SkillcoinTransactionType.adminAdjustment: 'admin_adjustment',
  SkillcoinTransactionType.topup: 'topup',
  SkillcoinTransactionType.withdrawal: 'withdrawal',
  SkillcoinTransactionType.withdrawalFee: 'withdrawal_fee',
  SkillcoinTransactionType.platformRevenue: 'platform_revenue',
  SkillcoinTransactionType.platformCashbackDebit: 'platform_cashback_debit',
  SkillcoinTransactionType.registrationBonus: 'registration_bonus',
  SkillcoinTransactionType.unknown: 'unknown',
};

const _$SkillcoinTransactionStatusEnumMap = {
  SkillcoinTransactionStatus.posted: 'posted',
  SkillcoinTransactionStatus.pending: 'pending',
  SkillcoinTransactionStatus.cancelled: 'cancelled',
  SkillcoinTransactionStatus.refunded: 'refunded',
  SkillcoinTransactionStatus.failed: 'failed',
};
