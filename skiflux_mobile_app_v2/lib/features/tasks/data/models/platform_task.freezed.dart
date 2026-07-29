// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'platform_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlatformTask {

 String get id; String get slug; String get title; String get description; String get category;/// Empty string = manual task (user submits, then claims).
 String get triggerType;/// Legacy write alias of [triggerType]; the list response returns both.
 String get actionType; String get verificationMode; int get progressTarget; int get progressCurrent; String get icon; Map<String, dynamic> get metadata; int get sortOrder; int get xpReward;@DecimalConverter() Decimal get skillcoinReward; PlatformTaskStatus get status; bool get claimable; bool get completed;/// Required in the spec's PlatformTaskUser response but absent from the
/// platform-tasks.md example payload — defaulted true (a task returned in
/// the user's list is live) so both shapes parse.
 bool get isActive;/// Flash-challenge timer, frontend-enforced — server-side expiry is not
/// implemented yet per the doc.
 int? get durationMinutes; String? get externalUrl; DateTime? get startedAt; DateTime? get claimableAt; DateTime? get claimedAt; DateTime? get completedAt;
/// Create a copy of PlatformTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlatformTaskCopyWith<PlatformTask> get copyWith => _$PlatformTaskCopyWithImpl<PlatformTask>(this as PlatformTask, _$identity);

  /// Serializes this PlatformTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlatformTask&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.triggerType, triggerType) || other.triggerType == triggerType)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.verificationMode, verificationMode) || other.verificationMode == verificationMode)&&(identical(other.progressTarget, progressTarget) || other.progressTarget == progressTarget)&&(identical(other.progressCurrent, progressCurrent) || other.progressCurrent == progressCurrent)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.skillcoinReward, skillcoinReward) || other.skillcoinReward == skillcoinReward)&&(identical(other.status, status) || other.status == status)&&(identical(other.claimable, claimable) || other.claimable == claimable)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.externalUrl, externalUrl) || other.externalUrl == externalUrl)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.claimableAt, claimableAt) || other.claimableAt == claimableAt)&&(identical(other.claimedAt, claimedAt) || other.claimedAt == claimedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,title,description,category,triggerType,actionType,verificationMode,progressTarget,progressCurrent,icon,const DeepCollectionEquality().hash(metadata),sortOrder,xpReward,skillcoinReward,status,claimable,completed,isActive,durationMinutes,externalUrl,startedAt,claimableAt,claimedAt,completedAt]);

