// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow_editor_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateWorkflowState {
  bool get isCreated;
  String get selectedRepository;
  String get selectedWorkingDirectory;
  TriggerType get selectedTriggerType;
  String get selectedTriggerBranch;
  List<WorkflowStep> get selectedWorkflowSteps;

  /// Create a copy of CreateWorkflowState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CreateWorkflowStateCopyWith<CreateWorkflowState> get copyWith =>
      _$CreateWorkflowStateCopyWithImpl<CreateWorkflowState>(
          this as CreateWorkflowState, _$identity);

  /// Serializes this CreateWorkflowState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CreateWorkflowState &&
            (identical(other.isCreated, isCreated) ||
                other.isCreated == isCreated) &&
            (identical(other.selectedRepository, selectedRepository) ||
                other.selectedRepository == selectedRepository) &&
            (identical(
                    other.selectedWorkingDirectory, selectedWorkingDirectory) ||
                other.selectedWorkingDirectory == selectedWorkingDirectory) &&
            (identical(other.selectedTriggerType, selectedTriggerType) ||
                other.selectedTriggerType == selectedTriggerType) &&
            (identical(other.selectedTriggerBranch, selectedTriggerBranch) ||
                other.selectedTriggerBranch == selectedTriggerBranch) &&
            const DeepCollectionEquality()
                .equals(other.selectedWorkflowSteps, selectedWorkflowSteps));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      isCreated,
      selectedRepository,
      selectedWorkingDirectory,
      selectedTriggerType,
      selectedTriggerBranch,
      const DeepCollectionEquality().hash(selectedWorkflowSteps));

  @override
  String toString() {
    return 'CreateWorkflowState(isCreated: $isCreated, selectedRepository: $selectedRepository, selectedWorkingDirectory: $selectedWorkingDirectory, selectedTriggerType: $selectedTriggerType, selectedTriggerBranch: $selectedTriggerBranch, selectedWorkflowSteps: $selectedWorkflowSteps)';
  }
}

/// @nodoc
abstract mixin class $CreateWorkflowStateCopyWith<$Res> {
  factory $CreateWorkflowStateCopyWith(
          CreateWorkflowState value, $Res Function(CreateWorkflowState) _then) =
      _$CreateWorkflowStateCopyWithImpl;
  @useResult
  $Res call(
      {bool isCreated,
      String selectedRepository,
      String selectedWorkingDirectory,
      TriggerType selectedTriggerType,
      String selectedTriggerBranch,
      List<WorkflowStep> selectedWorkflowSteps});
}

/// @nodoc
class _$CreateWorkflowStateCopyWithImpl<$Res>
    implements $CreateWorkflowStateCopyWith<$Res> {
  _$CreateWorkflowStateCopyWithImpl(this._self, this._then);

  final CreateWorkflowState _self;
  final $Res Function(CreateWorkflowState) _then;

  /// Create a copy of CreateWorkflowState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isCreated = null,
    Object? selectedRepository = null,
    Object? selectedWorkingDirectory = null,
    Object? selectedTriggerType = null,
    Object? selectedTriggerBranch = null,
    Object? selectedWorkflowSteps = null,
  }) {
    return _then(_self.copyWith(
      isCreated: null == isCreated
          ? _self.isCreated
          : isCreated // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedRepository: null == selectedRepository
          ? _self.selectedRepository
          : selectedRepository // ignore: cast_nullable_to_non_nullable
              as String,
      selectedWorkingDirectory: null == selectedWorkingDirectory
          ? _self.selectedWorkingDirectory
          : selectedWorkingDirectory // ignore: cast_nullable_to_non_nullable
              as String,
      selectedTriggerType: null == selectedTriggerType
          ? _self.selectedTriggerType
          : selectedTriggerType // ignore: cast_nullable_to_non_nullable
              as TriggerType,
      selectedTriggerBranch: null == selectedTriggerBranch
          ? _self.selectedTriggerBranch
          : selectedTriggerBranch // ignore: cast_nullable_to_non_nullable
              as String,
      selectedWorkflowSteps: null == selectedWorkflowSteps
          ? _self.selectedWorkflowSteps
          : selectedWorkflowSteps // ignore: cast_nullable_to_non_nullable
              as List<WorkflowStep>,
    ));
  }
}

