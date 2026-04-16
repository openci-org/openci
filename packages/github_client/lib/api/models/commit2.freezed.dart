// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commit2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Commit2 {

 String get url; NullableGitUser? get author; NullableGitUser? get committer; String get message;@JsonKey(name: 'comment_count') int get commentCount; Tree get tree;@JsonKey(name: 'Verification') Verification? get verification;
/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Commit2CopyWith<Commit2> get copyWith => _$Commit2CopyWithImpl<Commit2>(this as Commit2, _$identity);

  /// Serializes this Commit2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Commit2&&(identical(other.url, url) || other.url == url)&&(identical(other.author, author) || other.author == author)&&(identical(other.committer, committer) || other.committer == committer)&&(identical(other.message, message) || other.message == message)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.tree, tree) || other.tree == tree)&&(identical(other.verification, verification) || other.verification == verification));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,author,committer,message,commentCount,tree,verification);

@override
String toString() {
  return 'Commit2(url: $url, author: $author, committer: $committer, message: $message, commentCount: $commentCount, tree: $tree, verification: $verification)';
}


}

/// @nodoc
abstract mixin class $Commit2CopyWith<$Res>  {
  factory $Commit2CopyWith(Commit2 value, $Res Function(Commit2) _then) = _$Commit2CopyWithImpl;
@useResult
$Res call({
 String url, NullableGitUser? author, NullableGitUser? committer, String message,@JsonKey(name: 'comment_count') int commentCount, Tree tree,@JsonKey(name: 'Verification') Verification? verification
});


$NullableGitUserCopyWith<$Res>? get author;$NullableGitUserCopyWith<$Res>? get committer;$TreeCopyWith<$Res> get tree;$VerificationCopyWith<$Res>? get verification;

}
/// @nodoc
class _$Commit2CopyWithImpl<$Res>
    implements $Commit2CopyWith<$Res> {
  _$Commit2CopyWithImpl(this._self, this._then);

  final Commit2 _self;
  final $Res Function(Commit2) _then;

/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? author = freezed,Object? committer = freezed,Object? message = null,Object? commentCount = null,Object? tree = null,Object? verification = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as NullableGitUser?,committer: freezed == committer ? _self.committer : committer // ignore: cast_nullable_to_non_nullable
as NullableGitUser?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,tree: null == tree ? _self.tree : tree // ignore: cast_nullable_to_non_nullable
as Tree,verification: freezed == verification ? _self.verification : verification // ignore: cast_nullable_to_non_nullable
as Verification?,
  ));
}
/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NullableGitUserCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $NullableGitUserCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NullableGitUserCopyWith<$Res>? get committer {
    if (_self.committer == null) {
    return null;
  }

  return $NullableGitUserCopyWith<$Res>(_self.committer!, (value) {
    return _then(_self.copyWith(committer: value));
  });
}/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TreeCopyWith<$Res> get tree {
  
  return $TreeCopyWith<$Res>(_self.tree, (value) {
    return _then(_self.copyWith(tree: value));
  });
}/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationCopyWith<$Res>? get verification {
    if (_self.verification == null) {
    return null;
  }

  return $VerificationCopyWith<$Res>(_self.verification!, (value) {
    return _then(_self.copyWith(verification: value));
  });
}
}


