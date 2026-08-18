// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdrawal_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WithdrawalAccount {

 String get id; WithdrawalDestinationType get destinationType; String get displayName; WithdrawalAccountStatus get status; bool get isDefault;// Empty on Stripe Connect rows and absent on the nested copy.
 String get bankCode; String get bankName; String get accountNumber; String get accountName; String? get gatewayName; DateTime? get createdAt;
/// Create a copy of WithdrawalAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawalAccountCopyWith<WithdrawalAccount> get copyWith => _$WithdrawalAccountCopyWithImpl<WithdrawalAccount>(this as WithdrawalAccount, _$identity);

  /// Serializes this WithdrawalAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawalAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.destinationType, destinationType) || other.destinationType == destinationType)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.gatewayName, gatewayName) || other.gatewayName == gatewayName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,destinationType,displayName,status,isDefault,bankCode,bankName,accountNumber,accountName,gatewayName,createdAt);

@override
String toString() {
  return 'WithdrawalAccount(id: $id, destinationType: $destinationType, displayName: $displayName, status: $status, isDefault: $isDefault, bankCode: $bankCode, bankName: $bankName, accountNumber: $accountNumber, accountName: $accountName, gatewayName: $gatewayName, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WithdrawalAccountCopyWith<$Res>  {
  factory $WithdrawalAccountCopyWith(WithdrawalAccount value, $Res Function(WithdrawalAccount) _then) = _$WithdrawalAccountCopyWithImpl;
@useResult
$Res call({
 String id, WithdrawalDestinationType destinationType, String displayName, WithdrawalAccountStatus status, bool isDefault, String bankCode, String bankName, String accountNumber, String accountName, String? gatewayName, DateTime? createdAt
});




}
/// @nodoc
class _$WithdrawalAccountCopyWithImpl<$Res>
    implements $WithdrawalAccountCopyWith<$Res> {
  _$WithdrawalAccountCopyWithImpl(this._self, this._then);

  final WithdrawalAccount _self;
  final $Res Function(WithdrawalAccount) _then;

/// Create a copy of WithdrawalAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? destinationType = null,Object? displayName = null,Object? status = null,Object? isDefault = null,Object? bankCode = null,Object? bankName = null,Object? accountNumber = null,Object? accountName = null,Object? gatewayName = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,destinationType: null == destinationType ? _self.destinationType : destinationType // ignore: cast_nullable_to_non_nullable
as WithdrawalDestinationType,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WithdrawalAccountStatus,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,bankCode: null == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,gatewayName: freezed == gatewayName ? _self.gatewayName : gatewayName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WithdrawalAccount].
extension WithdrawalAccountPatterns on WithdrawalAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawalAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawalAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawalAccount value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawalAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawalAccount value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawalAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  WithdrawalDestinationType destinationType,  String displayName,  WithdrawalAccountStatus status,  bool isDefault,  String bankCode,  String bankName,  String accountNumber,  String accountName,  String? gatewayName,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawalAccount() when $default != null:
return $default(_that.id,_that.destinationType,_that.displayName,_that.status,_that.isDefault,_that.bankCode,_that.bankName,_that.accountNumber,_that.accountName,_that.gatewayName,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  WithdrawalDestinationType destinationType,  String displayName,  WithdrawalAccountStatus status,  bool isDefault,  String bankCode,  String bankName,  String accountNumber,  String accountName,  String? gatewayName,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _WithdrawalAccount():
return $default(_that.id,_that.destinationType,_that.displayName,_that.status,_that.isDefault,_that.bankCode,_that.bankName,_that.accountNumber,_that.accountName,_that.gatewayName,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  WithdrawalDestinationType destinationType,  String displayName,  WithdrawalAccountStatus status,  bool isDefault,  String bankCode,  String bankName,  String accountNumber,  String accountName,  String? gatewayName,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawalAccount() when $default != null:
return $default(_that.id,_that.destinationType,_that.displayName,_that.status,_that.isDefault,_that.bankCode,_that.bankName,_that.accountNumber,_that.accountName,_that.gatewayName,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WithdrawalAccount implements WithdrawalAccount {
  const _WithdrawalAccount({required this.id, required this.destinationType, required this.displayName, required this.status, required this.isDefault, this.bankCode = '', this.bankName = '', this.accountNumber = '', this.accountName = '', this.gatewayName, this.createdAt});
  factory _WithdrawalAccount.fromJson(Map<String, dynamic> json) => _$WithdrawalAccountFromJson(json);

@override final  String id;
@override final  WithdrawalDestinationType destinationType;
@override final  String displayName;
@override final  WithdrawalAccountStatus status;
@override final  bool isDefault;
// Empty on Stripe Connect rows and absent on the nested copy.
@override@JsonKey() final  String bankCode;
@override@JsonKey() final  String bankName;
@override@JsonKey() final  String accountNumber;
@override@JsonKey() final  String accountName;
@override final  String? gatewayName;
@override final  DateTime? createdAt;

/// Create a copy of WithdrawalAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawalAccountCopyWith<_WithdrawalAccount> get copyWith => __$WithdrawalAccountCopyWithImpl<_WithdrawalAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WithdrawalAccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawalAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.destinationType, destinationType) || other.destinationType == destinationType)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.bankCode, bankCode) || other.bankCode == bankCode)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.accountNumber, accountNumber) || other.accountNumber == accountNumber)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.gatewayName, gatewayName) || other.gatewayName == gatewayName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,destinationType,displayName,status,isDefault,bankCode,bankName,accountNumber,accountName,gatewayName,createdAt);

@override
String toString() {
  return 'WithdrawalAccount(id: $id, destinationType: $destinationType, displayName: $displayName, status: $status, isDefault: $isDefault, bankCode: $bankCode, bankName: $bankName, accountNumber: $accountNumber, accountName: $accountName, gatewayName: $gatewayName, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WithdrawalAccountCopyWith<$Res> implements $WithdrawalAccountCopyWith<$Res> {
  factory _$WithdrawalAccountCopyWith(_WithdrawalAccount value, $Res Function(_WithdrawalAccount) _then) = __$WithdrawalAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, WithdrawalDestinationType destinationType, String displayName, WithdrawalAccountStatus status, bool isDefault, String bankCode, String bankName, String accountNumber, String accountName, String? gatewayName, DateTime? createdAt
});




}
/// @nodoc
class __$WithdrawalAccountCopyWithImpl<$Res>
    implements _$WithdrawalAccountCopyWith<$Res> {
  __$WithdrawalAccountCopyWithImpl(this._self, this._then);

  final _WithdrawalAccount _self;
  final $Res Function(_WithdrawalAccount) _then;

/// Create a copy of WithdrawalAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? destinationType = null,Object? displayName = null,Object? status = null,Object? isDefault = null,Object? bankCode = null,Object? bankName = null,Object? accountNumber = null,Object? accountName = null,Object? gatewayName = freezed,Object? createdAt = freezed,}) {
  return _then(_WithdrawalAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,destinationType: null == destinationType ? _self.destinationType : destinationType // ignore: cast_nullable_to_non_nullable
as WithdrawalDestinationType,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WithdrawalAccountStatus,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,bankCode: null == bankCode ? _self.bankCode : bankCode // ignore: cast_nullable_to_non_nullable
as String,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,accountNumber: null == accountNumber ? _self.accountNumber : accountNumber // ignore: cast_nullable_to_non_nullable
as String,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,gatewayName: freezed == gatewayName ? _self.gatewayName : gatewayName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
