// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'git_context_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GitContextState {

 String get repository; String get branch; String? get commitSha; String? get commitMessage;
/// Create a copy of GitContextState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitContextStateCopyWith<GitContextState> get copyWith => _$GitContextStateCopyWithImpl<GitContextState>(this as GitContextState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitContextState&&(identical(other.repository, repository) || other.repository == repository)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.commitMessage, commitMessage) || other.commitMessage == commitMessage));
}


@override
int get hashCode => Object.hash(runtimeType,repository,branch,commitSha,commitMessage);

@override
String toString() {
  return 'GitContextState(repository: $repository, branch: $branch, commitSha: $commitSha, commitMessage: $commitMessage)';
}


}

/// @nodoc
abstract mixin class $GitContextStateCopyWith<$Res>  {
  factory $GitContextStateCopyWith(GitContextState value, $Res Function(GitContextState) _then) = _$GitContextStateCopyWithImpl;
@useResult
$Res call({
 String repository, String branch, String? commitSha, String? commitMessage
});




}
/// @nodoc
class _$GitContextStateCopyWithImpl<$Res>
    implements $GitContextStateCopyWith<$Res> {
  _$GitContextStateCopyWithImpl(this._self, this._then);

  final GitContextState _self;
  final $Res Function(GitContextState) _then;

/// Create a copy of GitContextState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? repository = null,Object? branch = null,Object? commitSha = freezed,Object? commitMessage = freezed,}) {
  return _then(_self.copyWith(
repository: null == repository ? _self.repository : repository // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,commitMessage: freezed == commitMessage ? _self.commitMessage : commitMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GitContextState].
extension GitContextStatePatterns on GitContextState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitContextState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitContextState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitContextState value)  $default,){
final _that = this;
switch (_that) {
case _GitContextState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitContextState value)?  $default,){
final _that = this;
switch (_that) {
case _GitContextState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String repository,  String branch,  String? commitSha,  String? commitMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitContextState() when $default != null:
return $default(_that.repository,_that.branch,_that.commitSha,_that.commitMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String repository,  String branch,  String? commitSha,  String? commitMessage)  $default,) {final _that = this;
switch (_that) {
case _GitContextState():
return $default(_that.repository,_that.branch,_that.commitSha,_that.commitMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String repository,  String branch,  String? commitSha,  String? commitMessage)?  $default,) {final _that = this;
switch (_that) {
case _GitContextState() when $default != null:
return $default(_that.repository,_that.branch,_that.commitSha,_that.commitMessage);case _:
  return null;

}
}

}

/// @nodoc


class _GitContextState implements GitContextState {
  const _GitContextState({required this.repository, required this.branch, this.commitSha, this.commitMessage});
  

@override final  String repository;
@override final  String branch;
@override final  String? commitSha;
@override final  String? commitMessage;

/// Create a copy of GitContextState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitContextStateCopyWith<_GitContextState> get copyWith => __$GitContextStateCopyWithImpl<_GitContextState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitContextState&&(identical(other.repository, repository) || other.repository == repository)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.commitMessage, commitMessage) || other.commitMessage == commitMessage));
}


@override
int get hashCode => Object.hash(runtimeType,repository,branch,commitSha,commitMessage);

@override
String toString() {
  return 'GitContextState(repository: $repository, branch: $branch, commitSha: $commitSha, commitMessage: $commitMessage)';
}


}

/// @nodoc
abstract mixin class _$GitContextStateCopyWith<$Res> implements $GitContextStateCopyWith<$Res> {
  factory _$GitContextStateCopyWith(_GitContextState value, $Res Function(_GitContextState) _then) = __$GitContextStateCopyWithImpl;
@override @useResult
$Res call({
 String repository, String branch, String? commitSha, String? commitMessage
});




}
/// @nodoc
class __$GitContextStateCopyWithImpl<$Res>
    implements _$GitContextStateCopyWith<$Res> {
  __$GitContextStateCopyWithImpl(this._self, this._then);

  final _GitContextState _self;
  final $Res Function(_GitContextState) _then;

/// Create a copy of GitContextState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? repository = null,Object? branch = null,Object? commitSha = freezed,Object? commitMessage = freezed,}) {
  return _then(_GitContextState(
repository: null == repository ? _self.repository : repository // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,commitMessage: freezed == commitMessage ? _self.commitMessage : commitMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$GitBranch {

 String get name; bool get isDefault;
/// Create a copy of GitBranch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitBranchCopyWith<GitBranch> get copyWith => _$GitBranchCopyWithImpl<GitBranch>(this as GitBranch, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitBranch&&(identical(other.name, name) || other.name == name)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}


@override
int get hashCode => Object.hash(runtimeType,name,isDefault);

@override
String toString() {
  return 'GitBranch(name: $name, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class $GitBranchCopyWith<$Res>  {
  factory $GitBranchCopyWith(GitBranch value, $Res Function(GitBranch) _then) = _$GitBranchCopyWithImpl;
@useResult
$Res call({
 String name, bool isDefault
});




}
/// @nodoc
class _$GitBranchCopyWithImpl<$Res>
    implements $GitBranchCopyWith<$Res> {
  _$GitBranchCopyWithImpl(this._self, this._then);

  final GitBranch _self;
  final $Res Function(GitBranch) _then;

/// Create a copy of GitBranch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? isDefault = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GitBranch].
extension GitBranchPatterns on GitBranch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitBranch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitBranch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitBranch value)  $default,){
final _that = this;
switch (_that) {
case _GitBranch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitBranch value)?  $default,){
final _that = this;
switch (_that) {
case _GitBranch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  bool isDefault)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitBranch() when $default != null:
return $default(_that.name,_that.isDefault);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  bool isDefault)  $default,) {final _that = this;
switch (_that) {
case _GitBranch():
return $default(_that.name,_that.isDefault);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  bool isDefault)?  $default,) {final _that = this;
switch (_that) {
case _GitBranch() when $default != null:
return $default(_that.name,_that.isDefault);case _:
  return null;

}
}

}

/// @nodoc


class _GitBranch implements GitBranch {
  const _GitBranch({required this.name, this.isDefault = false});
  

@override final  String name;
@override@JsonKey() final  bool isDefault;

/// Create a copy of GitBranch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitBranchCopyWith<_GitBranch> get copyWith => __$GitBranchCopyWithImpl<_GitBranch>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitBranch&&(identical(other.name, name) || other.name == name)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault));
}


@override
int get hashCode => Object.hash(runtimeType,name,isDefault);

@override
String toString() {
  return 'GitBranch(name: $name, isDefault: $isDefault)';
}


}

