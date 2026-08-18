// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WithdrawalRequest _$WithdrawalRequestFromJson(
  Map<String, dynamic> json,
) => _WithdrawalRequest(
  id: json['id'] as String,
  amount: const DecimalConverter().fromJson(json['amount'] as String),
  netAmount: const DecimalConverter().fromJson(json['net_amount'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  account: WithdrawalAccount.fromJson(json['account'] as Map<String, dynamic>),
  fee: _$JsonConverterFromJson<String, Decimal>(
    json['fee'],
    const DecimalConverter().fromJson,
  ),
  status:
      $enumDecodeNullable(_$WithdrawalRequestStatusEnumMap, json['status']) ??
      WithdrawalRequestStatus.pending,
  gatewayName: json['gateway_name'] as String?,
  failureReason: json['failure_reason'] as String?,
  processedAt: json['processed_at'] == null
      ? null
      : DateTime.parse(json['processed_at'] as String),
);

Map<String, dynamic> _$WithdrawalRequestToJson(_WithdrawalRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': const DecimalConverter().toJson(instance.amount),
      'net_amount': const DecimalConverter().toJson(instance.netAmount),
      'created_at': instance.createdAt.toIso8601String(),
      'account': instance.account.toJson(),
      'fee': _$JsonConverterToJson<String, Decimal>(
        instance.fee,
        const DecimalConverter().toJson,
      ),
      'status': _$WithdrawalRequestStatusEnumMap[instance.status]!,
      'gateway_name': instance.gatewayName,
      'failure_reason': instance.failureReason,
      'processed_at': instance.processedAt?.toIso8601String(),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

const _$WithdrawalRequestStatusEnumMap = {
  WithdrawalRequestStatus.pending: 'pending',
  WithdrawalRequestStatus.processing: 'processing',
  WithdrawalRequestStatus.completed: 'completed',
  WithdrawalRequestStatus.failed: 'failed',
  WithdrawalRequestStatus.cancelled: 'cancelled',
  WithdrawalRequestStatus.rejected: 'rejected',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
