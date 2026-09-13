// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'loki_push_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LokiStream {

 LokiLabels get labels; List<List<String>> get values;
/// Create a copy of LokiStream
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LokiStreamCopyWith<LokiStream> get copyWith => _$LokiStreamCopyWithImpl<LokiStream>(this as LokiStream, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LokiStream&&(identical(other.labels, labels) || other.labels == labels)&&const DeepCollectionEquality().equals(other.values, values));
}


@override
int get hashCode => Object.hash(runtimeType,labels,const DeepCollectionEquality().hash(values));

@override
String toString() {
  return 'LokiStream(labels: $labels, values: $values)';
}


}

/// @nodoc
abstract mixin class $LokiStreamCopyWith<$Res>  {
  factory $LokiStreamCopyWith(LokiStream value, $Res Function(LokiStream) _then) = _$LokiStreamCopyWithImpl;
@useResult
$Res call({
 LokiLabels labels, List<List<String>> values
});


$LokiLabelsCopyWith<$Res> get labels;

}
/// @nodoc
class _$LokiStreamCopyWithImpl<$Res>
    implements $LokiStreamCopyWith<$Res> {
  _$LokiStreamCopyWithImpl(this._self, this._then);

  final LokiStream _self;
  final $Res Function(LokiStream) _then;

/// Create a copy of LokiStream
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? labels = null,Object? values = null,}) {
  return _then(_self.copyWith(
labels: null == labels ? _self.labels : labels // ignore: cast_nullable_to_non_nullable
as LokiLabels,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as List<List<String>>,
  ));
}
/// Create a copy of LokiStream
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LokiLabelsCopyWith<$Res> get labels {
  
  return $LokiLabelsCopyWith<$Res>(_self.labels, (value) {
    return _then(_self.copyWith(labels: value));
  });
}
}


/// Adds pattern-matching-related methods to [LokiStream].
extension LokiStreamPatterns on LokiStream {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LokiStream value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LokiStream() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LokiStream value)  $default,){
final _that = this;
switch (_that) {
case _LokiStream():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LokiStream value)?  $default,){
final _that = this;
switch (_that) {
case _LokiStream() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LokiLabels labels,  List<List<String>> values)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LokiStream() when $default != null:
return $default(_that.labels,_that.values);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LokiLabels labels,  List<List<String>> values)  $default,) {final _that = this;
switch (_that) {
case _LokiStream():
return $default(_that.labels,_that.values);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LokiLabels labels,  List<List<String>> values)?  $default,) {final _that = this;
switch (_that) {
case _LokiStream() when $default != null:
return $default(_that.labels,_that.values);case _:
  return null;

}
}

}

/// @nodoc


class _LokiStream extends LokiStream {
  const _LokiStream({required this.labels, required final  List<List<String>> values}): _values = values,super._();
  

@override final  LokiLabels labels;
 final  List<List<String>> _values;
@override List<List<String>> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}


/// Create a copy of LokiStream
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LokiStreamCopyWith<_LokiStream> get copyWith => __$LokiStreamCopyWithImpl<_LokiStream>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LokiStream&&(identical(other.labels, labels) || other.labels == labels)&&const DeepCollectionEquality().equals(other._values, _values));
}


@override
int get hashCode => Object.hash(runtimeType,labels,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'LokiStream(labels: $labels, values: $values)';
}


}

/// @nodoc
abstract mixin class _$LokiStreamCopyWith<$Res> implements $LokiStreamCopyWith<$Res> {
  factory _$LokiStreamCopyWith(_LokiStream value, $Res Function(_LokiStream) _then) = __$LokiStreamCopyWithImpl;
@override @useResult
$Res call({
 LokiLabels labels, List<List<String>> values
});


@override $LokiLabelsCopyWith<$Res> get labels;

}
/// @nodoc
class __$LokiStreamCopyWithImpl<$Res>
    implements _$LokiStreamCopyWith<$Res> {
  __$LokiStreamCopyWithImpl(this._self, this._then);

  final _LokiStream _self;
  final $Res Function(_LokiStream) _then;

/// Create a copy of LokiStream
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? labels = null,Object? values = null,}) {
  return _then(_LokiStream(
labels: null == labels ? _self.labels : labels // ignore: cast_nullable_to_non_nullable
as LokiLabels,values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<List<String>>,
  ));
}

