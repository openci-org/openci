// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'open_ci_parser.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ParsedWorkflow {

 String get workflowFileName; String get workflowName; List<ParsedCITrigger> get ciTriggers;
/// Create a copy of ParsedWorkflow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedWorkflowCopyWith<ParsedWorkflow> get copyWith => _$ParsedWorkflowCopyWithImpl<ParsedWorkflow>(this as ParsedWorkflow, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedWorkflow&&(identical(other.workflowFileName, workflowFileName) || other.workflowFileName == workflowFileName)&&(identical(other.workflowName, workflowName) || other.workflowName == workflowName)&&const DeepCollectionEquality().equals(other.ciTriggers, ciTriggers));
}


@override
int get hashCode => Object.hash(runtimeType,workflowFileName,workflowName,const DeepCollectionEquality().hash(ciTriggers));

@override
String toString() {
  return 'ParsedWorkflow(workflowFileName: $workflowFileName, workflowName: $workflowName, ciTriggers: $ciTriggers)';
}


}

/// @nodoc
abstract mixin class $ParsedWorkflowCopyWith<$Res>  {
  factory $ParsedWorkflowCopyWith(ParsedWorkflow value, $Res Function(ParsedWorkflow) _then) = _$ParsedWorkflowCopyWithImpl;
@useResult
$Res call({
 String workflowFileName, String workflowName, List<ParsedCITrigger> ciTriggers
});




}
/// @nodoc
class _$ParsedWorkflowCopyWithImpl<$Res>
    implements $ParsedWorkflowCopyWith<$Res> {
  _$ParsedWorkflowCopyWithImpl(this._self, this._then);

  final ParsedWorkflow _self;
  final $Res Function(ParsedWorkflow) _then;

/// Create a copy of ParsedWorkflow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workflowFileName = null,Object? workflowName = null,Object? ciTriggers = null,}) {
  return _then(_self.copyWith(
workflowFileName: null == workflowFileName ? _self.workflowFileName : workflowFileName // ignore: cast_nullable_to_non_nullable
as String,workflowName: null == workflowName ? _self.workflowName : workflowName // ignore: cast_nullable_to_non_nullable
as String,ciTriggers: null == ciTriggers ? _self.ciTriggers : ciTriggers // ignore: cast_nullable_to_non_nullable
as List<ParsedCITrigger>,
  ));
}

}


/// Adds pattern-matching-related methods to [ParsedWorkflow].
extension ParsedWorkflowPatterns on ParsedWorkflow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedWorkflow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedWorkflow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedWorkflow value)  $default,){
final _that = this;
switch (_that) {
case _ParsedWorkflow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedWorkflow value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedWorkflow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String workflowFileName,  String workflowName,  List<ParsedCITrigger> ciTriggers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedWorkflow() when $default != null:
return $default(_that.workflowFileName,_that.workflowName,_that.ciTriggers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String workflowFileName,  String workflowName,  List<ParsedCITrigger> ciTriggers)  $default,) {final _that = this;
switch (_that) {
case _ParsedWorkflow():
return $default(_that.workflowFileName,_that.workflowName,_that.ciTriggers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String workflowFileName,  String workflowName,  List<ParsedCITrigger> ciTriggers)?  $default,) {final _that = this;
switch (_that) {
case _ParsedWorkflow() when $default != null:
return $default(_that.workflowFileName,_that.workflowName,_that.ciTriggers);case _:
  return null;

}
}

}

/// @nodoc


class _ParsedWorkflow extends ParsedWorkflow {
  const _ParsedWorkflow({required this.workflowFileName, required this.workflowName, required final  List<ParsedCITrigger> ciTriggers}): _ciTriggers = ciTriggers,super._();


@override final  String workflowFileName;
@override final  String workflowName;
 final  List<ParsedCITrigger> _ciTriggers;
@override List<ParsedCITrigger> get ciTriggers {
  if (_ciTriggers is EqualUnmodifiableListView) return _ciTriggers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ciTriggers);
}


/// Create a copy of ParsedWorkflow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedWorkflowCopyWith<_ParsedWorkflow> get copyWith => __$ParsedWorkflowCopyWithImpl<_ParsedWorkflow>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedWorkflow&&(identical(other.workflowFileName, workflowFileName) || other.workflowFileName == workflowFileName)&&(identical(other.workflowName, workflowName) || other.workflowName == workflowName)&&const DeepCollectionEquality().equals(other._ciTriggers, _ciTriggers));
}


@override
int get hashCode => Object.hash(runtimeType,workflowFileName,workflowName,const DeepCollectionEquality().hash(_ciTriggers));

@override
String toString() {
  return 'ParsedWorkflow(workflowFileName: $workflowFileName, workflowName: $workflowName, ciTriggers: $ciTriggers)';
}


}

