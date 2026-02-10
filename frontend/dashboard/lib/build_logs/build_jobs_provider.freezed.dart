// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'build_jobs_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuildJob {
  String get id;
  String get status;
  String get owner;
  String get repo;
  String? get teamId;
  String? get workflowId;
  String? get commitSha;
  int? get pullRequestNumber;
  int? get runCount;
  String? get latestRunId;
  String? get tagName;
  @DateTimeConverter()
  DateTime get createdAt;
  @DateTimeConverter()
  DateTime get updatedAt;

  /// Create a copy of BuildJob
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BuildJobCopyWith<BuildJob> get copyWith =>
      _$BuildJobCopyWithImpl<BuildJob>(this as BuildJob, _$identity);

  /// Serializes this BuildJob to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BuildJob &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.repo, repo) || other.repo == repo) &&
            (identical(other.teamId, teamId) || other.teamId == teamId) &&
            (identical(other.workflowId, workflowId) ||
                other.workflowId == workflowId) &&
            (identical(other.commitSha, commitSha) ||
                other.commitSha == commitSha) &&
            (identical(other.pullRequestNumber, pullRequestNumber) ||
                other.pullRequestNumber == pullRequestNumber) &&
            (identical(other.runCount, runCount) ||
                other.runCount == runCount) &&
            (identical(other.latestRunId, latestRunId) ||
                other.latestRunId == latestRunId) &&
            (identical(other.tagName, tagName) || other.tagName == tagName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      status,
      owner,
      repo,
      teamId,
      workflowId,
      commitSha,
      pullRequestNumber,
      runCount,
      latestRunId,
      tagName,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'BuildJob(id: $id, status: $status, owner: $owner, repo: $repo, teamId: $teamId, workflowId: $workflowId, commitSha: $commitSha, pullRequestNumber: $pullRequestNumber, runCount: $runCount, latestRunId: $latestRunId, tagName: $tagName, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $BuildJobCopyWith<$Res> {
  factory $BuildJobCopyWith(BuildJob value, $Res Function(BuildJob) _then) =
      _$BuildJobCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String status,
      String owner,
      String repo,
      String? teamId,
      String? workflowId,
      String? commitSha,
      int? pullRequestNumber,
      int? runCount,
      String? latestRunId,
      String? tagName,
      @DateTimeConverter() DateTime createdAt,
      @DateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class _$BuildJobCopyWithImpl<$Res> implements $BuildJobCopyWith<$Res> {
  _$BuildJobCopyWithImpl(this._self, this._then);

  final BuildJob _self;
  final $Res Function(BuildJob) _then;

  /// Create a copy of BuildJob
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? owner = null,
    Object? repo = null,
    Object? teamId = freezed,
    Object? workflowId = freezed,
    Object? commitSha = freezed,
    Object? pullRequestNumber = freezed,
    Object? runCount = freezed,
    Object? latestRunId = freezed,
    Object? tagName = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      owner: null == owner
          ? _self.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      repo: null == repo
          ? _self.repo
          : repo // ignore: cast_nullable_to_non_nullable
              as String,
      teamId: freezed == teamId
          ? _self.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String?,
      workflowId: freezed == workflowId
          ? _self.workflowId
          : workflowId // ignore: cast_nullable_to_non_nullable
              as String?,
      commitSha: freezed == commitSha
          ? _self.commitSha
          : commitSha // ignore: cast_nullable_to_non_nullable
              as String?,
      pullRequestNumber: freezed == pullRequestNumber
          ? _self.pullRequestNumber
          : pullRequestNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      runCount: freezed == runCount
          ? _self.runCount
          : runCount // ignore: cast_nullable_to_non_nullable
              as int?,
      latestRunId: freezed == latestRunId
          ? _self.latestRunId
          : latestRunId // ignore: cast_nullable_to_non_nullable
              as String?,
      tagName: freezed == tagName
          ? _self.tagName
          : tagName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [BuildJob].
extension BuildJobPatterns on BuildJob {
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
    TResult Function(_BuildJob value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BuildJob() when $default != null:
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
    TResult Function(_BuildJob value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BuildJob():
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
    TResult? Function(_BuildJob value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BuildJob() when $default != null:
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
            String id,
            String status,
            String owner,
            String repo,
            String? teamId,
            String? workflowId,
            String? commitSha,
            int? pullRequestNumber,
            int? runCount,
            String? latestRunId,
            String? tagName,
            @DateTimeConverter() DateTime createdAt,
            @DateTimeConverter() DateTime updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BuildJob() when $default != null:
        return $default(
            _that.id,
            _that.status,
            _that.owner,
            _that.repo,
            _that.teamId,
            _that.workflowId,
            _that.commitSha,
            _that.pullRequestNumber,
            _that.runCount,
            _that.latestRunId,
            _that.tagName,
            _that.createdAt,
            _that.updatedAt);
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
            String id,
            String status,
            String owner,
            String repo,
            String? teamId,
            String? workflowId,
            String? commitSha,
            int? pullRequestNumber,
            int? runCount,
            String? latestRunId,
            String? tagName,
            @DateTimeConverter() DateTime createdAt,
            @DateTimeConverter() DateTime updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BuildJob():
        return $default(
            _that.id,
            _that.status,
            _that.owner,
            _that.repo,
            _that.teamId,
            _that.workflowId,
            _that.commitSha,
            _that.pullRequestNumber,
            _that.runCount,
            _that.latestRunId,
            _that.tagName,
            _that.createdAt,
            _that.updatedAt);
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
            String id,
            String status,
            String owner,
            String repo,
            String? teamId,
            String? workflowId,
            String? commitSha,
            int? pullRequestNumber,
            int? runCount,
            String? latestRunId,
            String? tagName,
            @DateTimeConverter() DateTime createdAt,
            @DateTimeConverter() DateTime updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BuildJob() when $default != null:
        return $default(
            _that.id,
            _that.status,
            _that.owner,
            _that.repo,
            _that.teamId,
            _that.workflowId,
            _that.commitSha,
            _that.pullRequestNumber,
            _that.runCount,
            _that.latestRunId,
            _that.tagName,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BuildJob implements BuildJob {
  const _BuildJob(
      {required this.id,
      required this.status,
      required this.owner,
      required this.repo,
      this.teamId,
      this.workflowId,
      this.commitSha,
      this.pullRequestNumber,
      this.runCount,
      this.latestRunId,
      this.tagName,
      @DateTimeConverter() required this.createdAt,
      @DateTimeConverter() required this.updatedAt});
  factory _BuildJob.fromJson(Map<String, dynamic> json) =>
      _$BuildJobFromJson(json);

  @override
  final String id;
  @override
  final String status;
  @override
  final String owner;
  @override
  final String repo;
  @override
  final String? teamId;
  @override
  final String? workflowId;
  @override
  final String? commitSha;
  @override
  final int? pullRequestNumber;
  @override
  final int? runCount;
  @override
  final String? latestRunId;
  @override
  final String? tagName;
  @override
  @DateTimeConverter()
  final DateTime createdAt;
  @override
  @DateTimeConverter()
  final DateTime updatedAt;

  /// Create a copy of BuildJob
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BuildJobCopyWith<_BuildJob> get copyWith =>
      __$BuildJobCopyWithImpl<_BuildJob>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BuildJobToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BuildJob &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.repo, repo) || other.repo == repo) &&
            (identical(other.teamId, teamId) || other.teamId == teamId) &&
            (identical(other.workflowId, workflowId) ||
                other.workflowId == workflowId) &&
            (identical(other.commitSha, commitSha) ||
                other.commitSha == commitSha) &&
            (identical(other.pullRequestNumber, pullRequestNumber) ||
                other.pullRequestNumber == pullRequestNumber) &&
            (identical(other.runCount, runCount) ||
                other.runCount == runCount) &&
            (identical(other.latestRunId, latestRunId) ||
                other.latestRunId == latestRunId) &&
            (identical(other.tagName, tagName) || other.tagName == tagName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      status,
      owner,
      repo,
      teamId,
      workflowId,
      commitSha,
      pullRequestNumber,
      runCount,
      latestRunId,
      tagName,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'BuildJob(id: $id, status: $status, owner: $owner, repo: $repo, teamId: $teamId, workflowId: $workflowId, commitSha: $commitSha, pullRequestNumber: $pullRequestNumber, runCount: $runCount, latestRunId: $latestRunId, tagName: $tagName, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$BuildJobCopyWith<$Res>
    implements $BuildJobCopyWith<$Res> {
  factory _$BuildJobCopyWith(_BuildJob value, $Res Function(_BuildJob) _then) =
      __$BuildJobCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String status,
      String owner,
      String repo,
      String? teamId,
      String? workflowId,
      String? commitSha,
      int? pullRequestNumber,
      int? runCount,
      String? latestRunId,
      String? tagName,
      @DateTimeConverter() DateTime createdAt,
      @DateTimeConverter() DateTime updatedAt});
}

/// @nodoc
class __$BuildJobCopyWithImpl<$Res> implements _$BuildJobCopyWith<$Res> {
  __$BuildJobCopyWithImpl(this._self, this._then);

  final _BuildJob _self;
  final $Res Function(_BuildJob) _then;

  /// Create a copy of BuildJob
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? owner = null,
    Object? repo = null,
    Object? teamId = freezed,
    Object? workflowId = freezed,
    Object? commitSha = freezed,
    Object? pullRequestNumber = freezed,
    Object? runCount = freezed,
    Object? latestRunId = freezed,
    Object? tagName = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_BuildJob(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      owner: null == owner
          ? _self.owner
          : owner // ignore: cast_nullable_to_non_nullable
              as String,
      repo: null == repo
          ? _self.repo
          : repo // ignore: cast_nullable_to_non_nullable
              as String,
      teamId: freezed == teamId
          ? _self.teamId
          : teamId // ignore: cast_nullable_to_non_nullable
              as String?,
      workflowId: freezed == workflowId
          ? _self.workflowId
          : workflowId // ignore: cast_nullable_to_non_nullable
              as String?,
      commitSha: freezed == commitSha
          ? _self.commitSha
          : commitSha // ignore: cast_nullable_to_non_nullable
              as String?,
      pullRequestNumber: freezed == pullRequestNumber
          ? _self.pullRequestNumber
          : pullRequestNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      runCount: freezed == runCount
          ? _self.runCount
          : runCount // ignore: cast_nullable_to_non_nullable
              as int?,
      latestRunId: freezed == latestRunId
          ? _self.latestRunId
          : latestRunId // ignore: cast_nullable_to_non_nullable
              as String?,
      tagName: freezed == tagName
          ? _self.tagName
          : tagName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
