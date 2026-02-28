// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'yaml_workflow.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$YamlWorkflow {

 String get name; YamlWorkflowTrigger get on; String get workingDirectory; List<YamlWorkflowStep> get steps;
/// Create a copy of YamlWorkflow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YamlWorkflowCopyWith<YamlWorkflow> get copyWith => _$YamlWorkflowCopyWithImpl<YamlWorkflow>(this as YamlWorkflow, _$identity);

  /// Serializes this YamlWorkflow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YamlWorkflow&&(identical(other.name, name) || other.name == name)&&(identical(other.on, on) || other.on == on)&&(identical(other.workingDirectory, workingDirectory) || other.workingDirectory == workingDirectory)&&const DeepCollectionEquality().equals(other.steps, steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,on,workingDirectory,const DeepCollectionEquality().hash(steps));

@override
String toString() {
  return 'YamlWorkflow(name: $name, on: $on, workingDirectory: $workingDirectory, steps: $steps)';
}


}

/// @nodoc
abstract mixin class $YamlWorkflowCopyWith<$Res>  {
  factory $YamlWorkflowCopyWith(YamlWorkflow value, $Res Function(YamlWorkflow) _then) = _$YamlWorkflowCopyWithImpl;
@useResult
$Res call({
 String name, YamlWorkflowTrigger on, String workingDirectory, List<YamlWorkflowStep> steps
});


$YamlWorkflowTriggerCopyWith<$Res> get on;

}
/// @nodoc
class _$YamlWorkflowCopyWithImpl<$Res>
    implements $YamlWorkflowCopyWith<$Res> {
  _$YamlWorkflowCopyWithImpl(this._self, this._then);

  final YamlWorkflow _self;
  final $Res Function(YamlWorkflow) _then;

/// Create a copy of YamlWorkflow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? on = null,Object? workingDirectory = null,Object? steps = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,on: null == on ? _self.on : on // ignore: cast_nullable_to_non_nullable
as YamlWorkflowTrigger,workingDirectory: null == workingDirectory ? _self.workingDirectory : workingDirectory // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<YamlWorkflowStep>,
  ));
}
/// Create a copy of YamlWorkflow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YamlWorkflowTriggerCopyWith<$Res> get on {
  
  return $YamlWorkflowTriggerCopyWith<$Res>(_self.on, (value) {
    return _then(_self.copyWith(on: value));
  });
}
}


