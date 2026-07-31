// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserWallet _$UserWalletFromJson(Map<String, dynamic> json) => _UserWallet(
  id: json['id'] as String,
  balance: const _DecimalOrZeroConverter().fromJson(json['balance']),
  bonusBalance: const _DecimalOrZeroConverter().fromJson(json['bonus_balance']),
  withdrawableBalance: const DecimalFromNumConverter().fromJson(
    json['withdrawable_balance'] as num,
  ),
  isLocked: json['is_locked'] as bool? ?? false,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  isPlatformWallet: json['is_platform_wallet'] as bool? ?? false,
);

Map<String, dynamic> _$UserWalletToJson(_UserWallet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'balance': const _DecimalOrZeroConverter().toJson(instance.balance),
      'bonus_balance': const _DecimalOrZeroConverter().toJson(
        instance.bonusBalance,
      ),
      'withdrawable_balance': const DecimalFromNumConverter().toJson(
        instance.withdrawableBalance,
      ),
      'is_locked': instance.isLocked,
      'updated_at': instance.updatedAt.toIso8601String(),
      'is_platform_wallet': instance.isPlatformWallet,
    };
