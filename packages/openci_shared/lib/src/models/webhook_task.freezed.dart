// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'webhook_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WebhookTask {

 String get id; String get deliveryId; String get eventType; String get payload; String get status; int get retryCount; String? get errorMessage;@DateTimeConverter() DateTime get createdAt;@DateTimeConverter() DateTime get updatedAt;
/// Create a copy of WebhookTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebhookTaskCopyWith<WebhookTask> get copyWith => _$WebhookTaskCopyWithImpl<WebhookTask>(this as WebhookTask, _$identity);

  /// Serializes this WebhookTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebhookTask&&(identical(other.id, id) || other.id == id)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.status, status) || other.status == status)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deliveryId,eventType,payload,status,retryCount,errorMessage,createdAt,updatedAt);

@override
String toString() {
  return 'WebhookTask(id: $id, deliveryId: $deliveryId, eventType: $eventType, payload: $payload, status: $status, retryCount: $retryCount, errorMessage: $errorMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WebhookTaskCopyWith<$Res>  {
  factory $WebhookTaskCopyWith(WebhookTask value, $Res Function(WebhookTask) _then) = _$WebhookTaskCopyWithImpl;
@useResult
$Res call({
 String id, String deliveryId, String eventType, String payload, String status, int retryCount, String? errorMessage,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class _$WebhookTaskCopyWithImpl<$Res>
    implements $WebhookTaskCopyWith<$Res> {
  _$WebhookTaskCopyWithImpl(this._self, this._then);

  final WebhookTask _self;
  final $Res Function(WebhookTask) _then;

/// Create a copy of WebhookTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? deliveryId = null,Object? eventType = null,Object? payload = null,Object? status = null,Object? retryCount = null,Object? errorMessage = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WebhookTask].
extension WebhookTaskPatterns on WebhookTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebhookTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebhookTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebhookTask value)  $default,){
final _that = this;
switch (_that) {
case _WebhookTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebhookTask value)?  $default,){
final _that = this;
switch (_that) {
case _WebhookTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String deliveryId,  String eventType,  String payload,  String status,  int retryCount,  String? errorMessage, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebhookTask() when $default != null:
return $default(_that.id,_that.deliveryId,_that.eventType,_that.payload,_that.status,_that.retryCount,_that.errorMessage,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String deliveryId,  String eventType,  String payload,  String status,  int retryCount,  String? errorMessage, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WebhookTask():
return $default(_that.id,_that.deliveryId,_that.eventType,_that.payload,_that.status,_that.retryCount,_that.errorMessage,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String deliveryId,  String eventType,  String payload,  String status,  int retryCount,  String? errorMessage, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WebhookTask() when $default != null:
return $default(_that.id,_that.deliveryId,_that.eventType,_that.payload,_that.status,_that.retryCount,_that.errorMessage,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebhookTask implements WebhookTask {
  const _WebhookTask({required this.id, required this.deliveryId, required this.eventType, required this.payload, this.status = 'pending', this.retryCount = 0, this.errorMessage, @DateTimeConverter() required this.createdAt, @DateTimeConverter() required this.updatedAt});
  factory _WebhookTask.fromJson(Map<String, dynamic> json) => _$WebhookTaskFromJson(json);

@override final  String id;
@override final  String deliveryId;
@override final  String eventType;
@override final  String payload;
@override@JsonKey() final  String status;
@override@JsonKey() final  int retryCount;
@override final  String? errorMessage;
@override@DateTimeConverter() final  DateTime createdAt;
@override@DateTimeConverter() final  DateTime updatedAt;

/// Create a copy of WebhookTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebhookTaskCopyWith<_WebhookTask> get copyWith => __$WebhookTaskCopyWithImpl<_WebhookTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebhookTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebhookTask&&(identical(other.id, id) || other.id == id)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.status, status) || other.status == status)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deliveryId,eventType,payload,status,retryCount,errorMessage,createdAt,updatedAt);

@override
String toString() {
  return 'WebhookTask(id: $id, deliveryId: $deliveryId, eventType: $eventType, payload: $payload, status: $status, retryCount: $retryCount, errorMessage: $errorMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WebhookTaskCopyWith<$Res> implements $WebhookTaskCopyWith<$Res> {
  factory _$WebhookTaskCopyWith(_WebhookTask value, $Res Function(_WebhookTask) _then) = __$WebhookTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String deliveryId, String eventType, String payload, String status, int retryCount, String? errorMessage,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class __$WebhookTaskCopyWithImpl<$Res>
    implements _$WebhookTaskCopyWith<$Res> {
  __$WebhookTaskCopyWithImpl(this._self, this._then);

  final _WebhookTask _self;
  final $Res Function(_WebhookTask) _then;

/// Create a copy of WebhookTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? deliveryId = null,Object? eventType = null,Object? payload = null,Object? status = null,Object? retryCount = null,Object? errorMessage = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_WebhookTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
