// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavedCard {

 String get id; String get gatewayName;/// Pre-masked by the backend, e.g. `**** **** **** 4081`.
 String get maskedNumber; String get last4; DateTime get createdAt;// Empty string (not absent) in the documented Stripe example; optional
// per the spec either way.
 String get cardBrand; String get expMonth; String get expYear; bool get isDefault; String get bankName; String get cardType;
/// Create a copy of SavedCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedCardCopyWith<SavedCard> get copyWith => _$SavedCardCopyWithImpl<SavedCard>(this as SavedCard, _$identity);

  /// Serializes this SavedCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedCard&&(identical(other.id, id) || other.id == id)&&(identical(other.gatewayName, gatewayName) || other.gatewayName == gatewayName)&&(identical(other.maskedNumber, maskedNumber) || other.maskedNumber == maskedNumber)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.cardBrand, cardBrand) || other.cardBrand == cardBrand)&&(identical(other.expMonth, expMonth) || other.expMonth == expMonth)&&(identical(other.expYear, expYear) || other.expYear == expYear)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.cardType, cardType) || other.cardType == cardType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gatewayName,maskedNumber,last4,createdAt,cardBrand,expMonth,expYear,isDefault,bankName,cardType);

@override
String toString() {
  return 'SavedCard(id: $id, gatewayName: $gatewayName, maskedNumber: $maskedNumber, last4: $last4, createdAt: $createdAt, cardBrand: $cardBrand, expMonth: $expMonth, expYear: $expYear, isDefault: $isDefault, bankName: $bankName, cardType: $cardType)';
}


}