/// Adds pattern-matching-related methods to [YamlWorkflow].
extension YamlWorkflowPatterns on YamlWorkflow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YamlWorkflow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YamlWorkflow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YamlWorkflow value)  $default,){
final _that = this;
switch (_that) {
case _YamlWorkflow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YamlWorkflow value)?  $default,){
final _that = this;
switch (_that) {
case _YamlWorkflow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  YamlWorkflowTrigger on,  String workingDirectory,  List<YamlWorkflowStep> steps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YamlWorkflow() when $default != null:
return $default(_that.name,_that.on,_that.workingDirectory,_that.steps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  YamlWorkflowTrigger on,  String workingDirectory,  List<YamlWorkflowStep> steps)  $default,) {final _that = this;
switch (_that) {
case _YamlWorkflow():
return $default(_that.name,_that.on,_that.workingDirectory,_that.steps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  YamlWorkflowTrigger on,  String workingDirectory,  List<YamlWorkflowStep> steps)?  $default,) {final _that = this;
switch (_that) {
case _YamlWorkflow() when $default != null:
return $default(_that.name,_that.on,_that.workingDirectory,_that.steps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _YamlWorkflow implements YamlWorkflow {
  const _YamlWorkflow({required this.name, required this.on, this.workingDirectory = '.', final  List<YamlWorkflowStep> steps = const []}): _steps = steps;
  factory _YamlWorkflow.fromJson(Map<String, dynamic> json) => _$YamlWorkflowFromJson(json);

@override final  String name;
@override final  YamlWorkflowTrigger on;
@override@JsonKey() final  String workingDirectory;
 final  List<YamlWorkflowStep> _steps;
@override@JsonKey() List<YamlWorkflowStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}


/// Create a copy of YamlWorkflow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YamlWorkflowCopyWith<_YamlWorkflow> get copyWith => __$YamlWorkflowCopyWithImpl<_YamlWorkflow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YamlWorkflowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YamlWorkflow&&(identical(other.name, name) || other.name == name)&&(identical(other.on, on) || other.on == on)&&(identical(other.workingDirectory, workingDirectory) || other.workingDirectory == workingDirectory)&&const DeepCollectionEquality().equals(other._steps, _steps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,on,workingDirectory,const DeepCollectionEquality().hash(_steps));

@override
String toString() {
  return 'YamlWorkflow(name: $name, on: $on, workingDirectory: $workingDirectory, steps: $steps)';
}


}

/// @nodoc
abstract mixin class _$YamlWorkflowCopyWith<$Res> implements $YamlWorkflowCopyWith<$Res> {
  factory _$YamlWorkflowCopyWith(_YamlWorkflow value, $Res Function(_YamlWorkflow) _then) = __$YamlWorkflowCopyWithImpl;
@override @useResult
$Res call({
 String name, YamlWorkflowTrigger on, String workingDirectory, List<YamlWorkflowStep> steps
});


@override $YamlWorkflowTriggerCopyWith<$Res> get on;

}
/// @nodoc
class __$YamlWorkflowCopyWithImpl<$Res>
    implements _$YamlWorkflowCopyWith<$Res> {
  __$YamlWorkflowCopyWithImpl(this._self, this._then);

  final _YamlWorkflow _self;
  final $Res Function(_YamlWorkflow) _then;

/// Create a copy of YamlWorkflow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? on = null,Object? workingDirectory = null,Object? steps = null,}) {
  return _then(_YamlWorkflow(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,on: null == on ? _self.on : on // ignore: cast_nullable_to_non_nullable
as YamlWorkflowTrigger,workingDirectory: null == workingDirectory ? _self.workingDirectory : workingDirectory // ignore: cast_nullable_to_non_nullable
as String,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<YamlWorkflowStep>,
  ));
}

/// Create a copy of YamlWorkflow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YamlWorkflowTriggerCopyWith<$Res> get on {
  
  return $YamlWorkflowTriggerCopyWith<$Res>(_self.on, (value) {
    return _then(_self.copyWith(on: value));
  });
}
}


/// @nodoc
mixin _$YamlWorkflowTrigger {

 YamlTriggerConfig? get push; YamlTriggerConfig? get pullRequest; bool? get tag; YamlReleaseTriggerConfig? get release;
/// Create a copy of YamlWorkflowTrigger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YamlWorkflowTriggerCopyWith<YamlWorkflowTrigger> get copyWith => _$YamlWorkflowTriggerCopyWithImpl<YamlWorkflowTrigger>(this as YamlWorkflowTrigger, _$identity);

  /// Serializes this YamlWorkflowTrigger to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YamlWorkflowTrigger&&(identical(other.push, push) || other.push == push)&&(identical(other.pullRequest, pullRequest) || other.pullRequest == pullRequest)&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.release, release) || other.release == release));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,push,pullRequest,tag,release);

@override
String toString() {
  return 'YamlWorkflowTrigger(push: $push, pullRequest: $pullRequest, tag: $tag, release: $release)';
}


}

/// @nodoc
abstract mixin class $YamlWorkflowTriggerCopyWith<$Res>  {
  factory $YamlWorkflowTriggerCopyWith(YamlWorkflowTrigger value, $Res Function(YamlWorkflowTrigger) _then) = _$YamlWorkflowTriggerCopyWithImpl;
@useResult
$Res call({
 YamlTriggerConfig? push, YamlTriggerConfig? pullRequest, bool? tag, YamlReleaseTriggerConfig? release
});


$YamlTriggerConfigCopyWith<$Res>? get push;$YamlTriggerConfigCopyWith<$Res>? get pullRequest;$YamlReleaseTriggerConfigCopyWith<$Res>? get release;

}
/// @nodoc
class _$YamlWorkflowTriggerCopyWithImpl<$Res>
    implements $YamlWorkflowTriggerCopyWith<$Res> {
  _$YamlWorkflowTriggerCopyWithImpl(this._self, this._then);

  final YamlWorkflowTrigger _self;
  final $Res Function(YamlWorkflowTrigger) _then;

/// Create a copy of YamlWorkflowTrigger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? push = freezed,Object? pullRequest = freezed,Object? tag = freezed,Object? release = freezed,}) {
  return _then(_self.copyWith(
push: freezed == push ? _self.push : push // ignore: cast_nullable_to_non_nullable
as YamlTriggerConfig?,pullRequest: freezed == pullRequest ? _self.pullRequest : pullRequest // ignore: cast_nullable_to_non_nullable
as YamlTriggerConfig?,tag: freezed == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as bool?,release: freezed == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as YamlReleaseTriggerConfig?,
  ));
}
/// Create a copy of YamlWorkflowTrigger
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YamlTriggerConfigCopyWith<$Res>? get push {
    if (_self.push == null) {
    return null;
  }

  return $YamlTriggerConfigCopyWith<$Res>(_self.push!, (value) {
    return _then(_self.copyWith(push: value));
  });
}/// Create a copy of YamlWorkflowTrigger
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YamlTriggerConfigCopyWith<$Res>? get pullRequest {
    if (_self.pullRequest == null) {
    return null;
  }

  return $YamlTriggerConfigCopyWith<$Res>(_self.pullRequest!, (value) {
    return _then(_self.copyWith(pullRequest: value));
  });
}/// Create a copy of YamlWorkflowTrigger
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YamlReleaseTriggerConfigCopyWith<$Res>? get release {
    if (_self.release == null) {
    return null;
  }

  return $YamlReleaseTriggerConfigCopyWith<$Res>(_self.release!, (value) {
    return _then(_self.copyWith(release: value));
  });
}
}


/// Adds pattern-matching-related methods to [YamlWorkflowTrigger].
extension YamlWorkflowTriggerPatterns on YamlWorkflowTrigger {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YamlWorkflowTrigger value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YamlWorkflowTrigger() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YamlWorkflowTrigger value)  $default,){
final _that = this;
switch (_that) {
case _YamlWorkflowTrigger():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YamlWorkflowTrigger value)?  $default,){
final _that = this;
switch (_that) {
case _YamlWorkflowTrigger() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( YamlTriggerConfig? push,  YamlTriggerConfig? pullRequest,  bool? tag,  YamlReleaseTriggerConfig? release)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YamlWorkflowTrigger() when $default != null:
return $default(_that.push,_that.pullRequest,_that.tag,_that.release);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( YamlTriggerConfig? push,  YamlTriggerConfig? pullRequest,  bool? tag,  YamlReleaseTriggerConfig? release)  $default,) {final _that = this;
switch (_that) {
case _YamlWorkflowTrigger():
return $default(_that.push,_that.pullRequest,_that.tag,_that.release);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( YamlTriggerConfig? push,  YamlTriggerConfig? pullRequest,  bool? tag,  YamlReleaseTriggerConfig? release)?  $default,) {final _that = this;
switch (_that) {
case _YamlWorkflowTrigger() when $default != null:
return $default(_that.push,_that.pullRequest,_that.tag,_that.release);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _YamlWorkflowTrigger implements YamlWorkflowTrigger {
  const _YamlWorkflowTrigger({this.push, this.pullRequest, this.tag, this.release});
  factory _YamlWorkflowTrigger.fromJson(Map<String, dynamic> json) => _$YamlWorkflowTriggerFromJson(json);

@override final  YamlTriggerConfig? push;
@override final  YamlTriggerConfig? pullRequest;
@override final  bool? tag;
@override final  YamlReleaseTriggerConfig? release;

/// Create a copy of YamlWorkflowTrigger
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YamlWorkflowTriggerCopyWith<_YamlWorkflowTrigger> get copyWith => __$YamlWorkflowTriggerCopyWithImpl<_YamlWorkflowTrigger>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YamlWorkflowTriggerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YamlWorkflowTrigger&&(identical(other.push, push) || other.push == push)&&(identical(other.pullRequest, pullRequest) || other.pullRequest == pullRequest)&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.release, release) || other.release == release));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,push,pullRequest,tag,release);

@override
String toString() {
  return 'YamlWorkflowTrigger(push: $push, pullRequest: $pullRequest, tag: $tag, release: $release)';
}


}

