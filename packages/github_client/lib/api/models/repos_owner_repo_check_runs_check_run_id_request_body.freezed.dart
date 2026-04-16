// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repos_owner_repo_check_runs_check_run_id_request_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReposOwnerRepoCheckRunsCheckRunIdRequestBody {

/// The name of the check. For example, "code-coverage".
 String? get name;/// The URL of the integrator's site that has the full details of the check.
@JsonKey(name: 'details_url') String? get detailsUrl;/// A reference for the run on the integrator's system.
@JsonKey(name: 'external_id') String? get externalId;/// This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
@JsonKey(name: 'started_at') DateTime? get startedAt;/// The current Status of the check run. Only GitHub Actions can set a Status of `waiting`, `pending`, or `requested`.
@JsonKey(name: 'Status') Status? get status;/// **Required if you provide `completed_at` or a `status` of `completed`**. The final conclusion of the check. .
/// **Note:** Providing `conclusion` will automatically set the `status` parameter to `completed`. You cannot change a check run conclusion to `stale`, only GitHub can set this.
 Conclusion? get conclusion;/// The time the check completed. This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
@JsonKey(name: 'completed_at') DateTime? get completedAt;/// Check runs can accept a variety of data in the `output` object, including a `title` and `summary` and can optionally provide descriptive details about the run.
 Output2? get output;/// Possible further actions the integrator can perform, which a user may trigger. Each action includes a `label`, `identifier` and `description`. A maximum of three actions are accepted. To learn more about check runs and requested actions, see "[Check runs and requested actions](https://docs.github.com/rest/guides/using-the-rest-api-to-interact-with-checks#check-runs-and-requested-actions)."
 List<Actions2>? get actions;
/// Create a copy of ReposOwnerRepoCheckRunsCheckRunIdRequestBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWith<ReposOwnerRepoCheckRunsCheckRunIdRequestBody> get copyWith => _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWithImpl<ReposOwnerRepoCheckRunsCheckRunIdRequestBody>(this as ReposOwnerRepoCheckRunsCheckRunIdRequestBody, _$identity);

  /// Serializes this ReposOwnerRepoCheckRunsCheckRunIdRequestBody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReposOwnerRepoCheckRunsCheckRunIdRequestBody&&(identical(other.name, name) || other.name == name)&&(identical(other.detailsUrl, detailsUrl) || other.detailsUrl == detailsUrl)&&(identical(other.externalId, externalId) || other.externalId == externalId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.output, output) || other.output == output)&&const DeepCollectionEquality().equals(other.actions, actions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,detailsUrl,externalId,startedAt,status,conclusion,completedAt,output,const DeepCollectionEquality().hash(actions));

@override
String toString() {
  return 'ReposOwnerRepoCheckRunsCheckRunIdRequestBody(name: $name, detailsUrl: $detailsUrl, externalId: $externalId, startedAt: $startedAt, status: $status, conclusion: $conclusion, completedAt: $completedAt, output: $output, actions: $actions)';
}


}

