// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'streak_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StreakSummary {

 int get currentStreakCount; bool get isStreakActive; int get bestStreak; int get totalStreakXpEarned; StreakWeek get week; StreakMilestone get milestone;
/// Create a copy of StreakSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreakSummaryCopyWith<StreakSummary> get copyWith => _$StreakSummaryCopyWithImpl<StreakSummary>(this as StreakSummary, _$identity);

  /// Serializes this StreakSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreakSummary&&(identical(other.currentStreakCount, currentStreakCount) || other.currentStreakCount == currentStreakCount)&&(identical(other.isStreakActive, isStreakActive) || other.isStreakActive == isStreakActive)&&(identical(other.bestStreak, bestStreak) || other.bestStreak == bestStreak)&&(identical(other.totalStreakXpEarned, totalStreakXpEarned) || other.totalStreakXpEarned == totalStreakXpEarned)&&(identical(other.week, week) || other.week == week)&&(identical(other.milestone, milestone) || other.milestone == milestone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentStreakCount,isStreakActive,bestStreak,totalStreakXpEarned,week,milestone);

@override
String toString() {
  return 'StreakSummary(currentStreakCount: $currentStreakCount, isStreakActive: $isStreakActive, bestStreak: $bestStreak, totalStreakXpEarned: $totalStreakXpEarned, week: $week, milestone: $milestone)';
}


}

/// @nodoc
abstract mixin class $StreakSummaryCopyWith<$Res>  {
  factory $StreakSummaryCopyWith(StreakSummary value, $Res Function(StreakSummary) _then) = _$StreakSummaryCopyWithImpl;
@useResult
$Res call({
 int currentStreakCount, bool isStreakActive, int bestStreak, int totalStreakXpEarned, StreakWeek week, StreakMilestone milestone
});


$StreakWeekCopyWith<$Res> get week;$StreakMilestoneCopyWith<$Res> get milestone;

}
/// @nodoc
class _$StreakSummaryCopyWithImpl<$Res>
    implements $StreakSummaryCopyWith<$Res> {
  _$StreakSummaryCopyWithImpl(this._self, this._then);

  final StreakSummary _self;
  final $Res Function(StreakSummary) _then;

/// Create a copy of StreakSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStreakCount = null,Object? isStreakActive = null,Object? bestStreak = null,Object? totalStreakXpEarned = null,Object? week = null,Object? milestone = null,}) {
  return _then(_self.copyWith(
currentStreakCount: null == currentStreakCount ? _self.currentStreakCount : currentStreakCount // ignore: cast_nullable_to_non_nullable
as int,isStreakActive: null == isStreakActive ? _self.isStreakActive : isStreakActive // ignore: cast_nullable_to_non_nullable
as bool,bestStreak: null == bestStreak ? _self.bestStreak : bestStreak // ignore: cast_nullable_to_non_nullable
as int,totalStreakXpEarned: null == totalStreakXpEarned ? _self.totalStreakXpEarned : totalStreakXpEarned // ignore: cast_nullable_to_non_nullable
as int,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as StreakWeek,milestone: null == milestone ? _self.milestone : milestone // ignore: cast_nullable_to_non_nullable
as StreakMilestone,
  ));
}
/// Create a copy of StreakSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreakWeekCopyWith<$Res> get week {
  
  return $StreakWeekCopyWith<$Res>(_self.week, (value) {
    return _then(_self.copyWith(week: value));
  });
}/// Create a copy of StreakSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreakMilestoneCopyWith<$Res> get milestone {
  
  return $StreakMilestoneCopyWith<$Res>(_self.milestone, (value) {
    return _then(_self.copyWith(milestone: value));
  });
}
}


