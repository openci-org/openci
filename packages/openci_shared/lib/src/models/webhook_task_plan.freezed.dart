// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'webhook_task_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WebhookTaskPlan {

 List<BuildJobPlan> get jobs;@JsonKey(disallowNullValue: true) List<SkippedWorkflowPlan> get skippedWorkflows; String? get changedFilesFallbackReason;
/// Create a copy of WebhookTaskPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebhookTaskPlanCopyWith<WebhookTaskPlan> get copyWith => _$WebhookTaskPlanCopyWithImpl<WebhookTaskPlan>(this as WebhookTaskPlan, _$identity);

  /// Serializes this WebhookTaskPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebhookTaskPlan&&const DeepCollectionEquality().equals(other.jobs, jobs)&&const DeepCollectionEquality().equals(other.skippedWorkflows, skippedWorkflows)&&(identical(other.changedFilesFallbackReason, changedFilesFallbackReason) || other.changedFilesFallbackReason == changedFilesFallbackReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(jobs),const DeepCollectionEquality().hash(skippedWorkflows),changedFilesFallbackReason);

@override
String toString() {
  return 'WebhookTaskPlan(jobs: $jobs, skippedWorkflows: $skippedWorkflows, changedFilesFallbackReason: $changedFilesFallbackReason)';
}


}

