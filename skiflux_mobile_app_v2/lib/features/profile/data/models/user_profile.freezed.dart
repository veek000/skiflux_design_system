// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

 String get id; String get firstName; String get lastName; String get email; String get username; String get bio; String get country; String get phone; String? get avatarUrl; List<String> get goal; List<String> get skillworld; String get status;@DecimalConverter() Decimal? get balance;@DecimalConverter() Decimal? get bonusBalance; int get xp; String get currentLevel; int get streakCount; int? get rank; int get taskDone; int get episodeCompleted; bool get biometricsEnabled;@JsonKey(name: 'is_onboarded') bool get isOnboarded;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.username, username) || other.username == username)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.country, country) || other.country == country)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other.goal, goal)&&const DeepCollectionEquality().equals(other.skillworld, skillworld)&&(identical(other.status, status) || other.status == status)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.bonusBalance, bonusBalance) || other.bonusBalance == bonusBalance)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.currentLevel, currentLevel) || other.currentLevel == currentLevel)&&(identical(other.streakCount, streakCount) || other.streakCount == streakCount)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.taskDone, taskDone) || other.taskDone == taskDone)&&(identical(other.episodeCompleted, episodeCompleted) || other.episodeCompleted == episodeCompleted)&&(identical(other.biometricsEnabled, biometricsEnabled) || other.biometricsEnabled == biometricsEnabled)&&(identical(other.isOnboarded, isOnboarded) || other.isOnboarded == isOnboarded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,firstName,lastName,email,username,bio,country,phone,avatarUrl,const DeepCollectionEquality().hash(goal),const DeepCollectionEquality().hash(skillworld),status,balance,bonusBalance,xp,currentLevel,streakCount,rank,taskDone,episodeCompleted,biometricsEnabled,isOnboarded]);

