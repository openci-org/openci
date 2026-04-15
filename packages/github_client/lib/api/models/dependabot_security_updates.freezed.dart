// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dependabot_security_updates.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DependabotSecurityUpdates {

/// The enablement Status of Dependabot security updates for the repository.
@JsonKey(name: 'Status') Status2? get status;
/// Create a copy of DependabotSecurityUpdates
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DependabotSecurityUpdatesCopyWith<DependabotSecurityUpdates> get copyWith => _$DependabotSecurityUpdatesCopyWithImpl<DependabotSecurityUpdates>(this as DependabotSecurityUpdates, _$identity);

  /// Serializes this DependabotSecurityUpdates to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DependabotSecurityUpdates&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'DependabotSecurityUpdates(status: $status)';
}


}

/// @nodoc
abstract mixin class $DependabotSecurityUpdatesCopyWith<$Res>  {
  factory $DependabotSecurityUpdatesCopyWith(DependabotSecurityUpdates value, $Res Function(DependabotSecurityUpdates) _then) = _$DependabotSecurityUpdatesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Status') Status2? status
});




}
/// @nodoc
class _$DependabotSecurityUpdatesCopyWithImpl<$Res>
    implements $DependabotSecurityUpdatesCopyWith<$Res> {
  _$DependabotSecurityUpdatesCopyWithImpl(this._self, this._then);

  final DependabotSecurityUpdates _self;
  final $Res Function(DependabotSecurityUpdates) _then;

/// Create a copy of DependabotSecurityUpdates
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = freezed,}) {
  return _then(_self.copyWith(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status2?,
  ));
}

}


/// Adds pattern-matching-related methods to [DependabotSecurityUpdates].
extension DependabotSecurityUpdatesPatterns on DependabotSecurityUpdates {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DependabotSecurityUpdates value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DependabotSecurityUpdates() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DependabotSecurityUpdates value)  $default,){
final _that = this;
switch (_that) {
case _DependabotSecurityUpdates():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DependabotSecurityUpdates value)?  $default,){
final _that = this;
switch (_that) {
case _DependabotSecurityUpdates() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Status')  Status2? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DependabotSecurityUpdates() when $default != null:
return $default(_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Status')  Status2? status)  $default,) {final _that = this;
switch (_that) {
case _DependabotSecurityUpdates():
return $default(_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Status')  Status2? status)?  $default,) {final _that = this;
switch (_that) {
case _DependabotSecurityUpdates() when $default != null:
return $default(_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DependabotSecurityUpdates implements DependabotSecurityUpdates {
  const _DependabotSecurityUpdates({@JsonKey(name: 'Status') this.status});
  factory _DependabotSecurityUpdates.fromJson(Map<String, dynamic> json) => _$DependabotSecurityUpdatesFromJson(json);

/// The enablement Status of Dependabot security updates for the repository.
@override@JsonKey(name: 'Status') final  Status2? status;

/// Create a copy of DependabotSecurityUpdates
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DependabotSecurityUpdatesCopyWith<_DependabotSecurityUpdates> get copyWith => __$DependabotSecurityUpdatesCopyWithImpl<_DependabotSecurityUpdates>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DependabotSecurityUpdatesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DependabotSecurityUpdates&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'DependabotSecurityUpdates(status: $status)';
}


}

/// @nodoc
abstract mixin class _$DependabotSecurityUpdatesCopyWith<$Res> implements $DependabotSecurityUpdatesCopyWith<$Res> {
  factory _$DependabotSecurityUpdatesCopyWith(_DependabotSecurityUpdates value, $Res Function(_DependabotSecurityUpdates) _then) = __$DependabotSecurityUpdatesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Status') Status2? status
});




}
/// @nodoc
class __$DependabotSecurityUpdatesCopyWithImpl<$Res>
    implements _$DependabotSecurityUpdatesCopyWith<$Res> {
  __$DependabotSecurityUpdatesCopyWithImpl(this._self, this._then);

  final _DependabotSecurityUpdates _self;
  final $Res Function(_DependabotSecurityUpdates) _then;

/// Create a copy of DependabotSecurityUpdates
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(_DependabotSecurityUpdates(
status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as Status2?,
  ));
}


}

// dart format on
