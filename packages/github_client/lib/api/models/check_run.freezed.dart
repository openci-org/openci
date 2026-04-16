// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'check_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CheckRun {

@JsonKey(name: 'completed_at') DateTime? get completedAt;/// The result of the completed check run. This value will be `null` until the check run has completed.
 Conclusion3? get conclusion;@JsonKey(name: 'details_url') String get detailsUrl;@JsonKey(name: 'external_id') String get externalId;/// The SHA of the Commit that is being checked.
@JsonKey(name: 'head_sha') String get headSha;@JsonKey(name: 'html_url') String get htmlUrl;/// The id of the check.
 int get id;/// The name of the check run.
 String get name;@JsonKey(name: 'node_id') String get nodeId;@JsonKey(name: 'started_at') DateTime get startedAt;/// The current Status of the check run. Can be `queued`, `in_progress`, or `completed`.
@JsonKey(name: 'Status') Status7 get status; String get url;
/// Create a copy of CheckRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckRunCopyWith<CheckRun> get copyWith => _$CheckRunCopyWithImpl<CheckRun>(this as CheckRun, _$identity);

  /// Serializes this CheckRun to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckRun&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion)&&(identical(other.detailsUrl, detailsUrl) || other.detailsUrl == detailsUrl)&&(identical(other.externalId, externalId) || other.externalId == externalId)&&(identical(other.headSha, headSha) || other.headSha == headSha)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,completedAt,conclusion,detailsUrl,externalId,headSha,htmlUrl,id,name,nodeId,startedAt,status,url);

@override
String toString() {
  return 'CheckRun(completedAt: $completedAt, conclusion: $conclusion, detailsUrl: $detailsUrl, externalId: $externalId, headSha: $headSha, htmlUrl: $htmlUrl, id: $id, name: $name, nodeId: $nodeId, startedAt: $startedAt, status: $status, url: $url)';
}


}

