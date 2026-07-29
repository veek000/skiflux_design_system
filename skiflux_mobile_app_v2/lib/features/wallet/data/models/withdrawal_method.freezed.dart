// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdrawal_method.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WithdrawalMethod {

 String get method; String get gateway;/// Picks the UI: `bank_form` → bank picker + account form,
/// `hosted_redirect` → open the Stripe onboarding URL.
 String get flow; String get label;
/// Create a copy of WithdrawalMethod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawalMethodCopyWith<WithdrawalMethod> get copyWith => _$WithdrawalMethodCopyWithImpl<WithdrawalMethod>(this as WithdrawalMethod, _$identity);

  /// Serializes this WithdrawalMethod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawalMethod&&(identical(other.method, method) || other.method == method)&&(identical(other.gateway, gateway) || other.gateway == gateway)&&(identical(other.flow, flow) || other.flow == flow)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,method,gateway,flow,label);

@override
String toString() {
  return 'WithdrawalMethod(method: $method, gateway: $gateway, flow: $flow, label: $label)';
}


}

/// @nodoc
abstract mixin class $WithdrawalMethodCopyWith<$Res>  {
  factory $WithdrawalMethodCopyWith(WithdrawalMethod value, $Res Function(WithdrawalMethod) _then) = _$WithdrawalMethodCopyWithImpl;
@useResult
$Res call({
 String method, String gateway, String flow, String label
});




}
/// @nodoc
class _$WithdrawalMethodCopyWithImpl<$Res>
    implements $WithdrawalMethodCopyWith<$Res> {
  _$WithdrawalMethodCopyWithImpl(this._self, this._then);

  final WithdrawalMethod _self;
  final $Res Function(WithdrawalMethod) _then;

/// Create a copy of WithdrawalMethod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? method = null,Object? gateway = null,Object? flow = null,Object? label = null,}) {
  return _then(_self.copyWith(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,gateway: null == gateway ? _self.gateway : gateway // ignore: cast_nullable_to_non_nullable
as String,flow: null == flow ? _self.flow : flow // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WithdrawalMethod].
extension WithdrawalMethodPatterns on WithdrawalMethod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawalMethod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawalMethod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawalMethod value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawalMethod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawalMethod value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawalMethod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String method,  String gateway,  String flow,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawalMethod() when $default != null:
return $default(_that.method,_that.gateway,_that.flow,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String method,  String gateway,  String flow,  String label)  $default,) {final _that = this;
switch (_that) {
case _WithdrawalMethod():
return $default(_that.method,_that.gateway,_that.flow,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String method,  String gateway,  String flow,  String label)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawalMethod() when $default != null:
return $default(_that.method,_that.gateway,_that.flow,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WithdrawalMethod implements WithdrawalMethod {
  const _WithdrawalMethod({required this.method, required this.gateway, required this.flow, required this.label});
  factory _WithdrawalMethod.fromJson(Map<String, dynamic> json) => _$WithdrawalMethodFromJson(json);

@override final  String method;
@override final  String gateway;
/// Picks the UI: `bank_form` → bank picker + account form,
/// `hosted_redirect` → open the Stripe onboarding URL.
@override final  String flow;
@override final  String label;

/// Create a copy of WithdrawalMethod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawalMethodCopyWith<_WithdrawalMethod> get copyWith => __$WithdrawalMethodCopyWithImpl<_WithdrawalMethod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WithdrawalMethodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawalMethod&&(identical(other.method, method) || other.method == method)&&(identical(other.gateway, gateway) || other.gateway == gateway)&&(identical(other.flow, flow) || other.flow == flow)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,method,gateway,flow,label);

@override
String toString() {
  return 'WithdrawalMethod(method: $method, gateway: $gateway, flow: $flow, label: $label)';
}


}

/// @nodoc
abstract mixin class _$WithdrawalMethodCopyWith<$Res> implements $WithdrawalMethodCopyWith<$Res> {
  factory _$WithdrawalMethodCopyWith(_WithdrawalMethod value, $Res Function(_WithdrawalMethod) _then) = __$WithdrawalMethodCopyWithImpl;
@override @useResult
$Res call({
 String method, String gateway, String flow, String label
});




}
/// @nodoc
class __$WithdrawalMethodCopyWithImpl<$Res>
    implements _$WithdrawalMethodCopyWith<$Res> {
  __$WithdrawalMethodCopyWithImpl(this._self, this._then);

  final _WithdrawalMethod _self;
  final $Res Function(_WithdrawalMethod) _then;

/// Create a copy of WithdrawalMethod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? method = null,Object? gateway = null,Object? flow = null,Object? label = null,}) {
  return _then(_WithdrawalMethod(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,gateway: null == gateway ? _self.gateway : gateway // ignore: cast_nullable_to_non_nullable
as String,flow: null == flow ? _self.flow : flow // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
