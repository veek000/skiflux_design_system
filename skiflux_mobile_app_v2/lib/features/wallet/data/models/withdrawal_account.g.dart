// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WithdrawalAccount _$WithdrawalAccountFromJson(Map<String, dynamic> json) =>
    _WithdrawalAccount(
      id: json['id'] as String,
      destinationType: $enumDecode(
        _$WithdrawalDestinationTypeEnumMap,
        json['destination_type'],
      ),
      displayName: json['display_name'] as String,
      status: $enumDecode(_$WithdrawalAccountStatusEnumMap, json['status']),
      isDefault: json['is_default'] as bool,
      bankCode: json['bank_code'] as String? ?? '',
      bankName: json['bank_name'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      gatewayName: json['gateway_name'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$WithdrawalAccountToJson(_WithdrawalAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'destination_type':
          _$WithdrawalDestinationTypeEnumMap[instance.destinationType]!,
      'display_name': instance.displayName,
      'status': _$WithdrawalAccountStatusEnumMap[instance.status]!,
      'is_default': instance.isDefault,
      'bank_code': instance.bankCode,
      'bank_name': instance.bankName,
      'account_number': instance.accountNumber,
      'account_name': instance.accountName,
      'gateway_name': instance.gatewayName,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$WithdrawalDestinationTypeEnumMap = {
  WithdrawalDestinationType.bank: 'bank',
  WithdrawalDestinationType.stripeConnect: 'stripe_connect',
};

const _$WithdrawalAccountStatusEnumMap = {
  WithdrawalAccountStatus.pending: 'pending',
  WithdrawalAccountStatus.verified: 'verified',
  WithdrawalAccountStatus.rejected: 'rejected',
};
