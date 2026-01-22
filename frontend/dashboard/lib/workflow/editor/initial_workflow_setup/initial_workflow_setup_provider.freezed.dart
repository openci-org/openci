// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'initial_workflow_setup_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InitialWorkflowSetupState {

 bool get isCreated; String get selectedRepository; String get selectedWorkingDirectory; TriggerType get selectedTriggerType; String get selectedTriggerBranch;
/// Create a copy of InitialWorkflowSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InitialWorkflowSetupStateCopyWith<InitialWorkflowSetupState> get copyWith => _$InitialWorkflowSetupStateCopyWithImpl<InitialWorkflowSetupState>(this as InitialWorkflowSetupState, _$identity);

  /// Serializes this InitialWorkflowSetupState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InitialWorkflowSetupState&&(identical(other.isCreated, isCreated) || other.isCreated == isCreated)&&(identical(other.selectedRepository, selectedRepository) || other.selectedRepository == selectedRepository)&&(identical(other.selectedWorkingDirectory, selectedWorkingDirectory) || other.selectedWorkingDirectory == selectedWorkingDirectory)&&(identical(other.selectedTriggerType, selectedTriggerType) || other.selectedTriggerType == selectedTriggerType)&&(identical(other.selectedTriggerBranch, selectedTriggerBranch) || other.selectedTriggerBranch == selectedTriggerBranch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isCreated,selectedRepository,selectedWorkingDirectory,selectedTriggerType,selectedTriggerBranch);

@override
String toString() {
  return 'InitialWorkflowSetupState(isCreated: $isCreated, selectedRepository: $selectedRepository, selectedWorkingDirectory: $selectedWorkingDirectory, selectedTriggerType: $selectedTriggerType, selectedTriggerBranch: $selectedTriggerBranch)';
}


}

