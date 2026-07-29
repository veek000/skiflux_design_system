// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_financial_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WalletFinancialSummary {

@DecimalConverter() Decimal get totalEarned;@DecimalConverter() Decimal get totalSpent;@DecimalConverter() Decimal get totalWithdrawn;
/// Create a copy of WalletFinancialSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletFinancialSummaryCopyWith<WalletFinancialSummary> get copyWith => _$WalletFinancialSummaryCopyWithImpl<WalletFinancialSummary>(this as WalletFinancialSummary, _$identity);

  /// Serializes this WalletFinancialSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletFinancialSummary&&(identical(other.totalEarned, totalEarned) || other.totalEarned == totalEarned)&&(identical(other.totalSpent, totalSpent) || other.totalSpent == totalSpent)&&(identical(other.totalWithdrawn, totalWithdrawn) || other.totalWithdrawn == totalWithdrawn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalEarned,totalSpent,totalWithdrawn);

@override
String toString() {
  return 'WalletFinancialSummary(totalEarned: $totalEarned, totalSpent: $totalSpent, totalWithdrawn: $totalWithdrawn)';
}


}

/// @nodoc
abstract mixin class $WalletFinancialSummaryCopyWith<$Res>  {
  factory $WalletFinancialSummaryCopyWith(WalletFinancialSummary value, $Res Function(WalletFinancialSummary) _then) = _$WalletFinancialSummaryCopyWithImpl;
@useResult
$Res call({
@DecimalConverter() Decimal totalEarned,@DecimalConverter() Decimal totalSpent,@DecimalConverter() Decimal totalWithdrawn
});




}
/// @nodoc
class _$WalletFinancialSummaryCopyWithImpl<$Res>
    implements $WalletFinancialSummaryCopyWith<$Res> {
  _$WalletFinancialSummaryCopyWithImpl(this._self, this._then);

  final WalletFinancialSummary _self;
  final $Res Function(WalletFinancialSummary) _then;

/// Create a copy of WalletFinancialSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalEarned = null,Object? totalSpent = null,Object? totalWithdrawn = null,}) {
  return _then(_self.copyWith(
totalEarned: null == totalEarned ? _self.totalEarned : totalEarned // ignore: cast_nullable_to_non_nullable
as Decimal,totalSpent: null == totalSpent ? _self.totalSpent : totalSpent // ignore: cast_nullable_to_non_nullable
as Decimal,totalWithdrawn: null == totalWithdrawn ? _self.totalWithdrawn : totalWithdrawn // ignore: cast_nullable_to_non_nullable
as Decimal,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletFinancialSummary].
extension WalletFinancialSummaryPatterns on WalletFinancialSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletFinancialSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletFinancialSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletFinancialSummary value)  $default,){
final _that = this;
switch (_that) {
case _WalletFinancialSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletFinancialSummary value)?  $default,){
final _that = this;
switch (_that) {
case _WalletFinancialSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DecimalConverter()  Decimal totalEarned, @DecimalConverter()  Decimal totalSpent, @DecimalConverter()  Decimal totalWithdrawn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletFinancialSummary() when $default != null:
return $default(_that.totalEarned,_that.totalSpent,_that.totalWithdrawn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DecimalConverter()  Decimal totalEarned, @DecimalConverter()  Decimal totalSpent, @DecimalConverter()  Decimal totalWithdrawn)  $default,) {final _that = this;
switch (_that) {
case _WalletFinancialSummary():
return $default(_that.totalEarned,_that.totalSpent,_that.totalWithdrawn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DecimalConverter()  Decimal totalEarned, @DecimalConverter()  Decimal totalSpent, @DecimalConverter()  Decimal totalWithdrawn)?  $default,) {final _that = this;
switch (_that) {
case _WalletFinancialSummary() when $default != null:
return $default(_that.totalEarned,_that.totalSpent,_that.totalWithdrawn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletFinancialSummary implements WalletFinancialSummary {
  const _WalletFinancialSummary({@DecimalConverter() required this.totalEarned, @DecimalConverter() required this.totalSpent, @DecimalConverter() required this.totalWithdrawn});
  factory _WalletFinancialSummary.fromJson(Map<String, dynamic> json) => _$WalletFinancialSummaryFromJson(json);

@override@DecimalConverter() final  Decimal totalEarned;
@override@DecimalConverter() final  Decimal totalSpent;
@override@DecimalConverter() final  Decimal totalWithdrawn;

/// Create a copy of WalletFinancialSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletFinancialSummaryCopyWith<_WalletFinancialSummary> get copyWith => __$WalletFinancialSummaryCopyWithImpl<_WalletFinancialSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletFinancialSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletFinancialSummary&&(identical(other.totalEarned, totalEarned) || other.totalEarned == totalEarned)&&(identical(other.totalSpent, totalSpent) || other.totalSpent == totalSpent)&&(identical(other.totalWithdrawn, totalWithdrawn) || other.totalWithdrawn == totalWithdrawn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalEarned,totalSpent,totalWithdrawn);

@override
String toString() {
  return 'WalletFinancialSummary(totalEarned: $totalEarned, totalSpent: $totalSpent, totalWithdrawn: $totalWithdrawn)';
}


}

/// @nodoc
abstract mixin class _$WalletFinancialSummaryCopyWith<$Res> implements $WalletFinancialSummaryCopyWith<$Res> {
  factory _$WalletFinancialSummaryCopyWith(_WalletFinancialSummary value, $Res Function(_WalletFinancialSummary) _then) = __$WalletFinancialSummaryCopyWithImpl;
@override @useResult
$Res call({
@DecimalConverter() Decimal totalEarned,@DecimalConverter() Decimal totalSpent,@DecimalConverter() Decimal totalWithdrawn
});




}
/// @nodoc
class __$WalletFinancialSummaryCopyWithImpl<$Res>
    implements _$WalletFinancialSummaryCopyWith<$Res> {
  __$WalletFinancialSummaryCopyWithImpl(this._self, this._then);

  final _WalletFinancialSummary _self;
  final $Res Function(_WalletFinancialSummary) _then;

/// Create a copy of WalletFinancialSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalEarned = null,Object? totalSpent = null,Object? totalWithdrawn = null,}) {
  return _then(_WalletFinancialSummary(
totalEarned: null == totalEarned ? _self.totalEarned : totalEarned // ignore: cast_nullable_to_non_nullable
as Decimal,totalSpent: null == totalSpent ? _self.totalSpent : totalSpent // ignore: cast_nullable_to_non_nullable
as Decimal,totalWithdrawn: null == totalWithdrawn ? _self.totalWithdrawn : totalWithdrawn // ignore: cast_nullable_to_non_nullable
as Decimal,
  ));
}


}

// dart format on
