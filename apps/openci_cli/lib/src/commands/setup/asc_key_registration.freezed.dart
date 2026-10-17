// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asc_key_registration.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AscKeySaveTarget {

 String get profileName; AuthProfile get profile;
/// Create a copy of AscKeySaveTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AscKeySaveTargetCopyWith<AscKeySaveTarget> get copyWith => _$AscKeySaveTargetCopyWithImpl<AscKeySaveTarget>(this as AscKeySaveTarget, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AscKeySaveTarget&&(identical(other.profileName, profileName) || other.profileName == profileName)&&(identical(other.profile, profile) || other.profile == profile));
}


@override
int get hashCode => Object.hash(runtimeType,profileName,profile);



}

/// @nodoc
abstract mixin class $AscKeySaveTargetCopyWith<$Res>  {
  factory $AscKeySaveTargetCopyWith(AscKeySaveTarget value, $Res Function(AscKeySaveTarget) _then) = _$AscKeySaveTargetCopyWithImpl;
@useResult
$Res call({
 String profileName, AuthProfile profile
});


$AuthProfileCopyWith<$Res> get profile;

}
/// @nodoc
class _$AscKeySaveTargetCopyWithImpl<$Res>
    implements $AscKeySaveTargetCopyWith<$Res> {
  _$AscKeySaveTargetCopyWithImpl(this._self, this._then);

  final AscKeySaveTarget _self;
  final $Res Function(AscKeySaveTarget) _then;

/// Create a copy of AscKeySaveTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? profileName = null,Object? profile = null,}) {
  return _then(_self.copyWith(
profileName: null == profileName ? _self.profileName : profileName // ignore: cast_nullable_to_non_nullable
as String,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as AuthProfile,
  ));
}
/// Create a copy of AscKeySaveTarget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthProfileCopyWith<$Res> get profile {

  return $AuthProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [AscKeySaveTarget].
extension AscKeySaveTargetPatterns on AscKeySaveTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AscKeySaveTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AscKeySaveTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AscKeySaveTarget value)  $default,){
final _that = this;
switch (_that) {
case _AscKeySaveTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AscKeySaveTarget value)?  $default,){
final _that = this;
switch (_that) {
case _AscKeySaveTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String profileName,  AuthProfile profile)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AscKeySaveTarget() when $default != null:
return $default(_that.profileName,_that.profile);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String profileName,  AuthProfile profile)  $default,) {final _that = this;
switch (_that) {
case _AscKeySaveTarget():
return $default(_that.profileName,_that.profile);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String profileName,  AuthProfile profile)?  $default,) {final _that = this;
switch (_that) {
case _AscKeySaveTarget() when $default != null:
return $default(_that.profileName,_that.profile);case _:
  return null;

}
}

}

/// @nodoc


class _AscKeySaveTarget implements AscKeySaveTarget {
  const _AscKeySaveTarget({required this.profileName, required this.profile});


@override final  String profileName;
@override final  AuthProfile profile;

/// Create a copy of AscKeySaveTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AscKeySaveTargetCopyWith<_AscKeySaveTarget> get copyWith => __$AscKeySaveTargetCopyWithImpl<_AscKeySaveTarget>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AscKeySaveTarget&&(identical(other.profileName, profileName) || other.profileName == profileName)&&(identical(other.profile, profile) || other.profile == profile));
}


@override
int get hashCode => Object.hash(runtimeType,profileName,profile);



}

/// @nodoc
abstract mixin class _$AscKeySaveTargetCopyWith<$Res> implements $AscKeySaveTargetCopyWith<$Res> {
  factory _$AscKeySaveTargetCopyWith(_AscKeySaveTarget value, $Res Function(_AscKeySaveTarget) _then) = __$AscKeySaveTargetCopyWithImpl;
@override @useResult
$Res call({
 String profileName, AuthProfile profile
});


@override $AuthProfileCopyWith<$Res> get profile;

}
/// @nodoc
class __$AscKeySaveTargetCopyWithImpl<$Res>
    implements _$AscKeySaveTargetCopyWith<$Res> {
  __$AscKeySaveTargetCopyWithImpl(this._self, this._then);

  final _AscKeySaveTarget _self;
  final $Res Function(_AscKeySaveTarget) _then;

/// Create a copy of AscKeySaveTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? profileName = null,Object? profile = null,}) {
  return _then(_AscKeySaveTarget(
profileName: null == profileName ? _self.profileName : profileName // ignore: cast_nullable_to_non_nullable
as String,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as AuthProfile,
  ));
}

/// Create a copy of AscKeySaveTarget
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthProfileCopyWith<$Res> get profile {

  return $AuthProfileCopyWith<$Res>(_self.profile, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

// dart format on
