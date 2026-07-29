import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/data/decimal_converter.dart';
import 'withdrawal_account.dart';

part 'withdrawal_request.freezed.dart';
part 'withdrawal_request.g.dart';

/// Status set per the OpenAPI spec's WithdrawalRequestStatusEnum — a superset
/// of the lifecycle narrated in withdrawal-flows.md §7, which omits
/// `cancelled`. A plain enum, not a freezed union: no status carries a
/// payload, and this matches the app's existing enum style.
enum WithdrawalRequestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('rejected')
  rejected,
}

/// `POST /wallet/withdrawals/request` response / one entry of
/// `GET /wallet/withdrawals/requests`. Amounts are Skillcoins; the hold is
/// placed the moment the request is created, so `withdrawable_balance` drops
/// immediately, not when an admin processes it.
///
/// The spec marks only account/amount/created_at/id/net_amount as required,
/// so `fee` tolerates absence and `status` falls back to pending (a request
/// the backend hasn't stamped yet is by definition pending).
@freezed
abstract class WithdrawalRequest with _$WithdrawalRequest {
  const factory WithdrawalRequest({
    required String id,
    @DecimalConverter() required Decimal amount,

    /// amount − fee; what the gateway transfer actually pays out.
    @DecimalConverter() required Decimal netAmount,
    required DateTime createdAt,
    required WithdrawalAccount account,

    /// amount × withdrawal_fee_percentage / 100, computed by the backend.
    @DecimalConverter() Decimal? fee,
    @Default(WithdrawalRequestStatus.pending) WithdrawalRequestStatus status,

    /// Set once an admin processes; null while pending.
    String? gatewayName,
    String? failureReason,
    DateTime? processedAt,
  }) = _WithdrawalRequest;

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalRequestFromJson(json);
}
