// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WithdrawalMethod _$WithdrawalMethodFromJson(Map<String, dynamic> json) =>
    _WithdrawalMethod(
      method: json['method'] as String,
      gateway: json['gateway'] as String,
      flow: json['flow'] as String,
      label: json['label'] as String,
    );

Map<String, dynamic> _$WithdrawalMethodToJson(_WithdrawalMethod instance) =>
    <String, dynamic>{
      'method': instance.method,
      'gateway': instance.gateway,
      'flow': instance.flow,
      'label': instance.label,
    };
