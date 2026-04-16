// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'code_search_index_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CodeSearchIndexStatus {

@JsonKey(name: 'lexical_search_ok') bool? get lexicalSearchOk;@JsonKey(name: 'lexical_commit_sha') String? get lexicalCommitSha;
/// Create a copy of CodeSearchIndexStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodeSearchIndexStatusCopyWith<CodeSearchIndexStatus> get copyWith => _$CodeSearchIndexStatusCopyWithImpl<CodeSearchIndexStatus>(this as CodeSearchIndexStatus, _$identity);

  /// Serializes this CodeSearchIndexStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeSearchIndexStatus&&(identical(other.lexicalSearchOk, lexicalSearchOk) || other.lexicalSearchOk == lexicalSearchOk)&&(identical(other.lexicalCommitSha, lexicalCommitSha) || other.lexicalCommitSha == lexicalCommitSha));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lexicalSearchOk,lexicalCommitSha);

@override
String toString() {
  return 'CodeSearchIndexStatus(lexicalSearchOk: $lexicalSearchOk, lexicalCommitSha: $lexicalCommitSha)';
}


}

/// @nodoc
abstract mixin class $CodeSearchIndexStatusCopyWith<$Res>  {
  factory $CodeSearchIndexStatusCopyWith(CodeSearchIndexStatus value, $Res Function(CodeSearchIndexStatus) _then) = _$CodeSearchIndexStatusCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'lexical_search_ok') bool? lexicalSearchOk,@JsonKey(name: 'lexical_commit_sha') String? lexicalCommitSha
});




}
/// @nodoc
class _$CodeSearchIndexStatusCopyWithImpl<$Res>
    implements $CodeSearchIndexStatusCopyWith<$Res> {
  _$CodeSearchIndexStatusCopyWithImpl(this._self, this._then);

  final CodeSearchIndexStatus _self;
  final $Res Function(CodeSearchIndexStatus) _then;

/// Create a copy of CodeSearchIndexStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lexicalSearchOk = freezed,Object? lexicalCommitSha = freezed,}) {
  return _then(_self.copyWith(
lexicalSearchOk: freezed == lexicalSearchOk ? _self.lexicalSearchOk : lexicalSearchOk // ignore: cast_nullable_to_non_nullable
as bool?,lexicalCommitSha: freezed == lexicalCommitSha ? _self.lexicalCommitSha : lexicalCommitSha // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CodeSearchIndexStatus].
extension CodeSearchIndexStatusPatterns on CodeSearchIndexStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CodeSearchIndexStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CodeSearchIndexStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CodeSearchIndexStatus value)  $default,){
final _that = this;
switch (_that) {
case _CodeSearchIndexStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CodeSearchIndexStatus value)?  $default,){
final _that = this;
switch (_that) {
case _CodeSearchIndexStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'lexical_search_ok')  bool? lexicalSearchOk, @JsonKey(name: 'lexical_commit_sha')  String? lexicalCommitSha)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CodeSearchIndexStatus() when $default != null:
return $default(_that.lexicalSearchOk,_that.lexicalCommitSha);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'lexical_search_ok')  bool? lexicalSearchOk, @JsonKey(name: 'lexical_commit_sha')  String? lexicalCommitSha)  $default,) {final _that = this;
switch (_that) {
case _CodeSearchIndexStatus():
return $default(_that.lexicalSearchOk,_that.lexicalCommitSha);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'lexical_search_ok')  bool? lexicalSearchOk, @JsonKey(name: 'lexical_commit_sha')  String? lexicalCommitSha)?  $default,) {final _that = this;
switch (_that) {
case _CodeSearchIndexStatus() when $default != null:
return $default(_that.lexicalSearchOk,_that.lexicalCommitSha);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CodeSearchIndexStatus implements CodeSearchIndexStatus {
  const _CodeSearchIndexStatus({@JsonKey(name: 'lexical_search_ok') this.lexicalSearchOk, @JsonKey(name: 'lexical_commit_sha') this.lexicalCommitSha});
  factory _CodeSearchIndexStatus.fromJson(Map<String, dynamic> json) => _$CodeSearchIndexStatusFromJson(json);

@override@JsonKey(name: 'lexical_search_ok') final  bool? lexicalSearchOk;
@override@JsonKey(name: 'lexical_commit_sha') final  String? lexicalCommitSha;

/// Create a copy of CodeSearchIndexStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CodeSearchIndexStatusCopyWith<_CodeSearchIndexStatus> get copyWith => __$CodeSearchIndexStatusCopyWithImpl<_CodeSearchIndexStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CodeSearchIndexStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CodeSearchIndexStatus&&(identical(other.lexicalSearchOk, lexicalSearchOk) || other.lexicalSearchOk == lexicalSearchOk)&&(identical(other.lexicalCommitSha, lexicalCommitSha) || other.lexicalCommitSha == lexicalCommitSha));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lexicalSearchOk,lexicalCommitSha);

@override
String toString() {
  return 'CodeSearchIndexStatus(lexicalSearchOk: $lexicalSearchOk, lexicalCommitSha: $lexicalCommitSha)';
}


}

/// @nodoc
abstract mixin class _$CodeSearchIndexStatusCopyWith<$Res> implements $CodeSearchIndexStatusCopyWith<$Res> {
  factory _$CodeSearchIndexStatusCopyWith(_CodeSearchIndexStatus value, $Res Function(_CodeSearchIndexStatus) _then) = __$CodeSearchIndexStatusCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'lexical_search_ok') bool? lexicalSearchOk,@JsonKey(name: 'lexical_commit_sha') String? lexicalCommitSha
});




}
/// @nodoc
class __$CodeSearchIndexStatusCopyWithImpl<$Res>
    implements _$CodeSearchIndexStatusCopyWith<$Res> {
  __$CodeSearchIndexStatusCopyWithImpl(this._self, this._then);

  final _CodeSearchIndexStatus _self;
  final $Res Function(_CodeSearchIndexStatus) _then;

/// Create a copy of CodeSearchIndexStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lexicalSearchOk = freezed,Object? lexicalCommitSha = freezed,}) {
  return _then(_CodeSearchIndexStatus(
lexicalSearchOk: freezed == lexicalSearchOk ? _self.lexicalSearchOk : lexicalSearchOk // ignore: cast_nullable_to_non_nullable
as bool?,lexicalCommitSha: freezed == lexicalCommitSha ? _self.lexicalCommitSha : lexicalCommitSha // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
