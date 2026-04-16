// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diff_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DiffEntry {

 String? get sha; String get filename;@JsonKey(name: 'Status') DiffEntryStatus get status; int get additions; int get deletions; int get changes;@JsonKey(name: 'blob_url') String get blobUrl;@JsonKey(name: 'raw_url') String get rawUrl;@JsonKey(name: 'contents_url') String get contentsUrl; String? get patch;@JsonKey(name: 'previous_filename') String? get previousFilename;
/// Create a copy of DiffEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiffEntryCopyWith<DiffEntry> get copyWith => _$DiffEntryCopyWithImpl<DiffEntry>(this as DiffEntry, _$identity);

  /// Serializes this DiffEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiffEntry&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.status, status) || other.status == status)&&(identical(other.additions, additions) || other.additions == additions)&&(identical(other.deletions, deletions) || other.deletions == deletions)&&(identical(other.changes, changes) || other.changes == changes)&&(identical(other.blobUrl, blobUrl) || other.blobUrl == blobUrl)&&(identical(other.rawUrl, rawUrl) || other.rawUrl == rawUrl)&&(identical(other.contentsUrl, contentsUrl) || other.contentsUrl == contentsUrl)&&(identical(other.patch, patch) || other.patch == patch)&&(identical(other.previousFilename, previousFilename) || other.previousFilename == previousFilename));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sha,filename,status,additions,deletions,changes,blobUrl,rawUrl,contentsUrl,patch,previousFilename);

@override
String toString() {
  return 'DiffEntry(sha: $sha, filename: $filename, status: $status, additions: $additions, deletions: $deletions, changes: $changes, blobUrl: $blobUrl, rawUrl: $rawUrl, contentsUrl: $contentsUrl, patch: $patch, previousFilename: $previousFilename)';
}


}

