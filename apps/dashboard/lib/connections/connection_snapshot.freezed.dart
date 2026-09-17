// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ConnectionSnapshot {

 List<ConnectionProfile> get profiles; String get activeId;
/// Create a copy of ConnectionSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectionSnapshotCopyWith<ConnectionSnapshot> get copyWith => _$ConnectionSnapshotCopyWithImpl<ConnectionSnapshot>(this as ConnectionSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectionSnapshot&&const DeepCollectionEquality().equals(other.profiles, profiles)&&(identical(other.activeId, activeId) || other.activeId == activeId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(profiles),activeId);

@override
String toString() {
  return 'ConnectionSnapshot(profiles: $profiles, activeId: $activeId)';
}


}

/// @nodoc
abstract mixin class $ConnectionSnapshotCopyWith<$Res>  {
  factory $ConnectionSnapshotCopyWith(ConnectionSnapshot value, $Res Function(ConnectionSnapshot) _then) = _$ConnectionSnapshotCopyWithImpl;
@useResult
$Res call({
 List<ConnectionProfile> profiles, String activeId
});




}
/// @nodoc
class _$ConnectionSnapshotCopyWithImpl<$Res>
    implements $ConnectionSnapshotCopyWith<$Res> {
  _$ConnectionSnapshotCopyWithImpl(this._self, this._then);

  final ConnectionSnapshot _self;
  final $Res Function(ConnectionSnapshot) _then;

/// Create a copy of ConnectionSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? profiles = null,Object? activeId = null,}) {
  return _then(_self.copyWith(
profiles: null == profiles ? _self.profiles : profiles // ignore: cast_nullable_to_non_nullable
as List<ConnectionProfile>,activeId: null == activeId ? _self.activeId : activeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ConnectionSnapshot].
extension ConnectionSnapshotPatterns on ConnectionSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConnectionSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConnectionSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConnectionSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _ConnectionSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConnectionSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _ConnectionSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ConnectionProfile> profiles,  String activeId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConnectionSnapshot() when $default != null:
return $default(_that.profiles,_that.activeId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ConnectionProfile> profiles,  String activeId)  $default,) {final _that = this;
switch (_that) {
case _ConnectionSnapshot():
return $default(_that.profiles,_that.activeId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ConnectionProfile> profiles,  String activeId)?  $default,) {final _that = this;
switch (_that) {
case _ConnectionSnapshot() when $default != null:
return $default(_that.profiles,_that.activeId);case _:
  return null;

}
}

}

/// @nodoc


class _ConnectionSnapshot implements ConnectionSnapshot {
  const _ConnectionSnapshot({required final  List<ConnectionProfile> profiles, required this.activeId}): _profiles = profiles;


 final  List<ConnectionProfile> _profiles;
@override List<ConnectionProfile> get profiles {
  if (_profiles is EqualUnmodifiableListView) return _profiles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_profiles);
}

@override final  String activeId;

/// Create a copy of ConnectionSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConnectionSnapshotCopyWith<_ConnectionSnapshot> get copyWith => __$ConnectionSnapshotCopyWithImpl<_ConnectionSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConnectionSnapshot&&const DeepCollectionEquality().equals(other._profiles, _profiles)&&(identical(other.activeId, activeId) || other.activeId == activeId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_profiles),activeId);

@override
String toString() {
  return 'ConnectionSnapshot(profiles: $profiles, activeId: $activeId)';
}


}

/// @nodoc
abstract mixin class _$ConnectionSnapshotCopyWith<$Res> implements $ConnectionSnapshotCopyWith<$Res> {
  factory _$ConnectionSnapshotCopyWith(_ConnectionSnapshot value, $Res Function(_ConnectionSnapshot) _then) = __$ConnectionSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<ConnectionProfile> profiles, String activeId
});




}
/// @nodoc
class __$ConnectionSnapshotCopyWithImpl<$Res>
    implements _$ConnectionSnapshotCopyWith<$Res> {
  __$ConnectionSnapshotCopyWithImpl(this._self, this._then);

  final _ConnectionSnapshot _self;
  final $Res Function(_ConnectionSnapshot) _then;

/// Create a copy of ConnectionSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? profiles = null,Object? activeId = null,}) {
  return _then(_ConnectionSnapshot(
profiles: null == profiles ? _self._profiles : profiles // ignore: cast_nullable_to_non_nullable
as List<ConnectionProfile>,activeId: null == activeId ? _self.activeId : activeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
