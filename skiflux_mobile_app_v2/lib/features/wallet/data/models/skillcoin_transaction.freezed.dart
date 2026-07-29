// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skillcoin_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SkillcoinTransaction {

@DecimalConverter() Decimal get amount;@JsonKey(unknownEnumValue: SkillcoinTransactionType.unknown) SkillcoinTransactionType get transactionType;/// Backend-rendered display string ("Top-up via Payment Gateway") —
/// required in responses per the spec; show it verbatim.
 String get transactionTypeLabel; String get description; DateTime get createdAt;/// Optional in the spec; unknown future values read as null.
@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) SkillcoinTransactionStatus? get status; String? get id; String? get referenceId;
/// Create a copy of SkillcoinTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillcoinTransactionCopyWith<SkillcoinTransaction> get copyWith => _$SkillcoinTransactionCopyWithImpl<SkillcoinTransaction>(this as SkillcoinTransaction, _$identity);

  /// Serializes this SkillcoinTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillcoinTransaction&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.transactionTypeLabel, transactionTypeLabel) || other.transactionTypeLabel == transactionTypeLabel)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.id, id) || other.id == id)&&(identical(other.referenceId, referenceId) || other.referenceId == referenceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,transactionType,transactionTypeLabel,description,createdAt,status,id,referenceId);

@override
String toString() {
  return 'SkillcoinTransaction(amount: $amount, transactionType: $transactionType, transactionTypeLabel: $transactionTypeLabel, description: $description, createdAt: $createdAt, status: $status, id: $id, referenceId: $referenceId)';
}


}

