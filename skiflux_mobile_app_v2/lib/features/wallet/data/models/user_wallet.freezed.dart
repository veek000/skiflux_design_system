// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_wallet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserWallet {

 String get id;/// Optional in the spec — absent reads as zero via the converter.
@_DecimalOrZeroConverter() Decimal get balance;/// Non-withdrawable registration bonus. Optional in the spec — absent
/// reads as zero via the converter.
@_DecimalOrZeroConverter() Decimal get bonusBalance;/// Returned by the API already hold-aware (balance − bonus_balance −
/// active_holds) — trusted as sent, never recomputed client-side.
/// Spec quirk: this one arrives as a JSON *number* (`format: double`),
/// not a decimal string like the other money fields.
@DecimalFromNumConverter() Decimal get withdrawableBalance;/// Locked wallets have an effective withdrawable balance of zero.
/// Optional in the spec — absent reads as unlocked.
 bool get isLocked; DateTime get updatedAt; bool get isPlatformWallet;
/// Create a copy of UserWallet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserWalletCopyWith<UserWallet> get copyWith => _$UserWalletCopyWithImpl<UserWallet>(this as UserWallet, _$identity);

  /// Serializes this UserWallet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserWallet&&(identical(other.id, id) || other.id == id)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.bonusBalance, bonusBalance) || other.bonusBalance == bonusBalance)&&(identical(other.withdrawableBalance, withdrawableBalance) || other.withdrawableBalance == withdrawableBalance)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isPlatformWallet, isPlatformWallet) || other.isPlatformWallet == isPlatformWallet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,balance,bonusBalance,withdrawableBalance,isLocked,updatedAt,isPlatformWallet);

@override
String toString() {
  return 'UserWallet(id: $id, balance: $balance, bonusBalance: $bonusBalance, withdrawableBalance: $withdrawableBalance, isLocked: $isLocked, updatedAt: $updatedAt, isPlatformWallet: $isPlatformWallet)';
}


}

