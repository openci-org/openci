// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nullable_git_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NullableGitUser {

 String? get name;@JsonKey(name: 'Email') String? get email; DateTime? get date;
/// Create a copy of NullableGitUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NullableGitUserCopyWith<NullableGitUser> get copyWith => _$NullableGitUserCopyWithImpl<NullableGitUser>(this as NullableGitUser, _$identity);

  /// Serializes this NullableGitUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NullableGitUser&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,email,date);

@override
String toString() {
  return 'NullableGitUser(name: $name, email: $email, date: $date)';
}


}

/// @nodoc
abstract mixin class $NullableGitUserCopyWith<$Res>  {
  factory $NullableGitUserCopyWith(NullableGitUser value, $Res Function(NullableGitUser) _then) = _$NullableGitUserCopyWithImpl;
@useResult
$Res call({
 String? name,@JsonKey(name: 'Email') String? email, DateTime? date
});




}
/// @nodoc
class _$NullableGitUserCopyWithImpl<$Res>
    implements $NullableGitUserCopyWith<$Res> {
  _$NullableGitUserCopyWithImpl(this._self, this._then);

  final NullableGitUser _self;
  final $Res Function(NullableGitUser) _then;

/// Create a copy of NullableGitUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? email = freezed,Object? date = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [NullableGitUser].
extension NullableGitUserPatterns on NullableGitUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NullableGitUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NullableGitUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NullableGitUser value)  $default,){
final _that = this;
switch (_that) {
case _NullableGitUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NullableGitUser value)?  $default,){
final _that = this;
switch (_that) {
case _NullableGitUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name, @JsonKey(name: 'Email')  String? email,  DateTime? date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NullableGitUser() when $default != null:
return $default(_that.name,_that.email,_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name, @JsonKey(name: 'Email')  String? email,  DateTime? date)  $default,) {final _that = this;
switch (_that) {
case _NullableGitUser():
return $default(_that.name,_that.email,_that.date);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name, @JsonKey(name: 'Email')  String? email,  DateTime? date)?  $default,) {final _that = this;
switch (_that) {
case _NullableGitUser() when $default != null:
return $default(_that.name,_that.email,_that.date);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NullableGitUser implements NullableGitUser {
  const _NullableGitUser({this.name, @JsonKey(name: 'Email') this.email, this.date});
  factory _NullableGitUser.fromJson(Map<String, dynamic> json) => _$NullableGitUserFromJson(json);

@override final  String? name;
@override@JsonKey(name: 'Email') final  String? email;
@override final  DateTime? date;

/// Create a copy of NullableGitUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NullableGitUserCopyWith<_NullableGitUser> get copyWith => __$NullableGitUserCopyWithImpl<_NullableGitUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NullableGitUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NullableGitUser&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,email,date);

@override
String toString() {
  return 'NullableGitUser(name: $name, email: $email, date: $date)';
}


}

/// @nodoc
abstract mixin class _$NullableGitUserCopyWith<$Res> implements $NullableGitUserCopyWith<$Res> {
  factory _$NullableGitUserCopyWith(_NullableGitUser value, $Res Function(_NullableGitUser) _then) = __$NullableGitUserCopyWithImpl;
@override @useResult
$Res call({
 String? name,@JsonKey(name: 'Email') String? email, DateTime? date
});




}
/// @nodoc
class __$NullableGitUserCopyWithImpl<$Res>
    implements _$NullableGitUserCopyWith<$Res> {
  __$NullableGitUserCopyWithImpl(this._self, this._then);

  final _NullableGitUser _self;
  final $Res Function(_NullableGitUser) _then;

/// Create a copy of NullableGitUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? email = freezed,Object? date = freezed,}) {
  return _then(_NullableGitUser(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
