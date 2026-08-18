// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leaderboard_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LeaderboardRow {

/// Learner UUID from `UserLeaderboardEntry.id`. Empty when omitted.
 String get id; int get rank; String get firstName; String get lastName; String get username; String? get avatarUrl; int get xp;/// The league this learner sits in ("Novice" … "Professional"), from the
/// entry's `current_level`. Empty when the payload omits it.
 String get currentLevel;/// The entry's own `is_me`. Defaults false so the store can fall back to a
/// username / id match — see `LeaderboardNotifier.resolve`.
 bool get isCurrentUser;
/// Create a copy of LeaderboardRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaderboardRowCopyWith<LeaderboardRow> get copyWith => _$LeaderboardRowCopyWithImpl<LeaderboardRow>(this as LeaderboardRow, _$identity);

  /// Serializes this LeaderboardRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaderboardRow&&(identical(other.id, id) || other.id == id)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.currentLevel, currentLevel) || other.currentLevel == currentLevel)&&(identical(other.isCurrentUser, isCurrentUser) || other.isCurrentUser == isCurrentUser));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rank,firstName,lastName,username,avatarUrl,xp,currentLevel,isCurrentUser);

@override
String toString() {
  return 'LeaderboardRow(id: $id, rank: $rank, firstName: $firstName, lastName: $lastName, username: $username, avatarUrl: $avatarUrl, xp: $xp, currentLevel: $currentLevel, isCurrentUser: $isCurrentUser)';
}


}

/// @nodoc
abstract mixin class $LeaderboardRowCopyWith<$Res>  {
  factory $LeaderboardRowCopyWith(LeaderboardRow value, $Res Function(LeaderboardRow) _then) = _$LeaderboardRowCopyWithImpl;
@useResult
$Res call({
 String id, int rank, String firstName, String lastName, String username, String? avatarUrl, int xp, String currentLevel, bool isCurrentUser
});




}
/// @nodoc
class _$LeaderboardRowCopyWithImpl<$Res>
    implements $LeaderboardRowCopyWith<$Res> {
  _$LeaderboardRowCopyWithImpl(this._self, this._then);

  final LeaderboardRow _self;
  final $Res Function(LeaderboardRow) _then;

/// Create a copy of LeaderboardRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rank = null,Object? firstName = null,Object? lastName = null,Object? username = null,Object? avatarUrl = freezed,Object? xp = null,Object? currentLevel = null,Object? isCurrentUser = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,currentLevel: null == currentLevel ? _self.currentLevel : currentLevel // ignore: cast_nullable_to_non_nullable
as String,isCurrentUser: null == isCurrentUser ? _self.isCurrentUser : isCurrentUser // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LeaderboardRow].
extension LeaderboardRowPatterns on LeaderboardRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeaderboardRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeaderboardRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeaderboardRow value)  $default,){
final _that = this;
switch (_that) {
case _LeaderboardRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeaderboardRow value)?  $default,){
final _that = this;
switch (_that) {
case _LeaderboardRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int rank,  String firstName,  String lastName,  String username,  String? avatarUrl,  int xp,  String currentLevel,  bool isCurrentUser)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeaderboardRow() when $default != null:
return $default(_that.id,_that.rank,_that.firstName,_that.lastName,_that.username,_that.avatarUrl,_that.xp,_that.currentLevel,_that.isCurrentUser);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int rank,  String firstName,  String lastName,  String username,  String? avatarUrl,  int xp,  String currentLevel,  bool isCurrentUser)  $default,) {final _that = this;
switch (_that) {
case _LeaderboardRow():
return $default(_that.id,_that.rank,_that.firstName,_that.lastName,_that.username,_that.avatarUrl,_that.xp,_that.currentLevel,_that.isCurrentUser);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int rank,  String firstName,  String lastName,  String username,  String? avatarUrl,  int xp,  String currentLevel,  bool isCurrentUser)?  $default,) {final _that = this;
switch (_that) {
case _LeaderboardRow() when $default != null:
return $default(_that.id,_that.rank,_that.firstName,_that.lastName,_that.username,_that.avatarUrl,_that.xp,_that.currentLevel,_that.isCurrentUser);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LeaderboardRow extends LeaderboardRow {
  const _LeaderboardRow({this.id = '', this.rank = 0, this.firstName = '', this.lastName = '', this.username = '', this.avatarUrl, this.xp = 0, this.currentLevel = '', this.isCurrentUser = false}): super._();
  factory _LeaderboardRow.fromJson(Map<String, dynamic> json) => _$LeaderboardRowFromJson(json);

/// Learner UUID from `UserLeaderboardEntry.id`. Empty when omitted.
@override@JsonKey() final  String id;
@override@JsonKey() final  int rank;
@override@JsonKey() final  String firstName;
@override@JsonKey() final  String lastName;
@override@JsonKey() final  String username;
@override final  String? avatarUrl;
@override@JsonKey() final  int xp;
/// The league this learner sits in ("Novice" … "Professional"), from the
/// entry's `current_level`. Empty when the payload omits it.
@override@JsonKey() final  String currentLevel;
/// The entry's own `is_me`. Defaults false so the store can fall back to a
/// username / id match — see `LeaderboardNotifier.resolve`.
@override@JsonKey() final  bool isCurrentUser;

/// Create a copy of LeaderboardRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaderboardRowCopyWith<_LeaderboardRow> get copyWith => __$LeaderboardRowCopyWithImpl<_LeaderboardRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeaderboardRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeaderboardRow&&(identical(other.id, id) || other.id == id)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.username, username) || other.username == username)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.currentLevel, currentLevel) || other.currentLevel == currentLevel)&&(identical(other.isCurrentUser, isCurrentUser) || other.isCurrentUser == isCurrentUser));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rank,firstName,lastName,username,avatarUrl,xp,currentLevel,isCurrentUser);

@override
String toString() {
  return 'LeaderboardRow(id: $id, rank: $rank, firstName: $firstName, lastName: $lastName, username: $username, avatarUrl: $avatarUrl, xp: $xp, currentLevel: $currentLevel, isCurrentUser: $isCurrentUser)';
}


}

/// @nodoc
abstract mixin class _$LeaderboardRowCopyWith<$Res> implements $LeaderboardRowCopyWith<$Res> {
  factory _$LeaderboardRowCopyWith(_LeaderboardRow value, $Res Function(_LeaderboardRow) _then) = __$LeaderboardRowCopyWithImpl;
@override @useResult
$Res call({
 String id, int rank, String firstName, String lastName, String username, String? avatarUrl, int xp, String currentLevel, bool isCurrentUser
});




}
/// @nodoc
class __$LeaderboardRowCopyWithImpl<$Res>
    implements _$LeaderboardRowCopyWith<$Res> {
  __$LeaderboardRowCopyWithImpl(this._self, this._then);

  final _LeaderboardRow _self;
  final $Res Function(_LeaderboardRow) _then;

/// Create a copy of LeaderboardRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rank = null,Object? firstName = null,Object? lastName = null,Object? username = null,Object? avatarUrl = freezed,Object? xp = null,Object? currentLevel = null,Object? isCurrentUser = null,}) {
  return _then(_LeaderboardRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,currentLevel: null == currentLevel ? _self.currentLevel : currentLevel // ignore: cast_nullable_to_non_nullable
as String,isCurrentUser: null == isCurrentUser ? _self.isCurrentUser : isCurrentUser // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