@override
String toString() {
  return 'PlatformTask(id: $id, slug: $slug, title: $title, description: $description, category: $category, triggerType: $triggerType, actionType: $actionType, verificationMode: $verificationMode, progressTarget: $progressTarget, progressCurrent: $progressCurrent, icon: $icon, metadata: $metadata, sortOrder: $sortOrder, xpReward: $xpReward, skillcoinReward: $skillcoinReward, status: $status, claimable: $claimable, completed: $completed, isActive: $isActive, durationMinutes: $durationMinutes, externalUrl: $externalUrl, startedAt: $startedAt, claimableAt: $claimableAt, claimedAt: $claimedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $PlatformTaskCopyWith<$Res>  {
  factory $PlatformTaskCopyWith(PlatformTask value, $Res Function(PlatformTask) _then) = _$PlatformTaskCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title, String description, String category, String triggerType, String actionType, String verificationMode, int progressTarget, int progressCurrent, String icon, Map<String, dynamic> metadata, int sortOrder, int xpReward,@DecimalConverter() Decimal skillcoinReward, PlatformTaskStatus status, bool claimable, bool completed, bool isActive, int? durationMinutes, String? externalUrl, DateTime? startedAt, DateTime? claimableAt, DateTime? claimedAt, DateTime? completedAt
});




}
/// @nodoc
class _$PlatformTaskCopyWithImpl<$Res>
    implements $PlatformTaskCopyWith<$Res> {
  _$PlatformTaskCopyWithImpl(this._self, this._then);

  final PlatformTask _self;
  final $Res Function(PlatformTask) _then;

/// Create a copy of PlatformTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? description = null,Object? category = null,Object? triggerType = null,Object? actionType = null,Object? verificationMode = null,Object? progressTarget = null,Object? progressCurrent = null,Object? icon = null,Object? metadata = null,Object? sortOrder = null,Object? xpReward = null,Object? skillcoinReward = null,Object? status = null,Object? claimable = null,Object? completed = null,Object? isActive = null,Object? durationMinutes = freezed,Object? externalUrl = freezed,Object? startedAt = freezed,Object? claimableAt = freezed,Object? claimedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,triggerType: null == triggerType ? _self.triggerType : triggerType // ignore: cast_nullable_to_non_nullable
as String,actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as String,verificationMode: null == verificationMode ? _self.verificationMode : verificationMode // ignore: cast_nullable_to_non_nullable
as String,progressTarget: null == progressTarget ? _self.progressTarget : progressTarget // ignore: cast_nullable_to_non_nullable
as int,progressCurrent: null == progressCurrent ? _self.progressCurrent : progressCurrent // ignore: cast_nullable_to_non_nullable
as int,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,skillcoinReward: null == skillcoinReward ? _self.skillcoinReward : skillcoinReward // ignore: cast_nullable_to_non_nullable
as Decimal,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlatformTaskStatus,claimable: null == claimable ? _self.claimable : claimable // ignore: cast_nullable_to_non_nullable
as bool,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,externalUrl: freezed == externalUrl ? _self.externalUrl : externalUrl // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,claimableAt: freezed == claimableAt ? _self.claimableAt : claimableAt // ignore: cast_nullable_to_non_nullable
as DateTime?,claimedAt: freezed == claimedAt ? _self.claimedAt : claimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlatformTask].
extension PlatformTaskPatterns on PlatformTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlatformTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlatformTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlatformTask value)  $default,){
final _that = this;
switch (_that) {
case _PlatformTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlatformTask value)?  $default,){
final _that = this;
switch (_that) {
case _PlatformTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String description,  String category,  String triggerType,  String actionType,  String verificationMode,  int progressTarget,  int progressCurrent,  String icon,  Map<String, dynamic> metadata,  int sortOrder,  int xpReward, @DecimalConverter()  Decimal skillcoinReward,  PlatformTaskStatus status,  bool claimable,  bool completed,  bool isActive,  int? durationMinutes,  String? externalUrl,  DateTime? startedAt,  DateTime? claimableAt,  DateTime? claimedAt,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlatformTask() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.description,_that.category,_that.triggerType,_that.actionType,_that.verificationMode,_that.progressTarget,_that.progressCurrent,_that.icon,_that.metadata,_that.sortOrder,_that.xpReward,_that.skillcoinReward,_that.status,_that.claimable,_that.completed,_that.isActive,_that.durationMinutes,_that.externalUrl,_that.startedAt,_that.claimableAt,_that.claimedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String description,  String category,  String triggerType,  String actionType,  String verificationMode,  int progressTarget,  int progressCurrent,  String icon,  Map<String, dynamic> metadata,  int sortOrder,  int xpReward, @DecimalConverter()  Decimal skillcoinReward,  PlatformTaskStatus status,  bool claimable,  bool completed,  bool isActive,  int? durationMinutes,  String? externalUrl,  DateTime? startedAt,  DateTime? claimableAt,  DateTime? claimedAt,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _PlatformTask():
return $default(_that.id,_that.slug,_that.title,_that.description,_that.category,_that.triggerType,_that.actionType,_that.verificationMode,_that.progressTarget,_that.progressCurrent,_that.icon,_that.metadata,_that.sortOrder,_that.xpReward,_that.skillcoinReward,_that.status,_that.claimable,_that.completed,_that.isActive,_that.durationMinutes,_that.externalUrl,_that.startedAt,_that.claimableAt,_that.claimedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String title,  String description,  String category,  String triggerType,  String actionType,  String verificationMode,  int progressTarget,  int progressCurrent,  String icon,  Map<String, dynamic> metadata,  int sortOrder,  int xpReward, @DecimalConverter()  Decimal skillcoinReward,  PlatformTaskStatus status,  bool claimable,  bool completed,  bool isActive,  int? durationMinutes,  String? externalUrl,  DateTime? startedAt,  DateTime? claimableAt,  DateTime? claimedAt,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlatformTask() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.description,_that.category,_that.triggerType,_that.actionType,_that.verificationMode,_that.progressTarget,_that.progressCurrent,_that.icon,_that.metadata,_that.sortOrder,_that.xpReward,_that.skillcoinReward,_that.status,_that.claimable,_that.completed,_that.isActive,_that.durationMinutes,_that.externalUrl,_that.startedAt,_that.claimableAt,_that.claimedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlatformTask implements PlatformTask {
  const _PlatformTask({required this.id, required this.slug, required this.title, required this.description, required this.category, required this.triggerType, required this.actionType, required this.verificationMode, required this.progressTarget, required this.progressCurrent, required this.icon, required final  Map<String, dynamic> metadata, required this.sortOrder, required this.xpReward, @DecimalConverter() required this.skillcoinReward, required this.status, required this.claimable, required this.completed, this.isActive = true, this.durationMinutes, this.externalUrl, this.startedAt, this.claimableAt, this.claimedAt, this.completedAt}): _metadata = metadata;
  factory _PlatformTask.fromJson(Map<String, dynamic> json) => _$PlatformTaskFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String title;
@override final  String description;
@override final  String category;
/// Empty string = manual task (user submits, then claims).
@override final  String triggerType;
/// Legacy write alias of [triggerType]; the list response returns both.
@override final  String actionType;
@override final  String verificationMode;
@override final  int progressTarget;
@override final  int progressCurrent;
@override final  String icon;
 final  Map<String, dynamic> _metadata;
@override Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override final  int sortOrder;
@override final  int xpReward;
@override@DecimalConverter() final  Decimal skillcoinReward;
@override final  PlatformTaskStatus status;
@override final  bool claimable;
@override final  bool completed;
/// Required in the spec's PlatformTaskUser response but absent from the
/// platform-tasks.md example payload — defaulted true (a task returned in
/// the user's list is live) so both shapes parse.
@override@JsonKey() final  bool isActive;
/// Flash-challenge timer, frontend-enforced — server-side expiry is not
/// implemented yet per the doc.
@override final  int? durationMinutes;
@override final  String? externalUrl;
@override final  DateTime? startedAt;
@override final  DateTime? claimableAt;
@override final  DateTime? claimedAt;
@override final  DateTime? completedAt;

/// Create a copy of PlatformTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlatformTaskCopyWith<_PlatformTask> get copyWith => __$PlatformTaskCopyWithImpl<_PlatformTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlatformTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlatformTask&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.triggerType, triggerType) || other.triggerType == triggerType)&&(identical(other.actionType, actionType) || other.actionType == actionType)&&(identical(other.verificationMode, verificationMode) || other.verificationMode == verificationMode)&&(identical(other.progressTarget, progressTarget) || other.progressTarget == progressTarget)&&(identical(other.progressCurrent, progressCurrent) || other.progressCurrent == progressCurrent)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.skillcoinReward, skillcoinReward) || other.skillcoinReward == skillcoinReward)&&(identical(other.status, status) || other.status == status)&&(identical(other.claimable, claimable) || other.claimable == claimable)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.externalUrl, externalUrl) || other.externalUrl == externalUrl)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.claimableAt, claimableAt) || other.claimableAt == claimableAt)&&(identical(other.claimedAt, claimedAt) || other.claimedAt == claimedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,slug,title,description,category,triggerType,actionType,verificationMode,progressTarget,progressCurrent,icon,const DeepCollectionEquality().hash(_metadata),sortOrder,xpReward,skillcoinReward,status,claimable,completed,isActive,durationMinutes,externalUrl,startedAt,claimableAt,claimedAt,completedAt]);

@override
String toString() {
  return 'PlatformTask(id: $id, slug: $slug, title: $title, description: $description, category: $category, triggerType: $triggerType, actionType: $actionType, verificationMode: $verificationMode, progressTarget: $progressTarget, progressCurrent: $progressCurrent, icon: $icon, metadata: $metadata, sortOrder: $sortOrder, xpReward: $xpReward, skillcoinReward: $skillcoinReward, status: $status, claimable: $claimable, completed: $completed, isActive: $isActive, durationMinutes: $durationMinutes, externalUrl: $externalUrl, startedAt: $startedAt, claimableAt: $claimableAt, claimedAt: $claimedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$PlatformTaskCopyWith<$Res> implements $PlatformTaskCopyWith<$Res> {
  factory _$PlatformTaskCopyWith(_PlatformTask value, $Res Function(_PlatformTask) _then) = __$PlatformTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title, String description, String category, String triggerType, String actionType, String verificationMode, int progressTarget, int progressCurrent, String icon, Map<String, dynamic> metadata, int sortOrder, int xpReward,@DecimalConverter() Decimal skillcoinReward, PlatformTaskStatus status, bool claimable, bool completed, bool isActive, int? durationMinutes, String? externalUrl, DateTime? startedAt, DateTime? claimableAt, DateTime? claimedAt, DateTime? completedAt
});




}
/// @nodoc
class __$PlatformTaskCopyWithImpl<$Res>
    implements _$PlatformTaskCopyWith<$Res> {
  __$PlatformTaskCopyWithImpl(this._self, this._then);

  final _PlatformTask _self;
  final $Res Function(_PlatformTask) _then;

/// Create a copy of PlatformTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? description = null,Object? category = null,Object? triggerType = null,Object? actionType = null,Object? verificationMode = null,Object? progressTarget = null,Object? progressCurrent = null,Object? icon = null,Object? metadata = null,Object? sortOrder = null,Object? xpReward = null,Object? skillcoinReward = null,Object? status = null,Object? claimable = null,Object? completed = null,Object? isActive = null,Object? durationMinutes = freezed,Object? externalUrl = freezed,Object? startedAt = freezed,Object? claimableAt = freezed,Object? claimedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_PlatformTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,triggerType: null == triggerType ? _self.triggerType : triggerType // ignore: cast_nullable_to_non_nullable
as String,actionType: null == actionType ? _self.actionType : actionType // ignore: cast_nullable_to_non_nullable
as String,verificationMode: null == verificationMode ? _self.verificationMode : verificationMode // ignore: cast_nullable_to_non_nullable
as String,progressTarget: null == progressTarget ? _self.progressTarget : progressTarget // ignore: cast_nullable_to_non_nullable
as int,progressCurrent: null == progressCurrent ? _self.progressCurrent : progressCurrent // ignore: cast_nullable_to_non_nullable
as int,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,skillcoinReward: null == skillcoinReward ? _self.skillcoinReward : skillcoinReward // ignore: cast_nullable_to_non_nullable
as Decimal,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlatformTaskStatus,claimable: null == claimable ? _self.claimable : claimable // ignore: cast_nullable_to_non_nullable
as bool,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,externalUrl: freezed == externalUrl ? _self.externalUrl : externalUrl // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,claimableAt: freezed == claimableAt ? _self.claimableAt : claimableAt // ignore: cast_nullable_to_non_nullable
as DateTime?,claimedAt: freezed == claimedAt ? _self.claimedAt : claimedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