/// Adds pattern-matching-related methods to [CreateWorkflowState].
extension CreateWorkflowStatePatterns on CreateWorkflowState {
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
    TResult Function(_CreateWorkflowState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CreateWorkflowState() when $default != null:
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
    TResult Function(_CreateWorkflowState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CreateWorkflowState():
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
    TResult? Function(_CreateWorkflowState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CreateWorkflowState() when $default != null:
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
    TResult Function(
            bool isCreated,
            String selectedRepository,
            String selectedWorkingDirectory,
            TriggerType selectedTriggerType,
            String selectedTriggerBranch,
            List<WorkflowStep> selectedWorkflowSteps)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CreateWorkflowState() when $default != null:
        return $default(
            _that.isCreated,
            _that.selectedRepository,
            _that.selectedWorkingDirectory,
            _that.selectedTriggerType,
            _that.selectedTriggerBranch,
            _that.selectedWorkflowSteps);
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
    TResult Function(
            bool isCreated,
            String selectedRepository,
            String selectedWorkingDirectory,
            TriggerType selectedTriggerType,
            String selectedTriggerBranch,
            List<WorkflowStep> selectedWorkflowSteps)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CreateWorkflowState():
        return $default(
            _that.isCreated,
            _that.selectedRepository,
            _that.selectedWorkingDirectory,
            _that.selectedTriggerType,
            _that.selectedTriggerBranch,
            _that.selectedWorkflowSteps);
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
    TResult? Function(
            bool isCreated,
            String selectedRepository,
            String selectedWorkingDirectory,
            TriggerType selectedTriggerType,
            String selectedTriggerBranch,
            List<WorkflowStep> selectedWorkflowSteps)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CreateWorkflowState() when $default != null:
        return $default(
            _that.isCreated,
            _that.selectedRepository,
            _that.selectedWorkingDirectory,
            _that.selectedTriggerType,
            _that.selectedTriggerBranch,
            _that.selectedWorkflowSteps);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CreateWorkflowState implements CreateWorkflowState {
  const _CreateWorkflowState(
      {required this.isCreated,
      required this.selectedRepository,
      required this.selectedWorkingDirectory,
      required this.selectedTriggerType,
      required this.selectedTriggerBranch,
      required this.selectedWorkflowSteps});
  factory _CreateWorkflowState.fromJson(Map<String, dynamic> json) =>
      _$CreateWorkflowStateFromJson(json);

  @override
  final bool isCreated;
  @override
  final String selectedRepository;
  @override
  final String selectedWorkingDirectory;
  @override
  final TriggerType selectedTriggerType;
  @override
  final String selectedTriggerBranch;
  @override
  final List<WorkflowStep> selectedWorkflowSteps;

  /// Create a copy of CreateWorkflowState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CreateWorkflowStateCopyWith<_CreateWorkflowState> get copyWith =>
      __$CreateWorkflowStateCopyWithImpl<_CreateWorkflowState>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CreateWorkflowStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CreateWorkflowState &&
            (identical(other.isCreated, isCreated) ||
                other.isCreated == isCreated) &&
            (identical(other.selectedRepository, selectedRepository) ||
                other.selectedRepository == selectedRepository) &&
            (identical(
                    other.selectedWorkingDirectory, selectedWorkingDirectory) ||
                other.selectedWorkingDirectory == selectedWorkingDirectory) &&
            (identical(other.selectedTriggerType, selectedTriggerType) ||
                other.selectedTriggerType == selectedTriggerType) &&
            (identical(other.selectedTriggerBranch, selectedTriggerBranch) ||
                other.selectedTriggerBranch == selectedTriggerBranch) &&
            const DeepCollectionEquality()
                .equals(other.selectedWorkflowSteps, selectedWorkflowSteps));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      isCreated,
      selectedRepository,
      selectedWorkingDirectory,
      selectedTriggerType,
      selectedTriggerBranch,
      const DeepCollectionEquality().hash(selectedWorkflowSteps));

  @override
  String toString() {
    return 'CreateWorkflowState(isCreated: $isCreated, selectedRepository: $selectedRepository, selectedWorkingDirectory: $selectedWorkingDirectory, selectedTriggerType: $selectedTriggerType, selectedTriggerBranch: $selectedTriggerBranch, selectedWorkflowSteps: $selectedWorkflowSteps)';
  }
}

/// @nodoc
abstract mixin class _$CreateWorkflowStateCopyWith<$Res>
    implements $CreateWorkflowStateCopyWith<$Res> {
  factory _$CreateWorkflowStateCopyWith(_CreateWorkflowState value,
          $Res Function(_CreateWorkflowState) _then) =
      __$CreateWorkflowStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool isCreated,
      String selectedRepository,
      String selectedWorkingDirectory,
      TriggerType selectedTriggerType,
      String selectedTriggerBranch,
      List<WorkflowStep> selectedWorkflowSteps});
}

/// @nodoc
class __$CreateWorkflowStateCopyWithImpl<$Res>
    implements _$CreateWorkflowStateCopyWith<$Res> {
  __$CreateWorkflowStateCopyWithImpl(this._self, this._then);

  final _CreateWorkflowState _self;
  final $Res Function(_CreateWorkflowState) _then;

  /// Create a copy of CreateWorkflowState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isCreated = null,
    Object? selectedRepository = null,
    Object? selectedWorkingDirectory = null,
    Object? selectedTriggerType = null,
    Object? selectedTriggerBranch = null,
    Object? selectedWorkflowSteps = null,
  }) {
    return _then(_CreateWorkflowState(
      isCreated: null == isCreated
          ? _self.isCreated
          : isCreated // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedRepository: null == selectedRepository
          ? _self.selectedRepository
          : selectedRepository // ignore: cast_nullable_to_non_nullable
              as String,
      selectedWorkingDirectory: null == selectedWorkingDirectory
          ? _self.selectedWorkingDirectory
          : selectedWorkingDirectory // ignore: cast_nullable_to_non_nullable
              as String,
      selectedTriggerType: null == selectedTriggerType
          ? _self.selectedTriggerType
          : selectedTriggerType // ignore: cast_nullable_to_non_nullable
              as TriggerType,
      selectedTriggerBranch: null == selectedTriggerBranch
          ? _self.selectedTriggerBranch
          : selectedTriggerBranch // ignore: cast_nullable_to_non_nullable
              as String,
      selectedWorkflowSteps: null == selectedWorkflowSteps
          ? _self.selectedWorkflowSteps
          : selectedWorkflowSteps // ignore: cast_nullable_to_non_nullable
              as List<WorkflowStep>,
    ));
  }
}

// dart format on
