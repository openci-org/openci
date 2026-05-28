// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Team {

 String get id; String get name; List<String> get members; List<int> get installationIds; int get runNumber; bool get aiEnabled; String? get githubBaseUrl; String? get githubApiBaseUrl;@DateTimeConverter() DateTime get createdAt;@DateTimeConverter() DateTime get updatedAt;
/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamCopyWith<Team> get copyWith => _$TeamCopyWithImpl<Team>(this as Team, _$identity);

  /// Serializes this Team to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Team&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.members, members)&&const DeepCollectionEquality().equals(other.installationIds, installationIds)&&(identical(other.runNumber, runNumber) || other.runNumber == runNumber)&&(identical(other.aiEnabled, aiEnabled) || other.aiEnabled == aiEnabled)&&(identical(other.githubBaseUrl, githubBaseUrl) || other.githubBaseUrl == githubBaseUrl)&&(identical(other.githubApiBaseUrl, githubApiBaseUrl) || other.githubApiBaseUrl == githubApiBaseUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(members),const DeepCollectionEquality().hash(installationIds),runNumber,aiEnabled,githubBaseUrl,githubApiBaseUrl,createdAt,updatedAt);

@override
String toString() {
  return 'Team(id: $id, name: $name, members: $members, installationIds: $installationIds, runNumber: $runNumber, aiEnabled: $aiEnabled, githubBaseUrl: $githubBaseUrl, githubApiBaseUrl: $githubApiBaseUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TeamCopyWith<$Res>  {
  factory $TeamCopyWith(Team value, $Res Function(Team) _then) = _$TeamCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<String> members, List<int> installationIds, int runNumber, bool aiEnabled, String? githubBaseUrl, String? githubApiBaseUrl,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class _$TeamCopyWithImpl<$Res>
    implements $TeamCopyWith<$Res> {
  _$TeamCopyWithImpl(this._self, this._then);

  final Team _self;
  final $Res Function(Team) _then;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? members = null,Object? installationIds = null,Object? runNumber = null,Object? aiEnabled = null,Object? githubBaseUrl = freezed,Object? githubApiBaseUrl = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<String>,installationIds: null == installationIds ? _self.installationIds : installationIds // ignore: cast_nullable_to_non_nullable
as List<int>,runNumber: null == runNumber ? _self.runNumber : runNumber // ignore: cast_nullable_to_non_nullable
as int,aiEnabled: null == aiEnabled ? _self.aiEnabled : aiEnabled // ignore: cast_nullable_to_non_nullable
as bool,githubBaseUrl: freezed == githubBaseUrl ? _self.githubBaseUrl : githubBaseUrl // ignore: cast_nullable_to_non_nullable
as String?,githubApiBaseUrl: freezed == githubApiBaseUrl ? _self.githubApiBaseUrl : githubApiBaseUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Team].
extension TeamPatterns on Team {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Team value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Team() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Team value)  $default,){
final _that = this;
switch (_that) {
case _Team():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Team value)?  $default,){
final _that = this;
switch (_that) {
case _Team() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<String> members,  List<int> installationIds,  int runNumber,  bool aiEnabled,  String? githubBaseUrl,  String? githubApiBaseUrl, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Team() when $default != null:
return $default(_that.id,_that.name,_that.members,_that.installationIds,_that.runNumber,_that.aiEnabled,_that.githubBaseUrl,_that.githubApiBaseUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<String> members,  List<int> installationIds,  int runNumber,  bool aiEnabled,  String? githubBaseUrl,  String? githubApiBaseUrl, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Team():
return $default(_that.id,_that.name,_that.members,_that.installationIds,_that.runNumber,_that.aiEnabled,_that.githubBaseUrl,_that.githubApiBaseUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<String> members,  List<int> installationIds,  int runNumber,  bool aiEnabled,  String? githubBaseUrl,  String? githubApiBaseUrl, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Team() when $default != null:
return $default(_that.id,_that.name,_that.members,_that.installationIds,_that.runNumber,_that.aiEnabled,_that.githubBaseUrl,_that.githubApiBaseUrl,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Team implements Team {
  const _Team({required this.id, required this.name, required final  List<String> members, final  List<int> installationIds = const [], this.runNumber = 1, this.aiEnabled = true, this.githubBaseUrl, this.githubApiBaseUrl, @DateTimeConverter() required this.createdAt, @DateTimeConverter() required this.updatedAt}): _members = members,_installationIds = installationIds;
  factory _Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);

@override final  String id;
@override final  String name;
 final  List<String> _members;
@override List<String> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

 final  List<int> _installationIds;
@override@JsonKey() List<int> get installationIds {
  if (_installationIds is EqualUnmodifiableListView) return _installationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_installationIds);
}

@override@JsonKey() final  int runNumber;
@override@JsonKey() final  bool aiEnabled;
@override final  String? githubBaseUrl;
@override final  String? githubApiBaseUrl;
@override@DateTimeConverter() final  DateTime createdAt;
@override@DateTimeConverter() final  DateTime updatedAt;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamCopyWith<_Team> get copyWith => __$TeamCopyWithImpl<_Team>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Team&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._members, _members)&&const DeepCollectionEquality().equals(other._installationIds, _installationIds)&&(identical(other.runNumber, runNumber) || other.runNumber == runNumber)&&(identical(other.aiEnabled, aiEnabled) || other.aiEnabled == aiEnabled)&&(identical(other.githubBaseUrl, githubBaseUrl) || other.githubBaseUrl == githubBaseUrl)&&(identical(other.githubApiBaseUrl, githubApiBaseUrl) || other.githubApiBaseUrl == githubApiBaseUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_members),const DeepCollectionEquality().hash(_installationIds),runNumber,aiEnabled,githubBaseUrl,githubApiBaseUrl,createdAt,updatedAt);

@override
String toString() {
  return 'Team(id: $id, name: $name, members: $members, installationIds: $installationIds, runNumber: $runNumber, aiEnabled: $aiEnabled, githubBaseUrl: $githubBaseUrl, githubApiBaseUrl: $githubApiBaseUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TeamCopyWith<$Res> implements $TeamCopyWith<$Res> {
  factory _$TeamCopyWith(_Team value, $Res Function(_Team) _then) = __$TeamCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<String> members, List<int> installationIds, int runNumber, bool aiEnabled, String? githubBaseUrl, String? githubApiBaseUrl,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class __$TeamCopyWithImpl<$Res>
    implements _$TeamCopyWith<$Res> {
  __$TeamCopyWithImpl(this._self, this._then);

  final _Team _self;
  final $Res Function(_Team) _then;

/// Create a copy of Team
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? members = null,Object? installationIds = null,Object? runNumber = null,Object? aiEnabled = null,Object? githubBaseUrl = freezed,Object? githubApiBaseUrl = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Team(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<String>,installationIds: null == installationIds ? _self._installationIds : installationIds // ignore: cast_nullable_to_non_nullable
as List<int>,runNumber: null == runNumber ? _self.runNumber : runNumber // ignore: cast_nullable_to_non_nullable
as int,aiEnabled: null == aiEnabled ? _self.aiEnabled : aiEnabled // ignore: cast_nullable_to_non_nullable
as bool,githubBaseUrl: freezed == githubBaseUrl ? _self.githubBaseUrl : githubBaseUrl // ignore: cast_nullable_to_non_nullable
as String?,githubApiBaseUrl: freezed == githubApiBaseUrl ? _self.githubApiBaseUrl : githubApiBaseUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