/// @nodoc
abstract mixin class $ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWith<$Res>  {
  factory $ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWith(ReposOwnerRepoCheckRunsCheckRunIdRequestBody value, $Res Function(ReposOwnerRepoCheckRunsCheckRunIdRequestBody) _then) = _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWithImpl;
@useResult
$Res call({
 String? name,@JsonKey(name: 'details_url') String? detailsUrl,@JsonKey(name: 'external_id') String? externalId,@JsonKey(name: 'started_at') DateTime? startedAt,@JsonKey(name: 'Status') Status? status, Conclusion? conclusion,@JsonKey(name: 'completed_at') DateTime? completedAt, Output2? output, List<Actions2>? actions
});


$Output2CopyWith<$Res>? get output;

}
/// @nodoc
class _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWithImpl<$Res>
    implements $ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWith<$Res> {
  _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWithImpl(this._self, this._then);

  final ReposOwnerRepoCheckRunsCheckRunIdRequestBody _self;
  final $Res Function(ReposOwnerRepoCheckRunsCheckRunIdRequestBody) _then;

/// Create a copy of ReposOwnerRepoCheckRunsCheckRunIdRequestBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? detailsUrl = freezed,Object? externalId = freezed,Object? startedAt = freezed,Object? status = freezed,Object? conclusion = freezed,Object? completedAt = freezed,Object? output = freezed,Object? actions = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,detailsUrl: freezed == detailsUrl ? _self.detailsUrl : detailsUrl // ignore: cast_nullable_to_non_nullable
as String?,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status?,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as Conclusion?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as Output2?,actions: freezed == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<Actions2>?,
  ));
}
/// Create a copy of ReposOwnerRepoCheckRunsCheckRunIdRequestBody
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Output2CopyWith<$Res>? get output {
    if (_self.output == null) {
    return null;
  }

  return $Output2CopyWith<$Res>(_self.output!, (value) {
    return _then(_self.copyWith(output: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReposOwnerRepoCheckRunsCheckRunIdRequestBody].
extension ReposOwnerRepoCheckRunsCheckRunIdRequestBodyPatterns on ReposOwnerRepoCheckRunsCheckRunIdRequestBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReposOwnerRepoCheckRunsCheckRunIdRequestBody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsCheckRunIdRequestBody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReposOwnerRepoCheckRunsCheckRunIdRequestBody value)  $default,){
final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsCheckRunIdRequestBody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReposOwnerRepoCheckRunsCheckRunIdRequestBody value)?  $default,){
final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsCheckRunIdRequestBody() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name, @JsonKey(name: 'details_url')  String? detailsUrl, @JsonKey(name: 'external_id')  String? externalId, @JsonKey(name: 'started_at')  DateTime? startedAt, @JsonKey(name: 'Status')  Status? status,  Conclusion? conclusion, @JsonKey(name: 'completed_at')  DateTime? completedAt,  Output2? output,  List<Actions2>? actions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsCheckRunIdRequestBody() when $default != null:
return $default(_that.name,_that.detailsUrl,_that.externalId,_that.startedAt,_that.status,_that.conclusion,_that.completedAt,_that.output,_that.actions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name, @JsonKey(name: 'details_url')  String? detailsUrl, @JsonKey(name: 'external_id')  String? externalId, @JsonKey(name: 'started_at')  DateTime? startedAt, @JsonKey(name: 'Status')  Status? status,  Conclusion? conclusion, @JsonKey(name: 'completed_at')  DateTime? completedAt,  Output2? output,  List<Actions2>? actions)  $default,) {final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsCheckRunIdRequestBody():
return $default(_that.name,_that.detailsUrl,_that.externalId,_that.startedAt,_that.status,_that.conclusion,_that.completedAt,_that.output,_that.actions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name, @JsonKey(name: 'details_url')  String? detailsUrl, @JsonKey(name: 'external_id')  String? externalId, @JsonKey(name: 'started_at')  DateTime? startedAt, @JsonKey(name: 'Status')  Status? status,  Conclusion? conclusion, @JsonKey(name: 'completed_at')  DateTime? completedAt,  Output2? output,  List<Actions2>? actions)?  $default,) {final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsCheckRunIdRequestBody() when $default != null:
return $default(_that.name,_that.detailsUrl,_that.externalId,_that.startedAt,_that.status,_that.conclusion,_that.completedAt,_that.output,_that.actions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReposOwnerRepoCheckRunsCheckRunIdRequestBody implements ReposOwnerRepoCheckRunsCheckRunIdRequestBody {
  const _ReposOwnerRepoCheckRunsCheckRunIdRequestBody({this.name, @JsonKey(name: 'details_url') this.detailsUrl, @JsonKey(name: 'external_id') this.externalId, @JsonKey(name: 'started_at') this.startedAt, @JsonKey(name: 'Status') this.status, this.conclusion, @JsonKey(name: 'completed_at') this.completedAt, this.output, final  List<Actions2>? actions}): _actions = actions;
  factory _ReposOwnerRepoCheckRunsCheckRunIdRequestBody.fromJson(Map<String, dynamic> json) => _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyFromJson(json);

/// The name of the check. For example, "code-coverage".
@override final  String? name;
/// The URL of the integrator's site that has the full details of the check.
@override@JsonKey(name: 'details_url') final  String? detailsUrl;
/// A reference for the run on the integrator's system.
@override@JsonKey(name: 'external_id') final  String? externalId;
/// This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
@override@JsonKey(name: 'started_at') final  DateTime? startedAt;
/// The current Status of the check run. Only GitHub Actions can set a Status of `waiting`, `pending`, or `requested`.
@override@JsonKey(name: 'Status') final  Status? status;
/// **Required if you provide `completed_at` or a `status` of `completed`**. The final conclusion of the check. .
/// **Note:** Providing `conclusion` will automatically set the `status` parameter to `completed`. You cannot change a check run conclusion to `stale`, only GitHub can set this.
@override final  Conclusion? conclusion;
/// The time the check completed. This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
@override@JsonKey(name: 'completed_at') final  DateTime? completedAt;
/// Check runs can accept a variety of data in the `output` object, including a `title` and `summary` and can optionally provide descriptive details about the run.
@override final  Output2? output;
/// Possible further actions the integrator can perform, which a user may trigger. Each action includes a `label`, `identifier` and `description`. A maximum of three actions are accepted. To learn more about check runs and requested actions, see "[Check runs and requested actions](https://docs.github.com/rest/guides/using-the-rest-api-to-interact-with-checks#check-runs-and-requested-actions)."
 final  List<Actions2>? _actions;
/// Possible further actions the integrator can perform, which a user may trigger. Each action includes a `label`, `identifier` and `description`. A maximum of three actions are accepted. To learn more about check runs and requested actions, see "[Check runs and requested actions](https://docs.github.com/rest/guides/using-the-rest-api-to-interact-with-checks#check-runs-and-requested-actions)."
@override List<Actions2>? get actions {
  final value = _actions;
  if (value == null) return null;
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ReposOwnerRepoCheckRunsCheckRunIdRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWith<_ReposOwnerRepoCheckRunsCheckRunIdRequestBody> get copyWith => __$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWithImpl<_ReposOwnerRepoCheckRunsCheckRunIdRequestBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReposOwnerRepoCheckRunsCheckRunIdRequestBody&&(identical(other.name, name) || other.name == name)&&(identical(other.detailsUrl, detailsUrl) || other.detailsUrl == detailsUrl)&&(identical(other.externalId, externalId) || other.externalId == externalId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.output, output) || other.output == output)&&const DeepCollectionEquality().equals(other._actions, _actions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,detailsUrl,externalId,startedAt,status,conclusion,completedAt,output,const DeepCollectionEquality().hash(_actions));

@override
String toString() {
  return 'ReposOwnerRepoCheckRunsCheckRunIdRequestBody(name: $name, detailsUrl: $detailsUrl, externalId: $externalId, startedAt: $startedAt, status: $status, conclusion: $conclusion, completedAt: $completedAt, output: $output, actions: $actions)';
}


}

/// @nodoc
abstract mixin class _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWith<$Res> implements $ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWith<$Res> {
  factory _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWith(_ReposOwnerRepoCheckRunsCheckRunIdRequestBody value, $Res Function(_ReposOwnerRepoCheckRunsCheckRunIdRequestBody) _then) = __$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWithImpl;
@override @useResult
$Res call({
 String? name,@JsonKey(name: 'details_url') String? detailsUrl,@JsonKey(name: 'external_id') String? externalId,@JsonKey(name: 'started_at') DateTime? startedAt,@JsonKey(name: 'Status') Status? status, Conclusion? conclusion,@JsonKey(name: 'completed_at') DateTime? completedAt, Output2? output, List<Actions2>? actions
});


@override $Output2CopyWith<$Res>? get output;

}
/// @nodoc
class __$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWithImpl<$Res>
    implements _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWith<$Res> {
  __$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyCopyWithImpl(this._self, this._then);

  final _ReposOwnerRepoCheckRunsCheckRunIdRequestBody _self;
  final $Res Function(_ReposOwnerRepoCheckRunsCheckRunIdRequestBody) _then;

/// Create a copy of ReposOwnerRepoCheckRunsCheckRunIdRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? detailsUrl = freezed,Object? externalId = freezed,Object? startedAt = freezed,Object? status = freezed,Object? conclusion = freezed,Object? completedAt = freezed,Object? output = freezed,Object? actions = freezed,}) {
  return _then(_ReposOwnerRepoCheckRunsCheckRunIdRequestBody(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,detailsUrl: freezed == detailsUrl ? _self.detailsUrl : detailsUrl // ignore: cast_nullable_to_non_nullable
as String?,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status?,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as Conclusion?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as Output2?,actions: freezed == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<Actions2>?,
  ));
}

/// Create a copy of ReposOwnerRepoCheckRunsCheckRunIdRequestBody
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Output2CopyWith<$Res>? get output {
    if (_self.output == null) {
    return null;
  }

  return $Output2CopyWith<$Res>(_self.output!, (value) {
    return _then(_self.copyWith(output: value));
  });
}
}

// dart format on
