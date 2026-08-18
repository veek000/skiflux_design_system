import 'package:freezed_annotation/freezed_annotation.dart';

part 'withdrawal_method.freezed.dart';
part 'withdrawal_method.g.dart';

/// One entry of `GET /wallet/withdrawals/methods` (withdrawal-flows.md §3).
/// All four fields stay strings on purpose: the docs' design principle is
/// "render whatever discovery returns" — an enum here would hardcode the
/// gateway list the endpoint exists to avoid.
@freezed
abstract class WithdrawalMethod with _$WithdrawalMethod {
  const factory WithdrawalMethod({
    required String method,
    required String gateway,

    /// Picks the UI: `bank_form` → bank picker + account form,
    /// `hosted_redirect` → open the Stripe onboarding URL.
    required String flow,
    required String label,
  }) = _WithdrawalMethod;

  factory WithdrawalMethod.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalMethodFromJson(json);
}
