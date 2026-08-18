import 'package:freezed_annotation/freezed_annotation.dart';

part 'withdrawal_account.freezed.dart';
part 'withdrawal_account.g.dart';

enum WithdrawalAccountStatus { pending, verified, rejected }

enum WithdrawalDestinationType {
  @JsonValue('bank')
  bank,
  @JsonValue('stripe_connect')
  stripeConnect,
}

/// A payout destination — Paystack bank account or Stripe Connect account
/// (`GET /wallet/withdrawals/accounts/list`). The copy nested inside a
/// [WithdrawalRequest] response carries only id / destination_type /
/// display_name / status / is_default, so every other field must tolerate
/// being absent.
@freezed
abstract class WithdrawalAccount with _$WithdrawalAccount {
  const factory WithdrawalAccount({
    required String id,
    required WithdrawalDestinationType destinationType,
    required String displayName,
    required WithdrawalAccountStatus status,
    required bool isDefault,

    // Empty on Stripe Connect rows and absent on the nested copy.
    @Default('') String bankCode,
    @Default('') String bankName,
    @Default('') String accountNumber,
    @Default('') String accountName,
    String? gatewayName,
    DateTime? createdAt,
  }) = _WithdrawalAccount;

  factory WithdrawalAccount.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalAccountFromJson(json);
}