/// @nodoc
abstract mixin class $InitialWorkflowSetupStateCopyWith<$Res>  {
  factory $InitialWorkflowSetupStateCopyWith(InitialWorkflowSetupState value, $Res Function(InitialWorkflowSetupState) _then) = _$InitialWorkflowSetupStateCopyWithImpl;
@useResult
$Res call({
 bool isCreated, String selectedRepository, String selectedWorkingDirectory, TriggerType selectedTriggerType, String selectedTriggerBranch
});




}
/// @nodoc
class _$InitialWorkflowSetupStateCopyWithImpl<$Res>
    implements $InitialWorkflowSetupStateCopyWith<$Res> {
  _$InitialWorkflowSetupStateCopyWithImpl(this._self, this._then);

  final InitialWorkflowSetupState _self;
  final $Res Function(InitialWorkflowSetupState) _then;

/// Create a copy of InitialWorkflowSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isCreated = null,Object? selectedRepository = null,Object? selectedWorkingDirectory = null,Object? selectedTriggerType = null,Object? selectedTriggerBranch = null,}) {
  return _then(_self.copyWith(
isCreated: null == isCreated ? _self.isCreated : isCreated // ignore: cast_nullable_to_non_nullable
as bool,selectedRepository: null == selectedRepository ? _self.selectedRepository : selectedRepository // ignore: cast_nullable_to_non_nullable
as String,selectedWorkingDirectory: null == selectedWorkingDirectory ? _self.selectedWorkingDirectory : selectedWorkingDirectory // ignore: cast_nullable_to_non_nullable
as String,selectedTriggerType: null == selectedTriggerType ? _self.selectedTriggerType : selectedTriggerType // ignore: cast_nullable_to_non_nullable
as TriggerType,selectedTriggerBranch: null == selectedTriggerBranch ? _self.selectedTriggerBranch : selectedTriggerBranch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InitialWorkflowSetupState].
extension InitialWorkflowSetupStatePatterns on InitialWorkflowSetupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InitialWorkflowSetupState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InitialWorkflowSetupState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InitialWorkflowSetupState value)  $default,){
final _that = this;
switch (_that) {
case _InitialWorkflowSetupState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InitialWorkflowSetupState value)?  $default,){
final _that = this;
switch (_that) {
case _InitialWorkflowSetupState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isCreated,  String selectedRepository,  String selectedWorkingDirectory,  TriggerType selectedTriggerType,  String selectedTriggerBranch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InitialWorkflowSetupState() when $default != null:
return $default(_that.isCreated,_that.selectedRepository,_that.selectedWorkingDirectory,_that.selectedTriggerType,_that.selectedTriggerBranch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isCreated,  String selectedRepository,  String selectedWorkingDirectory,  TriggerType selectedTriggerType,  String selectedTriggerBranch)  $default,) {final _that = this;
switch (_that) {
case _InitialWorkflowSetupState():
return $default(_that.isCreated,_that.selectedRepository,_that.selectedWorkingDirectory,_that.selectedTriggerType,_that.selectedTriggerBranch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isCreated,  String selectedRepository,  String selectedWorkingDirectory,  TriggerType selectedTriggerType,  String selectedTriggerBranch)?  $default,) {final _that = this;
switch (_that) {
case _InitialWorkflowSetupState() when $default != null:
return $default(_that.isCreated,_that.selectedRepository,_that.selectedWorkingDirectory,_that.selectedTriggerType,_that.selectedTriggerBranch);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InitialWorkflowSetupState implements InitialWorkflowSetupState {
  const _InitialWorkflowSetupState({required this.isCreated, required this.selectedRepository, required this.selectedWorkingDirectory, required this.selectedTriggerType, required this.selectedTriggerBranch});
  factory _InitialWorkflowSetupState.fromJson(Map<String, dynamic> json) => _$InitialWorkflowSetupStateFromJson(json);

@override final  bool isCreated;
@override final  String selectedRepository;
@override final  String selectedWorkingDirectory;
@override final  TriggerType selectedTriggerType;
@override final  String selectedTriggerBranch;

/// Create a copy of InitialWorkflowSetupState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InitialWorkflowSetupStateCopyWith<_InitialWorkflowSetupState> get copyWith => __$InitialWorkflowSetupStateCopyWithImpl<_InitialWorkflowSetupState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InitialWorkflowSetupStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InitialWorkflowSetupState&&(identical(other.isCreated, isCreated) || other.isCreated == isCreated)&&(identical(other.selectedRepository, selectedRepository) || other.selectedRepository == selectedRepository)&&(identical(other.selectedWorkingDirectory, selectedWorkingDirectory) || other.selectedWorkingDirectory == selectedWorkingDirectory)&&(identical(other.selectedTriggerType, selectedTriggerType) || other.selectedTriggerType == selectedTriggerType)&&(identical(other.selectedTriggerBranch, selectedTriggerBranch) || other.selectedTriggerBranch == selectedTriggerBranch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isCreated,selectedRepository,selectedWorkingDirectory,selectedTriggerType,selectedTriggerBranch);

@override
String toString() {
  return 'InitialWorkflowSetupState(isCreated: $isCreated, selectedRepository: $selectedRepository, selectedWorkingDirectory: $selectedWorkingDirectory, selectedTriggerType: $selectedTriggerType, selectedTriggerBranch: $selectedTriggerBranch)';
}


}

/// @nodoc
abstract mixin class _$InitialWorkflowSetupStateCopyWith<$Res> implements $InitialWorkflowSetupStateCopyWith<$Res> {
  factory _$InitialWorkflowSetupStateCopyWith(_InitialWorkflowSetupState value, $Res Function(_InitialWorkflowSetupState) _then) = __$InitialWorkflowSetupStateCopyWithImpl;
@override @useResult
$Res call({
 bool isCreated, String selectedRepository, String selectedWorkingDirectory, TriggerType selectedTriggerType, String selectedTriggerBranch
});




}
/// @nodoc
class __$InitialWorkflowSetupStateCopyWithImpl<$Res>
    implements _$InitialWorkflowSetupStateCopyWith<$Res> {
  __$InitialWorkflowSetupStateCopyWithImpl(this._self, this._then);

  final _InitialWorkflowSetupState _self;
  final $Res Function(_InitialWorkflowSetupState) _then;

/// Create a copy of InitialWorkflowSetupState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isCreated = null,Object? selectedRepository = null,Object? selectedWorkingDirectory = null,Object? selectedTriggerType = null,Object? selectedTriggerBranch = null,}) {
  return _then(_InitialWorkflowSetupState(
isCreated: null == isCreated ? _self.isCreated : isCreated // ignore: cast_nullable_to_non_nullable
as bool,selectedRepository: null == selectedRepository ? _self.selectedRepository : selectedRepository // ignore: cast_nullable_to_non_nullable
as String,selectedWorkingDirectory: null == selectedWorkingDirectory ? _self.selectedWorkingDirectory : selectedWorkingDirectory // ignore: cast_nullable_to_non_nullable
as String,selectedTriggerType: null == selectedTriggerType ? _self.selectedTriggerType : selectedTriggerType // ignore: cast_nullable_to_non_nullable
as TriggerType,selectedTriggerBranch: null == selectedTriggerBranch ? _self.selectedTriggerBranch : selectedTriggerBranch // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