/// Adds pattern-matching-related methods to [StreakSummary].
extension StreakSummaryPatterns on StreakSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreakSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreakSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreakSummary value)  $default,){
final _that = this;
switch (_that) {
case _StreakSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreakSummary value)?  $default,){
final _that = this;
switch (_that) {
case _StreakSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentStreakCount,  bool isStreakActive,  int bestStreak,  int totalStreakXpEarned,  StreakWeek week,  StreakMilestone milestone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreakSummary() when $default != null:
return $default(_that.currentStreakCount,_that.isStreakActive,_that.bestStreak,_that.totalStreakXpEarned,_that.week,_that.milestone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentStreakCount,  bool isStreakActive,  int bestStreak,  int totalStreakXpEarned,  StreakWeek week,  StreakMilestone milestone)  $default,) {final _that = this;
switch (_that) {
case _StreakSummary():
return $default(_that.currentStreakCount,_that.isStreakActive,_that.bestStreak,_that.totalStreakXpEarned,_that.week,_that.milestone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentStreakCount,  bool isStreakActive,  int bestStreak,  int totalStreakXpEarned,  StreakWeek week,  StreakMilestone milestone)?  $default,) {final _that = this;
switch (_that) {
case _StreakSummary() when $default != null:
return $default(_that.currentStreakCount,_that.isStreakActive,_that.bestStreak,_that.totalStreakXpEarned,_that.week,_that.milestone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreakSummary implements StreakSummary {
  const _StreakSummary({required this.currentStreakCount, required this.isStreakActive, required this.bestStreak, required this.totalStreakXpEarned, required this.week, required this.milestone});
  factory _StreakSummary.fromJson(Map<String, dynamic> json) => _$StreakSummaryFromJson(json);

@override final  int currentStreakCount;
@override final  bool isStreakActive;
@override final  int bestStreak;
@override final  int totalStreakXpEarned;
@override final  StreakWeek week;
@override final  StreakMilestone milestone;

/// Create a copy of StreakSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreakSummaryCopyWith<_StreakSummary> get copyWith => __$StreakSummaryCopyWithImpl<_StreakSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreakSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreakSummary&&(identical(other.currentStreakCount, currentStreakCount) || other.currentStreakCount == currentStreakCount)&&(identical(other.isStreakActive, isStreakActive) || other.isStreakActive == isStreakActive)&&(identical(other.bestStreak, bestStreak) || other.bestStreak == bestStreak)&&(identical(other.totalStreakXpEarned, totalStreakXpEarned) || other.totalStreakXpEarned == totalStreakXpEarned)&&(identical(other.week, week) || other.week == week)&&(identical(other.milestone, milestone) || other.milestone == milestone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentStreakCount,isStreakActive,bestStreak,totalStreakXpEarned,week,milestone);

@override
String toString() {
  return 'StreakSummary(currentStreakCount: $currentStreakCount, isStreakActive: $isStreakActive, bestStreak: $bestStreak, totalStreakXpEarned: $totalStreakXpEarned, week: $week, milestone: $milestone)';
}


}

/// @nodoc
abstract mixin class _$StreakSummaryCopyWith<$Res> implements $StreakSummaryCopyWith<$Res> {
  factory _$StreakSummaryCopyWith(_StreakSummary value, $Res Function(_StreakSummary) _then) = __$StreakSummaryCopyWithImpl;
@override @useResult
$Res call({
 int currentStreakCount, bool isStreakActive, int bestStreak, int totalStreakXpEarned, StreakWeek week, StreakMilestone milestone
});


@override $StreakWeekCopyWith<$Res> get week;@override $StreakMilestoneCopyWith<$Res> get milestone;

}
/// @nodoc
class __$StreakSummaryCopyWithImpl<$Res>
    implements _$StreakSummaryCopyWith<$Res> {
  __$StreakSummaryCopyWithImpl(this._self, this._then);

  final _StreakSummary _self;
  final $Res Function(_StreakSummary) _then;

/// Create a copy of StreakSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStreakCount = null,Object? isStreakActive = null,Object? bestStreak = null,Object? totalStreakXpEarned = null,Object? week = null,Object? milestone = null,}) {
  return _then(_StreakSummary(
currentStreakCount: null == currentStreakCount ? _self.currentStreakCount : currentStreakCount // ignore: cast_nullable_to_non_nullable
as int,isStreakActive: null == isStreakActive ? _self.isStreakActive : isStreakActive // ignore: cast_nullable_to_non_nullable
as bool,bestStreak: null == bestStreak ? _self.bestStreak : bestStreak // ignore: cast_nullable_to_non_nullable
as int,totalStreakXpEarned: null == totalStreakXpEarned ? _self.totalStreakXpEarned : totalStreakXpEarned // ignore: cast_nullable_to_non_nullable
as int,week: null == week ? _self.week : week // ignore: cast_nullable_to_non_nullable
as StreakWeek,milestone: null == milestone ? _self.milestone : milestone // ignore: cast_nullable_to_non_nullable
as StreakMilestone,
  ));
}

/// Create a copy of StreakSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreakWeekCopyWith<$Res> get week {
  
  return $StreakWeekCopyWith<$Res>(_self.week, (value) {
    return _then(_self.copyWith(week: value));
  });
}/// Create a copy of StreakSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StreakMilestoneCopyWith<$Res> get milestone {
  
  return $StreakMilestoneCopyWith<$Res>(_self.milestone, (value) {
    return _then(_self.copyWith(milestone: value));
  });
}
}


/// @nodoc
mixin _$StreakWeek {

 DateTime get startDate; DateTime get endDate;/// Server-rendered range label ("May 20th - 27th"). Preferred over the
/// client's own formatting so the two never disagree.
 String get label; List<StreakWeekDay> get days;
/// Create a copy of StreakWeek
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreakWeekCopyWith<StreakWeek> get copyWith => _$StreakWeekCopyWithImpl<StreakWeek>(this as StreakWeek, _$identity);

  /// Serializes this StreakWeek to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreakWeek&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other.days, days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startDate,endDate,label,const DeepCollectionEquality().hash(days));

@override
String toString() {
  return 'StreakWeek(startDate: $startDate, endDate: $endDate, label: $label, days: $days)';
}


}

/// @nodoc
abstract mixin class $StreakWeekCopyWith<$Res>  {
  factory $StreakWeekCopyWith(StreakWeek value, $Res Function(StreakWeek) _then) = _$StreakWeekCopyWithImpl;
@useResult
$Res call({
 DateTime startDate, DateTime endDate, String label, List<StreakWeekDay> days
});




}
/// @nodoc
class _$StreakWeekCopyWithImpl<$Res>
    implements $StreakWeekCopyWith<$Res> {
  _$StreakWeekCopyWithImpl(this._self, this._then);

  final StreakWeek _self;
  final $Res Function(StreakWeek) _then;

/// Create a copy of StreakWeek
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = null,Object? endDate = null,Object? label = null,Object? days = null,}) {
  return _then(_self.copyWith(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<StreakWeekDay>,
  ));
}

}


