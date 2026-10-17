// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'changed_files_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChangedFilesResult {

 List<String> get paths; bool get isComplete; String? get baseSha; String? get headSha; String? get reason;
/// Create a copy of ChangedFilesResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangedFilesResultCopyWith<ChangedFilesResult> get copyWith => _$ChangedFilesResultCopyWithImpl<ChangedFilesResult>(this as ChangedFilesResult, _$identity);

  /// Serializes this ChangedFilesResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangedFilesResult&&const DeepCollectionEquality().equals(other.paths, paths)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.baseSha, baseSha) || other.baseSha == baseSha)&&(identical(other.headSha, headSha) || other.headSha == headSha)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(paths),isComplete,baseSha,headSha,reason);

@override
String toString() {
  return 'ChangedFilesResult(paths: $paths, isComplete: $isComplete, baseSha: $baseSha, headSha: $headSha, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ChangedFilesResultCopyWith<$Res>  {
  factory $ChangedFilesResultCopyWith(ChangedFilesResult value, $Res Function(ChangedFilesResult) _then) = _$ChangedFilesResultCopyWithImpl;
@useResult
$Res call({
 List<String> paths, bool isComplete, String? baseSha, String? headSha, String? reason
});




}
/// @nodoc
class _$ChangedFilesResultCopyWithImpl<$Res>
    implements $ChangedFilesResultCopyWith<$Res> {
  _$ChangedFilesResultCopyWithImpl(this._self, this._then);

  final ChangedFilesResult _self;
  final $Res Function(ChangedFilesResult) _then;

/// Create a copy of ChangedFilesResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? paths = null,Object? isComplete = null,Object? baseSha = freezed,Object? headSha = freezed,Object? reason = freezed,}) {
  return _then(_self.copyWith(
paths: null == paths ? _self.paths : paths // ignore: cast_nullable_to_non_nullable
as List<String>,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,baseSha: freezed == baseSha ? _self.baseSha : baseSha // ignore: cast_nullable_to_non_nullable
as String?,headSha: freezed == headSha ? _self.headSha : headSha // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangedFilesResult].
extension ChangedFilesResultPatterns on ChangedFilesResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangedFilesResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangedFilesResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangedFilesResult value)  $default,){
final _that = this;
switch (_that) {
case _ChangedFilesResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangedFilesResult value)?  $default,){
final _that = this;
switch (_that) {
case _ChangedFilesResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> paths,  bool isComplete,  String? baseSha,  String? headSha,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangedFilesResult() when $default != null:
return $default(_that.paths,_that.isComplete,_that.baseSha,_that.headSha,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> paths,  bool isComplete,  String? baseSha,  String? headSha,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _ChangedFilesResult():
return $default(_that.paths,_that.isComplete,_that.baseSha,_that.headSha,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> paths,  bool isComplete,  String? baseSha,  String? headSha,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _ChangedFilesResult() when $default != null:
return $default(_that.paths,_that.isComplete,_that.baseSha,_that.headSha,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChangedFilesResult implements ChangedFilesResult {
  const _ChangedFilesResult({required final  List<String> paths, required this.isComplete, this.baseSha, this.headSha, this.reason}): _paths = paths;
  factory _ChangedFilesResult.fromJson(Map<String, dynamic> json) => _$ChangedFilesResultFromJson(json);

 final  List<String> _paths;
@override List<String> get paths {
  if (_paths is EqualUnmodifiableListView) return _paths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paths);
}

@override final  bool isComplete;
@override final  String? baseSha;
@override final  String? headSha;
@override final  String? reason;

/// Create a copy of ChangedFilesResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangedFilesResultCopyWith<_ChangedFilesResult> get copyWith => __$ChangedFilesResultCopyWithImpl<_ChangedFilesResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangedFilesResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangedFilesResult&&const DeepCollectionEquality().equals(other._paths, _paths)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.baseSha, baseSha) || other.baseSha == baseSha)&&(identical(other.headSha, headSha) || other.headSha == headSha)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_paths),isComplete,baseSha,headSha,reason);

@override
String toString() {
  return 'ChangedFilesResult(paths: $paths, isComplete: $isComplete, baseSha: $baseSha, headSha: $headSha, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$ChangedFilesResultCopyWith<$Res> implements $ChangedFilesResultCopyWith<$Res> {
  factory _$ChangedFilesResultCopyWith(_ChangedFilesResult value, $Res Function(_ChangedFilesResult) _then) = __$ChangedFilesResultCopyWithImpl;
@override @useResult
$Res call({
 List<String> paths, bool isComplete, String? baseSha, String? headSha, String? reason
});




}
/// @nodoc
class __$ChangedFilesResultCopyWithImpl<$Res>
    implements _$ChangedFilesResultCopyWith<$Res> {
  __$ChangedFilesResultCopyWithImpl(this._self, this._then);

  final _ChangedFilesResult _self;
  final $Res Function(_ChangedFilesResult) _then;

/// Create a copy of ChangedFilesResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? paths = null,Object? isComplete = null,Object? baseSha = freezed,Object? headSha = freezed,Object? reason = freezed,}) {
  return _then(_ChangedFilesResult(
paths: null == paths ? _self._paths : paths // ignore: cast_nullable_to_non_nullable
as List<String>,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,baseSha: freezed == baseSha ? _self.baseSha : baseSha // ignore: cast_nullable_to_non_nullable
as String?,headSha: freezed == headSha ? _self.headSha : headSha // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