/// @nodoc
abstract mixin class $WebhookTaskPlanCopyWith<$Res>  {
  factory $WebhookTaskPlanCopyWith(WebhookTaskPlan value, $Res Function(WebhookTaskPlan) _then) = _$WebhookTaskPlanCopyWithImpl;
@useResult
$Res call({
 List<BuildJobPlan> jobs,@JsonKey(disallowNullValue: true) List<SkippedWorkflowPlan> skippedWorkflows, String? changedFilesFallbackReason
});




}
/// @nodoc
class _$WebhookTaskPlanCopyWithImpl<$Res>
    implements $WebhookTaskPlanCopyWith<$Res> {
  _$WebhookTaskPlanCopyWithImpl(this._self, this._then);

  final WebhookTaskPlan _self;
  final $Res Function(WebhookTaskPlan) _then;

/// Create a copy of WebhookTaskPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobs = null,Object? skippedWorkflows = null,Object? changedFilesFallbackReason = freezed,}) {
  return _then(_self.copyWith(
jobs: null == jobs ? _self.jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<BuildJobPlan>,skippedWorkflows: null == skippedWorkflows ? _self.skippedWorkflows : skippedWorkflows // ignore: cast_nullable_to_non_nullable
as List<SkippedWorkflowPlan>,changedFilesFallbackReason: freezed == changedFilesFallbackReason ? _self.changedFilesFallbackReason : changedFilesFallbackReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WebhookTaskPlan].
extension WebhookTaskPlanPatterns on WebhookTaskPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebhookTaskPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebhookTaskPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebhookTaskPlan value)  $default,){
final _that = this;
switch (_that) {
case _WebhookTaskPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebhookTaskPlan value)?  $default,){
final _that = this;
switch (_that) {
case _WebhookTaskPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuildJobPlan> jobs, @JsonKey(disallowNullValue: true)  List<SkippedWorkflowPlan> skippedWorkflows,  String? changedFilesFallbackReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebhookTaskPlan() when $default != null:
return $default(_that.jobs,_that.skippedWorkflows,_that.changedFilesFallbackReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuildJobPlan> jobs, @JsonKey(disallowNullValue: true)  List<SkippedWorkflowPlan> skippedWorkflows,  String? changedFilesFallbackReason)  $default,) {final _that = this;
switch (_that) {
case _WebhookTaskPlan():
return $default(_that.jobs,_that.skippedWorkflows,_that.changedFilesFallbackReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuildJobPlan> jobs, @JsonKey(disallowNullValue: true)  List<SkippedWorkflowPlan> skippedWorkflows,  String? changedFilesFallbackReason)?  $default,) {final _that = this;
switch (_that) {
case _WebhookTaskPlan() when $default != null:
return $default(_that.jobs,_that.skippedWorkflows,_that.changedFilesFallbackReason);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(disallowUnrecognizedKeys: true, explicitToJson: true, includeIfNull: false)
class _WebhookTaskPlan implements WebhookTaskPlan {
  const _WebhookTaskPlan({required final  List<BuildJobPlan> jobs, @JsonKey(disallowNullValue: true) final  List<SkippedWorkflowPlan> skippedWorkflows = const <SkippedWorkflowPlan>[], this.changedFilesFallbackReason}): _jobs = jobs,_skippedWorkflows = skippedWorkflows;
  factory _WebhookTaskPlan.fromJson(Map<String, dynamic> json) => _$WebhookTaskPlanFromJson(json);

 final  List<BuildJobPlan> _jobs;
@override List<BuildJobPlan> get jobs {
  if (_jobs is EqualUnmodifiableListView) return _jobs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_jobs);
}

 final  List<SkippedWorkflowPlan> _skippedWorkflows;
@override@JsonKey(disallowNullValue: true) List<SkippedWorkflowPlan> get skippedWorkflows {
  if (_skippedWorkflows is EqualUnmodifiableListView) return _skippedWorkflows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skippedWorkflows);
}

@override final  String? changedFilesFallbackReason;

/// Create a copy of WebhookTaskPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebhookTaskPlanCopyWith<_WebhookTaskPlan> get copyWith => __$WebhookTaskPlanCopyWithImpl<_WebhookTaskPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebhookTaskPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebhookTaskPlan&&const DeepCollectionEquality().equals(other._jobs, _jobs)&&const DeepCollectionEquality().equals(other._skippedWorkflows, _skippedWorkflows)&&(identical(other.changedFilesFallbackReason, changedFilesFallbackReason) || other.changedFilesFallbackReason == changedFilesFallbackReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_jobs),const DeepCollectionEquality().hash(_skippedWorkflows),changedFilesFallbackReason);

@override
String toString() {
  return 'WebhookTaskPlan(jobs: $jobs, skippedWorkflows: $skippedWorkflows, changedFilesFallbackReason: $changedFilesFallbackReason)';
}


}

/// @nodoc
abstract mixin class _$WebhookTaskPlanCopyWith<$Res> implements $WebhookTaskPlanCopyWith<$Res> {
  factory _$WebhookTaskPlanCopyWith(_WebhookTaskPlan value, $Res Function(_WebhookTaskPlan) _then) = __$WebhookTaskPlanCopyWithImpl;
@override @useResult
$Res call({
 List<BuildJobPlan> jobs,@JsonKey(disallowNullValue: true) List<SkippedWorkflowPlan> skippedWorkflows, String? changedFilesFallbackReason
});




}
/// @nodoc
class __$WebhookTaskPlanCopyWithImpl<$Res>
    implements _$WebhookTaskPlanCopyWith<$Res> {
  __$WebhookTaskPlanCopyWithImpl(this._self, this._then);

  final _WebhookTaskPlan _self;
  final $Res Function(_WebhookTaskPlan) _then;

/// Create a copy of WebhookTaskPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobs = null,Object? skippedWorkflows = null,Object? changedFilesFallbackReason = freezed,}) {
  return _then(_WebhookTaskPlan(
jobs: null == jobs ? _self._jobs : jobs // ignore: cast_nullable_to_non_nullable
as List<BuildJobPlan>,skippedWorkflows: null == skippedWorkflows ? _self._skippedWorkflows : skippedWorkflows // ignore: cast_nullable_to_non_nullable
as List<SkippedWorkflowPlan>,changedFilesFallbackReason: freezed == changedFilesFallbackReason ? _self.changedFilesFallbackReason : changedFilesFallbackReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
