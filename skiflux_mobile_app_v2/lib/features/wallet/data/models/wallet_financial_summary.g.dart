// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_financial_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalletFinancialSummary _$WalletFinancialSummaryFromJson(
  Map<String, dynamic> json,
) => _WalletFinancialSummary(
  totalEarned: const DecimalConverter().fromJson(
    json['total_earned'] as String,
  ),
  totalSpent: const DecimalConverter().fromJson(json['total_spent'] as String),
  totalWithdrawn: const DecimalConverter().fromJson(
    json['total_withdrawn'] as String,
  ),
);

Map<String, dynamic> _$WalletFinancialSummaryToJson(
  _WalletFinancialSummary instance,
) => <String, dynamic>{
  'total_earned': const DecimalConverter().toJson(instance.totalEarned),
  'total_spent': const DecimalConverter().toJson(instance.totalSpent),
  'total_withdrawn': const DecimalConverter().toJson(instance.totalWithdrawn),
};
