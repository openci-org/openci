// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'permissions10.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Permissions10 {

 bool get admin; bool get pull; bool get push; bool? get triage; bool? get maintain;
/// Create a copy of Permissions10
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Permissions10CopyWith<Permissions10> get copyWith => _$Permissions10CopyWithImpl<Permissions10>(this as Permissions10, _$identity);

  /// Serializes this Permissions10 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Permissions10&&(identical(other.admin, admin) || other.admin == admin)&&(identical(other.pull, pull) || other.pull == pull)&&(identical(other.push, push) || other.push == push)&&(identical(other.triage, triage) || other.triage == triage)&&(identical(other.maintain, maintain) || other.maintain == maintain));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,admin,pull,push,triage,maintain);

@override
String toString() {
  return 'Permissions10(admin: $admin, pull: $pull, push: $push, triage: $triage, maintain: $maintain)';
}


}

/// @nodoc
abstract mixin class $Permissions10CopyWith<$Res>  {
  factory $Permissions10CopyWith(Permissions10 value, $Res Function(Permissions10) _then) = _$Permissions10CopyWithImpl;
@useResult
$Res call({
 bool admin, bool pull, bool push, bool? triage, bool? maintain
});




}
/// @nodoc
class _$Permissions10CopyWithImpl<$Res>
    implements $Permissions10CopyWith<$Res> {
  _$Permissions10CopyWithImpl(this._self, this._then);

  final Permissions10 _self;
  final $Res Function(Permissions10) _then;

/// Create a copy of Permissions10
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? admin = null,Object? pull = null,Object? push = null,Object? triage = freezed,Object? maintain = freezed,}) {
  return _then(_self.copyWith(
admin: null == admin ? _self.admin : admin // ignore: cast_nullable_to_non_nullable
as bool,pull: null == pull ? _self.pull : pull // ignore: cast_nullable_to_non_nullable
as bool,push: null == push ? _self.push : push // ignore: cast_nullable_to_non_nullable
as bool,triage: freezed == triage ? _self.triage : triage // ignore: cast_nullable_to_non_nullable
as bool?,maintain: freezed == maintain ? _self.maintain : maintain // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [Permissions10].
extension Permissions10Patterns on Permissions10 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Permissions10 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Permissions10() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Permissions10 value)  $default,){
final _that = this;
switch (_that) {
case _Permissions10():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Permissions10 value)?  $default,){
final _that = this;
switch (_that) {
case _Permissions10() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool admin,  bool pull,  bool push,  bool? triage,  bool? maintain)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Permissions10() when $default != null:
return $default(_that.admin,_that.pull,_that.push,_that.triage,_that.maintain);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool admin,  bool pull,  bool push,  bool? triage,  bool? maintain)  $default,) {final _that = this;
switch (_that) {
case _Permissions10():
return $default(_that.admin,_that.pull,_that.push,_that.triage,_that.maintain);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool admin,  bool pull,  bool push,  bool? triage,  bool? maintain)?  $default,) {final _that = this;
switch (_that) {
case _Permissions10() when $default != null:
return $default(_that.admin,_that.pull,_that.push,_that.triage,_that.maintain);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Permissions10 implements Permissions10 {
  const _Permissions10({required this.admin, required this.pull, required this.push, this.triage, this.maintain});
  factory _Permissions10.fromJson(Map<String, dynamic> json) => _$Permissions10FromJson(json);

@override final  bool admin;
@override final  bool pull;
@override final  bool push;
@override final  bool? triage;
@override final  bool? maintain;

/// Create a copy of Permissions10
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Permissions10CopyWith<_Permissions10> get copyWith => __$Permissions10CopyWithImpl<_Permissions10>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Permissions10ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Permissions10&&(identical(other.admin, admin) || other.admin == admin)&&(identical(other.pull, pull) || other.pull == pull)&&(identical(other.push, push) || other.push == push)&&(identical(other.triage, triage) || other.triage == triage)&&(identical(other.maintain, maintain) || other.maintain == maintain));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,admin,pull,push,triage,maintain);

@override
String toString() {
  return 'Permissions10(admin: $admin, pull: $pull, push: $push, triage: $triage, maintain: $maintain)';
}


}

/// @nodoc
abstract mixin class _$Permissions10CopyWith<$Res> implements $Permissions10CopyWith<$Res> {
  factory _$Permissions10CopyWith(_Permissions10 value, $Res Function(_Permissions10) _then) = __$Permissions10CopyWithImpl;
@override @useResult
$Res call({
 bool admin, bool pull, bool push, bool? triage, bool? maintain
});




}
/// @nodoc
class __$Permissions10CopyWithImpl<$Res>
    implements _$Permissions10CopyWith<$Res> {
  __$Permissions10CopyWithImpl(this._self, this._then);

  final _Permissions10 _self;
  final $Res Function(_Permissions10) _then;

/// Create a copy of Permissions10
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? admin = null,Object? pull = null,Object? push = null,Object? triage = freezed,Object? maintain = freezed,}) {
  return _then(_Permissions10(
admin: null == admin ? _self.admin : admin // ignore: cast_nullable_to_non_nullable
as bool,pull: null == pull ? _self.pull : pull // ignore: cast_nullable_to_non_nullable
as bool,push: null == push ? _self.push : push // ignore: cast_nullable_to_non_nullable
as bool,triage: freezed == triage ? _self.triage : triage // ignore: cast_nullable_to_non_nullable
as bool?,maintain: freezed == maintain ? _self.maintain : maintain // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
