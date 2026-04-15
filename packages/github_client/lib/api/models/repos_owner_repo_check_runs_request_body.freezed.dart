// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repos_owner_repo_check_runs_request_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReposOwnerRepoCheckRunsRequestBody {

/// The name of the check. For example, "code-coverage".
 String get name;/// The SHA of the commit.
@JsonKey(name: 'head_sha') String get headSha;/// The current Status of the check run. Only GitHub Actions can set a Status of `waiting`, `pending`, or `requested`.
@JsonKey(name: 'Status') Status get status;/// The URL of the integrator's site that has the full details of the check. If the integrator does not provide this, then the homepage of the GitHub app is used.
@JsonKey(name: 'details_url') String? get detailsUrl;/// A reference for the run on the integrator's system.
@JsonKey(name: 'external_id') String? get externalId;/// The time that the check run began. This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
@JsonKey(name: 'started_at') DateTime? get startedAt;/// **Required if you provide `completed_at` or a `status` of `completed`**. The final conclusion of the check. .
/// **Note:** Providing `conclusion` will automatically set the `status` parameter to `completed`. You cannot change a check run conclusion to `stale`, only GitHub can set this.
 Conclusion? get conclusion;/// The time the check completed. This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
@JsonKey(name: 'completed_at') DateTime? get completedAt;/// Check runs can accept a variety of data in the `output` object, including a `title` and `summary` and can optionally provide descriptive details about the run.
 Output? get output;/// Displays a button on GitHub that can be clicked to alert your app to do additional tasks. For example, a code linting app can display a button that automatically fixes detected errors. The button created in this object is displayed after the check run completes. When a user clicks the button, GitHub sends the [`check_run.requested_action` webhook](https://docs.github.com/webhooks/event-payloads/#check_run) to your app. Each action includes a `label`, `identifier` and `description`. A maximum of three actions are accepted. To learn more about check runs and requested actions, see "[Check runs and requested actions](https://docs.github.com/rest/guides/using-the-rest-api-to-interact-with-checks#check-runs-and-requested-actions)."
 List<Actions>? get actions;
/// Create a copy of ReposOwnerRepoCheckRunsRequestBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReposOwnerRepoCheckRunsRequestBodyCopyWith<ReposOwnerRepoCheckRunsRequestBody> get copyWith => _$ReposOwnerRepoCheckRunsRequestBodyCopyWithImpl<ReposOwnerRepoCheckRunsRequestBody>(this as ReposOwnerRepoCheckRunsRequestBody, _$identity);

  /// Serializes this ReposOwnerRepoCheckRunsRequestBody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReposOwnerRepoCheckRunsRequestBody&&(identical(other.name, name) || other.name == name)&&(identical(other.headSha, headSha) || other.headSha == headSha)&&(identical(other.status, status) || other.status == status)&&(identical(other.detailsUrl, detailsUrl) || other.detailsUrl == detailsUrl)&&(identical(other.externalId, externalId) || other.externalId == externalId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.output, output) || other.output == output)&&const DeepCollectionEquality().equals(other.actions, actions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,headSha,status,detailsUrl,externalId,startedAt,conclusion,completedAt,output,const DeepCollectionEquality().hash(actions));

@override
String toString() {
  return 'ReposOwnerRepoCheckRunsRequestBody(name: $name, headSha: $headSha, status: $status, detailsUrl: $detailsUrl, externalId: $externalId, startedAt: $startedAt, conclusion: $conclusion, completedAt: $completedAt, output: $output, actions: $actions)';
}


}

