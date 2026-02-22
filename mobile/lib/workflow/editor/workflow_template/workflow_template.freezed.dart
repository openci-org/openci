// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkflowTemplate {
  String get name;
  String get title;

  /// Create a copy of WorkflowTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkflowTemplateCopyWith<WorkflowTemplate> get copyWith =>
      _$WorkflowTemplateCopyWithImpl<WorkflowTemplate>(
          this as WorkflowTemplate, _$identity);

  /// Serializes this WorkflowTemplate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkflowTemplate &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.title, title) || other.title == title));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, title);

  @override
  String toString() {
    return 'WorkflowTemplate(name: $name, title: $title)';
  }
}

/// @nodoc
abstract mixin class $WorkflowTemplateCopyWith<$Res> {
  factory $WorkflowTemplateCopyWith(
          WorkflowTemplate value, $Res Function(WorkflowTemplate) _then) =
      _$WorkflowTemplateCopyWithImpl;
  @useResult
  $Res call({String name, String title});
}

/// @nodoc
class _$WorkflowTemplateCopyWithImpl<$Res>
    implements $WorkflowTemplateCopyWith<$Res> {
  _$WorkflowTemplateCopyWithImpl(this._self, this._then);

  final WorkflowTemplate _self;
  final $Res Function(WorkflowTemplate) _then;

  /// Create a copy of WorkflowTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? title = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [WorkflowTemplate].
extension WorkflowTemplatePatterns on WorkflowTemplate {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_WorkflowTemplate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkflowTemplate() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_WorkflowTemplate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkflowTemplate():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_WorkflowTemplate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkflowTemplate() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String name, String title)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkflowTemplate() when $default != null:
        return $default(_that.name, _that.title);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String name, String title) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkflowTemplate():
        return $default(_that.name, _that.title);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String name, String title)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkflowTemplate() when $default != null:
        return $default(_that.name, _that.title);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WorkflowTemplate implements WorkflowTemplate {
  const _WorkflowTemplate({required this.name, required this.title});
  factory _WorkflowTemplate.fromJson(Map<String, dynamic> json) =>
      _$WorkflowTemplateFromJson(json);

  @override
  final String name;
  @override
  final String title;

  /// Create a copy of WorkflowTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkflowTemplateCopyWith<_WorkflowTemplate> get copyWith =>
      __$WorkflowTemplateCopyWithImpl<_WorkflowTemplate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkflowTemplateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkflowTemplate &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.title, title) || other.title == title));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, title);

  @override
  String toString() {
    return 'WorkflowTemplate(name: $name, title: $title)';
  }
}

/// @nodoc
abstract mixin class _$WorkflowTemplateCopyWith<$Res>
    implements $WorkflowTemplateCopyWith<$Res> {
  factory _$WorkflowTemplateCopyWith(
          _WorkflowTemplate value, $Res Function(_WorkflowTemplate) _then) =
      __$WorkflowTemplateCopyWithImpl;
  @override
  @useResult
  $Res call({String name, String title});
}

/// @nodoc
class __$WorkflowTemplateCopyWithImpl<$Res>
    implements _$WorkflowTemplateCopyWith<$Res> {
  __$WorkflowTemplateCopyWithImpl(this._self, this._then);

  final _WorkflowTemplate _self;
  final $Res Function(_WorkflowTemplate) _then;

  /// Create a copy of WorkflowTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? title = null,
  }) {
    return _then(_WorkflowTemplate(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
