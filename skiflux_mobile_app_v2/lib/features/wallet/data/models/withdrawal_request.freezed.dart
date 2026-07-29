// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdrawal_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WithdrawalRequest {

 String get id;@DecimalConverter() Decimal get amount;/// amount − fee; what the gateway transfer actually pays out.
@DecimalConverter() Decimal get netAmount; DateTime get createdAt; WithdrawalAccount get account;/// amount × withdrawal_fee_percentage / 100, computed by the backend.
@DecimalConverter() Decimal? get fee; WithdrawalRequestStatus get status;/// Set once an admin processes; null while pending.
 String? get gatewayName; String? get failureReason; DateTime? get processedAt;
/// Create a copy of WithdrawalRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawalRequestCopyWith<WithdrawalRequest> get copyWith => _$WithdrawalRequestCopyWithImpl<WithdrawalRequest>(this as WithdrawalRequest, _$identity);

  /// Serializes this WithdrawalRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawalRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.netAmount, netAmount) || other.netAmount == netAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.account, account) || other.account == account)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.status, status) || other.status == status)&&(identical(other.gatewayName, gatewayName) || other.gatewayName == gatewayName)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,netAmount,createdAt,account,fee,status,gatewayName,failureReason,processedAt);

@override
String toString() {
  return 'WithdrawalRequest(id: $id, amount: $amount, netAmount: $netAmount, createdAt: $createdAt, account: $account, fee: $fee, status: $status, gatewayName: $gatewayName, failureReason: $failureReason, processedAt: $processedAt)';
}


}

