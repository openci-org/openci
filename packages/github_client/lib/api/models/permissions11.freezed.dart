// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'permissions11.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Permissions11 {

 bool get admin; bool get push; bool get pull; bool? get maintain; bool? get triage;
/// Create a copy of Permissions11
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Permissions11CopyWith<Permissions11> get copyWith => _$Permissions11CopyWithImpl<Permissions11>(this as Permissions11, _$identity);

  /// Serializes this Permissions11 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Permissions11&&(identical(other.admin, admin) || other.admin == admin)&&(identical(other.push, push) || other.push == push)&&(identical(other.pull, pull) || other.pull == pull)&&(identical(other.maintain, maintain) || other.maintain == maintain)&&(identical(other.triage, triage) || other.triage == triage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,admin,push,pull,maintain,triage);

@override
String toString() {
  return 'Permissions11(admin: $admin, push: $push, pull: $pull, maintain: $maintain, triage: $triage)';
}


}

/// @nodoc
abstract mixin class $Permissions11CopyWith<$Res>  {
  factory $Permissions11CopyWith(Permissions11 value, $Res Function(Permissions11) _then) = _$Permissions11CopyWithImpl;
@useResult
$Res call({
 bool admin, bool push, bool pull, bool? maintain, bool? triage
});




}
/// @nodoc
class _$Permissions11CopyWithImpl<$Res>
    implements $Permissions11CopyWith<$Res> {
  _$Permissions11CopyWithImpl(this._self, this._then);

  final Permissions11 _self;
  final $Res Function(Permissions11) _then;

/// Create a copy of Permissions11
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? admin = null,Object? push = null,Object? pull = null,Object? maintain = freezed,Object? triage = freezed,}) {
  return _then(_self.copyWith(
admin: null == admin ? _self.admin : admin // ignore: cast_nullable_to_non_nullable
as bool,push: null == push ? _self.push : push // ignore: cast_nullable_to_non_nullable
as bool,pull: null == pull ? _self.pull : pull // ignore: cast_nullable_to_non_nullable
as bool,maintain: freezed == maintain ? _self.maintain : maintain // ignore: cast_nullable_to_non_nullable
as bool?,triage: freezed == triage ? _self.triage : triage // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [Permissions11].
extension Permissions11Patterns on Permissions11 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Permissions11 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Permissions11() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Permissions11 value)  $default,){
final _that = this;
switch (_that) {
case _Permissions11():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Permissions11 value)?  $default,){
final _that = this;
switch (_that) {
case _Permissions11() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool admin,  bool push,  bool pull,  bool? maintain,  bool? triage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Permissions11() when $default != null:
return $default(_that.admin,_that.push,_that.pull,_that.maintain,_that.triage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool admin,  bool push,  bool pull,  bool? maintain,  bool? triage)  $default,) {final _that = this;
switch (_that) {
case _Permissions11():
return $default(_that.admin,_that.push,_that.pull,_that.maintain,_that.triage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool admin,  bool push,  bool pull,  bool? maintain,  bool? triage)?  $default,) {final _that = this;
switch (_that) {
case _Permissions11() when $default != null:
return $default(_that.admin,_that.push,_that.pull,_that.maintain,_that.triage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Permissions11 implements Permissions11 {
  const _Permissions11({required this.admin, required this.push, required this.pull, this.maintain, this.triage});
  factory _Permissions11.fromJson(Map<String, dynamic> json) => _$Permissions11FromJson(json);

@override final  bool admin;
@override final  bool push;
@override final  bool pull;
@override final  bool? maintain;
@override final  bool? triage;

/// Create a copy of Permissions11
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Permissions11CopyWith<_Permissions11> get copyWith => __$Permissions11CopyWithImpl<_Permissions11>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Permissions11ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Permissions11&&(identical(other.admin, admin) || other.admin == admin)&&(identical(other.push, push) || other.push == push)&&(identical(other.pull, pull) || other.pull == pull)&&(identical(other.maintain, maintain) || other.maintain == maintain)&&(identical(other.triage, triage) || other.triage == triage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,admin,push,pull,maintain,triage);

@override
String toString() {
  return 'Permissions11(admin: $admin, push: $push, pull: $pull, maintain: $maintain, triage: $triage)';
}


}

/// @nodoc
abstract mixin class _$Permissions11CopyWith<$Res> implements $Permissions11CopyWith<$Res> {
  factory _$Permissions11CopyWith(_Permissions11 value, $Res Function(_Permissions11) _then) = __$Permissions11CopyWithImpl;
@override @useResult
$Res call({
 bool admin, bool push, bool pull, bool? maintain, bool? triage
});




}
/// @nodoc
class __$Permissions11CopyWithImpl<$Res>
    implements _$Permissions11CopyWith<$Res> {
  __$Permissions11CopyWithImpl(this._self, this._then);

  final _Permissions11 _self;
  final $Res Function(_Permissions11) _then;

/// Create a copy of Permissions11
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? admin = null,Object? push = null,Object? pull = null,Object? maintain = freezed,Object? triage = freezed,}) {
  return _then(_Permissions11(
admin: null == admin ? _self.admin : admin // ignore: cast_nullable_to_non_nullable
as bool,push: null == push ? _self.push : push // ignore: cast_nullable_to_non_nullable
as bool,pull: null == pull ? _self.pull : pull // ignore: cast_nullable_to_non_nullable
as bool,maintain: freezed == maintain ? _self.maintain : maintain // ignore: cast_nullable_to_non_nullable
as bool?,triage: freezed == triage ? _self.triage : triage // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