/// Create a copy of LokiStream
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LokiLabelsCopyWith<$Res> get labels {
  
  return $LokiLabelsCopyWith<$Res>(_self.labels, (value) {
    return _then(_self.copyWith(labels: value));
  });
}
}

/// @nodoc
mixin _$LokiPushPayload {

 List<LokiStream> get streams;
/// Create a copy of LokiPushPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LokiPushPayloadCopyWith<LokiPushPayload> get copyWith => _$LokiPushPayloadCopyWithImpl<LokiPushPayload>(this as LokiPushPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LokiPushPayload&&const DeepCollectionEquality().equals(other.streams, streams));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(streams));

@override
String toString() {
  return 'LokiPushPayload(streams: $streams)';
}


}

/// @nodoc
abstract mixin class $LokiPushPayloadCopyWith<$Res>  {
  factory $LokiPushPayloadCopyWith(LokiPushPayload value, $Res Function(LokiPushPayload) _then) = _$LokiPushPayloadCopyWithImpl;
@useResult
$Res call({
 List<LokiStream> streams
});




}
/// @nodoc
class _$LokiPushPayloadCopyWithImpl<$Res>
    implements $LokiPushPayloadCopyWith<$Res> {
  _$LokiPushPayloadCopyWithImpl(this._self, this._then);

  final LokiPushPayload _self;
  final $Res Function(LokiPushPayload) _then;

/// Create a copy of LokiPushPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streams = null,}) {
  return _then(_self.copyWith(
streams: null == streams ? _self.streams : streams // ignore: cast_nullable_to_non_nullable
as List<LokiStream>,
  ));
}

}


/// Adds pattern-matching-related methods to [LokiPushPayload].
extension LokiPushPayloadPatterns on LokiPushPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LokiPushPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LokiPushPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LokiPushPayload value)  $default,){
final _that = this;
switch (_that) {
case _LokiPushPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LokiPushPayload value)?  $default,){
final _that = this;
switch (_that) {
case _LokiPushPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LokiStream> streams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LokiPushPayload() when $default != null:
return $default(_that.streams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LokiStream> streams)  $default,) {final _that = this;
switch (_that) {
case _LokiPushPayload():
return $default(_that.streams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LokiStream> streams)?  $default,) {final _that = this;
switch (_that) {
case _LokiPushPayload() when $default != null:
return $default(_that.streams);case _:
  return null;

}
}

}

/// @nodoc


class _LokiPushPayload extends LokiPushPayload {
  const _LokiPushPayload({required final  List<LokiStream> streams}): _streams = streams,super._();
  

 final  List<LokiStream> _streams;
@override List<LokiStream> get streams {
  if (_streams is EqualUnmodifiableListView) return _streams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_streams);
}


/// Create a copy of LokiPushPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LokiPushPayloadCopyWith<_LokiPushPayload> get copyWith => __$LokiPushPayloadCopyWithImpl<_LokiPushPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LokiPushPayload&&const DeepCollectionEquality().equals(other._streams, _streams));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_streams));

@override
String toString() {
  return 'LokiPushPayload(streams: $streams)';
}


}

/// @nodoc
abstract mixin class _$LokiPushPayloadCopyWith<$Res> implements $LokiPushPayloadCopyWith<$Res> {
  factory _$LokiPushPayloadCopyWith(_LokiPushPayload value, $Res Function(_LokiPushPayload) _then) = __$LokiPushPayloadCopyWithImpl;
@override @useResult
$Res call({
 List<LokiStream> streams
});




}
/// @nodoc
class __$LokiPushPayloadCopyWithImpl<$Res>
    implements _$LokiPushPayloadCopyWith<$Res> {
  __$LokiPushPayloadCopyWithImpl(this._self, this._then);

  final _LokiPushPayload _self;
  final $Res Function(_LokiPushPayload) _then;

/// Create a copy of LokiPushPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streams = null,}) {
  return _then(_LokiPushPayload(
streams: null == streams ? _self._streams : streams // ignore: cast_nullable_to_non_nullable
as List<LokiStream>,
  ));
}


}

// dart format on