/// @nodoc
abstract mixin class _$YamlWorkflowTriggerCopyWith<$Res> implements $YamlWorkflowTriggerCopyWith<$Res> {
  factory _$YamlWorkflowTriggerCopyWith(_YamlWorkflowTrigger value, $Res Function(_YamlWorkflowTrigger) _then) = __$YamlWorkflowTriggerCopyWithImpl;
@override @useResult
$Res call({
 YamlTriggerConfig? push, YamlTriggerConfig? pullRequest, bool? tag, YamlReleaseTriggerConfig? release
});


@override $YamlTriggerConfigCopyWith<$Res>? get push;@override $YamlTriggerConfigCopyWith<$Res>? get pullRequest;@override $YamlReleaseTriggerConfigCopyWith<$Res>? get release;

}
/// @nodoc
class __$YamlWorkflowTriggerCopyWithImpl<$Res>
    implements _$YamlWorkflowTriggerCopyWith<$Res> {
  __$YamlWorkflowTriggerCopyWithImpl(this._self, this._then);

  final _YamlWorkflowTrigger _self;
  final $Res Function(_YamlWorkflowTrigger) _then;

/// Create a copy of YamlWorkflowTrigger
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? push = freezed,Object? pullRequest = freezed,Object? tag = freezed,Object? release = freezed,}) {
  return _then(_YamlWorkflowTrigger(
push: freezed == push ? _self.push : push // ignore: cast_nullable_to_non_nullable
as YamlTriggerConfig?,pullRequest: freezed == pullRequest ? _self.pullRequest : pullRequest // ignore: cast_nullable_to_non_nullable
as YamlTriggerConfig?,tag: freezed == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as bool?,release: freezed == release ? _self.release : release // ignore: cast_nullable_to_non_nullable
as YamlReleaseTriggerConfig?,
  ));
}

