import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/data/decimal_converter.dart';

part 'wallet_financial_summary.freezed.dart';
part 'wallet_financial_summary.g.dart';

/// `GET /wallet/summary` — OpenAPI `WalletFinancialSummary`.
@freezed
abstract class WalletFinancialSummary with _$WalletFinancialSummary {
  const factory WalletFinancialSummary({
    @DecimalConverter() required Decimal totalEarned,
    @DecimalConverter() required Decimal totalSpent,
    @DecimalConverter() required Decimal totalWithdrawn,
  }) = _WalletFinancialSummary;

  factory WalletFinancialSummary.fromJson(Map<String, dynamic> json) =>
      _$WalletFinancialSummaryFromJson(json);
}