/// Adds pattern-matching-related methods to [StreakWeek].
extension StreakWeekPatterns on StreakWeek {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreakWeek value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreakWeek() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreakWeek value)  $default,){
final _that = this;
switch (_that) {
case _StreakWeek():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreakWeek value)?  $default,){
final _that = this;
switch (_that) {
case _StreakWeek() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime startDate,  DateTime endDate,  String label,  List<StreakWeekDay> days)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreakWeek() when $default != null:
return $default(_that.startDate,_that.endDate,_that.label,_that.days);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime startDate,  DateTime endDate,  String label,  List<StreakWeekDay> days)  $default,) {final _that = this;
switch (_that) {
case _StreakWeek():
return $default(_that.startDate,_that.endDate,_that.label,_that.days);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime startDate,  DateTime endDate,  String label,  List<StreakWeekDay> days)?  $default,) {final _that = this;
switch (_that) {
case _StreakWeek() when $default != null:
return $default(_that.startDate,_that.endDate,_that.label,_that.days);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreakWeek implements StreakWeek {
  const _StreakWeek({required this.startDate, required this.endDate, required this.label, required final  List<StreakWeekDay> days}): _days = days;
  factory _StreakWeek.fromJson(Map<String, dynamic> json) => _$StreakWeekFromJson(json);

@override final  DateTime startDate;
@override final  DateTime endDate;
/// Server-rendered range label ("May 20th - 27th"). Preferred over the
/// client's own formatting so the two never disagree.
@override final  String label;
 final  List<StreakWeekDay> _days;
@override List<StreakWeekDay> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}


/// Create a copy of StreakWeek
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreakWeekCopyWith<_StreakWeek> get copyWith => __$StreakWeekCopyWithImpl<_StreakWeek>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreakWeekToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreakWeek&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.label, label) || other.label == label)&&const DeepCollectionEquality().equals(other._days, _days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startDate,endDate,label,const DeepCollectionEquality().hash(_days));

