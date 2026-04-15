// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'code_search_index_status2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CodeSearchIndexStatus2 {

@JsonKey(name: 'lexical_search_ok') bool? get lexicalSearchOk;@JsonKey(name: 'lexical_commit_sha') String? get lexicalCommitSha;
/// Create a copy of CodeSearchIndexStatus2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodeSearchIndexStatus2CopyWith<CodeSearchIndexStatus2> get copyWith => _$CodeSearchIndexStatus2CopyWithImpl<CodeSearchIndexStatus2>(this as CodeSearchIndexStatus2, _$identity);

  /// Serializes this CodeSearchIndexStatus2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeSearchIndexStatus2&&(identical(other.lexicalSearchOk, lexicalSearchOk) || other.lexicalSearchOk == lexicalSearchOk)&&(identical(other.lexicalCommitSha, lexicalCommitSha) || other.lexicalCommitSha == lexicalCommitSha));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lexicalSearchOk,lexicalCommitSha);

@override
String toString() {
  return 'CodeSearchIndexStatus2(lexicalSearchOk: $lexicalSearchOk, lexicalCommitSha: $lexicalCommitSha)';
}


}

/// @nodoc
abstract mixin class $CodeSearchIndexStatus2CopyWith<$Res>  {
  factory $CodeSearchIndexStatus2CopyWith(CodeSearchIndexStatus2 value, $Res Function(CodeSearchIndexStatus2) _then) = _$CodeSearchIndexStatus2CopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'lexical_search_ok') bool? lexicalSearchOk,@JsonKey(name: 'lexical_commit_sha') String? lexicalCommitSha
});




}
/// @nodoc
class _$CodeSearchIndexStatus2CopyWithImpl<$Res>
    implements $CodeSearchIndexStatus2CopyWith<$Res> {
  _$CodeSearchIndexStatus2CopyWithImpl(this._self, this._then);

  final CodeSearchIndexStatus2 _self;
  final $Res Function(CodeSearchIndexStatus2) _then;

/// Create a copy of CodeSearchIndexStatus2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lexicalSearchOk = freezed,Object? lexicalCommitSha = freezed,}) {
  return _then(_self.copyWith(
lexicalSearchOk: freezed == lexicalSearchOk ? _self.lexicalSearchOk : lexicalSearchOk // ignore: cast_nullable_to_non_nullable
as bool?,lexicalCommitSha: freezed == lexicalCommitSha ? _self.lexicalCommitSha : lexicalCommitSha // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CodeSearchIndexStatus2].
extension CodeSearchIndexStatus2Patterns on CodeSearchIndexStatus2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CodeSearchIndexStatus2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CodeSearchIndexStatus2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CodeSearchIndexStatus2 value)  $default,){
final _that = this;
switch (_that) {
case _CodeSearchIndexStatus2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CodeSearchIndexStatus2 value)?  $default,){
final _that = this;
switch (_that) {
case _CodeSearchIndexStatus2() when $default != null:
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
case _CodeSearchIndexStatus2() when $default != null:
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
case _CodeSearchIndexStatus2():
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
case _CodeSearchIndexStatus2() when $default != null:
return $default(_that.lexicalSearchOk,_that.lexicalCommitSha);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CodeSearchIndexStatus2 implements CodeSearchIndexStatus2 {
  const _CodeSearchIndexStatus2({@JsonKey(name: 'lexical_search_ok') this.lexicalSearchOk, @JsonKey(name: 'lexical_commit_sha') this.lexicalCommitSha});
  factory _CodeSearchIndexStatus2.fromJson(Map<String, dynamic> json) => _$CodeSearchIndexStatus2FromJson(json);

@override@JsonKey(name: 'lexical_search_ok') final  bool? lexicalSearchOk;
@override@JsonKey(name: 'lexical_commit_sha') final  String? lexicalCommitSha;

/// Create a copy of CodeSearchIndexStatus2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CodeSearchIndexStatus2CopyWith<_CodeSearchIndexStatus2> get copyWith => __$CodeSearchIndexStatus2CopyWithImpl<_CodeSearchIndexStatus2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CodeSearchIndexStatus2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CodeSearchIndexStatus2&&(identical(other.lexicalSearchOk, lexicalSearchOk) || other.lexicalSearchOk == lexicalSearchOk)&&(identical(other.lexicalCommitSha, lexicalCommitSha) || other.lexicalCommitSha == lexicalCommitSha));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lexicalSearchOk,lexicalCommitSha);

@override
String toString() {
  return 'CodeSearchIndexStatus2(lexicalSearchOk: $lexicalSearchOk, lexicalCommitSha: $lexicalCommitSha)';
}


}

/// @nodoc
abstract mixin class _$CodeSearchIndexStatus2CopyWith<$Res> implements $CodeSearchIndexStatus2CopyWith<$Res> {
  factory _$CodeSearchIndexStatus2CopyWith(_CodeSearchIndexStatus2 value, $Res Function(_CodeSearchIndexStatus2) _then) = __$CodeSearchIndexStatus2CopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'lexical_search_ok') bool? lexicalSearchOk,@JsonKey(name: 'lexical_commit_sha') String? lexicalCommitSha
});




}
/// @nodoc
class __$CodeSearchIndexStatus2CopyWithImpl<$Res>
    implements _$CodeSearchIndexStatus2CopyWith<$Res> {
  __$CodeSearchIndexStatus2CopyWithImpl(this._self, this._then);

  final _CodeSearchIndexStatus2 _self;
  final $Res Function(_CodeSearchIndexStatus2) _then;

/// Create a copy of CodeSearchIndexStatus2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lexicalSearchOk = freezed,Object? lexicalCommitSha = freezed,}) {
  return _then(_CodeSearchIndexStatus2(
lexicalSearchOk: freezed == lexicalSearchOk ? _self.lexicalSearchOk : lexicalSearchOk // ignore: cast_nullable_to_non_nullable
as bool?,lexicalCommitSha: freezed == lexicalCommitSha ? _self.lexicalCommitSha : lexicalCommitSha // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