@override
String toString() {
  return 'UserProfile(id: $id, firstName: $firstName, lastName: $lastName, email: $email, username: $username, bio: $bio, country: $country, phone: $phone, avatarUrl: $avatarUrl, goal: $goal, skillworld: $skillworld, status: $status, balance: $balance, bonusBalance: $bonusBalance, xp: $xp, currentLevel: $currentLevel, streakCount: $streakCount, rank: $rank, taskDone: $taskDone, episodeCompleted: $episodeCompleted, biometricsEnabled: $biometricsEnabled, isOnboarded: $isOnboarded)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String id, String firstName, String lastName, String email, String username, String bio, String country, String phone, String? avatarUrl, List<String> goal, List<String> skillworld, String status,@DecimalConverter() Decimal? balance,@DecimalConverter() Decimal? bonusBalance, int xp, String currentLevel, int streakCount, int? rank, int taskDone, int episodeCompleted, bool biometricsEnabled,@JsonKey(name: 'is_onboarded') bool isOnboarded
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? username = null,Object? bio = null,Object? country = null,Object? phone = null,Object? avatarUrl = freezed,Object? goal = null,Object? skillworld = null,Object? status = null,Object? balance = freezed,Object? bonusBalance = freezed,Object? xp = null,Object? currentLevel = null,Object? streakCount = null,Object? rank = freezed,Object? taskDone = null,Object? episodeCompleted = null,Object? biometricsEnabled = null,Object? isOnboarded = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as List<String>,skillworld: null == skillworld ? _self.skillworld : skillworld // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Decimal?,bonusBalance: freezed == bonusBalance ? _self.bonusBalance : bonusBalance // ignore: cast_nullable_to_non_nullable
as Decimal?,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,currentLevel: null == currentLevel ? _self.currentLevel : currentLevel // ignore: cast_nullable_to_non_nullable
as String,streakCount: null == streakCount ? _self.streakCount : streakCount // ignore: cast_nullable_to_non_nullable
as int,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,taskDone: null == taskDone ? _self.taskDone : taskDone // ignore: cast_nullable_to_non_nullable
as int,episodeCompleted: null == episodeCompleted ? _self.episodeCompleted : episodeCompleted // ignore: cast_nullable_to_non_nullable
as int,biometricsEnabled: null == biometricsEnabled ? _self.biometricsEnabled : biometricsEnabled // ignore: cast_nullable_to_non_nullable
as bool,isOnboarded: null == isOnboarded ? _self.isOnboarded : isOnboarded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName,  String email,  String username,  String bio,  String country,  String phone,  String? avatarUrl,  List<String> goal,  List<String> skillworld,  String status, @DecimalConverter()  Decimal? balance, @DecimalConverter()  Decimal? bonusBalance,  int xp,  String currentLevel,  int streakCount,  int? rank,  int taskDone,  int episodeCompleted,  bool biometricsEnabled, @JsonKey(name: 'is_onboarded')  bool isOnboarded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.username,_that.bio,_that.country,_that.phone,_that.avatarUrl,_that.goal,_that.skillworld,_that.status,_that.balance,_that.bonusBalance,_that.xp,_that.currentLevel,_that.streakCount,_that.rank,_that.taskDone,_that.episodeCompleted,_that.biometricsEnabled,_that.isOnboarded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String firstName,  String lastName,  String email,  String username,  String bio,  String country,  String phone,  String? avatarUrl,  List<String> goal,  List<String> skillworld,  String status, @DecimalConverter()  Decimal? balance, @DecimalConverter()  Decimal? bonusBalance,  int xp,  String currentLevel,  int streakCount,  int? rank,  int taskDone,  int episodeCompleted,  bool biometricsEnabled, @JsonKey(name: 'is_onboarded')  bool isOnboarded)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.username,_that.bio,_that.country,_that.phone,_that.avatarUrl,_that.goal,_that.skillworld,_that.status,_that.balance,_that.bonusBalance,_that.xp,_that.currentLevel,_that.streakCount,_that.rank,_that.taskDone,_that.episodeCompleted,_that.biometricsEnabled,_that.isOnboarded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String firstName,  String lastName,  String email,  String username,  String bio,  String country,  String phone,  String? avatarUrl,  List<String> goal,  List<String> skillworld,  String status, @DecimalConverter()  Decimal? balance, @DecimalConverter()  Decimal? bonusBalance,  int xp,  String currentLevel,  int streakCount,  int? rank,  int taskDone,  int episodeCompleted,  bool biometricsEnabled, @JsonKey(name: 'is_onboarded')  bool isOnboarded)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.firstName,_that.lastName,_that.email,_that.username,_that.bio,_that.country,_that.phone,_that.avatarUrl,_that.goal,_that.skillworld,_that.status,_that.balance,_that.bonusBalance,_that.xp,_that.currentLevel,_that.streakCount,_that.rank,_that.taskDone,_that.episodeCompleted,_that.biometricsEnabled,_that.isOnboarded);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile extends UserProfile {
  const _UserProfile({required this.id, this.firstName = '', this.lastName = '', this.email = '', this.username = '', this.bio = '', this.country = '', this.phone = '', this.avatarUrl, final  List<String> goal = const [], final  List<String> skillworld = const [], this.status = '', @DecimalConverter() this.balance, @DecimalConverter() this.bonusBalance, this.xp = 0, this.currentLevel = '', this.streakCount = 0, this.rank, this.taskDone = 0, this.episodeCompleted = 0, this.biometricsEnabled = false, @JsonKey(name: 'is_onboarded') this.isOnboarded = true}): _goal = goal,_skillworld = skillworld,super._();
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  String id;
@override@JsonKey() final  String firstName;
@override@JsonKey() final  String lastName;
@override@JsonKey() final  String email;
@override@JsonKey() final  String username;
@override@JsonKey() final  String bio;
@override@JsonKey() final  String country;
@override@JsonKey() final  String phone;
@override final  String? avatarUrl;
 final  List<String> _goal;
@override@JsonKey() List<String> get goal {
  if (_goal is EqualUnmodifiableListView) return _goal;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_goal);
}

 final  List<String> _skillworld;
@override@JsonKey() List<String> get skillworld {
  if (_skillworld is EqualUnmodifiableListView) return _skillworld;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skillworld);
}