/// Create a copy of YamlWorkflowTrigger
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YamlTriggerConfigCopyWith<$Res>? get push {
    if (_self.push == null) {
    return null;
  }

  return $YamlTriggerConfigCopyWith<$Res>(_self.push!, (value) {
    return _then(_self.copyWith(push: value));
  });
}/// Create a copy of YamlWorkflowTrigger
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YamlTriggerConfigCopyWith<$Res>? get pullRequest {
    if (_self.pullRequest == null) {
    return null;
  }

  return $YamlTriggerConfigCopyWith<$Res>(_self.pullRequest!, (value) {
    return _then(_self.copyWith(pullRequest: value));
  });
}/// Create a copy of YamlWorkflowTrigger
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YamlReleaseTriggerConfigCopyWith<$Res>? get release {
    if (_self.release == null) {
    return null;
  }

  return $YamlReleaseTriggerConfigCopyWith<$Res>(_self.release!, (value) {
    return _then(_self.copyWith(release: value));
  });
}
}


/// @nodoc
mixin _$YamlTriggerConfig {

 List<String> get branches;
/// Create a copy of YamlTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YamlTriggerConfigCopyWith<YamlTriggerConfig> get copyWith => _$YamlTriggerConfigCopyWithImpl<YamlTriggerConfig>(this as YamlTriggerConfig, _$identity);

  /// Serializes this YamlTriggerConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YamlTriggerConfig&&const DeepCollectionEquality().equals(other.branches, branches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(branches));

@override
String toString() {
  return 'YamlTriggerConfig(branches: $branches)';
}


}