/// @nodoc
abstract mixin class $UserWalletCopyWith<$Res>  {
  factory $UserWalletCopyWith(UserWallet value, $Res Function(UserWallet) _then) = _$UserWalletCopyWithImpl;
@useResult
$Res call({
 String id,@_DecimalOrZeroConverter() Decimal balance,@_DecimalOrZeroConverter() Decimal bonusBalance,@DecimalFromNumConverter() Decimal withdrawableBalance, bool isLocked, DateTime updatedAt, bool isPlatformWallet
});




}
/// @nodoc
class _$UserWalletCopyWithImpl<$Res>
    implements $UserWalletCopyWith<$Res> {
  _$UserWalletCopyWithImpl(this._self, this._then);

  final UserWallet _self;
  final $Res Function(UserWallet) _then;

/// Create a copy of UserWallet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? balance = null,Object? bonusBalance = null,Object? withdrawableBalance = null,Object? isLocked = null,Object? updatedAt = null,Object? isPlatformWallet = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Decimal,bonusBalance: null == bonusBalance ? _self.bonusBalance : bonusBalance // ignore: cast_nullable_to_non_nullable
as Decimal,withdrawableBalance: null == withdrawableBalance ? _self.withdrawableBalance : withdrawableBalance // ignore: cast_nullable_to_non_nullable
as Decimal,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isPlatformWallet: null == isPlatformWallet ? _self.isPlatformWallet : isPlatformWallet // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserWallet].
extension UserWalletPatterns on UserWallet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserWallet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserWallet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserWallet value)  $default,){
final _that = this;
switch (_that) {
case _UserWallet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserWallet value)?  $default,){
final _that = this;
switch (_that) {
case _UserWallet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @_DecimalOrZeroConverter()  Decimal balance, @_DecimalOrZeroConverter()  Decimal bonusBalance, @DecimalFromNumConverter()  Decimal withdrawableBalance,  bool isLocked,  DateTime updatedAt,  bool isPlatformWallet)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserWallet() when $default != null:
return $default(_that.id,_that.balance,_that.bonusBalance,_that.withdrawableBalance,_that.isLocked,_that.updatedAt,_that.isPlatformWallet);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @_DecimalOrZeroConverter()  Decimal balance, @_DecimalOrZeroConverter()  Decimal bonusBalance, @DecimalFromNumConverter()  Decimal withdrawableBalance,  bool isLocked,  DateTime updatedAt,  bool isPlatformWallet)  $default,) {final _that = this;
switch (_that) {
case _UserWallet():
return $default(_that.id,_that.balance,_that.bonusBalance,_that.withdrawableBalance,_that.isLocked,_that.updatedAt,_that.isPlatformWallet);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @_DecimalOrZeroConverter()  Decimal balance, @_DecimalOrZeroConverter()  Decimal bonusBalance, @DecimalFromNumConverter()  Decimal withdrawableBalance,  bool isLocked,  DateTime updatedAt,  bool isPlatformWallet)?  $default,) {final _that = this;
switch (_that) {
case _UserWallet() when $default != null:
return $default(_that.id,_that.balance,_that.bonusBalance,_that.withdrawableBalance,_that.isLocked,_that.updatedAt,_that.isPlatformWallet);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserWallet implements UserWallet {
  const _UserWallet({required this.id, @_DecimalOrZeroConverter() required this.balance, @_DecimalOrZeroConverter() required this.bonusBalance, @DecimalFromNumConverter() required this.withdrawableBalance, this.isLocked = false, required this.updatedAt, this.isPlatformWallet = false});
  factory _UserWallet.fromJson(Map<String, dynamic> json) => _$UserWalletFromJson(json);

@override final  String id;
/// Optional in the spec — absent reads as zero via the converter.
@override@_DecimalOrZeroConverter() final  Decimal balance;
/// Non-withdrawable registration bonus. Optional in the spec — absent
/// reads as zero via the converter.
@override@_DecimalOrZeroConverter() final  Decimal bonusBalance;
/// Returned by the API already hold-aware (balance − bonus_balance −
/// active_holds) — trusted as sent, never recomputed client-side.
/// Spec quirk: this one arrives as a JSON *number* (`format: double`),
/// not a decimal string like the other money fields.
@override@DecimalFromNumConverter() final  Decimal withdrawableBalance;
/// Locked wallets have an effective withdrawable balance of zero.
/// Optional in the spec — absent reads as unlocked.
@override@JsonKey() final  bool isLocked;
@override final  DateTime updatedAt;
@override@JsonKey() final  bool isPlatformWallet;

/// Create a copy of UserWallet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserWalletCopyWith<_UserWallet> get copyWith => __$UserWalletCopyWithImpl<_UserWallet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserWalletToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserWallet&&(identical(other.id, id) || other.id == id)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.bonusBalance, bonusBalance) || other.bonusBalance == bonusBalance)&&(identical(other.withdrawableBalance, withdrawableBalance) || other.withdrawableBalance == withdrawableBalance)&&(identical(other.isLocked, isLocked) || other.isLocked == isLocked)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isPlatformWallet, isPlatformWallet) || other.isPlatformWallet == isPlatformWallet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,balance,bonusBalance,withdrawableBalance,isLocked,updatedAt,isPlatformWallet);

@override
String toString() {
  return 'UserWallet(id: $id, balance: $balance, bonusBalance: $bonusBalance, withdrawableBalance: $withdrawableBalance, isLocked: $isLocked, updatedAt: $updatedAt, isPlatformWallet: $isPlatformWallet)';
}


}

/// @nodoc
abstract mixin class _$UserWalletCopyWith<$Res> implements $UserWalletCopyWith<$Res> {
  factory _$UserWalletCopyWith(_UserWallet value, $Res Function(_UserWallet) _then) = __$UserWalletCopyWithImpl;
@override @useResult
$Res call({
 String id,@_DecimalOrZeroConverter() Decimal balance,@_DecimalOrZeroConverter() Decimal bonusBalance,@DecimalFromNumConverter() Decimal withdrawableBalance, bool isLocked, DateTime updatedAt, bool isPlatformWallet
});




}
/// @nodoc
class __$UserWalletCopyWithImpl<$Res>
    implements _$UserWalletCopyWith<$Res> {
  __$UserWalletCopyWithImpl(this._self, this._then);

  final _UserWallet _self;
  final $Res Function(_UserWallet) _then;

/// Create a copy of UserWallet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? balance = null,Object? bonusBalance = null,Object? withdrawableBalance = null,Object? isLocked = null,Object? updatedAt = null,Object? isPlatformWallet = null,}) {
  return _then(_UserWallet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Decimal,bonusBalance: null == bonusBalance ? _self.bonusBalance : bonusBalance // ignore: cast_nullable_to_non_nullable
as Decimal,withdrawableBalance: null == withdrawableBalance ? _self.withdrawableBalance : withdrawableBalance // ignore: cast_nullable_to_non_nullable
as Decimal,isLocked: null == isLocked ? _self.isLocked : isLocked // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isPlatformWallet: null == isPlatformWallet ? _self.isPlatformWallet : isPlatformWallet // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
