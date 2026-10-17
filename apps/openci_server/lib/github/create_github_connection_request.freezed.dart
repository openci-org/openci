// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_github_connection_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreateGitHubConnectionRequestResult {

 String get id; String get state; String get codeChallenge; DateTime get expiresAt;
/// Create a copy of CreateGitHubConnectionRequestResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateGitHubConnectionRequestResultCopyWith<CreateGitHubConnectionRequestResult> get copyWith => _$CreateGitHubConnectionRequestResultCopyWithImpl<CreateGitHubConnectionRequestResult>(this as CreateGitHubConnectionRequestResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateGitHubConnectionRequestResult&&(identical(other.id, id) || other.id == id)&&(identical(other.state, state) || other.state == state)&&(identical(other.codeChallenge, codeChallenge) || other.codeChallenge == codeChallenge)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,state,codeChallenge,expiresAt);



}

/// @nodoc
abstract mixin class $CreateGitHubConnectionRequestResultCopyWith<$Res>  {
  factory $CreateGitHubConnectionRequestResultCopyWith(CreateGitHubConnectionRequestResult value, $Res Function(CreateGitHubConnectionRequestResult) _then) = _$CreateGitHubConnectionRequestResultCopyWithImpl;
@useResult
$Res call({
 String id, String state, String codeChallenge, DateTime expiresAt
});




}
/// @nodoc
class _$CreateGitHubConnectionRequestResultCopyWithImpl<$Res>
    implements $CreateGitHubConnectionRequestResultCopyWith<$Res> {
  _$CreateGitHubConnectionRequestResultCopyWithImpl(this._self, this._then);

  final CreateGitHubConnectionRequestResult _self;
  final $Res Function(CreateGitHubConnectionRequestResult) _then;

/// Create a copy of CreateGitHubConnectionRequestResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? state = null,Object? codeChallenge = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,codeChallenge: null == codeChallenge ? _self.codeChallenge : codeChallenge // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateGitHubConnectionRequestResult].
extension CreateGitHubConnectionRequestResultPatterns on CreateGitHubConnectionRequestResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateGitHubConnectionRequestResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateGitHubConnectionRequestResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateGitHubConnectionRequestResult value)  $default,){
final _that = this;
switch (_that) {
case _CreateGitHubConnectionRequestResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateGitHubConnectionRequestResult value)?  $default,){
final _that = this;
switch (_that) {
case _CreateGitHubConnectionRequestResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String state,  String codeChallenge,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateGitHubConnectionRequestResult() when $default != null:
return $default(_that.id,_that.state,_that.codeChallenge,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String state,  String codeChallenge,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _CreateGitHubConnectionRequestResult():
return $default(_that.id,_that.state,_that.codeChallenge,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String state,  String codeChallenge,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _CreateGitHubConnectionRequestResult() when $default != null:
return $default(_that.id,_that.state,_that.codeChallenge,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _CreateGitHubConnectionRequestResult implements CreateGitHubConnectionRequestResult {
  const _CreateGitHubConnectionRequestResult({required this.id, required this.state, required this.codeChallenge, required this.expiresAt});


@override final  String id;
@override final  String state;
@override final  String codeChallenge;
@override final  DateTime expiresAt;

/// Create a copy of CreateGitHubConnectionRequestResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateGitHubConnectionRequestResultCopyWith<_CreateGitHubConnectionRequestResult> get copyWith => __$CreateGitHubConnectionRequestResultCopyWithImpl<_CreateGitHubConnectionRequestResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateGitHubConnectionRequestResult&&(identical(other.id, id) || other.id == id)&&(identical(other.state, state) || other.state == state)&&(identical(other.codeChallenge, codeChallenge) || other.codeChallenge == codeChallenge)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,state,codeChallenge,expiresAt);



}

/// @nodoc
abstract mixin class _$CreateGitHubConnectionRequestResultCopyWith<$Res> implements $CreateGitHubConnectionRequestResultCopyWith<$Res> {
  factory _$CreateGitHubConnectionRequestResultCopyWith(_CreateGitHubConnectionRequestResult value, $Res Function(_CreateGitHubConnectionRequestResult) _then) = __$CreateGitHubConnectionRequestResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String state, String codeChallenge, DateTime expiresAt
});




}
/// @nodoc
class __$CreateGitHubConnectionRequestResultCopyWithImpl<$Res>
    implements _$CreateGitHubConnectionRequestResultCopyWith<$Res> {
  __$CreateGitHubConnectionRequestResultCopyWithImpl(this._self, this._then);

  final _CreateGitHubConnectionRequestResult _self;
  final $Res Function(_CreateGitHubConnectionRequestResult) _then;

/// Create a copy of CreateGitHubConnectionRequestResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? state = null,Object? codeChallenge = null,Object? expiresAt = null,}) {
  return _then(_CreateGitHubConnectionRequestResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,codeChallenge: null == codeChallenge ? _self.codeChallenge : codeChallenge // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