/// @nodoc
abstract mixin class $ReposOwnerRepoCheckRunsRequestBodyCopyWith<$Res>  {
  factory $ReposOwnerRepoCheckRunsRequestBodyCopyWith(ReposOwnerRepoCheckRunsRequestBody value, $Res Function(ReposOwnerRepoCheckRunsRequestBody) _then) = _$ReposOwnerRepoCheckRunsRequestBodyCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'head_sha') String headSha,@JsonKey(name: 'Status') Status status,@JsonKey(name: 'details_url') String? detailsUrl,@JsonKey(name: 'external_id') String? externalId,@JsonKey(name: 'started_at') DateTime? startedAt, Conclusion? conclusion,@JsonKey(name: 'completed_at') DateTime? completedAt, Output? output, List<Actions>? actions
});


$OutputCopyWith<$Res>? get output;

}
/// @nodoc
class _$ReposOwnerRepoCheckRunsRequestBodyCopyWithImpl<$Res>
    implements $ReposOwnerRepoCheckRunsRequestBodyCopyWith<$Res> {
  _$ReposOwnerRepoCheckRunsRequestBodyCopyWithImpl(this._self, this._then);

  final ReposOwnerRepoCheckRunsRequestBody _self;
  final $Res Function(ReposOwnerRepoCheckRunsRequestBody) _then;

/// Create a copy of ReposOwnerRepoCheckRunsRequestBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? headSha = null,Object? status = null,Object? detailsUrl = freezed,Object? externalId = freezed,Object? startedAt = freezed,Object? conclusion = freezed,Object? completedAt = freezed,Object? output = freezed,Object? actions = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,headSha: null == headSha ? _self.headSha : headSha // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status,detailsUrl: freezed == detailsUrl ? _self.detailsUrl : detailsUrl // ignore: cast_nullable_to_non_nullable
as String?,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as Conclusion?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as Output?,actions: freezed == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<Actions>?,
  ));
}
/// Create a copy of ReposOwnerRepoCheckRunsRequestBody
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OutputCopyWith<$Res>? get output {
    if (_self.output == null) {
    return null;
  }

  return $OutputCopyWith<$Res>(_self.output!, (value) {
    return _then(_self.copyWith(output: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReposOwnerRepoCheckRunsRequestBody].
extension ReposOwnerRepoCheckRunsRequestBodyPatterns on ReposOwnerRepoCheckRunsRequestBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReposOwnerRepoCheckRunsRequestBody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsRequestBody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReposOwnerRepoCheckRunsRequestBody value)  $default,){
final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsRequestBody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReposOwnerRepoCheckRunsRequestBody value)?  $default,){
final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsRequestBody() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'head_sha')  String headSha, @JsonKey(name: 'Status')  Status status, @JsonKey(name: 'details_url')  String? detailsUrl, @JsonKey(name: 'external_id')  String? externalId, @JsonKey(name: 'started_at')  DateTime? startedAt,  Conclusion? conclusion, @JsonKey(name: 'completed_at')  DateTime? completedAt,  Output? output,  List<Actions>? actions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsRequestBody() when $default != null:
return $default(_that.name,_that.headSha,_that.status,_that.detailsUrl,_that.externalId,_that.startedAt,_that.conclusion,_that.completedAt,_that.output,_that.actions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'head_sha')  String headSha, @JsonKey(name: 'Status')  Status status, @JsonKey(name: 'details_url')  String? detailsUrl, @JsonKey(name: 'external_id')  String? externalId, @JsonKey(name: 'started_at')  DateTime? startedAt,  Conclusion? conclusion, @JsonKey(name: 'completed_at')  DateTime? completedAt,  Output? output,  List<Actions>? actions)  $default,) {final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsRequestBody():
return $default(_that.name,_that.headSha,_that.status,_that.detailsUrl,_that.externalId,_that.startedAt,_that.conclusion,_that.completedAt,_that.output,_that.actions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'head_sha')  String headSha, @JsonKey(name: 'Status')  Status status, @JsonKey(name: 'details_url')  String? detailsUrl, @JsonKey(name: 'external_id')  String? externalId, @JsonKey(name: 'started_at')  DateTime? startedAt,  Conclusion? conclusion, @JsonKey(name: 'completed_at')  DateTime? completedAt,  Output? output,  List<Actions>? actions)?  $default,) {final _that = this;
switch (_that) {
case _ReposOwnerRepoCheckRunsRequestBody() when $default != null:
return $default(_that.name,_that.headSha,_that.status,_that.detailsUrl,_that.externalId,_that.startedAt,_that.conclusion,_that.completedAt,_that.output,_that.actions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReposOwnerRepoCheckRunsRequestBody implements ReposOwnerRepoCheckRunsRequestBody {
  const _ReposOwnerRepoCheckRunsRequestBody({required this.name, @JsonKey(name: 'head_sha') required this.headSha, @JsonKey(name: 'Status') this.status = Status.queued, @JsonKey(name: 'details_url') this.detailsUrl, @JsonKey(name: 'external_id') this.externalId, @JsonKey(name: 'started_at') this.startedAt, this.conclusion, @JsonKey(name: 'completed_at') this.completedAt, this.output, final  List<Actions>? actions}): _actions = actions;
  factory _ReposOwnerRepoCheckRunsRequestBody.fromJson(Map<String, dynamic> json) => _$ReposOwnerRepoCheckRunsRequestBodyFromJson(json);

/// The name of the check. For example, "code-coverage".
@override final  String name;
/// The SHA of the commit.
@override@JsonKey(name: 'head_sha') final  String headSha;
/// The current Status of the check run. Only GitHub Actions can set a Status of `waiting`, `pending`, or `requested`.
@override@JsonKey(name: 'Status') final  Status status;
/// The URL of the integrator's site that has the full details of the check. If the integrator does not provide this, then the homepage of the GitHub app is used.
@override@JsonKey(name: 'details_url') final  String? detailsUrl;
/// A reference for the run on the integrator's system.
@override@JsonKey(name: 'external_id') final  String? externalId;
/// The time that the check run began. This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
@override@JsonKey(name: 'started_at') final  DateTime? startedAt;
/// **Required if you provide `completed_at` or a `status` of `completed`**. The final conclusion of the check. .
/// **Note:** Providing `conclusion` will automatically set the `status` parameter to `completed`. You cannot change a check run conclusion to `stale`, only GitHub can set this.
@override final  Conclusion? conclusion;
/// The time the check completed. This is a timestamp in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format: `YYYY-MM-DDTHH:MM:SSZ`.
@override@JsonKey(name: 'completed_at') final  DateTime? completedAt;
/// Check runs can accept a variety of data in the `output` object, including a `title` and `summary` and can optionally provide descriptive details about the run.
@override final  Output? output;
/// Displays a button on GitHub that can be clicked to alert your app to do additional tasks. For example, a code linting app can display a button that automatically fixes detected errors. The button created in this object is displayed after the check run completes. When a user clicks the button, GitHub sends the [`check_run.requested_action` webhook](https://docs.github.com/webhooks/event-payloads/#check_run) to your app. Each action includes a `label`, `identifier` and `description`. A maximum of three actions are accepted. To learn more about check runs and requested actions, see "[Check runs and requested actions](https://docs.github.com/rest/guides/using-the-rest-api-to-interact-with-checks#check-runs-and-requested-actions)."
 final  List<Actions>? _actions;
/// Displays a button on GitHub that can be clicked to alert your app to do additional tasks. For example, a code linting app can display a button that automatically fixes detected errors. The button created in this object is displayed after the check run completes. When a user clicks the button, GitHub sends the [`check_run.requested_action` webhook](https://docs.github.com/webhooks/event-payloads/#check_run) to your app. Each action includes a `label`, `identifier` and `description`. A maximum of three actions are accepted. To learn more about check runs and requested actions, see "[Check runs and requested actions](https://docs.github.com/rest/guides/using-the-rest-api-to-interact-with-checks#check-runs-and-requested-actions)."
@override List<Actions>? get actions {
  final value = _actions;
  if (value == null) return null;
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ReposOwnerRepoCheckRunsRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReposOwnerRepoCheckRunsRequestBodyCopyWith<_ReposOwnerRepoCheckRunsRequestBody> get copyWith => __$ReposOwnerRepoCheckRunsRequestBodyCopyWithImpl<_ReposOwnerRepoCheckRunsRequestBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReposOwnerRepoCheckRunsRequestBodyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReposOwnerRepoCheckRunsRequestBody&&(identical(other.name, name) || other.name == name)&&(identical(other.headSha, headSha) || other.headSha == headSha)&&(identical(other.status, status) || other.status == status)&&(identical(other.detailsUrl, detailsUrl) || other.detailsUrl == detailsUrl)&&(identical(other.externalId, externalId) || other.externalId == externalId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.output, output) || other.output == output)&&const DeepCollectionEquality().equals(other._actions, _actions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,headSha,status,detailsUrl,externalId,startedAt,conclusion,completedAt,output,const DeepCollectionEquality().hash(_actions));

@override
String toString() {
  return 'ReposOwnerRepoCheckRunsRequestBody(name: $name, headSha: $headSha, status: $status, detailsUrl: $detailsUrl, externalId: $externalId, startedAt: $startedAt, conclusion: $conclusion, completedAt: $completedAt, output: $output, actions: $actions)';
}


}

/// @nodoc
abstract mixin class _$ReposOwnerRepoCheckRunsRequestBodyCopyWith<$Res> implements $ReposOwnerRepoCheckRunsRequestBodyCopyWith<$Res> {
  factory _$ReposOwnerRepoCheckRunsRequestBodyCopyWith(_ReposOwnerRepoCheckRunsRequestBody value, $Res Function(_ReposOwnerRepoCheckRunsRequestBody) _then) = __$ReposOwnerRepoCheckRunsRequestBodyCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'head_sha') String headSha,@JsonKey(name: 'Status') Status status,@JsonKey(name: 'details_url') String? detailsUrl,@JsonKey(name: 'external_id') String? externalId,@JsonKey(name: 'started_at') DateTime? startedAt, Conclusion? conclusion,@JsonKey(name: 'completed_at') DateTime? completedAt, Output? output, List<Actions>? actions
});


@override $OutputCopyWith<$Res>? get output;

}
/// @nodoc
class __$ReposOwnerRepoCheckRunsRequestBodyCopyWithImpl<$Res>
    implements _$ReposOwnerRepoCheckRunsRequestBodyCopyWith<$Res> {
  __$ReposOwnerRepoCheckRunsRequestBodyCopyWithImpl(this._self, this._then);

  final _ReposOwnerRepoCheckRunsRequestBody _self;
  final $Res Function(_ReposOwnerRepoCheckRunsRequestBody) _then;

/// Create a copy of ReposOwnerRepoCheckRunsRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? headSha = null,Object? status = null,Object? detailsUrl = freezed,Object? externalId = freezed,Object? startedAt = freezed,Object? conclusion = freezed,Object? completedAt = freezed,Object? output = freezed,Object? actions = freezed,}) {
  return _then(_ReposOwnerRepoCheckRunsRequestBody(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,headSha: null == headSha ? _self.headSha : headSha // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status,detailsUrl: freezed == detailsUrl ? _self.detailsUrl : detailsUrl // ignore: cast_nullable_to_non_nullable
as String?,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as Conclusion?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,output: freezed == output ? _self.output : output // ignore: cast_nullable_to_non_nullable
as Output?,actions: freezed == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<Actions>?,
  ));
}

/// Create a copy of ReposOwnerRepoCheckRunsRequestBody
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OutputCopyWith<$Res>? get output {
    if (_self.output == null) {
    return null;
  }

  return $OutputCopyWith<$Res>(_self.output!, (value) {
    return _then(_self.copyWith(output: value));
  });
}
}

// dart format on