/// Adds pattern-matching-related methods to [Commit2].
extension Commit2Patterns on Commit2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Commit2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Commit2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Commit2 value)  $default,){
final _that = this;
switch (_that) {
case _Commit2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Commit2 value)?  $default,){
final _that = this;
switch (_that) {
case _Commit2() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  NullableGitUser? author,  NullableGitUser? committer,  String message, @JsonKey(name: 'comment_count')  int commentCount,  Tree tree, @JsonKey(name: 'Verification')  Verification? verification)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Commit2() when $default != null:
return $default(_that.url,_that.author,_that.committer,_that.message,_that.commentCount,_that.tree,_that.verification);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  NullableGitUser? author,  NullableGitUser? committer,  String message, @JsonKey(name: 'comment_count')  int commentCount,  Tree tree, @JsonKey(name: 'Verification')  Verification? verification)  $default,) {final _that = this;
switch (_that) {
case _Commit2():
return $default(_that.url,_that.author,_that.committer,_that.message,_that.commentCount,_that.tree,_that.verification);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  NullableGitUser? author,  NullableGitUser? committer,  String message, @JsonKey(name: 'comment_count')  int commentCount,  Tree tree, @JsonKey(name: 'Verification')  Verification? verification)?  $default,) {final _that = this;
switch (_that) {
case _Commit2() when $default != null:
return $default(_that.url,_that.author,_that.committer,_that.message,_that.commentCount,_that.tree,_that.verification);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Commit2 implements Commit2 {
  const _Commit2({required this.url, required this.author, required this.committer, required this.message, @JsonKey(name: 'comment_count') required this.commentCount, required this.tree, @JsonKey(name: 'Verification') this.verification});
  factory _Commit2.fromJson(Map<String, dynamic> json) => _$Commit2FromJson(json);

@override final  String url;
@override final  NullableGitUser? author;
@override final  NullableGitUser? committer;
@override final  String message;
@override@JsonKey(name: 'comment_count') final  int commentCount;
@override final  Tree tree;
@override@JsonKey(name: 'Verification') final  Verification? verification;

/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Commit2CopyWith<_Commit2> get copyWith => __$Commit2CopyWithImpl<_Commit2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Commit2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Commit2&&(identical(other.url, url) || other.url == url)&&(identical(other.author, author) || other.author == author)&&(identical(other.committer, committer) || other.committer == committer)&&(identical(other.message, message) || other.message == message)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.tree, tree) || other.tree == tree)&&(identical(other.verification, verification) || other.verification == verification));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,author,committer,message,commentCount,tree,verification);

@override
String toString() {
  return 'Commit2(url: $url, author: $author, committer: $committer, message: $message, commentCount: $commentCount, tree: $tree, verification: $verification)';
}


}

/// @nodoc
abstract mixin class _$Commit2CopyWith<$Res> implements $Commit2CopyWith<$Res> {
  factory _$Commit2CopyWith(_Commit2 value, $Res Function(_Commit2) _then) = __$Commit2CopyWithImpl;
@override @useResult
$Res call({
 String url, NullableGitUser? author, NullableGitUser? committer, String message,@JsonKey(name: 'comment_count') int commentCount, Tree tree,@JsonKey(name: 'Verification') Verification? verification
});


@override $NullableGitUserCopyWith<$Res>? get author;@override $NullableGitUserCopyWith<$Res>? get committer;@override $TreeCopyWith<$Res> get tree;@override $VerificationCopyWith<$Res>? get verification;

}
/// @nodoc
class __$Commit2CopyWithImpl<$Res>
    implements _$Commit2CopyWith<$Res> {
  __$Commit2CopyWithImpl(this._self, this._then);

  final _Commit2 _self;
  final $Res Function(_Commit2) _then;

/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? author = freezed,Object? committer = freezed,Object? message = null,Object? commentCount = null,Object? tree = null,Object? verification = freezed,}) {
  return _then(_Commit2(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as NullableGitUser?,committer: freezed == committer ? _self.committer : committer // ignore: cast_nullable_to_non_nullable
as NullableGitUser?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,tree: null == tree ? _self.tree : tree // ignore: cast_nullable_to_non_nullable
as Tree,verification: freezed == verification ? _self.verification : verification // ignore: cast_nullable_to_non_nullable
as Verification?,
  ));
}

/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NullableGitUserCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $NullableGitUserCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NullableGitUserCopyWith<$Res>? get committer {
    if (_self.committer == null) {
    return null;
  }

  return $NullableGitUserCopyWith<$Res>(_self.committer!, (value) {
    return _then(_self.copyWith(committer: value));
  });
}/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TreeCopyWith<$Res> get tree {
  
  return $TreeCopyWith<$Res>(_self.tree, (value) {
    return _then(_self.copyWith(tree: value));
  });
}/// Create a copy of Commit2
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationCopyWith<$Res>? get verification {
    if (_self.verification == null) {
    return null;
  }

  return $VerificationCopyWith<$Res>(_self.verification!, (value) {
    return _then(_self.copyWith(verification: value));
  });
}
}

// dart format on
