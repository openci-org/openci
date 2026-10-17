// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fetch_github_installations.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InstallationPage {

 int get totalCount; List<GitHubInstallation> get installations; bool get hasNext;
/// Create a copy of _InstallationPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstallationPageCopyWith<_InstallationPage> get copyWith => __$InstallationPageCopyWithImpl<_InstallationPage>(this as _InstallationPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstallationPage&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&const DeepCollectionEquality().equals(other.installations, installations)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext));
}


@override
int get hashCode => Object.hash(runtimeType,totalCount,const DeepCollectionEquality().hash(installations),hasNext);

@override
String toString() {
  return '_InstallationPage(totalCount: $totalCount, installations: $installations, hasNext: $hasNext)';
}


}

/// @nodoc
abstract mixin class _$InstallationPageCopyWith<$Res>  {
  factory _$InstallationPageCopyWith(_InstallationPage value, $Res Function(_InstallationPage) _then) = __$InstallationPageCopyWithImpl;
@useResult
$Res call({
 int totalCount, List<GitHubInstallation> installations, bool hasNext
});




}
/// @nodoc
class __$InstallationPageCopyWithImpl<$Res>
    implements _$InstallationPageCopyWith<$Res> {
  __$InstallationPageCopyWithImpl(this._self, this._then);

  final _InstallationPage _self;
  final $Res Function(_InstallationPage) _then;

/// Create a copy of _InstallationPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalCount = null,Object? installations = null,Object? hasNext = null,}) {
  return _then(_self.copyWith(
totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,installations: null == installations ? _self.installations : installations // ignore: cast_nullable_to_non_nullable
as List<GitHubInstallation>,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [_InstallationPage].
extension _InstallationPagePatterns on _InstallationPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstallationPageData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstallationPageData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstallationPageData value)  $default,){
final _that = this;
switch (_that) {
case _InstallationPageData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstallationPageData value)?  $default,){
final _that = this;
switch (_that) {
case _InstallationPageData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalCount,  List<GitHubInstallation> installations,  bool hasNext)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstallationPageData() when $default != null:
return $default(_that.totalCount,_that.installations,_that.hasNext);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalCount,  List<GitHubInstallation> installations,  bool hasNext)  $default,) {final _that = this;
switch (_that) {
case _InstallationPageData():
return $default(_that.totalCount,_that.installations,_that.hasNext);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalCount,  List<GitHubInstallation> installations,  bool hasNext)?  $default,) {final _that = this;
switch (_that) {
case _InstallationPageData() when $default != null:
return $default(_that.totalCount,_that.installations,_that.hasNext);case _:
  return null;

}
}

}

/// @nodoc


class _InstallationPageData implements _InstallationPage {
  const _InstallationPageData({required this.totalCount, required final  List<GitHubInstallation> installations, required this.hasNext}): _installations = installations;


@override final  int totalCount;
 final  List<GitHubInstallation> _installations;
@override List<GitHubInstallation> get installations {
  if (_installations is EqualUnmodifiableListView) return _installations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_installations);
}

@override final  bool hasNext;

/// Create a copy of _InstallationPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstallationPageDataCopyWith<_InstallationPageData> get copyWith => __$InstallationPageDataCopyWithImpl<_InstallationPageData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstallationPageData&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&const DeepCollectionEquality().equals(other._installations, _installations)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext));
}


@override
int get hashCode => Object.hash(runtimeType,totalCount,const DeepCollectionEquality().hash(_installations),hasNext);

@override
String toString() {
  return '_InstallationPage(totalCount: $totalCount, installations: $installations, hasNext: $hasNext)';
}


}