/// @nodoc
abstract mixin class $SkillcoinTransactionCopyWith<$Res>  {
  factory $SkillcoinTransactionCopyWith(SkillcoinTransaction value, $Res Function(SkillcoinTransaction) _then) = _$SkillcoinTransactionCopyWithImpl;
@useResult
$Res call({
@DecimalConverter() Decimal amount,@JsonKey(unknownEnumValue: SkillcoinTransactionType.unknown) SkillcoinTransactionType transactionType, String transactionTypeLabel, String description, DateTime createdAt,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) SkillcoinTransactionStatus? status, String? id, String? referenceId
});




}
/// @nodoc
class _$SkillcoinTransactionCopyWithImpl<$Res>
    implements $SkillcoinTransactionCopyWith<$Res> {
  _$SkillcoinTransactionCopyWithImpl(this._self, this._then);

  final SkillcoinTransaction _self;
  final $Res Function(SkillcoinTransaction) _then;

/// Create a copy of SkillcoinTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? transactionType = null,Object? transactionTypeLabel = null,Object? description = null,Object? createdAt = null,Object? status = freezed,Object? id = freezed,Object? referenceId = freezed,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as SkillcoinTransactionType,transactionTypeLabel: null == transactionTypeLabel ? _self.transactionTypeLabel : transactionTypeLabel // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SkillcoinTransactionStatus?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,referenceId: freezed == referenceId ? _self.referenceId : referenceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillcoinTransaction].
extension SkillcoinTransactionPatterns on SkillcoinTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillcoinTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillcoinTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillcoinTransaction value)  $default,){
final _that = this;
switch (_that) {
case _SkillcoinTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillcoinTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _SkillcoinTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@DecimalConverter()  Decimal amount, @JsonKey(unknownEnumValue: SkillcoinTransactionType.unknown)  SkillcoinTransactionType transactionType,  String transactionTypeLabel,  String description,  DateTime createdAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  SkillcoinTransactionStatus? status,  String? id,  String? referenceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillcoinTransaction() when $default != null:
return $default(_that.amount,_that.transactionType,_that.transactionTypeLabel,_that.description,_that.createdAt,_that.status,_that.id,_that.referenceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@DecimalConverter()  Decimal amount, @JsonKey(unknownEnumValue: SkillcoinTransactionType.unknown)  SkillcoinTransactionType transactionType,  String transactionTypeLabel,  String description,  DateTime createdAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  SkillcoinTransactionStatus? status,  String? id,  String? referenceId)  $default,) {final _that = this;
switch (_that) {
case _SkillcoinTransaction():
return $default(_that.amount,_that.transactionType,_that.transactionTypeLabel,_that.description,_that.createdAt,_that.status,_that.id,_that.referenceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@DecimalConverter()  Decimal amount, @JsonKey(unknownEnumValue: SkillcoinTransactionType.unknown)  SkillcoinTransactionType transactionType,  String transactionTypeLabel,  String description,  DateTime createdAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  SkillcoinTransactionStatus? status,  String? id,  String? referenceId)?  $default,) {final _that = this;
switch (_that) {
case _SkillcoinTransaction() when $default != null:
return $default(_that.amount,_that.transactionType,_that.transactionTypeLabel,_that.description,_that.createdAt,_that.status,_that.id,_that.referenceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SkillcoinTransaction implements SkillcoinTransaction {
  const _SkillcoinTransaction({@DecimalConverter() required this.amount, @JsonKey(unknownEnumValue: SkillcoinTransactionType.unknown) required this.transactionType, required this.transactionTypeLabel, required this.description, required this.createdAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.status, this.id, this.referenceId});
  factory _SkillcoinTransaction.fromJson(Map<String, dynamic> json) => _$SkillcoinTransactionFromJson(json);

@override@DecimalConverter() final  Decimal amount;
@override@JsonKey(unknownEnumValue: SkillcoinTransactionType.unknown) final  SkillcoinTransactionType transactionType;
/// Backend-rendered display string ("Top-up via Payment Gateway") —
/// required in responses per the spec; show it verbatim.
@override final  String transactionTypeLabel;
@override final  String description;
@override final  DateTime createdAt;
/// Optional in the spec; unknown future values read as null.
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  SkillcoinTransactionStatus? status;
@override final  String? id;
@override final  String? referenceId;

/// Create a copy of SkillcoinTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillcoinTransactionCopyWith<_SkillcoinTransaction> get copyWith => __$SkillcoinTransactionCopyWithImpl<_SkillcoinTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SkillcoinTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillcoinTransaction&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.transactionType, transactionType) || other.transactionType == transactionType)&&(identical(other.transactionTypeLabel, transactionTypeLabel) || other.transactionTypeLabel == transactionTypeLabel)&&(identical(other.description, description) || other.description == description)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.id, id) || other.id == id)&&(identical(other.referenceId, referenceId) || other.referenceId == referenceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,transactionType,transactionTypeLabel,description,createdAt,status,id,referenceId);

@override
String toString() {
  return 'SkillcoinTransaction(amount: $amount, transactionType: $transactionType, transactionTypeLabel: $transactionTypeLabel, description: $description, createdAt: $createdAt, status: $status, id: $id, referenceId: $referenceId)';
}


}

/// @nodoc
abstract mixin class _$SkillcoinTransactionCopyWith<$Res> implements $SkillcoinTransactionCopyWith<$Res> {
  factory _$SkillcoinTransactionCopyWith(_SkillcoinTransaction value, $Res Function(_SkillcoinTransaction) _then) = __$SkillcoinTransactionCopyWithImpl;
@override @useResult
$Res call({
@DecimalConverter() Decimal amount,@JsonKey(unknownEnumValue: SkillcoinTransactionType.unknown) SkillcoinTransactionType transactionType, String transactionTypeLabel, String description, DateTime createdAt,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) SkillcoinTransactionStatus? status, String? id, String? referenceId
});




}
/// @nodoc
class __$SkillcoinTransactionCopyWithImpl<$Res>
    implements _$SkillcoinTransactionCopyWith<$Res> {
  __$SkillcoinTransactionCopyWithImpl(this._self, this._then);

  final _SkillcoinTransaction _self;
  final $Res Function(_SkillcoinTransaction) _then;

/// Create a copy of SkillcoinTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? transactionType = null,Object? transactionTypeLabel = null,Object? description = null,Object? createdAt = null,Object? status = freezed,Object? id = freezed,Object? referenceId = freezed,}) {
  return _then(_SkillcoinTransaction(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as Decimal,transactionType: null == transactionType ? _self.transactionType : transactionType // ignore: cast_nullable_to_non_nullable
as SkillcoinTransactionType,transactionTypeLabel: null == transactionTypeLabel ? _self.transactionTypeLabel : transactionTypeLabel // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SkillcoinTransactionStatus?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,referenceId: freezed == referenceId ? _self.referenceId : referenceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