/// @nodoc
abstract mixin class _$GitBranchCopyWith<$Res> implements $GitBranchCopyWith<$Res> {
  factory _$GitBranchCopyWith(_GitBranch value, $Res Function(_GitBranch) _then) = __$GitBranchCopyWithImpl;
@override @useResult
$Res call({
 String name, bool isDefault
});




}
/// @nodoc
class __$GitBranchCopyWithImpl<$Res>
    implements _$GitBranchCopyWith<$Res> {
  __$GitBranchCopyWithImpl(this._self, this._then);

  final _GitBranch _self;
  final $Res Function(_GitBranch) _then;

/// Create a copy of GitBranch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? isDefault = null,}) {
  return _then(_GitBranch(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$GitCommit {

 String get sha; String get message; String get author; DateTime get date;
/// Create a copy of GitCommit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitCommitCopyWith<GitCommit> get copyWith => _$GitCommitCopyWithImpl<GitCommit>(this as GitCommit, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitCommit&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.message, message) || other.message == message)&&(identical(other.author, author) || other.author == author)&&(identical(other.date, date) || other.date == date));
}


@override
int get hashCode => Object.hash(runtimeType,sha,message,author,date);

@override
String toString() {
  return 'GitCommit(sha: $sha, message: $message, author: $author, date: $date)';
}


}

/// @nodoc
abstract mixin class $GitCommitCopyWith<$Res>  {
  factory $GitCommitCopyWith(GitCommit value, $Res Function(GitCommit) _then) = _$GitCommitCopyWithImpl;
@useResult
$Res call({
 String sha, String message, String author, DateTime date
});




}
/// @nodoc
class _$GitCommitCopyWithImpl<$Res>
    implements $GitCommitCopyWith<$Res> {
  _$GitCommitCopyWithImpl(this._self, this._then);

  final GitCommit _self;
  final $Res Function(GitCommit) _then;

/// Create a copy of GitCommit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sha = null,Object? message = null,Object? author = null,Object? date = null,}) {
  return _then(_self.copyWith(
sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GitCommit].
extension GitCommitPatterns on GitCommit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitCommit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitCommit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitCommit value)  $default,){
final _that = this;
switch (_that) {
case _GitCommit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitCommit value)?  $default,){
final _that = this;
switch (_that) {
case _GitCommit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sha,  String message,  String author,  DateTime date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitCommit() when $default != null:
return $default(_that.sha,_that.message,_that.author,_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sha,  String message,  String author,  DateTime date)  $default,) {final _that = this;
switch (_that) {
case _GitCommit():
return $default(_that.sha,_that.message,_that.author,_that.date);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sha,  String message,  String author,  DateTime date)?  $default,) {final _that = this;
switch (_that) {
case _GitCommit() when $default != null:
return $default(_that.sha,_that.message,_that.author,_that.date);case _:
  return null;

}
}

}

/// @nodoc


class _GitCommit implements GitCommit {
  const _GitCommit({required this.sha, required this.message, required this.author, required this.date});
  

@override final  String sha;
@override final  String message;
@override final  String author;
@override final  DateTime date;

/// Create a copy of GitCommit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitCommitCopyWith<_GitCommit> get copyWith => __$GitCommitCopyWithImpl<_GitCommit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitCommit&&(identical(other.sha, sha) || other.sha == sha)&&(identical(other.message, message) || other.message == message)&&(identical(other.author, author) || other.author == author)&&(identical(other.date, date) || other.date == date));
}


@override
int get hashCode => Object.hash(runtimeType,sha,message,author,date);

@override
String toString() {
  return 'GitCommit(sha: $sha, message: $message, author: $author, date: $date)';
}


}

/// @nodoc
abstract mixin class _$GitCommitCopyWith<$Res> implements $GitCommitCopyWith<$Res> {
  factory _$GitCommitCopyWith(_GitCommit value, $Res Function(_GitCommit) _then) = __$GitCommitCopyWithImpl;
@override @useResult
$Res call({
 String sha, String message, String author, DateTime date
});




}
/// @nodoc
class __$GitCommitCopyWithImpl<$Res>
    implements _$GitCommitCopyWith<$Res> {
  __$GitCommitCopyWithImpl(this._self, this._then);

  final _GitCommit _self;
  final $Res Function(_GitCommit) _then;

/// Create a copy of GitCommit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sha = null,Object? message = null,Object? author = null,Object? date = null,}) {
  return _then(_GitCommit(
sha: null == sha ? _self.sha : sha // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