/// @nodoc
abstract mixin class _$InstallationPageDataCopyWith<$Res> implements _$InstallationPageCopyWith<$Res> {
  factory _$InstallationPageDataCopyWith(_InstallationPageData value, $Res Function(_InstallationPageData) _then) = __$InstallationPageDataCopyWithImpl;
@override @useResult
$Res call({
 int totalCount, List<GitHubInstallation> installations, bool hasNext
});




}
/// @nodoc
class __$InstallationPageDataCopyWithImpl<$Res>
    implements _$InstallationPageDataCopyWith<$Res> {
  __$InstallationPageDataCopyWithImpl(this._self, this._then);

  final _InstallationPageData _self;
  final $Res Function(_InstallationPageData) _then;

/// Create a copy of _InstallationPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalCount = null,Object? installations = null,Object? hasNext = null,}) {
  return _then(_InstallationPageData(
totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,installations: null == installations ? _self._installations : installations // ignore: cast_nullable_to_non_nullable
as List<GitHubInstallation>,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$GitHubInstallation {

 int get id; int get appId; int get accountId; String get accountType; String get accountLogin; DateTime? get suspendedAt;
/// Create a copy of GitHubInstallation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubInstallationCopyWith<GitHubInstallation> get copyWith => _$GitHubInstallationCopyWithImpl<GitHubInstallation>(this as GitHubInstallation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubInstallation&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.accountLogin, accountLogin) || other.accountLogin == accountLogin)&&(identical(other.suspendedAt, suspendedAt) || other.suspendedAt == suspendedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,appId,accountId,accountType,accountLogin,suspendedAt);

@override
String toString() {
  return 'GitHubInstallation(id: $id, appId: $appId, accountId: $accountId, accountType: $accountType, accountLogin: $accountLogin, suspendedAt: $suspendedAt)';
}


}

/// @nodoc
abstract mixin class $GitHubInstallationCopyWith<$Res>  {
  factory $GitHubInstallationCopyWith(GitHubInstallation value, $Res Function(GitHubInstallation) _then) = _$GitHubInstallationCopyWithImpl;
@useResult
$Res call({
 int id, int appId, int accountId, String accountType, String accountLogin, DateTime? suspendedAt
});




}
/// @nodoc
class _$GitHubInstallationCopyWithImpl<$Res>
    implements $GitHubInstallationCopyWith<$Res> {
  _$GitHubInstallationCopyWithImpl(this._self, this._then);

  final GitHubInstallation _self;
  final $Res Function(GitHubInstallation) _then;

/// Create a copy of GitHubInstallation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? appId = null,Object? accountId = null,Object? accountType = null,Object? accountLogin = null,Object? suspendedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,accountLogin: null == accountLogin ? _self.accountLogin : accountLogin // ignore: cast_nullable_to_non_nullable
as String,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubInstallation].
extension GitHubInstallationPatterns on GitHubInstallation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubInstallation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubInstallation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubInstallation value)  $default,){
final _that = this;
switch (_that) {
case _GitHubInstallation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubInstallation value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubInstallation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int appId,  int accountId,  String accountType,  String accountLogin,  DateTime? suspendedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubInstallation() when $default != null:
return $default(_that.id,_that.appId,_that.accountId,_that.accountType,_that.accountLogin,_that.suspendedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int appId,  int accountId,  String accountType,  String accountLogin,  DateTime? suspendedAt)  $default,) {final _that = this;
switch (_that) {
case _GitHubInstallation():
return $default(_that.id,_that.appId,_that.accountId,_that.accountType,_that.accountLogin,_that.suspendedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int appId,  int accountId,  String accountType,  String accountLogin,  DateTime? suspendedAt)?  $default,) {final _that = this;
switch (_that) {
case _GitHubInstallation() when $default != null:
return $default(_that.id,_that.appId,_that.accountId,_that.accountType,_that.accountLogin,_that.suspendedAt);case _:
  return null;

}
}

}

/// @nodoc


class _GitHubInstallation implements GitHubInstallation {
  const _GitHubInstallation({required this.id, required this.appId, required this.accountId, required this.accountType, required this.accountLogin, required this.suspendedAt});


@override final  int id;
@override final  int appId;
@override final  int accountId;
@override final  String accountType;
@override final  String accountLogin;
@override final  DateTime? suspendedAt;

/// Create a copy of GitHubInstallation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubInstallationCopyWith<_GitHubInstallation> get copyWith => __$GitHubInstallationCopyWithImpl<_GitHubInstallation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubInstallation&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.accountLogin, accountLogin) || other.accountLogin == accountLogin)&&(identical(other.suspendedAt, suspendedAt) || other.suspendedAt == suspendedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,appId,accountId,accountType,accountLogin,suspendedAt);

@override
String toString() {
  return 'GitHubInstallation(id: $id, appId: $appId, accountId: $accountId, accountType: $accountType, accountLogin: $accountLogin, suspendedAt: $suspendedAt)';
}


}

/// @nodoc
abstract mixin class _$GitHubInstallationCopyWith<$Res> implements $GitHubInstallationCopyWith<$Res> {
  factory _$GitHubInstallationCopyWith(_GitHubInstallation value, $Res Function(_GitHubInstallation) _then) = __$GitHubInstallationCopyWithImpl;
@override @useResult
$Res call({
 int id, int appId, int accountId, String accountType, String accountLogin, DateTime? suspendedAt
});




}
/// @nodoc
class __$GitHubInstallationCopyWithImpl<$Res>
    implements _$GitHubInstallationCopyWith<$Res> {
  __$GitHubInstallationCopyWithImpl(this._self, this._then);

  final _GitHubInstallation _self;
  final $Res Function(_GitHubInstallation) _then;

/// Create a copy of GitHubInstallation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? appId = null,Object? accountId = null,Object? accountType = null,Object? accountLogin = null,Object? suspendedAt = freezed,}) {
  return _then(_GitHubInstallation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,accountLogin: null == accountLogin ? _self.accountLogin : accountLogin // ignore: cast_nullable_to_non_nullable
as String,suspendedAt: freezed == suspendedAt ? _self.suspendedAt : suspendedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