/// @nodoc
abstract mixin class $DiffEntryCopyWith<$Res>  {
  factory $DiffEntryCopyWith(DiffEntry value, $Res Function(DiffEntry) _then) = _$DiffEntryCopyWithImpl;
@useResult
$Res call({
 String? sha, String filename,@JsonKey(name: 'Status') DiffEntryStatus status, int additions, int deletions, int changes,@JsonKey(name: 'blob_url') String blobUrl,@JsonKey(name: 'raw_url') String rawUrl,@JsonKey(name: 'contents_url') String contentsUrl, String? patch,@JsonKey(name: 'previous_filename') String? previousFilename
});




}
/// @nodoc
class _$DiffEntryCopyWithImpl<$Res>
    implements $DiffEntryCopyWith<$Res> {
  _$DiffEntryCopyWithImpl(this._self, this._then);

  final DiffEntry _self;
  final $Res Function(DiffEntry) _then;

/// Create a copy of DiffEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sha = freezed,Object? filename = null,Object? status = null,Object? additions = null,Object? deletions = null,Object? changes = null,Object? blobUrl = null,Object? rawUrl = null,Object? contentsUrl = null,Object? patch = freezed,Object? previousFilename = freezed,}) {
  return _then(_self.copyWith(
sha: freezed == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String?,filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DiffEntryStatus,additions: null == additions ? _self.additions : additions // ignore: cast_nullable_to_non_nullable
as int,deletions: null == deletions ? _self.deletions : deletions // ignore: cast_nullable_to_non_nullable
as int,changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as int,blobUrl: null == blobUrl ? _self.blobUrl : blobUrl // ignore: cast_nullable_to_non_nullable
as String,rawUrl: null == rawUrl ? _self.rawUrl : rawUrl // ignore: cast_nullable_to_non_nullable
as String,contentsUrl: null == contentsUrl ? _self.contentsUrl : contentsUrl // ignore: cast_nullable_to_non_nullable
as String,patch: freezed == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as String?,previousFilename: freezed == previousFilename ? _self.previousFilename : previousFilename // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DiffEntry].
extension DiffEntryPatterns on DiffEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiffEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiffEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiffEntry value)  $default,){
final _that = this;
switch (_that) {
case _DiffEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiffEntry value)?  $default,){
final _that = this;
switch (_that) {
case _DiffEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? sha,  String filename, @JsonKey(name: 'Status')  DiffEntryStatus status,  int additions,  int deletions,  int changes, @JsonKey(name: 'blob_url')  String blobUrl, @JsonKey(name: 'raw_url')  String rawUrl, @JsonKey(name: 'contents_url')  String contentsUrl,  String? patch, @JsonKey(name: 'previous_filename')  String? previousFilename)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiffEntry() when $default != null:
return $default(_that.sha,_that.filename,_that.status,_that.additions,_that.deletions,_that.changes,_that.blobUrl,_that.rawUrl,_that.contentsUrl,_that.patch,_that.previousFilename);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? sha,  String filename, @JsonKey(name: 'Status')  DiffEntryStatus status,  int additions,  int deletions,  int changes, @JsonKey(name: 'blob_url')  String blobUrl, @JsonKey(name: 'raw_url')  String rawUrl, @JsonKey(name: 'contents_url')  String contentsUrl,  String? patch, @JsonKey(name: 'previous_filename')  String? previousFilename)  $default,) {final _that = this;
switch (_that) {
case _DiffEntry():
return $default(_that.sha,_that.filename,_that.status,_that.additions,_that.deletions,_that.changes,_that.blobUrl,_that.rawUrl,_that.contentsUrl,_that.patch,_that.previousFilename);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? sha,  String filename, @JsonKey(name: 'Status')  DiffEntryStatus status,  int additions,  int deletions,  int changes, @JsonKey(name: 'blob_url')  String blobUrl, @JsonKey(name: 'raw_url')  String rawUrl, @JsonKey(name: 'contents_url')  String contentsUrl,  String? patch, @JsonKey(name: 'previous_filename')  String? previousFilename)?  $default,) {final _that = this;
switch (_that) {
case _DiffEntry() when $default != null:
return $default(_that.sha,_that.filename,_that.status,_that.additions,_that.deletions,_that.changes,_that.blobUrl,_that.rawUrl,_that.contentsUrl,_that.patch,_that.previousFilename);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiffEntry implements DiffEntry {
  const _DiffEntry({required this.sha, required this.filename, @JsonKey(name: 'Status') required this.status, required this.additions, required this.deletions, required this.changes, @JsonKey(name: 'blob_url') required this.blobUrl, @JsonKey(name: 'raw_url') required this.rawUrl, @JsonKey(name: 'contents_url') required this.contentsUrl, this.patch, @JsonKey(name: 'previous_filename') this.previousFilename});
  factory _DiffEntry.fromJson(Map<String, dynamic> json) => _$DiffEntryFromJson(json);

@override final  String? sha;
@override final  String filename;
@override@JsonKey(name: 'Status') final  DiffEntryStatus status;
@override final  int additions;
@override final  int deletions;
@override final  int changes;
@override@JsonKey(name: 'blob_url') final  String blobUrl;
@override@JsonKey(name: 'raw_url') final  String rawUrl;
@override@JsonKey(name: 'contents_url') final  String contentsUrl;
@override final  String? patch;
@override@JsonKey(name: 'previous_filename') final  String? previousFilename;

/// Create a copy of DiffEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiffEntryCopyWith<_DiffEntry> get copyWith => __$DiffEntryCopyWithImpl<_DiffEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiffEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiffEntry&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.status, status) || other.status == status)&&(identical(other.additions, additions) || other.additions == additions)&&(identical(other.deletions, deletions) || other.deletions == deletions)&&(identical(other.changes, changes) || other.changes == changes)&&(identical(other.blobUrl, blobUrl) || other.blobUrl == blobUrl)&&(identical(other.rawUrl, rawUrl) || other.rawUrl == rawUrl)&&(identical(other.contentsUrl, contentsUrl) || other.contentsUrl == contentsUrl)&&(identical(other.patch, patch) || other.patch == patch)&&(identical(other.previousFilename, previousFilename) || other.previousFilename == previousFilename));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sha,filename,status,additions,deletions,changes,blobUrl,rawUrl,contentsUrl,patch,previousFilename);

@override
String toString() {
  return 'DiffEntry(sha: $sha, filename: $filename, status: $status, additions: $additions, deletions: $deletions, changes: $changes, blobUrl: $blobUrl, rawUrl: $rawUrl, contentsUrl: $contentsUrl, patch: $patch, previousFilename: $previousFilename)';
}


}

/// @nodoc
abstract mixin class _$DiffEntryCopyWith<$Res> implements $DiffEntryCopyWith<$Res> {
  factory _$DiffEntryCopyWith(_DiffEntry value, $Res Function(_DiffEntry) _then) = __$DiffEntryCopyWithImpl;
@override @useResult
$Res call({
 String? sha, String filename,@JsonKey(name: 'Status') DiffEntryStatus status, int additions, int deletions, int changes,@JsonKey(name: 'blob_url') String blobUrl,@JsonKey(name: 'raw_url') String rawUrl,@JsonKey(name: 'contents_url') String contentsUrl, String? patch,@JsonKey(name: 'previous_filename') String? previousFilename
});




}
/// @nodoc
class __$DiffEntryCopyWithImpl<$Res>
    implements _$DiffEntryCopyWith<$Res> {
  __$DiffEntryCopyWithImpl(this._self, this._then);

  final _DiffEntry _self;
  final $Res Function(_DiffEntry) _then;

/// Create a copy of DiffEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sha = freezed,Object? filename = null,Object? status = null,Object? additions = null,Object? deletions = null,Object? changes = null,Object? blobUrl = null,Object? rawUrl = null,Object? contentsUrl = null,Object? patch = freezed,Object? previousFilename = freezed,}) {
  return _then(_DiffEntry(
sha: freezed == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String?,filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DiffEntryStatus,additions: null == additions ? _self.additions : additions // ignore: cast_nullable_to_non_nullable
as int,deletions: null == deletions ? _self.deletions : deletions // ignore: cast_nullable_to_non_nullable
as int,changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as int,blobUrl: null == blobUrl ? _self.blobUrl : blobUrl // ignore: cast_nullable_to_non_nullable
as String,rawUrl: null == rawUrl ? _self.rawUrl : rawUrl // ignore: cast_nullable_to_non_nullable
as String,contentsUrl: null == contentsUrl ? _self.contentsUrl : contentsUrl // ignore: cast_nullable_to_non_nullable
as String,patch: freezed == patch ? _self.patch : patch // ignore: cast_nullable_to_non_nullable
as String?,previousFilename: freezed == previousFilename ? _self.previousFilename : previousFilename // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
