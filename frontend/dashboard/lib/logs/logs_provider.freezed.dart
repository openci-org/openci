// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'logs_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuildJob {

 String get id; String get status; String get owner; String get repo; String? get userId; String? get commitSha; int? get pullRequestNumber; int? get runCount; String? get latestRunId;@TimestampConverter() DateTime get createdAt;@TimestampConverter() DateTime get updatedAt;
/// Create a copy of BuildJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildJobCopyWith<BuildJob> get copyWith => _$BuildJobCopyWithImpl<BuildJob>(this as BuildJob, _$identity);

  /// Serializes this BuildJob to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildJob&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.pullRequestNumber, pullRequestNumber) || other.pullRequestNumber == pullRequestNumber)&&(identical(other.runCount, runCount) || other.runCount == runCount)&&(identical(other.latestRunId, latestRunId) || other.latestRunId == latestRunId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,owner,repo,userId,commitSha,pullRequestNumber,runCount,latestRunId,createdAt,updatedAt);

@override
String toString() {
  return 'BuildJob(id: $id, status: $status, owner: $owner, repo: $repo, userId: $userId, commitSha: $commitSha, pullRequestNumber: $pullRequestNumber, runCount: $runCount, latestRunId: $latestRunId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BuildJobCopyWith<$Res>  {
  factory $BuildJobCopyWith(BuildJob value, $Res Function(BuildJob) _then) = _$BuildJobCopyWithImpl;
@useResult
$Res call({
 String id, String status, String owner, String repo, String? userId, String? commitSha, int? pullRequestNumber, int? runCount, String? latestRunId,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class _$BuildJobCopyWithImpl<$Res>
    implements $BuildJobCopyWith<$Res> {
  _$BuildJobCopyWithImpl(this._self, this._then);

  final BuildJob _self;
  final $Res Function(BuildJob) _then;

/// Create a copy of BuildJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? owner = null,Object? repo = null,Object? userId = freezed,Object? commitSha = freezed,Object? pullRequestNumber = freezed,Object? runCount = freezed,Object? latestRunId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,pullRequestNumber: freezed == pullRequestNumber ? _self.pullRequestNumber : pullRequestNumber // ignore: cast_nullable_to_non_nullable
as int?,runCount: freezed == runCount ? _self.runCount : runCount // ignore: cast_nullable_to_non_nullable
as int?,latestRunId: freezed == latestRunId ? _self.latestRunId : latestRunId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BuildJob].
extension BuildJobPatterns on BuildJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildJob value)  $default,){
final _that = this;
switch (_that) {
case _BuildJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildJob value)?  $default,){
final _that = this;
switch (_that) {
case _BuildJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status,  String owner,  String repo,  String? userId,  String? commitSha,  int? pullRequestNumber,  int? runCount,  String? latestRunId, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuildJob() when $default != null:
return $default(_that.id,_that.status,_that.owner,_that.repo,_that.userId,_that.commitSha,_that.pullRequestNumber,_that.runCount,_that.latestRunId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status,  String owner,  String repo,  String? userId,  String? commitSha,  int? pullRequestNumber,  int? runCount,  String? latestRunId, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BuildJob():
return $default(_that.id,_that.status,_that.owner,_that.repo,_that.userId,_that.commitSha,_that.pullRequestNumber,_that.runCount,_that.latestRunId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status,  String owner,  String repo,  String? userId,  String? commitSha,  int? pullRequestNumber,  int? runCount,  String? latestRunId, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BuildJob() when $default != null:
return $default(_that.id,_that.status,_that.owner,_that.repo,_that.userId,_that.commitSha,_that.pullRequestNumber,_that.runCount,_that.latestRunId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuildJob implements BuildJob {
  const _BuildJob({required this.id, required this.status, required this.owner, required this.repo, this.userId, this.commitSha, this.pullRequestNumber, this.runCount, this.latestRunId, @TimestampConverter() required this.createdAt, @TimestampConverter() required this.updatedAt});
  factory _BuildJob.fromJson(Map<String, dynamic> json) => _$BuildJobFromJson(json);

@override final  String id;
@override final  String status;
@override final  String owner;
@override final  String repo;
@override final  String? userId;
@override final  String? commitSha;
@override final  int? pullRequestNumber;
@override final  int? runCount;
@override final  String? latestRunId;
@override@TimestampConverter() final  DateTime createdAt;
@override@TimestampConverter() final  DateTime updatedAt;

/// Create a copy of BuildJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildJobCopyWith<_BuildJob> get copyWith => __$BuildJobCopyWithImpl<_BuildJob>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildJobToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildJob&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.pullRequestNumber, pullRequestNumber) || other.pullRequestNumber == pullRequestNumber)&&(identical(other.runCount, runCount) || other.runCount == runCount)&&(identical(other.latestRunId, latestRunId) || other.latestRunId == latestRunId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,owner,repo,userId,commitSha,pullRequestNumber,runCount,latestRunId,createdAt,updatedAt);

@override
String toString() {
  return 'BuildJob(id: $id, status: $status, owner: $owner, repo: $repo, userId: $userId, commitSha: $commitSha, pullRequestNumber: $pullRequestNumber, runCount: $runCount, latestRunId: $latestRunId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BuildJobCopyWith<$Res> implements $BuildJobCopyWith<$Res> {
  factory _$BuildJobCopyWith(_BuildJob value, $Res Function(_BuildJob) _then) = __$BuildJobCopyWithImpl;
@override @useResult
$Res call({
 String id, String status, String owner, String repo, String? userId, String? commitSha, int? pullRequestNumber, int? runCount, String? latestRunId,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class __$BuildJobCopyWithImpl<$Res>
    implements _$BuildJobCopyWith<$Res> {
  __$BuildJobCopyWithImpl(this._self, this._then);

  final _BuildJob _self;
  final $Res Function(_BuildJob) _then;

/// Create a copy of BuildJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? owner = null,Object? repo = null,Object? userId = freezed,Object? commitSha = freezed,Object? pullRequestNumber = freezed,Object? runCount = freezed,Object? latestRunId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_BuildJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,pullRequestNumber: freezed == pullRequestNumber ? _self.pullRequestNumber : pullRequestNumber // ignore: cast_nullable_to_non_nullable
as int?,runCount: freezed == runCount ? _self.runCount : runCount // ignore: cast_nullable_to_non_nullable
as int?,latestRunId: freezed == latestRunId ? _self.latestRunId : latestRunId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$BuildLog {

 String get message; String get level;@TimestampConverter() DateTime? get timestamp;
/// Create a copy of BuildLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildLogCopyWith<BuildLog> get copyWith => _$BuildLogCopyWithImpl<BuildLog>(this as BuildLog, _$identity);

  /// Serializes this BuildLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildLog&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level,timestamp);

@override
String toString() {
  return 'BuildLog(message: $message, level: $level, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $BuildLogCopyWith<$Res>  {
  factory $BuildLogCopyWith(BuildLog value, $Res Function(BuildLog) _then) = _$BuildLogCopyWithImpl;
@useResult
$Res call({
 String message, String level,@TimestampConverter() DateTime? timestamp
});




}
/// @nodoc
class _$BuildLogCopyWithImpl<$Res>
    implements $BuildLogCopyWith<$Res> {
  _$BuildLogCopyWithImpl(this._self, this._then);

  final BuildLog _self;
  final $Res Function(BuildLog) _then;

/// Create a copy of BuildLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? level = null,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuildLog].
extension BuildLogPatterns on BuildLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildLog value)  $default,){
final _that = this;
switch (_that) {
case _BuildLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildLog value)?  $default,){
final _that = this;
switch (_that) {
case _BuildLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  String level, @TimestampConverter()  DateTime? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuildLog() when $default != null:
return $default(_that.message,_that.level,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  String level, @TimestampConverter()  DateTime? timestamp)  $default,) {final _that = this;
switch (_that) {
case _BuildLog():
return $default(_that.message,_that.level,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  String level, @TimestampConverter()  DateTime? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _BuildLog() when $default != null:
return $default(_that.message,_that.level,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuildLog implements BuildLog {
  const _BuildLog({required this.message, required this.level, @TimestampConverter() this.timestamp});
  factory _BuildLog.fromJson(Map<String, dynamic> json) => _$BuildLogFromJson(json);

@override final  String message;
@override final  String level;
@override@TimestampConverter() final  DateTime? timestamp;

/// Create a copy of BuildLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildLogCopyWith<_BuildLog> get copyWith => __$BuildLogCopyWithImpl<_BuildLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildLog&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level,timestamp);

@override
String toString() {
  return 'BuildLog(message: $message, level: $level, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$BuildLogCopyWith<$Res> implements $BuildLogCopyWith<$Res> {
  factory _$BuildLogCopyWith(_BuildLog value, $Res Function(_BuildLog) _then) = __$BuildLogCopyWithImpl;
@override @useResult
$Res call({
 String message, String level,@TimestampConverter() DateTime? timestamp
});




}
/// @nodoc
class __$BuildLogCopyWithImpl<$Res>
    implements _$BuildLogCopyWith<$Res> {
  __$BuildLogCopyWithImpl(this._self, this._then);

  final _BuildLog _self;
  final $Res Function(_BuildLog) _then;

/// Create a copy of BuildLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? level = null,Object? timestamp = freezed,}) {
  return _then(_BuildLog(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