/// @nodoc
abstract mixin class $SavedCardCopyWith<$Res>  {
  factory $SavedCardCopyWith(SavedCard value, $Res Function(SavedCard) _then) = _$SavedCardCopyWithImpl;
@useResult
$Res call({
 String id, String gatewayName, String maskedNumber, String last4, DateTime createdAt, String cardBrand, String expMonth, String expYear, bool isDefault, String bankName, String cardType
});




}
/// @nodoc
class _$SavedCardCopyWithImpl<$Res>
    implements $SavedCardCopyWith<$Res> {
  _$SavedCardCopyWithImpl(this._self, this._then);

  final SavedCard _self;
  final $Res Function(SavedCard) _then;

/// Create a copy of SavedCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? gatewayName = null,Object? maskedNumber = null,Object? last4 = null,Object? createdAt = null,Object? cardBrand = null,Object? expMonth = null,Object? expYear = null,Object? isDefault = null,Object? bankName = null,Object? cardType = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gatewayName: null == gatewayName ? _self.gatewayName : gatewayName // ignore: cast_nullable_to_non_nullable
as String,maskedNumber: null == maskedNumber ? _self.maskedNumber : maskedNumber // ignore: cast_nullable_to_non_nullable
as String,last4: null == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,cardBrand: null == cardBrand ? _self.cardBrand : cardBrand // ignore: cast_nullable_to_non_nullable
as String,expMonth: null == expMonth ? _self.expMonth : expMonth // ignore: cast_nullable_to_non_nullable
as String,expYear: null == expYear ? _self.expYear : expYear // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,cardType: null == cardType ? _self.cardType : cardType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedCard].
extension SavedCardPatterns on SavedCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedCard value)  $default,){
final _that = this;
switch (_that) {
case _SavedCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedCard value)?  $default,){
final _that = this;
switch (_that) {
case _SavedCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String gatewayName,  String maskedNumber,  String last4,  DateTime createdAt,  String cardBrand,  String expMonth,  String expYear,  bool isDefault,  String bankName,  String cardType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedCard() when $default != null:
return $default(_that.id,_that.gatewayName,_that.maskedNumber,_that.last4,_that.createdAt,_that.cardBrand,_that.expMonth,_that.expYear,_that.isDefault,_that.bankName,_that.cardType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String gatewayName,  String maskedNumber,  String last4,  DateTime createdAt,  String cardBrand,  String expMonth,  String expYear,  bool isDefault,  String bankName,  String cardType)  $default,) {final _that = this;
switch (_that) {
case _SavedCard():
return $default(_that.id,_that.gatewayName,_that.maskedNumber,_that.last4,_that.createdAt,_that.cardBrand,_that.expMonth,_that.expYear,_that.isDefault,_that.bankName,_that.cardType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String gatewayName,  String maskedNumber,  String last4,  DateTime createdAt,  String cardBrand,  String expMonth,  String expYear,  bool isDefault,  String bankName,  String cardType)?  $default,) {final _that = this;
switch (_that) {
case _SavedCard() when $default != null:
return $default(_that.id,_that.gatewayName,_that.maskedNumber,_that.last4,_that.createdAt,_that.cardBrand,_that.expMonth,_that.expYear,_that.isDefault,_that.bankName,_that.cardType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedCard implements SavedCard {
  const _SavedCard({required this.id, required this.gatewayName, required this.maskedNumber, required this.last4, required this.createdAt, this.cardBrand = '', this.expMonth = '', this.expYear = '', this.isDefault = false, this.bankName = '', this.cardType = ''});
  factory _SavedCard.fromJson(Map<String, dynamic> json) => _$SavedCardFromJson(json);

@override final  String id;
@override final  String gatewayName;
/// Pre-masked by the backend, e.g. `**** **** **** 4081`.
@override final  String maskedNumber;
@override final  String last4;
@override final  DateTime createdAt;
// Empty string (not absent) in the documented Stripe example; optional
// per the spec either way.
@override@JsonKey() final  String cardBrand;
@override@JsonKey() final  String expMonth;
@override@JsonKey() final  String expYear;
@override@JsonKey() final  bool isDefault;
@override@JsonKey() final  String bankName;
@override@JsonKey() final  String cardType;

/// Create a copy of SavedCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedCardCopyWith<_SavedCard> get copyWith => __$SavedCardCopyWithImpl<_SavedCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedCard&&(identical(other.id, id) || other.id == id)&&(identical(other.gatewayName, gatewayName) || other.gatewayName == gatewayName)&&(identical(other.maskedNumber, maskedNumber) || other.maskedNumber == maskedNumber)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.cardBrand, cardBrand) || other.cardBrand == cardBrand)&&(identical(other.expMonth, expMonth) || other.expMonth == expMonth)&&(identical(other.expYear, expYear) || other.expYear == expYear)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.cardType, cardType) || other.cardType == cardType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gatewayName,maskedNumber,last4,createdAt,cardBrand,expMonth,expYear,isDefault,bankName,cardType);

@override
String toString() {
  return 'SavedCard(id: $id, gatewayName: $gatewayName, maskedNumber: $maskedNumber, last4: $last4, createdAt: $createdAt, cardBrand: $cardBrand, expMonth: $expMonth, expYear: $expYear, isDefault: $isDefault, bankName: $bankName, cardType: $cardType)';
}


}

/// @nodoc
abstract mixin class _$SavedCardCopyWith<$Res> implements $SavedCardCopyWith<$Res> {
  factory _$SavedCardCopyWith(_SavedCard value, $Res Function(_SavedCard) _then) = __$SavedCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String gatewayName, String maskedNumber, String last4, DateTime createdAt, String cardBrand, String expMonth, String expYear, bool isDefault, String bankName, String cardType
});




}
/// @nodoc
class __$SavedCardCopyWithImpl<$Res>
    implements _$SavedCardCopyWith<$Res> {
  __$SavedCardCopyWithImpl(this._self, this._then);

  final _SavedCard _self;
  final $Res Function(_SavedCard) _then;

/// Create a copy of SavedCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? gatewayName = null,Object? maskedNumber = null,Object? last4 = null,Object? createdAt = null,Object? cardBrand = null,Object? expMonth = null,Object? expYear = null,Object? isDefault = null,Object? bankName = null,Object? cardType = null,}) {
  return _then(_SavedCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gatewayName: null == gatewayName ? _self.gatewayName : gatewayName // ignore: cast_nullable_to_non_nullable
as String,maskedNumber: null == maskedNumber ? _self.maskedNumber : maskedNumber // ignore: cast_nullable_to_non_nullable
as String,last4: null == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,cardBrand: null == cardBrand ? _self.cardBrand : cardBrand // ignore: cast_nullable_to_non_nullable
as String,expMonth: null == expMonth ? _self.expMonth : expMonth // ignore: cast_nullable_to_non_nullable
as String,expYear: null == expYear ? _self.expYear : expYear // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,bankName: null == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String,cardType: null == cardType ? _self.cardType : cardType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