@override
String toString() {
  return 'StreakWeek(startDate: $startDate, endDate: $endDate, label: $label, days: $days)';
}


}

/// @nodoc
abstract mixin class _$StreakWeekCopyWith<$Res> implements $StreakWeekCopyWith<$Res> {
  factory _$StreakWeekCopyWith(_StreakWeek value, $Res Function(_StreakWeek) _then) = __$StreakWeekCopyWithImpl;
@override @useResult
$Res call({
 DateTime startDate, DateTime endDate, String label, List<StreakWeekDay> days
});




}
/// @nodoc
class __$StreakWeekCopyWithImpl<$Res>
    implements _$StreakWeekCopyWith<$Res> {
  __$StreakWeekCopyWithImpl(this._self, this._then);

  final _StreakWeek _self;
  final $Res Function(_StreakWeek) _then;

/// Create a copy of StreakWeek
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? endDate = null,Object? label = null,Object? days = null,}) {
  return _then(_StreakWeek(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<StreakWeekDay>,
  ));
}


}


/// @nodoc
mixin _$StreakWeekDay {

/// Short weekday name ("Sun" … "Sat").
 String get weekday; DateTime get date; int get dayOfMonth; StreakWeekDayStatus get status;
/// Create a copy of StreakWeekDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreakWeekDayCopyWith<StreakWeekDay> get copyWith => _$StreakWeekDayCopyWithImpl<StreakWeekDay>(this as StreakWeekDay, _$identity);

  /// Serializes this StreakWeekDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreakWeekDay&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.date, date) || other.date == date)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekday,date,dayOfMonth,status);

@override
String toString() {
  return 'StreakWeekDay(weekday: $weekday, date: $date, dayOfMonth: $dayOfMonth, status: $status)';
}


}