/// @nodoc
abstract mixin class $CheckRunCopyWith<$Res>  {
  factory $CheckRunCopyWith(CheckRun value, $Res Function(CheckRun) _then) = _$CheckRunCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'completed_at') DateTime? completedAt, Conclusion3? conclusion,@JsonKey(name: 'details_url') String detailsUrl,@JsonKey(name: 'external_id') String externalId,@JsonKey(name: 'head_sha') String headSha,@JsonKey(name: 'html_url') String htmlUrl, int id, String name,@JsonKey(name: 'node_id') String nodeId,@JsonKey(name: 'started_at') DateTime startedAt,@JsonKey(name: 'Status') Status7 status, String url
});




}
/// @nodoc
class _$CheckRunCopyWithImpl<$Res>
    implements $CheckRunCopyWith<$Res> {
  _$CheckRunCopyWithImpl(this._self, this._then);

  final CheckRun _self;
  final $Res Function(CheckRun) _then;

/// Create a copy of CheckRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completedAt = freezed,Object? conclusion = freezed,Object? detailsUrl = null,Object? externalId = null,Object? headSha = null,Object? htmlUrl = null,Object? id = null,Object? name = null,Object? nodeId = null,Object? startedAt = null,Object? status = null,Object? url = null,}) {
  return _then(_self.copyWith(
completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as Conclusion3?,detailsUrl: null == detailsUrl ? _self.detailsUrl : detailsUrl // ignore: cast_nullable_to_non_nullable
as String,externalId: null == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String,headSha: null == headSha ? _self.headSha : headSha // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status7,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckRun].
extension CheckRunPatterns on CheckRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckRun value)  $default,){
final _that = this;
switch (_that) {
case _CheckRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckRun value)?  $default,){
final _that = this;
switch (_that) {
case _CheckRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'completed_at')  DateTime? completedAt,  Conclusion3? conclusion, @JsonKey(name: 'details_url')  String detailsUrl, @JsonKey(name: 'external_id')  String externalId, @JsonKey(name: 'head_sha')  String headSha, @JsonKey(name: 'html_url')  String htmlUrl,  int id,  String name, @JsonKey(name: 'node_id')  String nodeId, @JsonKey(name: 'started_at')  DateTime startedAt, @JsonKey(name: 'Status')  Status7 status,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckRun() when $default != null:
return $default(_that.completedAt,_that.conclusion,_that.detailsUrl,_that.externalId,_that.headSha,_that.htmlUrl,_that.id,_that.name,_that.nodeId,_that.startedAt,_that.status,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'completed_at')  DateTime? completedAt,  Conclusion3? conclusion, @JsonKey(name: 'details_url')  String detailsUrl, @JsonKey(name: 'external_id')  String externalId, @JsonKey(name: 'head_sha')  String headSha, @JsonKey(name: 'html_url')  String htmlUrl,  int id,  String name, @JsonKey(name: 'node_id')  String nodeId, @JsonKey(name: 'started_at')  DateTime startedAt, @JsonKey(name: 'Status')  Status7 status,  String url)  $default,) {final _that = this;
switch (_that) {
case _CheckRun():
return $default(_that.completedAt,_that.conclusion,_that.detailsUrl,_that.externalId,_that.headSha,_that.htmlUrl,_that.id,_that.name,_that.nodeId,_that.startedAt,_that.status,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'completed_at')  DateTime? completedAt,  Conclusion3? conclusion, @JsonKey(name: 'details_url')  String detailsUrl, @JsonKey(name: 'external_id')  String externalId, @JsonKey(name: 'head_sha')  String headSha, @JsonKey(name: 'html_url')  String htmlUrl,  int id,  String name, @JsonKey(name: 'node_id')  String nodeId, @JsonKey(name: 'started_at')  DateTime startedAt, @JsonKey(name: 'Status')  Status7 status,  String url)?  $default,) {final _that = this;
switch (_that) {
case _CheckRun() when $default != null:
return $default(_that.completedAt,_that.conclusion,_that.detailsUrl,_that.externalId,_that.headSha,_that.htmlUrl,_that.id,_that.name,_that.nodeId,_that.startedAt,_that.status,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckRun implements CheckRun {
  const _CheckRun({@JsonKey(name: 'completed_at') required this.completedAt, required this.conclusion, @JsonKey(name: 'details_url') required this.detailsUrl, @JsonKey(name: 'external_id') required this.externalId, @JsonKey(name: 'head_sha') required this.headSha, @JsonKey(name: 'html_url') required this.htmlUrl, required this.id, required this.name, @JsonKey(name: 'node_id') required this.nodeId, @JsonKey(name: 'started_at') required this.startedAt, @JsonKey(name: 'Status') required this.status, required this.url});
  factory _CheckRun.fromJson(Map<String, dynamic> json) => _$CheckRunFromJson(json);

@override@JsonKey(name: 'completed_at') final  DateTime? completedAt;
/// The result of the completed check run. This value will be `null` until the check run has completed.
@override final  Conclusion3? conclusion;
@override@JsonKey(name: 'details_url') final  String detailsUrl;
@override@JsonKey(name: 'external_id') final  String externalId;
/// The SHA of the Commit that is being checked.
@override@JsonKey(name: 'head_sha') final  String headSha;
@override@JsonKey(name: 'html_url') final  String htmlUrl;
/// The id of the check.
@override final  int id;
/// The name of the check run.
@override final  String name;
@override@JsonKey(name: 'node_id') final  String nodeId;
@override@JsonKey(name: 'started_at') final  DateTime startedAt;
/// The current Status of the check run. Can be `queued`, `in_progress`, or `completed`.
@override@JsonKey(name: 'Status') final  Status7 status;
@override final  String url;

/// Create a copy of CheckRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckRunCopyWith<_CheckRun> get copyWith => __$CheckRunCopyWithImpl<_CheckRun>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckRunToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckRun&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.conclusion, conclusion) || other.conclusion == conclusion)&&(identical(other.detailsUrl, detailsUrl) || other.detailsUrl == detailsUrl)&&(identical(other.externalId, externalId) || other.externalId == externalId)&&(identical(other.headSha, headSha) || other.headSha == headSha)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,completedAt,conclusion,detailsUrl,externalId,headSha,htmlUrl,id,name,nodeId,startedAt,status,url);

@override
String toString() {
  return 'CheckRun(completedAt: $completedAt, conclusion: $conclusion, detailsUrl: $detailsUrl, externalId: $externalId, headSha: $headSha, htmlUrl: $htmlUrl, id: $id, name: $name, nodeId: $nodeId, startedAt: $startedAt, status: $status, url: $url)';
}


}

/// @nodoc
abstract mixin class _$CheckRunCopyWith<$Res> implements $CheckRunCopyWith<$Res> {
  factory _$CheckRunCopyWith(_CheckRun value, $Res Function(_CheckRun) _then) = __$CheckRunCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'completed_at') DateTime? completedAt, Conclusion3? conclusion,@JsonKey(name: 'details_url') String detailsUrl,@JsonKey(name: 'external_id') String externalId,@JsonKey(name: 'head_sha') String headSha,@JsonKey(name: 'html_url') String htmlUrl, int id, String name,@JsonKey(name: 'node_id') String nodeId,@JsonKey(name: 'started_at') DateTime startedAt,@JsonKey(name: 'Status') Status7 status, String url
});




}
/// @nodoc
class __$CheckRunCopyWithImpl<$Res>
    implements _$CheckRunCopyWith<$Res> {
  __$CheckRunCopyWithImpl(this._self, this._then);

  final _CheckRun _self;
  final $Res Function(_CheckRun) _then;

/// Create a copy of CheckRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completedAt = freezed,Object? conclusion = freezed,Object? detailsUrl = null,Object? externalId = null,Object? headSha = null,Object? htmlUrl = null,Object? id = null,Object? name = null,Object? nodeId = null,Object? startedAt = null,Object? status = null,Object? url = null,}) {
  return _then(_CheckRun(
completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,conclusion: freezed == conclusion ? _self.conclusion : conclusion // ignore: cast_nullable_to_non_nullable
as Conclusion3?,detailsUrl: null == detailsUrl ? _self.detailsUrl : detailsUrl // ignore: cast_nullable_to_non_nullable
as String,externalId: null == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String,headSha: null == headSha ? _self.headSha : headSha // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status7,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