/// @nodoc
abstract mixin class $WithdrawalRequestCopyWith<$Res>  {
  factory $WithdrawalRequestCopyWith(WithdrawalRequest value, $Res Function(WithdrawalRequest) _then) = _$WithdrawalRequestCopyWithImpl;
@useResult
$Res call({
 String id,@DecimalConverter() Decimal amount,@DecimalConverter() Decimal netAmount, DateTime createdAt, WithdrawalAccount account,@DecimalConverter() Decimal? fee, WithdrawalRequestStatus status, String? gatewayName, String? failureReason, DateTime? processedAt
});


$WithdrawalAccountCopyWith<$Res> get account;

}
/// @nodoc
class _$WithdrawalRequestCopyWithImpl<$Res>
    implements $WithdrawalRequestCopyWith<$Res> {
  _$WithdrawalRequestCopyWithImpl(this._self, this._then);

  final WithdrawalRequest _self;
  final $Res Function(WithdrawalRequest) _then;

/// Create a copy of WithdrawalRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? netAmount = null,Object? createdAt = null,Object? account = null,Object? fee = freezed,Object? status = null,Object? gatewayName = freezed,Object? failureReason = freezed,Object? processedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,netAmount: null == netAmount ? _self.netAmount : netAmount // ignore: cast_nullable_to_non_nullable
as Decimal,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as WithdrawalAccount,fee: freezed == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as Decimal?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WithdrawalRequestStatus,gatewayName: freezed == gatewayName ? _self.gatewayName : gatewayName // ignore: cast_nullable_to_non_nullable
as String?,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of WithdrawalRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WithdrawalAccountCopyWith<$Res> get account {
  
  return $WithdrawalAccountCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}


/// Adds pattern-matching-related methods to [WithdrawalRequest].
extension WithdrawalRequestPatterns on WithdrawalRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawalRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawalRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawalRequest value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawalRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawalRequest value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawalRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @DecimalConverter()  Decimal amount, @DecimalConverter()  Decimal netAmount,  DateTime createdAt,  WithdrawalAccount account, @DecimalConverter()  Decimal? fee,  WithdrawalRequestStatus status,  String? gatewayName,  String? failureReason,  DateTime? processedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawalRequest() when $default != null:
return $default(_that.id,_that.amount,_that.netAmount,_that.createdAt,_that.account,_that.fee,_that.status,_that.gatewayName,_that.failureReason,_that.processedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @DecimalConverter()  Decimal amount, @DecimalConverter()  Decimal netAmount,  DateTime createdAt,  WithdrawalAccount account, @DecimalConverter()  Decimal? fee,  WithdrawalRequestStatus status,  String? gatewayName,  String? failureReason,  DateTime? processedAt)  $default,) {final _that = this;
switch (_that) {
case _WithdrawalRequest():
return $default(_that.id,_that.amount,_that.netAmount,_that.createdAt,_that.account,_that.fee,_that.status,_that.gatewayName,_that.failureReason,_that.processedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @DecimalConverter()  Decimal amount, @DecimalConverter()  Decimal netAmount,  DateTime createdAt,  WithdrawalAccount account, @DecimalConverter()  Decimal? fee,  WithdrawalRequestStatus status,  String? gatewayName,  String? failureReason,  DateTime? processedAt)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawalRequest() when $default != null:
return $default(_that.id,_that.amount,_that.netAmount,_that.createdAt,_that.account,_that.fee,_that.status,_that.gatewayName,_that.failureReason,_that.processedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WithdrawalRequest implements WithdrawalRequest {
  const _WithdrawalRequest({required this.id, @DecimalConverter() required this.amount, @DecimalConverter() required this.netAmount, required this.createdAt, required this.account, @DecimalConverter() this.fee, this.status = WithdrawalRequestStatus.pending, this.gatewayName, this.failureReason, this.processedAt});
  factory _WithdrawalRequest.fromJson(Map<String, dynamic> json) => _$WithdrawalRequestFromJson(json);

@override final  String id;
@override@DecimalConverter() final  Decimal amount;
/// amount − fee; what the gateway transfer actually pays out.
@override@DecimalConverter() final  Decimal netAmount;
@override final  DateTime createdAt;
@override final  WithdrawalAccount account;
/// amount × withdrawal_fee_percentage / 100, computed by the backend.
@override@DecimalConverter() final  Decimal? fee;
@override@JsonKey() final  WithdrawalRequestStatus status;
/// Set once an admin processes; null while pending.
@override final  String? gatewayName;
@override final  String? failureReason;
@override final  DateTime? processedAt;

/// Create a copy of WithdrawalRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawalRequestCopyWith<_WithdrawalRequest> get copyWith => __$WithdrawalRequestCopyWithImpl<_WithdrawalRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WithdrawalRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawalRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.netAmount, netAmount) || other.netAmount == netAmount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.account, account) || other.account == account)&&(identical(other.fee, fee) || other.fee == fee)&&(identical(other.status, status) || other.status == status)&&(identical(other.gatewayName, gatewayName) || other.gatewayName == gatewayName)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.processedAt, processedAt) || other.processedAt == processedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,amount,netAmount,createdAt,account,fee,status,gatewayName,failureReason,processedAt);

@override
String toString() {
  return 'WithdrawalRequest(id: $id, amount: $amount, netAmount: $netAmount, createdAt: $createdAt, account: $account, fee: $fee, status: $status, gatewayName: $gatewayName, failureReason: $failureReason, processedAt: $processedAt)';
}


}

/// @nodoc
abstract mixin class _$WithdrawalRequestCopyWith<$Res> implements $WithdrawalRequestCopyWith<$Res> {
  factory _$WithdrawalRequestCopyWith(_WithdrawalRequest value, $Res Function(_WithdrawalRequest) _then) = __$WithdrawalRequestCopyWithImpl;
@override @useResult
$Res call({
 String id,@DecimalConverter() Decimal amount,@DecimalConverter() Decimal netAmount, DateTime createdAt, WithdrawalAccount account,@DecimalConverter() Decimal? fee, WithdrawalRequestStatus status, String? gatewayName, String? failureReason, DateTime? processedAt
});


@override $WithdrawalAccountCopyWith<$Res> get account;

}
/// @nodoc
class __$WithdrawalRequestCopyWithImpl<$Res>
    implements _$WithdrawalRequestCopyWith<$Res> {
  __$WithdrawalRequestCopyWithImpl(this._self, this._then);

  final _WithdrawalRequest _self;
  final $Res Function(_WithdrawalRequest) _then;

/// Create a copy of WithdrawalRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? netAmount = null,Object? createdAt = null,Object? account = null,Object? fee = freezed,Object? status = null,Object? gatewayName = freezed,Object? failureReason = freezed,Object? processedAt = freezed,}) {
  return _then(_WithdrawalRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,netAmount: null == netAmount ? _self.netAmount : netAmount // ignore: cast_nullable_to_non_nullable
as Decimal,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as WithdrawalAccount,fee: freezed == fee ? _self.fee : fee // ignore: cast_nullable_to_non_nullable
as Decimal?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WithdrawalRequestStatus,gatewayName: freezed == gatewayName ? _self.gatewayName : gatewayName // ignore: cast_nullable_to_non_nullable
as String?,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,processedAt: freezed == processedAt ? _self.processedAt : processedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of WithdrawalRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WithdrawalAccountCopyWith<$Res> get account {
  
  return $WithdrawalAccountCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}
}

// dart format on