/// @nodoc
abstract mixin class $YamlTriggerConfigCopyWith<$Res>  {
  factory $YamlTriggerConfigCopyWith(YamlTriggerConfig value, $Res Function(YamlTriggerConfig) _then) = _$YamlTriggerConfigCopyWithImpl;
@useResult
$Res call({
 List<String> branches
});




}
/// @nodoc
class _$YamlTriggerConfigCopyWithImpl<$Res>
    implements $YamlTriggerConfigCopyWith<$Res> {
  _$YamlTriggerConfigCopyWithImpl(this._self, this._then);

  final YamlTriggerConfig _self;
  final $Res Function(YamlTriggerConfig) _then;

/// Create a copy of YamlTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? branches = null,}) {
  return _then(_self.copyWith(
branches: null == branches ? _self.branches : branches // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [YamlTriggerConfig].
extension YamlTriggerConfigPatterns on YamlTriggerConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YamlTriggerConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YamlTriggerConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YamlTriggerConfig value)  $default,){
final _that = this;
switch (_that) {
case _YamlTriggerConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YamlTriggerConfig value)?  $default,){
final _that = this;
switch (_that) {
case _YamlTriggerConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> branches)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YamlTriggerConfig() when $default != null:
return $default(_that.branches);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> branches)  $default,) {final _that = this;
switch (_that) {
case _YamlTriggerConfig():
return $default(_that.branches);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> branches)?  $default,) {final _that = this;
switch (_that) {
case _YamlTriggerConfig() when $default != null:
return $default(_that.branches);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _YamlTriggerConfig implements YamlTriggerConfig {
  const _YamlTriggerConfig({final  List<String> branches = const []}): _branches = branches;
  factory _YamlTriggerConfig.fromJson(Map<String, dynamic> json) => _$YamlTriggerConfigFromJson(json);

 final  List<String> _branches;
@override@JsonKey() List<String> get branches {
  if (_branches is EqualUnmodifiableListView) return _branches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_branches);
}


/// Create a copy of YamlTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YamlTriggerConfigCopyWith<_YamlTriggerConfig> get copyWith => __$YamlTriggerConfigCopyWithImpl<_YamlTriggerConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YamlTriggerConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YamlTriggerConfig&&const DeepCollectionEquality().equals(other._branches, _branches));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_branches));

@override
String toString() {
  return 'YamlTriggerConfig(branches: $branches)';
}


}

/// @nodoc
abstract mixin class _$YamlTriggerConfigCopyWith<$Res> implements $YamlTriggerConfigCopyWith<$Res> {
  factory _$YamlTriggerConfigCopyWith(_YamlTriggerConfig value, $Res Function(_YamlTriggerConfig) _then) = __$YamlTriggerConfigCopyWithImpl;
@override @useResult
$Res call({
 List<String> branches
});




}
/// @nodoc
class __$YamlTriggerConfigCopyWithImpl<$Res>
    implements _$YamlTriggerConfigCopyWith<$Res> {
  __$YamlTriggerConfigCopyWithImpl(this._self, this._then);

  final _YamlTriggerConfig _self;
  final $Res Function(_YamlTriggerConfig) _then;

/// Create a copy of YamlTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branches = null,}) {
  return _then(_YamlTriggerConfig(
branches: null == branches ? _self._branches : branches // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$YamlReleaseTriggerConfig {

 List<String> get types;
/// Create a copy of YamlReleaseTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YamlReleaseTriggerConfigCopyWith<YamlReleaseTriggerConfig> get copyWith => _$YamlReleaseTriggerConfigCopyWithImpl<YamlReleaseTriggerConfig>(this as YamlReleaseTriggerConfig, _$identity);

  /// Serializes this YamlReleaseTriggerConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YamlReleaseTriggerConfig&&const DeepCollectionEquality().equals(other.types, types));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(types));

@override
String toString() {
  return 'YamlReleaseTriggerConfig(types: $types)';
}


}

/// @nodoc
abstract mixin class $YamlReleaseTriggerConfigCopyWith<$Res>  {
  factory $YamlReleaseTriggerConfigCopyWith(YamlReleaseTriggerConfig value, $Res Function(YamlReleaseTriggerConfig) _then) = _$YamlReleaseTriggerConfigCopyWithImpl;
@useResult
$Res call({
 List<String> types
});




}
/// @nodoc
class _$YamlReleaseTriggerConfigCopyWithImpl<$Res>
    implements $YamlReleaseTriggerConfigCopyWith<$Res> {
  _$YamlReleaseTriggerConfigCopyWithImpl(this._self, this._then);

  final YamlReleaseTriggerConfig _self;
  final $Res Function(YamlReleaseTriggerConfig) _then;

/// Create a copy of YamlReleaseTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? types = null,}) {
  return _then(_self.copyWith(
types: null == types ? _self.types : types // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [YamlReleaseTriggerConfig].
extension YamlReleaseTriggerConfigPatterns on YamlReleaseTriggerConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YamlReleaseTriggerConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YamlReleaseTriggerConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YamlReleaseTriggerConfig value)  $default,){
final _that = this;
switch (_that) {
case _YamlReleaseTriggerConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YamlReleaseTriggerConfig value)?  $default,){
final _that = this;
switch (_that) {
case _YamlReleaseTriggerConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> types)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YamlReleaseTriggerConfig() when $default != null:
return $default(_that.types);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> types)  $default,) {final _that = this;
switch (_that) {
case _YamlReleaseTriggerConfig():
return $default(_that.types);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> types)?  $default,) {final _that = this;
switch (_that) {
case _YamlReleaseTriggerConfig() when $default != null:
return $default(_that.types);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _YamlReleaseTriggerConfig implements YamlReleaseTriggerConfig {
  const _YamlReleaseTriggerConfig({final  List<String> types = const ['published']}): _types = types;
  factory _YamlReleaseTriggerConfig.fromJson(Map<String, dynamic> json) => _$YamlReleaseTriggerConfigFromJson(json);

 final  List<String> _types;
@override@JsonKey() List<String> get types {
  if (_types is EqualUnmodifiableListView) return _types;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_types);
}


/// Create a copy of YamlReleaseTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YamlReleaseTriggerConfigCopyWith<_YamlReleaseTriggerConfig> get copyWith => __$YamlReleaseTriggerConfigCopyWithImpl<_YamlReleaseTriggerConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YamlReleaseTriggerConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YamlReleaseTriggerConfig&&const DeepCollectionEquality().equals(other._types, _types));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_types));

@override
String toString() {
  return 'YamlReleaseTriggerConfig(types: $types)';
}


}

/// @nodoc
abstract mixin class _$YamlReleaseTriggerConfigCopyWith<$Res> implements $YamlReleaseTriggerConfigCopyWith<$Res> {
  factory _$YamlReleaseTriggerConfigCopyWith(_YamlReleaseTriggerConfig value, $Res Function(_YamlReleaseTriggerConfig) _then) = __$YamlReleaseTriggerConfigCopyWithImpl;
@override @useResult
$Res call({
 List<String> types
});




}
/// @nodoc
class __$YamlReleaseTriggerConfigCopyWithImpl<$Res>
    implements _$YamlReleaseTriggerConfigCopyWith<$Res> {
  __$YamlReleaseTriggerConfigCopyWithImpl(this._self, this._then);

  final _YamlReleaseTriggerConfig _self;
  final $Res Function(_YamlReleaseTriggerConfig) _then;

/// Create a copy of YamlReleaseTriggerConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? types = null,}) {
  return _then(_YamlReleaseTriggerConfig(
types: null == types ? _self._types : types // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$YamlWorkflowStep {

 String get name; String? get run; String? get uses; Map<String, String> get withParams;
/// Create a copy of YamlWorkflowStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YamlWorkflowStepCopyWith<YamlWorkflowStep> get copyWith => _$YamlWorkflowStepCopyWithImpl<YamlWorkflowStep>(this as YamlWorkflowStep, _$identity);

  /// Serializes this YamlWorkflowStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YamlWorkflowStep&&(identical(other.name, name) || other.name == name)&&(identical(other.run, run) || other.run == run)&&(identical(other.uses, uses) || other.uses == uses)&&const DeepCollectionEquality().equals(other.withParams, withParams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,run,uses,const DeepCollectionEquality().hash(withParams));

@override
String toString() {
  return 'YamlWorkflowStep(name: $name, run: $run, uses: $uses, withParams: $withParams)';
}


}

/// @nodoc
abstract mixin class $YamlWorkflowStepCopyWith<$Res>  {
  factory $YamlWorkflowStepCopyWith(YamlWorkflowStep value, $Res Function(YamlWorkflowStep) _then) = _$YamlWorkflowStepCopyWithImpl;
@useResult
$Res call({
 String name, String? run, String? uses, Map<String, String> withParams
});




}
/// @nodoc
class _$YamlWorkflowStepCopyWithImpl<$Res>
    implements $YamlWorkflowStepCopyWith<$Res> {
  _$YamlWorkflowStepCopyWithImpl(this._self, this._then);

  final YamlWorkflowStep _self;
  final $Res Function(YamlWorkflowStep) _then;

/// Create a copy of YamlWorkflowStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? run = freezed,Object? uses = freezed,Object? withParams = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,run: freezed == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as String?,uses: freezed == uses ? _self.uses : uses // ignore: cast_nullable_to_non_nullable
as String?,withParams: null == withParams ? _self.withParams : withParams // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [YamlWorkflowStep].
extension YamlWorkflowStepPatterns on YamlWorkflowStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YamlWorkflowStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YamlWorkflowStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YamlWorkflowStep value)  $default,){
final _that = this;
switch (_that) {
case _YamlWorkflowStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YamlWorkflowStep value)?  $default,){
final _that = this;
switch (_that) {
case _YamlWorkflowStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? run,  String? uses,  Map<String, String> withParams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YamlWorkflowStep() when $default != null:
return $default(_that.name,_that.run,_that.uses,_that.withParams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? run,  String? uses,  Map<String, String> withParams)  $default,) {final _that = this;
switch (_that) {
case _YamlWorkflowStep():
return $default(_that.name,_that.run,_that.uses,_that.withParams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? run,  String? uses,  Map<String, String> withParams)?  $default,) {final _that = this;
switch (_that) {
case _YamlWorkflowStep() when $default != null:
return $default(_that.name,_that.run,_that.uses,_that.withParams);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _YamlWorkflowStep implements YamlWorkflowStep {
  const _YamlWorkflowStep({required this.name, this.run, this.uses, final  Map<String, String> withParams = const {}}): _withParams = withParams;
  factory _YamlWorkflowStep.fromJson(Map<String, dynamic> json) => _$YamlWorkflowStepFromJson(json);

@override final  String name;
@override final  String? run;
@override final  String? uses;
 final  Map<String, String> _withParams;
@override@JsonKey() Map<String, String> get withParams {
  if (_withParams is EqualUnmodifiableMapView) return _withParams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_withParams);
}


/// Create a copy of YamlWorkflowStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YamlWorkflowStepCopyWith<_YamlWorkflowStep> get copyWith => __$YamlWorkflowStepCopyWithImpl<_YamlWorkflowStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YamlWorkflowStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YamlWorkflowStep&&(identical(other.name, name) || other.name == name)&&(identical(other.run, run) || other.run == run)&&(identical(other.uses, uses) || other.uses == uses)&&const DeepCollectionEquality().equals(other._withParams, _withParams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,run,uses,const DeepCollectionEquality().hash(_withParams));

@override
String toString() {
  return 'YamlWorkflowStep(name: $name, run: $run, uses: $uses, withParams: $withParams)';
}


}

/// @nodoc
abstract mixin class _$YamlWorkflowStepCopyWith<$Res> implements $YamlWorkflowStepCopyWith<$Res> {
  factory _$YamlWorkflowStepCopyWith(_YamlWorkflowStep value, $Res Function(_YamlWorkflowStep) _then) = __$YamlWorkflowStepCopyWithImpl;
@override @useResult
$Res call({
 String name, String? run, String? uses, Map<String, String> withParams
});




}
/// @nodoc
class __$YamlWorkflowStepCopyWithImpl<$Res>
    implements _$YamlWorkflowStepCopyWith<$Res> {
  __$YamlWorkflowStepCopyWithImpl(this._self, this._then);

  final _YamlWorkflowStep _self;
  final $Res Function(_YamlWorkflowStep) _then;

/// Create a copy of YamlWorkflowStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? run = freezed,Object? uses = freezed,Object? withParams = null,}) {
  return _then(_YamlWorkflowStep(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,run: freezed == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as String?,uses: freezed == uses ? _self.uses : uses // ignore: cast_nullable_to_non_nullable
as String?,withParams: null == withParams ? _self._withParams : withParams // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