/// @nodoc
abstract mixin class $StreakWeekDayCopyWith<$Res>  {
  factory $StreakWeekDayCopyWith(StreakWeekDay value, $Res Function(StreakWeekDay) _then) = _$StreakWeekDayCopyWithImpl;
@useResult
$Res call({
 String weekday, DateTime date, int dayOfMonth, StreakWeekDayStatus status
});




}
/// @nodoc
class _$StreakWeekDayCopyWithImpl<$Res>
    implements $StreakWeekDayCopyWith<$Res> {
  _$StreakWeekDayCopyWithImpl(this._self, this._then);

  final StreakWeekDay _self;
  final $Res Function(StreakWeekDay) _then;

/// Create a copy of StreakWeekDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weekday = null,Object? date = null,Object? dayOfMonth = null,Object? status = null,}) {
  return _then(_self.copyWith(
weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,dayOfMonth: null == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StreakWeekDayStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [StreakWeekDay].
extension StreakWeekDayPatterns on StreakWeekDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreakWeekDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreakWeekDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreakWeekDay value)  $default,){
final _that = this;
switch (_that) {
case _StreakWeekDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreakWeekDay value)?  $default,){
final _that = this;
switch (_that) {
case _StreakWeekDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String weekday,  DateTime date,  int dayOfMonth,  StreakWeekDayStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreakWeekDay() when $default != null:
return $default(_that.weekday,_that.date,_that.dayOfMonth,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String weekday,  DateTime date,  int dayOfMonth,  StreakWeekDayStatus status)  $default,) {final _that = this;
switch (_that) {
case _StreakWeekDay():
return $default(_that.weekday,_that.date,_that.dayOfMonth,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String weekday,  DateTime date,  int dayOfMonth,  StreakWeekDayStatus status)?  $default,) {final _that = this;
switch (_that) {
case _StreakWeekDay() when $default != null:
return $default(_that.weekday,_that.date,_that.dayOfMonth,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreakWeekDay implements StreakWeekDay {
  const _StreakWeekDay({this.weekday = '', required this.date, this.dayOfMonth = 0, this.status = StreakWeekDayStatus.upcoming});
  factory _StreakWeekDay.fromJson(Map<String, dynamic> json) => _$StreakWeekDayFromJson(json);

/// Short weekday name ("Sun" … "Sat").
@override@JsonKey() final  String weekday;
@override final  DateTime date;
@override@JsonKey() final  int dayOfMonth;
@override@JsonKey() final  StreakWeekDayStatus status;

/// Create a copy of StreakWeekDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreakWeekDayCopyWith<_StreakWeekDay> get copyWith => __$StreakWeekDayCopyWithImpl<_StreakWeekDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreakWeekDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreakWeekDay&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.date, date) || other.date == date)&&(identical(other.dayOfMonth, dayOfMonth) || other.dayOfMonth == dayOfMonth)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weekday,date,dayOfMonth,status);

@override
String toString() {
  return 'StreakWeekDay(weekday: $weekday, date: $date, dayOfMonth: $dayOfMonth, status: $status)';
}


}

/// @nodoc
abstract mixin class _$StreakWeekDayCopyWith<$Res> implements $StreakWeekDayCopyWith<$Res> {
  factory _$StreakWeekDayCopyWith(_StreakWeekDay value, $Res Function(_StreakWeekDay) _then) = __$StreakWeekDayCopyWithImpl;
@override @useResult
$Res call({
 String weekday, DateTime date, int dayOfMonth, StreakWeekDayStatus status
});




}
/// @nodoc
class __$StreakWeekDayCopyWithImpl<$Res>
    implements _$StreakWeekDayCopyWith<$Res> {
  __$StreakWeekDayCopyWithImpl(this._self, this._then);

  final _StreakWeekDay _self;
  final $Res Function(_StreakWeekDay) _then;

/// Create a copy of StreakWeekDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weekday = null,Object? date = null,Object? dayOfMonth = null,Object? status = null,}) {
  return _then(_StreakWeekDay(
weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,dayOfMonth: null == dayOfMonth ? _self.dayOfMonth : dayOfMonth // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as StreakWeekDayStatus,
  ));
}


}


/// @nodoc
mixin _$StreakMilestone {

/// Streak length that earns the reward (7 = a weekly milestone).
 int get intervalDays; int get xpReward; int get nextAtStreak; int get daysRemaining; bool get reachedToday;
/// Create a copy of StreakMilestone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StreakMilestoneCopyWith<StreakMilestone> get copyWith => _$StreakMilestoneCopyWithImpl<StreakMilestone>(this as StreakMilestone, _$identity);

  /// Serializes this StreakMilestone to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StreakMilestone&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.nextAtStreak, nextAtStreak) || other.nextAtStreak == nextAtStreak)&&(identical(other.daysRemaining, daysRemaining) || other.daysRemaining == daysRemaining)&&(identical(other.reachedToday, reachedToday) || other.reachedToday == reachedToday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intervalDays,xpReward,nextAtStreak,daysRemaining,reachedToday);

@override
String toString() {
  return 'StreakMilestone(intervalDays: $intervalDays, xpReward: $xpReward, nextAtStreak: $nextAtStreak, daysRemaining: $daysRemaining, reachedToday: $reachedToday)';
}


}

/// @nodoc
abstract mixin class $StreakMilestoneCopyWith<$Res>  {
  factory $StreakMilestoneCopyWith(StreakMilestone value, $Res Function(StreakMilestone) _then) = _$StreakMilestoneCopyWithImpl;
@useResult
$Res call({
 int intervalDays, int xpReward, int nextAtStreak, int daysRemaining, bool reachedToday
});




}
/// @nodoc
class _$StreakMilestoneCopyWithImpl<$Res>
    implements $StreakMilestoneCopyWith<$Res> {
  _$StreakMilestoneCopyWithImpl(this._self, this._then);

  final StreakMilestone _self;
  final $Res Function(StreakMilestone) _then;

/// Create a copy of StreakMilestone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? intervalDays = null,Object? xpReward = null,Object? nextAtStreak = null,Object? daysRemaining = null,Object? reachedToday = null,}) {
  return _then(_self.copyWith(
intervalDays: null == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as int,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,nextAtStreak: null == nextAtStreak ? _self.nextAtStreak : nextAtStreak // ignore: cast_nullable_to_non_nullable
as int,daysRemaining: null == daysRemaining ? _self.daysRemaining : daysRemaining // ignore: cast_nullable_to_non_nullable
as int,reachedToday: null == reachedToday ? _self.reachedToday : reachedToday // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StreakMilestone].
extension StreakMilestonePatterns on StreakMilestone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StreakMilestone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StreakMilestone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StreakMilestone value)  $default,){
final _that = this;
switch (_that) {
case _StreakMilestone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StreakMilestone value)?  $default,){
final _that = this;
switch (_that) {
case _StreakMilestone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int intervalDays,  int xpReward,  int nextAtStreak,  int daysRemaining,  bool reachedToday)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StreakMilestone() when $default != null:
return $default(_that.intervalDays,_that.xpReward,_that.nextAtStreak,_that.daysRemaining,_that.reachedToday);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int intervalDays,  int xpReward,  int nextAtStreak,  int daysRemaining,  bool reachedToday)  $default,) {final _that = this;
switch (_that) {
case _StreakMilestone():
return $default(_that.intervalDays,_that.xpReward,_that.nextAtStreak,_that.daysRemaining,_that.reachedToday);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int intervalDays,  int xpReward,  int nextAtStreak,  int daysRemaining,  bool reachedToday)?  $default,) {final _that = this;
switch (_that) {
case _StreakMilestone() when $default != null:
return $default(_that.intervalDays,_that.xpReward,_that.nextAtStreak,_that.daysRemaining,_that.reachedToday);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StreakMilestone implements StreakMilestone {
  const _StreakMilestone({required this.intervalDays, required this.xpReward, required this.nextAtStreak, required this.daysRemaining, required this.reachedToday});
  factory _StreakMilestone.fromJson(Map<String, dynamic> json) => _$StreakMilestoneFromJson(json);

/// Streak length that earns the reward (7 = a weekly milestone).
@override final  int intervalDays;
@override final  int xpReward;
@override final  int nextAtStreak;
@override final  int daysRemaining;
@override final  bool reachedToday;

/// Create a copy of StreakMilestone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreakMilestoneCopyWith<_StreakMilestone> get copyWith => __$StreakMilestoneCopyWithImpl<_StreakMilestone>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StreakMilestoneToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreakMilestone&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&(identical(other.xpReward, xpReward) || other.xpReward == xpReward)&&(identical(other.nextAtStreak, nextAtStreak) || other.nextAtStreak == nextAtStreak)&&(identical(other.daysRemaining, daysRemaining) || other.daysRemaining == daysRemaining)&&(identical(other.reachedToday, reachedToday) || other.reachedToday == reachedToday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intervalDays,xpReward,nextAtStreak,daysRemaining,reachedToday);

@override
String toString() {
  return 'StreakMilestone(intervalDays: $intervalDays, xpReward: $xpReward, nextAtStreak: $nextAtStreak, daysRemaining: $daysRemaining, reachedToday: $reachedToday)';
}


}

/// @nodoc
abstract mixin class _$StreakMilestoneCopyWith<$Res> implements $StreakMilestoneCopyWith<$Res> {
  factory _$StreakMilestoneCopyWith(_StreakMilestone value, $Res Function(_StreakMilestone) _then) = __$StreakMilestoneCopyWithImpl;
@override @useResult
$Res call({
 int intervalDays, int xpReward, int nextAtStreak, int daysRemaining, bool reachedToday
});




}
/// @nodoc
class __$StreakMilestoneCopyWithImpl<$Res>
    implements _$StreakMilestoneCopyWith<$Res> {
  __$StreakMilestoneCopyWithImpl(this._self, this._then);

  final _StreakMilestone _self;
  final $Res Function(_StreakMilestone) _then;

/// Create a copy of StreakMilestone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? intervalDays = null,Object? xpReward = null,Object? nextAtStreak = null,Object? daysRemaining = null,Object? reachedToday = null,}) {
  return _then(_StreakMilestone(
intervalDays: null == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as int,xpReward: null == xpReward ? _self.xpReward : xpReward // ignore: cast_nullable_to_non_nullable
as int,nextAtStreak: null == nextAtStreak ? _self.nextAtStreak : nextAtStreak // ignore: cast_nullable_to_non_nullable
as int,daysRemaining: null == daysRemaining ? _self.daysRemaining : daysRemaining // ignore: cast_nullable_to_non_nullable
as int,reachedToday: null == reachedToday ? _self.reachedToday : reachedToday // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