@override@JsonKey() final  String status;
@override@DecimalConverter() final  Decimal? balance;
@override@DecimalConverter() final  Decimal? bonusBalance;
@override@JsonKey() final  int xp;
@override@JsonKey() final  String currentLevel;
@override@JsonKey() final  int streakCount;
@override final  int? rank;
@override@JsonKey() final  int taskDone;
@override@JsonKey() final  int episodeCompleted;
@override@JsonKey() final  bool biometricsEnabled;
@override@JsonKey(name: 'is_onboarded') final  bool isOnboarded;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.email, email) || other.email == email)&&(identical(other.username, username) || other.username == username)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.country, country) || other.country == country)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&const DeepCollectionEquality().equals(other._goal, _goal)&&const DeepCollectionEquality().equals(other._skillworld, _skillworld)&&(identical(other.status, status) || other.status == status)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.bonusBalance, bonusBalance) || other.bonusBalance == bonusBalance)&&(identical(other.xp, xp) || other.xp == xp)&&(identical(other.currentLevel, currentLevel) || other.currentLevel == currentLevel)&&(identical(other.streakCount, streakCount) || other.streakCount == streakCount)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.taskDone, taskDone) || other.taskDone == taskDone)&&(identical(other.episodeCompleted, episodeCompleted) || other.episodeCompleted == episodeCompleted)&&(identical(other.biometricsEnabled, biometricsEnabled) || other.biometricsEnabled == biometricsEnabled)&&(identical(other.isOnboarded, isOnboarded) || other.isOnboarded == isOnboarded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,firstName,lastName,email,username,bio,country,phone,avatarUrl,const DeepCollectionEquality().hash(_goal),const DeepCollectionEquality().hash(_skillworld),status,balance,bonusBalance,xp,currentLevel,streakCount,rank,taskDone,episodeCompleted,biometricsEnabled,isOnboarded]);

@override
String toString() {
  return 'UserProfile(id: $id, firstName: $firstName, lastName: $lastName, email: $email, username: $username, bio: $bio, country: $country, phone: $phone, avatarUrl: $avatarUrl, goal: $goal, skillworld: $skillworld, status: $status, balance: $balance, bonusBalance: $bonusBalance, xp: $xp, currentLevel: $currentLevel, streakCount: $streakCount, rank: $rank, taskDone: $taskDone, episodeCompleted: $episodeCompleted, biometricsEnabled: $biometricsEnabled, isOnboarded: $isOnboarded)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String firstName, String lastName, String email, String username, String bio, String country, String phone, String? avatarUrl, List<String> goal, List<String> skillworld, String status,@DecimalConverter() Decimal? balance,@DecimalConverter() Decimal? bonusBalance, int xp, String currentLevel, int streakCount, int? rank, int taskDone, int episodeCompleted, bool biometricsEnabled,@JsonKey(name: 'is_onboarded') bool isOnboarded
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? firstName = null,Object? lastName = null,Object? email = null,Object? username = null,Object? bio = null,Object? country = null,Object? phone = null,Object? avatarUrl = freezed,Object? goal = null,Object? skillworld = null,Object? status = null,Object? balance = freezed,Object? bonusBalance = freezed,Object? xp = null,Object? currentLevel = null,Object? streakCount = null,Object? rank = freezed,Object? taskDone = null,Object? episodeCompleted = null,Object? biometricsEnabled = null,Object? isOnboarded = null,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,goal: null == goal ? _self._goal : goal // ignore: cast_nullable_to_non_nullable
as List<String>,skillworld: null == skillworld ? _self._skillworld : skillworld // ignore: cast_nullable_to_non_nullable
as List<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as Decimal?,bonusBalance: freezed == bonusBalance ? _self.bonusBalance : bonusBalance // ignore: cast_nullable_to_non_nullable
as Decimal?,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,currentLevel: null == currentLevel ? _self.currentLevel : currentLevel // ignore: cast_nullable_to_non_nullable
as String,streakCount: null == streakCount ? _self.streakCount : streakCount // ignore: cast_nullable_to_non_nullable
as int,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,taskDone: null == taskDone ? _self.taskDone : taskDone // ignore: cast_nullable_to_non_nullable
as int,episodeCompleted: null == episodeCompleted ? _self.episodeCompleted : episodeCompleted // ignore: cast_nullable_to_non_nullable
as int,biometricsEnabled: null == biometricsEnabled ? _self.biometricsEnabled : biometricsEnabled // ignore: cast_nullable_to_non_nullable
as bool,isOnboarded: null == isOnboarded ? _self.isOnboarded : isOnboarded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
