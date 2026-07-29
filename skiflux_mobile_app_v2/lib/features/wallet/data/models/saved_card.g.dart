// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedCard _$SavedCardFromJson(Map<String, dynamic> json) => _SavedCard(
  id: json['id'] as String,
  gatewayName: json['gateway_name'] as String,
  cardBrand: json['card_brand'] as String,
  maskedNumber: json['masked_number'] as String,
  last4: json['last4'] as String,
  expMonth: json['exp_month'] as String,
  expYear: json['exp_year'] as String,
  isDefault: json['is_default'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  bankName: json['bank_name'] as String? ?? '',
  cardType: json['card_type'] as String? ?? '',
);

Map<String, dynamic> _$SavedCardToJson(_SavedCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gateway_name': instance.gatewayName,
      'card_brand': instance.cardBrand,
      'masked_number': instance.maskedNumber,
      'last4': instance.last4,
      'exp_month': instance.expMonth,
      'exp_year': instance.expYear,
      'is_default': instance.isDefault,
      'created_at': instance.createdAt.toIso8601String(),
      'bank_name': instance.bankName,
      'card_type': instance.cardType,
    };