/// @nodoc
abstract mixin class _$ParsedWorkflowCopyWith<$Res> implements $ParsedWorkflowCopyWith<$Res> {
  factory _$ParsedWorkflowCopyWith(_ParsedWorkflow value, $Res Function(_ParsedWorkflow) _then) = __$ParsedWorkflowCopyWithImpl;
@override @useResult
$Res call({
 String workflowFileName, String workflowName, List<ParsedCITrigger> ciTriggers
});




}
/// @nodoc
class __$ParsedWorkflowCopyWithImpl<$Res>
    implements _$ParsedWorkflowCopyWith<$Res> {
  __$ParsedWorkflowCopyWithImpl(this._self, this._then);

  final _ParsedWorkflow _self;
  final $Res Function(_ParsedWorkflow) _then;

/// Create a copy of ParsedWorkflow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workflowFileName = null,Object? workflowName = null,Object? ciTriggers = null,}) {
  return _then(_ParsedWorkflow(
workflowFileName: null == workflowFileName ? _self.workflowFileName : workflowFileName // ignore: cast_nullable_to_non_nullable
as String,workflowName: null == workflowName ? _self.workflowName : workflowName // ignore: cast_nullable_to_non_nullable
as String,ciTriggers: null == ciTriggers ? _self._ciTriggers : ciTriggers // ignore: cast_nullable_to_non_nullable
as List<ParsedCITrigger>,
  ));
}


}

/// @nodoc
mixin _$ParsedCITrigger {

 String get type; String get branch; List<String>? get whenChanged;
/// Create a copy of ParsedCITrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedCITriggerCopyWith<ParsedCITrigger> get copyWith => _$ParsedCITriggerCopyWithImpl<ParsedCITrigger>(this as ParsedCITrigger, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedCITrigger&&(identical(other.type, type) || other.type == type)&&(identical(other.branch, branch) || other.branch == branch)&&const DeepCollectionEquality().equals(other.whenChanged, whenChanged));
}


@override
int get hashCode => Object.hash(runtimeType,type,branch,const DeepCollectionEquality().hash(whenChanged));

@override
String toString() {
  return 'ParsedCITrigger(type: $type, branch: $branch, whenChanged: $whenChanged)';
}


}

/// @nodoc
abstract mixin class $ParsedCITriggerCopyWith<$Res>  {
  factory $ParsedCITriggerCopyWith(ParsedCITrigger value, $Res Function(ParsedCITrigger) _then) = _$ParsedCITriggerCopyWithImpl;
@useResult
$Res call({
 String type, String branch, List<String>? whenChanged
});




}
/// @nodoc
class _$ParsedCITriggerCopyWithImpl<$Res>
    implements $ParsedCITriggerCopyWith<$Res> {
  _$ParsedCITriggerCopyWithImpl(this._self, this._then);

  final ParsedCITrigger _self;
  final $Res Function(ParsedCITrigger) _then;

/// Create a copy of ParsedCITrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? branch = null,Object? whenChanged = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,whenChanged: freezed == whenChanged ? _self.whenChanged : whenChanged // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ParsedCITrigger].
extension ParsedCITriggerPatterns on ParsedCITrigger {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedCITrigger value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedCITrigger() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedCITrigger value)  $default,){
final _that = this;
switch (_that) {
case _ParsedCITrigger():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedCITrigger value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedCITrigger() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String branch,  List<String>? whenChanged)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedCITrigger() when $default != null:
return $default(_that.type,_that.branch,_that.whenChanged);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String branch,  List<String>? whenChanged)  $default,) {final _that = this;
switch (_that) {
case _ParsedCITrigger():
return $default(_that.type,_that.branch,_that.whenChanged);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String branch,  List<String>? whenChanged)?  $default,) {final _that = this;
switch (_that) {
case _ParsedCITrigger() when $default != null:
return $default(_that.type,_that.branch,_that.whenChanged);case _:
  return null;

}
}

}

/// @nodoc


class _ParsedCITrigger extends ParsedCITrigger {
  const _ParsedCITrigger({required this.type, required this.branch, final  List<String>? whenChanged}): _whenChanged = whenChanged,super._();


@override final  String type;
@override final  String branch;
 final  List<String>? _whenChanged;
@override List<String>? get whenChanged {
  final value = _whenChanged;
  if (value == null) return null;
  if (_whenChanged is EqualUnmodifiableListView) return _whenChanged;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ParsedCITrigger
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedCITriggerCopyWith<_ParsedCITrigger> get copyWith => __$ParsedCITriggerCopyWithImpl<_ParsedCITrigger>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedCITrigger&&(identical(other.type, type) || other.type == type)&&(identical(other.branch, branch) || other.branch == branch)&&const DeepCollectionEquality().equals(other._whenChanged, _whenChanged));
}


@override
int get hashCode => Object.hash(runtimeType,type,branch,const DeepCollectionEquality().hash(_whenChanged));

@override
String toString() {
  return 'ParsedCITrigger(type: $type, branch: $branch, whenChanged: $whenChanged)';
}


}

/// @nodoc
abstract mixin class _$ParsedCITriggerCopyWith<$Res> implements $ParsedCITriggerCopyWith<$Res> {
  factory _$ParsedCITriggerCopyWith(_ParsedCITrigger value, $Res Function(_ParsedCITrigger) _then) = __$ParsedCITriggerCopyWithImpl;
@override @useResult
$Res call({
 String type, String branch, List<String>? whenChanged
});




}
/// @nodoc
class __$ParsedCITriggerCopyWithImpl<$Res>
    implements _$ParsedCITriggerCopyWith<$Res> {
  __$ParsedCITriggerCopyWithImpl(this._self, this._then);

  final _ParsedCITrigger _self;
  final $Res Function(_ParsedCITrigger) _then;

/// Create a copy of ParsedCITrigger
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? branch = null,Object? whenChanged = freezed,}) {
  return _then(_ParsedCITrigger(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,whenChanged: freezed == whenChanged ? _self._whenChanged : whenChanged // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
