// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Workflow {

 DateTime get createdAt; DateTime get updatedAt; String get documentId; String get userId; WorkflowConfig get workflowConfig; List<WorkflowStep> get workflowSteps; bool get isEditing;
/// Create a copy of Workflow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowCopyWith<Workflow> get copyWith => _$WorkflowCopyWithImpl<Workflow>(this as Workflow, _$identity);

  /// Serializes this Workflow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Workflow&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.workflowConfig, workflowConfig) || other.workflowConfig == workflowConfig)&&const DeepCollectionEquality().equals(other.workflowSteps, workflowSteps)&&(identical(other.isEditing, isEditing) || other.isEditing == isEditing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,createdAt,updatedAt,documentId,userId,workflowConfig,const DeepCollectionEquality().hash(workflowSteps),isEditing);

@override
String toString() {
  return 'Workflow(createdAt: $createdAt, updatedAt: $updatedAt, documentId: $documentId, userId: $userId, workflowConfig: $workflowConfig, workflowSteps: $workflowSteps, isEditing: $isEditing)';
}


}

/// @nodoc
abstract mixin class $WorkflowCopyWith<$Res>  {
  factory $WorkflowCopyWith(Workflow value, $Res Function(Workflow) _then) = _$WorkflowCopyWithImpl;
@useResult
$Res call({
 DateTime createdAt, DateTime updatedAt, String documentId, String userId, WorkflowConfig workflowConfig, List<WorkflowStep> workflowSteps, bool isEditing
});


$WorkflowConfigCopyWith<$Res> get workflowConfig;

}
/// @nodoc
class _$WorkflowCopyWithImpl<$Res>
    implements $WorkflowCopyWith<$Res> {
  _$WorkflowCopyWithImpl(this._self, this._then);

  final Workflow _self;
  final $Res Function(Workflow) _then;

/// Create a copy of Workflow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? createdAt = null,Object? updatedAt = null,Object? documentId = null,Object? userId = null,Object? workflowConfig = null,Object? workflowSteps = null,Object? isEditing = null,}) {
  return _then(_self.copyWith(
createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,workflowConfig: null == workflowConfig ? _self.workflowConfig : workflowConfig // ignore: cast_nullable_to_non_nullable
as WorkflowConfig,workflowSteps: null == workflowSteps ? _self.workflowSteps : workflowSteps // ignore: cast_nullable_to_non_nullable
as List<WorkflowStep>,isEditing: null == isEditing ? _self.isEditing : isEditing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Workflow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkflowConfigCopyWith<$Res> get workflowConfig {
  
  return $WorkflowConfigCopyWith<$Res>(_self.workflowConfig, (value) {
    return _then(_self.copyWith(workflowConfig: value));
  });
}
}


/// Adds pattern-matching-related methods to [Workflow].
extension WorkflowPatterns on Workflow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Workflow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Workflow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Workflow value)  $default,){
final _that = this;
switch (_that) {
case _Workflow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Workflow value)?  $default,){
final _that = this;
switch (_that) {
case _Workflow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime createdAt,  DateTime updatedAt,  String documentId,  String userId,  WorkflowConfig workflowConfig,  List<WorkflowStep> workflowSteps,  bool isEditing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Workflow() when $default != null:
return $default(_that.createdAt,_that.updatedAt,_that.documentId,_that.userId,_that.workflowConfig,_that.workflowSteps,_that.isEditing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime createdAt,  DateTime updatedAt,  String documentId,  String userId,  WorkflowConfig workflowConfig,  List<WorkflowStep> workflowSteps,  bool isEditing)  $default,) {final _that = this;
switch (_that) {
case _Workflow():
return $default(_that.createdAt,_that.updatedAt,_that.documentId,_that.userId,_that.workflowConfig,_that.workflowSteps,_that.isEditing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime createdAt,  DateTime updatedAt,  String documentId,  String userId,  WorkflowConfig workflowConfig,  List<WorkflowStep> workflowSteps,  bool isEditing)?  $default,) {final _that = this;
switch (_that) {
case _Workflow() when $default != null:
return $default(_that.createdAt,_that.updatedAt,_that.documentId,_that.userId,_that.workflowConfig,_that.workflowSteps,_that.isEditing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Workflow implements Workflow {
  const _Workflow({required this.createdAt, required this.updatedAt, required this.documentId, required this.userId, required this.workflowConfig, required this.workflowSteps, required this.isEditing});
  factory _Workflow.fromJson(Map<String, dynamic> json) => _$WorkflowFromJson(json);

@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String documentId;
@override final  String userId;
@override final  WorkflowConfig workflowConfig;
@override final  List<WorkflowStep> workflowSteps;
@override final  bool isEditing;

/// Create a copy of Workflow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowCopyWith<_Workflow> get copyWith => __$WorkflowCopyWithImpl<_Workflow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Workflow&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.workflowConfig, workflowConfig) || other.workflowConfig == workflowConfig)&&const DeepCollectionEquality().equals(other.workflowSteps, workflowSteps)&&(identical(other.isEditing, isEditing) || other.isEditing == isEditing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,createdAt,updatedAt,documentId,userId,workflowConfig,const DeepCollectionEquality().hash(workflowSteps),isEditing);

@override
String toString() {
  return 'Workflow(createdAt: $createdAt, updatedAt: $updatedAt, documentId: $documentId, userId: $userId, workflowConfig: $workflowConfig, workflowSteps: $workflowSteps, isEditing: $isEditing)';
}


}

/// @nodoc
abstract mixin class _$WorkflowCopyWith<$Res> implements $WorkflowCopyWith<$Res> {
  factory _$WorkflowCopyWith(_Workflow value, $Res Function(_Workflow) _then) = __$WorkflowCopyWithImpl;
@override @useResult
$Res call({
 DateTime createdAt, DateTime updatedAt, String documentId, String userId, WorkflowConfig workflowConfig, List<WorkflowStep> workflowSteps, bool isEditing
});


@override $WorkflowConfigCopyWith<$Res> get workflowConfig;

}
/// @nodoc
class __$WorkflowCopyWithImpl<$Res>
    implements _$WorkflowCopyWith<$Res> {
  __$WorkflowCopyWithImpl(this._self, this._then);

  final _Workflow _self;
  final $Res Function(_Workflow) _then;

/// Create a copy of Workflow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? createdAt = null,Object? updatedAt = null,Object? documentId = null,Object? userId = null,Object? workflowConfig = null,Object? workflowSteps = null,Object? isEditing = null,}) {
  return _then(_Workflow(
createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,workflowConfig: null == workflowConfig ? _self.workflowConfig : workflowConfig // ignore: cast_nullable_to_non_nullable
as WorkflowConfig,workflowSteps: null == workflowSteps ? _self.workflowSteps : workflowSteps // ignore: cast_nullable_to_non_nullable
as List<WorkflowStep>,isEditing: null == isEditing ? _self.isEditing : isEditing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Workflow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkflowConfigCopyWith<$Res> get workflowConfig {
  
  return $WorkflowConfigCopyWith<$Res>(_self.workflowConfig, (value) {
    return _then(_self.copyWith(workflowConfig: value));
  });
}
}


/// @nodoc
mixin _$WorkflowConfig {

 String get selectedRepository; String get selectedWorkingDirectory; TriggerType get selectedTriggerType; String get selectedTriggerBranch;
/// Create a copy of WorkflowConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowConfigCopyWith<WorkflowConfig> get copyWith => _$WorkflowConfigCopyWithImpl<WorkflowConfig>(this as WorkflowConfig, _$identity);

  /// Serializes this WorkflowConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowConfig&&(identical(other.selectedRepository, selectedRepository) || other.selectedRepository == selectedRepository)&&(identical(other.selectedWorkingDirectory, selectedWorkingDirectory) || other.selectedWorkingDirectory == selectedWorkingDirectory)&&(identical(other.selectedTriggerType, selectedTriggerType) || other.selectedTriggerType == selectedTriggerType)&&(identical(other.selectedTriggerBranch, selectedTriggerBranch) || other.selectedTriggerBranch == selectedTriggerBranch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,selectedRepository,selectedWorkingDirectory,selectedTriggerType,selectedTriggerBranch);

@override
String toString() {
  return 'WorkflowConfig(selectedRepository: $selectedRepository, selectedWorkingDirectory: $selectedWorkingDirectory, selectedTriggerType: $selectedTriggerType, selectedTriggerBranch: $selectedTriggerBranch)';
}


}

/// @nodoc
abstract mixin class $WorkflowConfigCopyWith<$Res>  {
  factory $WorkflowConfigCopyWith(WorkflowConfig value, $Res Function(WorkflowConfig) _then) = _$WorkflowConfigCopyWithImpl;
@useResult
$Res call({
 String selectedRepository, String selectedWorkingDirectory, TriggerType selectedTriggerType, String selectedTriggerBranch
});




}
/// @nodoc
class _$WorkflowConfigCopyWithImpl<$Res>
    implements $WorkflowConfigCopyWith<$Res> {
  _$WorkflowConfigCopyWithImpl(this._self, this._then);

  final WorkflowConfig _self;
  final $Res Function(WorkflowConfig) _then;

/// Create a copy of WorkflowConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedRepository = null,Object? selectedWorkingDirectory = null,Object? selectedTriggerType = null,Object? selectedTriggerBranch = null,}) {
  return _then(_self.copyWith(
selectedRepository: null == selectedRepository ? _self.selectedRepository : selectedRepository // ignore: cast_nullable_to_non_nullable
as String,selectedWorkingDirectory: null == selectedWorkingDirectory ? _self.selectedWorkingDirectory : selectedWorkingDirectory // ignore: cast_nullable_to_non_nullable
as String,selectedTriggerType: null == selectedTriggerType ? _self.selectedTriggerType : selectedTriggerType // ignore: cast_nullable_to_non_nullable
as TriggerType,selectedTriggerBranch: null == selectedTriggerBranch ? _self.selectedTriggerBranch : selectedTriggerBranch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowConfig].
extension WorkflowConfigPatterns on WorkflowConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowConfig value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowConfig value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String selectedRepository,  String selectedWorkingDirectory,  TriggerType selectedTriggerType,  String selectedTriggerBranch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowConfig() when $default != null:
return $default(_that.selectedRepository,_that.selectedWorkingDirectory,_that.selectedTriggerType,_that.selectedTriggerBranch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String selectedRepository,  String selectedWorkingDirectory,  TriggerType selectedTriggerType,  String selectedTriggerBranch)  $default,) {final _that = this;
switch (_that) {
case _WorkflowConfig():
return $default(_that.selectedRepository,_that.selectedWorkingDirectory,_that.selectedTriggerType,_that.selectedTriggerBranch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String selectedRepository,  String selectedWorkingDirectory,  TriggerType selectedTriggerType,  String selectedTriggerBranch)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowConfig() when $default != null:
return $default(_that.selectedRepository,_that.selectedWorkingDirectory,_that.selectedTriggerType,_that.selectedTriggerBranch);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkflowConfig implements WorkflowConfig {
  const _WorkflowConfig({required this.selectedRepository, required this.selectedWorkingDirectory, required this.selectedTriggerType, required this.selectedTriggerBranch});
  factory _WorkflowConfig.fromJson(Map<String, dynamic> json) => _$WorkflowConfigFromJson(json);

@override final  String selectedRepository;
@override final  String selectedWorkingDirectory;
@override final  TriggerType selectedTriggerType;
@override final  String selectedTriggerBranch;

/// Create a copy of WorkflowConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowConfigCopyWith<_WorkflowConfig> get copyWith => __$WorkflowConfigCopyWithImpl<_WorkflowConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowConfig&&(identical(other.selectedRepository, selectedRepository) || other.selectedRepository == selectedRepository)&&(identical(other.selectedWorkingDirectory, selectedWorkingDirectory) || other.selectedWorkingDirectory == selectedWorkingDirectory)&&(identical(other.selectedTriggerType, selectedTriggerType) || other.selectedTriggerType == selectedTriggerType)&&(identical(other.selectedTriggerBranch, selectedTriggerBranch) || other.selectedTriggerBranch == selectedTriggerBranch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,selectedRepository,selectedWorkingDirectory,selectedTriggerType,selectedTriggerBranch);

@override
String toString() {
  return 'WorkflowConfig(selectedRepository: $selectedRepository, selectedWorkingDirectory: $selectedWorkingDirectory, selectedTriggerType: $selectedTriggerType, selectedTriggerBranch: $selectedTriggerBranch)';
}


}

/// @nodoc
abstract mixin class _$WorkflowConfigCopyWith<$Res> implements $WorkflowConfigCopyWith<$Res> {
  factory _$WorkflowConfigCopyWith(_WorkflowConfig value, $Res Function(_WorkflowConfig) _then) = __$WorkflowConfigCopyWithImpl;
@override @useResult
$Res call({
 String selectedRepository, String selectedWorkingDirectory, TriggerType selectedTriggerType, String selectedTriggerBranch
});




}
/// @nodoc
class __$WorkflowConfigCopyWithImpl<$Res>
    implements _$WorkflowConfigCopyWith<$Res> {
  __$WorkflowConfigCopyWithImpl(this._self, this._then);

  final _WorkflowConfig _self;
  final $Res Function(_WorkflowConfig) _then;

/// Create a copy of WorkflowConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedRepository = null,Object? selectedWorkingDirectory = null,Object? selectedTriggerType = null,Object? selectedTriggerBranch = null,}) {
  return _then(_WorkflowConfig(
selectedRepository: null == selectedRepository ? _self.selectedRepository : selectedRepository // ignore: cast_nullable_to_non_nullable
as String,selectedWorkingDirectory: null == selectedWorkingDirectory ? _self.selectedWorkingDirectory : selectedWorkingDirectory // ignore: cast_nullable_to_non_nullable
as String,selectedTriggerType: null == selectedTriggerType ? _self.selectedTriggerType : selectedTriggerType // ignore: cast_nullable_to_non_nullable
as TriggerType,selectedTriggerBranch: null == selectedTriggerBranch ? _self.selectedTriggerBranch : selectedTriggerBranch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WorkflowStep {

 String get name; String get script; bool get isCompleted;
/// Create a copy of WorkflowStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowStepCopyWith<WorkflowStep> get copyWith => _$WorkflowStepCopyWithImpl<WorkflowStep>(this as WorkflowStep, _$identity);

  /// Serializes this WorkflowStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowStep&&(identical(other.name, name) || other.name == name)&&(identical(other.script, script) || other.script == script)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,script,isCompleted);

@override
String toString() {
  return 'WorkflowStep(name: $name, script: $script, isCompleted: $isCompleted)';
}


}

/// @nodoc
abstract mixin class $WorkflowStepCopyWith<$Res>  {
  factory $WorkflowStepCopyWith(WorkflowStep value, $Res Function(WorkflowStep) _then) = _$WorkflowStepCopyWithImpl;
@useResult
$Res call({
 String name, String script, bool isCompleted
});




}
/// @nodoc
class _$WorkflowStepCopyWithImpl<$Res>
    implements $WorkflowStepCopyWith<$Res> {
  _$WorkflowStepCopyWithImpl(this._self, this._then);

  final WorkflowStep _self;
  final $Res Function(WorkflowStep) _then;

/// Create a copy of WorkflowStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? script = null,Object? isCompleted = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowStep].
extension WorkflowStepPatterns on WorkflowStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowStep value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowStep value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String script,  bool isCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowStep() when $default != null:
return $default(_that.name,_that.script,_that.isCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String script,  bool isCompleted)  $default,) {final _that = this;
switch (_that) {
case _WorkflowStep():
return $default(_that.name,_that.script,_that.isCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String script,  bool isCompleted)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowStep() when $default != null:
return $default(_that.name,_that.script,_that.isCompleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkflowStep implements WorkflowStep {
  const _WorkflowStep({required this.name, required this.script, required this.isCompleted});
  factory _WorkflowStep.fromJson(Map<String, dynamic> json) => _$WorkflowStepFromJson(json);

@override final  String name;
@override final  String script;
@override final  bool isCompleted;

/// Create a copy of WorkflowStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowStepCopyWith<_WorkflowStep> get copyWith => __$WorkflowStepCopyWithImpl<_WorkflowStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowStep&&(identical(other.name, name) || other.name == name)&&(identical(other.script, script) || other.script == script)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,script,isCompleted);

@override
String toString() {
  return 'WorkflowStep(name: $name, script: $script, isCompleted: $isCompleted)';
}


}

/// @nodoc
abstract mixin class _$WorkflowStepCopyWith<$Res> implements $WorkflowStepCopyWith<$Res> {
  factory _$WorkflowStepCopyWith(_WorkflowStep value, $Res Function(_WorkflowStep) _then) = __$WorkflowStepCopyWithImpl;
@override @useResult
$Res call({
 String name, String script, bool isCompleted
});




}
/// @nodoc
class __$WorkflowStepCopyWithImpl<$Res>
    implements _$WorkflowStepCopyWith<$Res> {
  __$WorkflowStepCopyWithImpl(this._self, this._then);

  final _WorkflowStep _self;
  final $Res Function(_WorkflowStep) _then;

/// Create a copy of WorkflowStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? script = null,Object? isCompleted = null,}) {
  return _then(_WorkflowStep(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,script: null == script ? _self.script : script // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
