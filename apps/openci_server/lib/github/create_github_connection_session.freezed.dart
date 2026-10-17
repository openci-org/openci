// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_github_connection_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreateGitHubConnectionSessionResult {

 String get reference; DateTime get expiresAt;
/// Create a copy of CreateGitHubConnectionSessionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateGitHubConnectionSessionResultCopyWith<CreateGitHubConnectionSessionResult> get copyWith => _$CreateGitHubConnectionSessionResultCopyWithImpl<CreateGitHubConnectionSessionResult>(this as CreateGitHubConnectionSessionResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateGitHubConnectionSessionResult&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,reference,expiresAt);



}

/// @nodoc
abstract mixin class $CreateGitHubConnectionSessionResultCopyWith<$Res>  {
  factory $CreateGitHubConnectionSessionResultCopyWith(CreateGitHubConnectionSessionResult value, $Res Function(CreateGitHubConnectionSessionResult) _then) = _$CreateGitHubConnectionSessionResultCopyWithImpl;
@useResult
$Res call({
 String reference, DateTime expiresAt
});




}
/// @nodoc
class _$CreateGitHubConnectionSessionResultCopyWithImpl<$Res>
    implements $CreateGitHubConnectionSessionResultCopyWith<$Res> {
  _$CreateGitHubConnectionSessionResultCopyWithImpl(this._self, this._then);

  final CreateGitHubConnectionSessionResult _self;
  final $Res Function(CreateGitHubConnectionSessionResult) _then;

/// Create a copy of CreateGitHubConnectionSessionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reference = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateGitHubConnectionSessionResult].
extension CreateGitHubConnectionSessionResultPatterns on CreateGitHubConnectionSessionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateGitHubConnectionSessionResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateGitHubConnectionSessionResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateGitHubConnectionSessionResult value)  $default,){
final _that = this;
switch (_that) {
case _CreateGitHubConnectionSessionResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateGitHubConnectionSessionResult value)?  $default,){
final _that = this;
switch (_that) {
case _CreateGitHubConnectionSessionResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reference,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateGitHubConnectionSessionResult() when $default != null:
return $default(_that.reference,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reference,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _CreateGitHubConnectionSessionResult():
return $default(_that.reference,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reference,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _CreateGitHubConnectionSessionResult() when $default != null:
return $default(_that.reference,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _CreateGitHubConnectionSessionResult implements CreateGitHubConnectionSessionResult {
  const _CreateGitHubConnectionSessionResult({required this.reference, required this.expiresAt});


@override final  String reference;
@override final  DateTime expiresAt;

/// Create a copy of CreateGitHubConnectionSessionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateGitHubConnectionSessionResultCopyWith<_CreateGitHubConnectionSessionResult> get copyWith => __$CreateGitHubConnectionSessionResultCopyWithImpl<_CreateGitHubConnectionSessionResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateGitHubConnectionSessionResult&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,reference,expiresAt);



}

/// @nodoc
abstract mixin class _$CreateGitHubConnectionSessionResultCopyWith<$Res> implements $CreateGitHubConnectionSessionResultCopyWith<$Res> {
  factory _$CreateGitHubConnectionSessionResultCopyWith(_CreateGitHubConnectionSessionResult value, $Res Function(_CreateGitHubConnectionSessionResult) _then) = __$CreateGitHubConnectionSessionResultCopyWithImpl;
@override @useResult
$Res call({
 String reference, DateTime expiresAt
});




}
/// @nodoc
class __$CreateGitHubConnectionSessionResultCopyWithImpl<$Res>
    implements _$CreateGitHubConnectionSessionResultCopyWith<$Res> {
  __$CreateGitHubConnectionSessionResultCopyWithImpl(this._self, this._then);

  final _CreateGitHubConnectionSessionResult _self;
  final $Res Function(_CreateGitHubConnectionSessionResult) _then;

/// Create a copy of CreateGitHubConnectionSessionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? expiresAt = null,}) {
  return _then(_CreateGitHubConnectionSessionResult(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
