// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TodoItemsTable extends TodoItems
    with TableInfo<$TodoItemsTable, TodoItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TodoItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 6,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'todo_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<TodoItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['body']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TodoItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TodoItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $TodoItemsTable createAlias(String alias) {
    return $TodoItemsTable(attachedDatabase, alias);
  }
}

class TodoItem extends DataClass implements Insertable<TodoItem> {
  final int id;
  final String title;
  final String content;
  final DateTime? createdAt;
  const TodoItem({
    required this.id,
    required this.title,
    required this.content,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(content);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  TodoItemsCompanion toCompanion(bool nullToAbsent) {
    return TodoItemsCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory TodoItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TodoItem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  TodoItem copyWith({
    int? id,
    String? title,
    String? content,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => TodoItem(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  TodoItem copyWithCompanion(TodoItemsCompanion data) {
    return TodoItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TodoItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TodoItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class TodoItemsCompanion extends UpdateCompanion<TodoItem> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<DateTime?> createdAt;
  const TodoItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TodoItemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String content,
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       content = Value(content);
  static Insertable<TodoItem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'body': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TodoItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? content,
    Value<DateTime?>? createdAt,
  }) {
    return TodoItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['body'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TodoItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BuildJobsTable extends BuildJobs
    with TableInfo<$BuildJobsTable, DriftBuildJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BuildJobStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BuildJobStatus>($BuildJobsTable.$converterstatus);
  static const VerificationMeta _ownerMeta = const VerificationMeta('owner');
  @override
  late final GeneratedColumn<String> owner = GeneratedColumn<String>(
    'owner',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repoMeta = const VerificationMeta('repo');
  @override
  late final GeneratedColumn<String> repo = GeneratedColumn<String>(
    'repo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workflowNameMeta = const VerificationMeta(
    'workflowName',
  );
  @override
  late final GeneratedColumn<String> workflowName = GeneratedColumn<String>(
    'workflow_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
    'team_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workflowIdMeta = const VerificationMeta(
    'workflowId',
  );
  @override
  late final GeneratedColumn<String> workflowId = GeneratedColumn<String>(
    'workflow_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workflowFileNameMeta = const VerificationMeta(
    'workflowFileName',
  );
  @override
  late final GeneratedColumn<String> workflowFileName = GeneratedColumn<String>(
    'workflow_file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commitShaMeta = const VerificationMeta(
    'commitSha',
  );
  @override
  late final GeneratedColumn<String> commitSha = GeneratedColumn<String>(
    'commit_sha',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pullRequestNumberMeta = const VerificationMeta(
    'pullRequestNumber',
  );
  @override
  late final GeneratedColumn<int> pullRequestNumber = GeneratedColumn<int>(
    'pull_request_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runCountMeta = const VerificationMeta(
    'runCount',
  );
  @override
  late final GeneratedColumn<int> runCount = GeneratedColumn<int>(
    'run_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestRunIdMeta = const VerificationMeta(
    'latestRunId',
  );
  @override
  late final GeneratedColumn<String> latestRunId = GeneratedColumn<String>(
    'latest_run_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagNameMeta = const VerificationMeta(
    'tagName',
  );
  @override
  late final GeneratedColumn<String> tagName = GeneratedColumn<String>(
    'tag_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
    'branch',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jobKeyMeta = const VerificationMeta('jobKey');
  @override
  late final GeneratedColumn<String> jobKey = GeneratedColumn<String>(
    'job_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workflowJobKeyMeta = const VerificationMeta(
    'workflowJobKey',
  );
  @override
  late final GeneratedColumn<String> workflowJobKey = GeneratedColumn<String>(
    'workflow_job_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, Object?>?, String>
  matrix = GeneratedColumn<String>(
    'matrix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Map<String, Object?>?>($BuildJobsTable.$convertermatrixn);
  static const VerificationMeta _matrixLabelMeta = const VerificationMeta(
    'matrixLabel',
  );
  @override
  late final GeneratedColumn<String> matrixLabel = GeneratedColumn<String>(
    'matrix_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workflowRunIdMeta = const VerificationMeta(
    'workflowRunId',
  );
  @override
  late final GeneratedColumn<String> workflowRunId = GeneratedColumn<String>(
    'workflow_run_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String> needs =
      GeneratedColumn<String>(
        'needs',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<String>?>($BuildJobsTable.$converterneedsn);
  static const VerificationMeta _failureSummaryMeta = const VerificationMeta(
    'failureSummary',
  );
  @override
  late final GeneratedColumn<String> failureSummary = GeneratedColumn<String>(
    'failure_summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureSummaryModelMeta =
      const VerificationMeta('failureSummaryModel');
  @override
  late final GeneratedColumn<String> failureSummaryModel =
      GeneratedColumn<String>(
        'failure_summary_model',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _failureSummaryStatusMeta =
      const VerificationMeta('failureSummaryStatus');
  @override
  late final GeneratedColumn<String> failureSummaryStatus =
      GeneratedColumn<String>(
        'failure_summary_status',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _failureSummaryDurationMsMeta =
      const VerificationMeta('failureSummaryDurationMs');
  @override
  late final GeneratedColumn<int> failureSummaryDurationMs =
      GeneratedColumn<int>(
        'failure_summary_duration_ms',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
  provisionedUdids = GeneratedColumn<String>(
    'provisioned_udids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<String>?>($BuildJobsTable.$converterprovisionedUdidsn);
  static const VerificationMeta _ipaUrlMeta = const VerificationMeta('ipaUrl');
  @override
  late final GeneratedColumn<String> ipaUrl = GeneratedColumn<String>(
    'ipa_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasIpaMeta = const VerificationMeta('hasIpa');
  @override
  late final GeneratedColumn<bool> hasIpa = GeneratedColumn<bool>(
    'has_ipa',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bundleIdMeta = const VerificationMeta(
    'bundleId',
  );
  @override
  late final GeneratedColumn<String> bundleId = GeneratedColumn<String>(
    'bundle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ipaVersionMeta = const VerificationMeta(
    'ipaVersion',
  );
  @override
  late final GeneratedColumn<String> ipaVersion = GeneratedColumn<String>(
    'ipa_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _githubBaseUrlMeta = const VerificationMeta(
    'githubBaseUrl',
  );
  @override
  late final GeneratedColumn<String> githubBaseUrl = GeneratedColumn<String>(
    'github_base_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _githubApiBaseUrlMeta = const VerificationMeta(
    'githubApiBaseUrl',
  );
  @override
  late final GeneratedColumn<String> githubApiBaseUrl = GeneratedColumn<String>(
    'github_api_base_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    owner,
    repo,
    workflowName,
    teamId,
    workflowId,
    workflowFileName,
    commitSha,
    pullRequestNumber,
    runCount,
    latestRunId,
    tagName,
    branch,
    jobKey,
    workflowJobKey,
    matrix,
    matrixLabel,
    workflowRunId,
    needs,
    failureSummary,
    failureSummaryModel,
    failureSummaryStatus,
    failureSummaryDurationMs,
    provisionedUdids,
    ipaUrl,
    hasIpa,
    bundleId,
    ipaVersion,
    appName,
    githubBaseUrl,
    githubApiBaseUrl,
    createdAt,
    updatedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'build_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftBuildJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner')) {
      context.handle(
        _ownerMeta,
        owner.isAcceptableOrUnknown(data['owner']!, _ownerMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerMeta);
    }
    if (data.containsKey('repo')) {
      context.handle(
        _repoMeta,
        repo.isAcceptableOrUnknown(data['repo']!, _repoMeta),
      );
    } else if (isInserting) {
      context.missing(_repoMeta);
    }
    if (data.containsKey('workflow_name')) {
      context.handle(
        _workflowNameMeta,
        workflowName.isAcceptableOrUnknown(
          data['workflow_name']!,
          _workflowNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workflowNameMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    }
    if (data.containsKey('workflow_id')) {
      context.handle(
        _workflowIdMeta,
        workflowId.isAcceptableOrUnknown(data['workflow_id']!, _workflowIdMeta),
      );
    }
    if (data.containsKey('workflow_file_name')) {
      context.handle(
        _workflowFileNameMeta,
        workflowFileName.isAcceptableOrUnknown(
          data['workflow_file_name']!,
          _workflowFileNameMeta,
        ),
      );
    }
    if (data.containsKey('commit_sha')) {
      context.handle(
        _commitShaMeta,
        commitSha.isAcceptableOrUnknown(data['commit_sha']!, _commitShaMeta),
      );
    }
    if (data.containsKey('pull_request_number')) {
      context.handle(
        _pullRequestNumberMeta,
        pullRequestNumber.isAcceptableOrUnknown(
          data['pull_request_number']!,
          _pullRequestNumberMeta,
        ),
      );
    }
    if (data.containsKey('run_count')) {
      context.handle(
        _runCountMeta,
        runCount.isAcceptableOrUnknown(data['run_count']!, _runCountMeta),
      );
    }
    if (data.containsKey('latest_run_id')) {
      context.handle(
        _latestRunIdMeta,
        latestRunId.isAcceptableOrUnknown(
          data['latest_run_id']!,
          _latestRunIdMeta,
        ),
      );
    }
    if (data.containsKey('tag_name')) {
      context.handle(
        _tagNameMeta,
        tagName.isAcceptableOrUnknown(data['tag_name']!, _tagNameMeta),
      );
    }
    if (data.containsKey('branch')) {
      context.handle(
        _branchMeta,
        branch.isAcceptableOrUnknown(data['branch']!, _branchMeta),
      );
    }
    if (data.containsKey('job_key')) {
      context.handle(
        _jobKeyMeta,
        jobKey.isAcceptableOrUnknown(data['job_key']!, _jobKeyMeta),
      );
    }
    if (data.containsKey('workflow_job_key')) {
      context.handle(
        _workflowJobKeyMeta,
        workflowJobKey.isAcceptableOrUnknown(
          data['workflow_job_key']!,
          _workflowJobKeyMeta,
        ),
      );
    }
    if (data.containsKey('matrix_label')) {
      context.handle(
        _matrixLabelMeta,
        matrixLabel.isAcceptableOrUnknown(
          data['matrix_label']!,
          _matrixLabelMeta,
        ),
      );
    }
    if (data.containsKey('workflow_run_id')) {
      context.handle(
        _workflowRunIdMeta,
        workflowRunId.isAcceptableOrUnknown(
          data['workflow_run_id']!,
          _workflowRunIdMeta,
        ),
      );
    }
    if (data.containsKey('failure_summary')) {
      context.handle(
        _failureSummaryMeta,
        failureSummary.isAcceptableOrUnknown(
          data['failure_summary']!,
          _failureSummaryMeta,
        ),
      );
    }
    if (data.containsKey('failure_summary_model')) {
      context.handle(
        _failureSummaryModelMeta,
        failureSummaryModel.isAcceptableOrUnknown(
          data['failure_summary_model']!,
          _failureSummaryModelMeta,
        ),
      );
    }
    if (data.containsKey('failure_summary_status')) {
      context.handle(
        _failureSummaryStatusMeta,
        failureSummaryStatus.isAcceptableOrUnknown(
          data['failure_summary_status']!,
          _failureSummaryStatusMeta,
        ),
      );
    }
    if (data.containsKey('failure_summary_duration_ms')) {
      context.handle(
        _failureSummaryDurationMsMeta,
        failureSummaryDurationMs.isAcceptableOrUnknown(
          data['failure_summary_duration_ms']!,
          _failureSummaryDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('ipa_url')) {
      context.handle(
        _ipaUrlMeta,
        ipaUrl.isAcceptableOrUnknown(data['ipa_url']!, _ipaUrlMeta),
      );
    }
    if (data.containsKey('has_ipa')) {
      context.handle(
        _hasIpaMeta,
        hasIpa.isAcceptableOrUnknown(data['has_ipa']!, _hasIpaMeta),
      );
    }
    if (data.containsKey('bundle_id')) {
      context.handle(
        _bundleIdMeta,
        bundleId.isAcceptableOrUnknown(data['bundle_id']!, _bundleIdMeta),
      );
    }
    if (data.containsKey('ipa_version')) {
      context.handle(
        _ipaVersionMeta,
        ipaVersion.isAcceptableOrUnknown(data['ipa_version']!, _ipaVersionMeta),
      );
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    }
    if (data.containsKey('github_base_url')) {
      context.handle(
        _githubBaseUrlMeta,
        githubBaseUrl.isAcceptableOrUnknown(
          data['github_base_url']!,
          _githubBaseUrlMeta,
        ),
      );
    }
    if (data.containsKey('github_api_base_url')) {
      context.handle(
        _githubApiBaseUrlMeta,
        githubApiBaseUrl.isAcceptableOrUnknown(
          data['github_api_base_url']!,
          _githubApiBaseUrlMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftBuildJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftBuildJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: $BuildJobsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      owner: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner'],
      )!,
      repo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo'],
      )!,
      workflowName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workflow_name'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      ),
      workflowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workflow_id'],
      ),
      workflowFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workflow_file_name'],
      ),
      commitSha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commit_sha'],
      ),
      pullRequestNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pull_request_number'],
      ),
      runCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_count'],
      ),
      latestRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_run_id'],
      ),
      tagName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_name'],
      ),
      branch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch'],
      ),
      jobKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_key'],
      ),
      workflowJobKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workflow_job_key'],
      ),
      matrix: $BuildJobsTable.$convertermatrixn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}matrix'],
        ),
      ),
      matrixLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matrix_label'],
      ),
      workflowRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workflow_run_id'],
      ),
      needs: $BuildJobsTable.$converterneedsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}needs'],
        ),
      ),
      failureSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_summary'],
      ),
      failureSummaryModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_summary_model'],
      ),
      failureSummaryStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_summary_status'],
      ),
      failureSummaryDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failure_summary_duration_ms'],
      ),
      provisionedUdids: $BuildJobsTable.$converterprovisionedUdidsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}provisioned_udids'],
        ),
      ),
      ipaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ipa_url'],
      ),
      hasIpa: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_ipa'],
      ),
      bundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bundle_id'],
      ),
      ipaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ipa_version'],
      ),
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      ),
      githubBaseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}github_base_url'],
      ),
      githubApiBaseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}github_api_base_url'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $BuildJobsTable createAlias(String alias) {
    return $BuildJobsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BuildJobStatus, String, String> $converterstatus =
      const EnumNameConverter<BuildJobStatus>(BuildJobStatus.values);
  static TypeConverter<Map<String, Object?>, String> $convertermatrix =
      const MapConverter();
  static TypeConverter<Map<String, Object?>?, String?> $convertermatrixn =
      NullAwareTypeConverter.wrap($convertermatrix);
  static TypeConverter<List<String>, String> $converterneeds =
      const StringListConverter();
  static TypeConverter<List<String>?, String?> $converterneedsn =
      NullAwareTypeConverter.wrap($converterneeds);
  static TypeConverter<List<String>, String> $converterprovisionedUdids =
      const StringListConverter();
  static TypeConverter<List<String>?, String?> $converterprovisionedUdidsn =
      NullAwareTypeConverter.wrap($converterprovisionedUdids);
}

class DriftBuildJob extends DataClass implements Insertable<DriftBuildJob> {
  final String id;
  final BuildJobStatus status;
  final String owner;
  final String repo;
  final String workflowName;
  final String? teamId;
  final String? workflowId;
  final String? workflowFileName;
  final String? commitSha;
  final int? pullRequestNumber;
  final int? runCount;
  final String? latestRunId;
  final String? tagName;
  final String? branch;
  final String? jobKey;
  final String? workflowJobKey;
  final Map<String, Object?>? matrix;
  final String? matrixLabel;
  final String? workflowRunId;
  final List<String>? needs;
  final String? failureSummary;
  final String? failureSummaryModel;
  final String? failureSummaryStatus;
  final int? failureSummaryDurationMs;
  final List<String>? provisionedUdids;
  final String? ipaUrl;
  final bool? hasIpa;
  final String? bundleId;
  final String? ipaVersion;
  final String? appName;
  final String? githubBaseUrl;
  final String? githubApiBaseUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  const DriftBuildJob({
    required this.id,
    required this.status,
    required this.owner,
    required this.repo,
    required this.workflowName,
    this.teamId,
    this.workflowId,
    this.workflowFileName,
    this.commitSha,
    this.pullRequestNumber,
    this.runCount,
    this.latestRunId,
    this.tagName,
    this.branch,
    this.jobKey,
    this.workflowJobKey,
    this.matrix,
    this.matrixLabel,
    this.workflowRunId,
    this.needs,
    this.failureSummary,
    this.failureSummaryModel,
    this.failureSummaryStatus,
    this.failureSummaryDurationMs,
    this.provisionedUdids,
    this.ipaUrl,
    this.hasIpa,
    this.bundleId,
    this.ipaVersion,
    this.appName,
    this.githubBaseUrl,
    this.githubApiBaseUrl,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['status'] = Variable<String>(
        $BuildJobsTable.$converterstatus.toSql(status),
      );
    }
    map['owner'] = Variable<String>(owner);
    map['repo'] = Variable<String>(repo);
    map['workflow_name'] = Variable<String>(workflowName);
    if (!nullToAbsent || teamId != null) {
      map['team_id'] = Variable<String>(teamId);
    }
    if (!nullToAbsent || workflowId != null) {
      map['workflow_id'] = Variable<String>(workflowId);
    }
    if (!nullToAbsent || workflowFileName != null) {
      map['workflow_file_name'] = Variable<String>(workflowFileName);
    }
    if (!nullToAbsent || commitSha != null) {
      map['commit_sha'] = Variable<String>(commitSha);
    }
    if (!nullToAbsent || pullRequestNumber != null) {
      map['pull_request_number'] = Variable<int>(pullRequestNumber);
    }
    if (!nullToAbsent || runCount != null) {
      map['run_count'] = Variable<int>(runCount);
    }
    if (!nullToAbsent || latestRunId != null) {
      map['latest_run_id'] = Variable<String>(latestRunId);
    }
    if (!nullToAbsent || tagName != null) {
      map['tag_name'] = Variable<String>(tagName);
    }
    if (!nullToAbsent || branch != null) {
      map['branch'] = Variable<String>(branch);
    }
    if (!nullToAbsent || jobKey != null) {
      map['job_key'] = Variable<String>(jobKey);
    }
    if (!nullToAbsent || workflowJobKey != null) {
      map['workflow_job_key'] = Variable<String>(workflowJobKey);
    }
    if (!nullToAbsent || matrix != null) {
      map['matrix'] = Variable<String>(
        $BuildJobsTable.$convertermatrixn.toSql(matrix),
      );
    }
    if (!nullToAbsent || matrixLabel != null) {
      map['matrix_label'] = Variable<String>(matrixLabel);
    }
    if (!nullToAbsent || workflowRunId != null) {
      map['workflow_run_id'] = Variable<String>(workflowRunId);
    }
    if (!nullToAbsent || needs != null) {
      map['needs'] = Variable<String>(
        $BuildJobsTable.$converterneedsn.toSql(needs),
      );
    }
    if (!nullToAbsent || failureSummary != null) {
      map['failure_summary'] = Variable<String>(failureSummary);
    }
    if (!nullToAbsent || failureSummaryModel != null) {
      map['failure_summary_model'] = Variable<String>(failureSummaryModel);
    }
    if (!nullToAbsent || failureSummaryStatus != null) {
      map['failure_summary_status'] = Variable<String>(failureSummaryStatus);
    }
    if (!nullToAbsent || failureSummaryDurationMs != null) {
      map['failure_summary_duration_ms'] = Variable<int>(
        failureSummaryDurationMs,
      );
    }
    if (!nullToAbsent || provisionedUdids != null) {
      map['provisioned_udids'] = Variable<String>(
        $BuildJobsTable.$converterprovisionedUdidsn.toSql(provisionedUdids),
      );
    }
    if (!nullToAbsent || ipaUrl != null) {
      map['ipa_url'] = Variable<String>(ipaUrl);
    }
    if (!nullToAbsent || hasIpa != null) {
      map['has_ipa'] = Variable<bool>(hasIpa);
    }
    if (!nullToAbsent || bundleId != null) {
      map['bundle_id'] = Variable<String>(bundleId);
    }
    if (!nullToAbsent || ipaVersion != null) {
      map['ipa_version'] = Variable<String>(ipaVersion);
    }
    if (!nullToAbsent || appName != null) {
      map['app_name'] = Variable<String>(appName);
    }
    if (!nullToAbsent || githubBaseUrl != null) {
      map['github_base_url'] = Variable<String>(githubBaseUrl);
    }
    if (!nullToAbsent || githubApiBaseUrl != null) {
      map['github_api_base_url'] = Variable<String>(githubApiBaseUrl);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  BuildJobsCompanion toCompanion(bool nullToAbsent) {
    return BuildJobsCompanion(
      id: Value(id),
      status: Value(status),
      owner: Value(owner),
      repo: Value(repo),
      workflowName: Value(workflowName),
      teamId: teamId == null && nullToAbsent
          ? const Value.absent()
          : Value(teamId),
      workflowId: workflowId == null && nullToAbsent
          ? const Value.absent()
          : Value(workflowId),
      workflowFileName: workflowFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(workflowFileName),
      commitSha: commitSha == null && nullToAbsent
          ? const Value.absent()
          : Value(commitSha),
      pullRequestNumber: pullRequestNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(pullRequestNumber),
      runCount: runCount == null && nullToAbsent
          ? const Value.absent()
          : Value(runCount),
      latestRunId: latestRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(latestRunId),
      tagName: tagName == null && nullToAbsent
          ? const Value.absent()
          : Value(tagName),
      branch: branch == null && nullToAbsent
          ? const Value.absent()
          : Value(branch),
      jobKey: jobKey == null && nullToAbsent
          ? const Value.absent()
          : Value(jobKey),
      workflowJobKey: workflowJobKey == null && nullToAbsent
          ? const Value.absent()
          : Value(workflowJobKey),
      matrix: matrix == null && nullToAbsent
          ? const Value.absent()
          : Value(matrix),
      matrixLabel: matrixLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(matrixLabel),
      workflowRunId: workflowRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(workflowRunId),
      needs: needs == null && nullToAbsent
          ? const Value.absent()
          : Value(needs),
      failureSummary: failureSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(failureSummary),
      failureSummaryModel: failureSummaryModel == null && nullToAbsent
          ? const Value.absent()
          : Value(failureSummaryModel),
      failureSummaryStatus: failureSummaryStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(failureSummaryStatus),
      failureSummaryDurationMs: failureSummaryDurationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(failureSummaryDurationMs),
      provisionedUdids: provisionedUdids == null && nullToAbsent
          ? const Value.absent()
          : Value(provisionedUdids),
      ipaUrl: ipaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(ipaUrl),
      hasIpa: hasIpa == null && nullToAbsent
          ? const Value.absent()
          : Value(hasIpa),
      bundleId: bundleId == null && nullToAbsent
          ? const Value.absent()
          : Value(bundleId),
      ipaVersion: ipaVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(ipaVersion),
      appName: appName == null && nullToAbsent
          ? const Value.absent()
          : Value(appName),
      githubBaseUrl: githubBaseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(githubBaseUrl),
      githubApiBaseUrl: githubApiBaseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(githubApiBaseUrl),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory DriftBuildJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftBuildJob(
      id: serializer.fromJson<String>(json['id']),
      status: $BuildJobsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      owner: serializer.fromJson<String>(json['owner']),
      repo: serializer.fromJson<String>(json['repo']),
      workflowName: serializer.fromJson<String>(json['workflowName']),
      teamId: serializer.fromJson<String?>(json['teamId']),
      workflowId: serializer.fromJson<String?>(json['workflowId']),
      workflowFileName: serializer.fromJson<String?>(json['workflowFileName']),
      commitSha: serializer.fromJson<String?>(json['commitSha']),
      pullRequestNumber: serializer.fromJson<int?>(json['pullRequestNumber']),
      runCount: serializer.fromJson<int?>(json['runCount']),
      latestRunId: serializer.fromJson<String?>(json['latestRunId']),
      tagName: serializer.fromJson<String?>(json['tagName']),
      branch: serializer.fromJson<String?>(json['branch']),
      jobKey: serializer.fromJson<String?>(json['jobKey']),
      workflowJobKey: serializer.fromJson<String?>(json['workflowJobKey']),
      matrix: serializer.fromJson<Map<String, Object?>?>(json['matrix']),
      matrixLabel: serializer.fromJson<String?>(json['matrixLabel']),
      workflowRunId: serializer.fromJson<String?>(json['workflowRunId']),
      needs: serializer.fromJson<List<String>?>(json['needs']),
      failureSummary: serializer.fromJson<String?>(json['failureSummary']),
      failureSummaryModel: serializer.fromJson<String?>(
        json['failureSummaryModel'],
      ),
      failureSummaryStatus: serializer.fromJson<String?>(
        json['failureSummaryStatus'],
      ),
      failureSummaryDurationMs: serializer.fromJson<int?>(
        json['failureSummaryDurationMs'],
      ),
      provisionedUdids: serializer.fromJson<List<String>?>(
        json['provisionedUdids'],
      ),
      ipaUrl: serializer.fromJson<String?>(json['ipaUrl']),
      hasIpa: serializer.fromJson<bool?>(json['hasIpa']),
      bundleId: serializer.fromJson<String?>(json['bundleId']),
      ipaVersion: serializer.fromJson<String?>(json['ipaVersion']),
      appName: serializer.fromJson<String?>(json['appName']),
      githubBaseUrl: serializer.fromJson<String?>(json['githubBaseUrl']),
      githubApiBaseUrl: serializer.fromJson<String?>(json['githubApiBaseUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(
        $BuildJobsTable.$converterstatus.toJson(status),
      ),
      'owner': serializer.toJson<String>(owner),
      'repo': serializer.toJson<String>(repo),
      'workflowName': serializer.toJson<String>(workflowName),
      'teamId': serializer.toJson<String?>(teamId),
      'workflowId': serializer.toJson<String?>(workflowId),
      'workflowFileName': serializer.toJson<String?>(workflowFileName),
      'commitSha': serializer.toJson<String?>(commitSha),
      'pullRequestNumber': serializer.toJson<int?>(pullRequestNumber),
      'runCount': serializer.toJson<int?>(runCount),
      'latestRunId': serializer.toJson<String?>(latestRunId),
      'tagName': serializer.toJson<String?>(tagName),
      'branch': serializer.toJson<String?>(branch),
      'jobKey': serializer.toJson<String?>(jobKey),
      'workflowJobKey': serializer.toJson<String?>(workflowJobKey),
      'matrix': serializer.toJson<Map<String, Object?>?>(matrix),
      'matrixLabel': serializer.toJson<String?>(matrixLabel),
      'workflowRunId': serializer.toJson<String?>(workflowRunId),
      'needs': serializer.toJson<List<String>?>(needs),
      'failureSummary': serializer.toJson<String?>(failureSummary),
      'failureSummaryModel': serializer.toJson<String?>(failureSummaryModel),
      'failureSummaryStatus': serializer.toJson<String?>(failureSummaryStatus),
      'failureSummaryDurationMs': serializer.toJson<int?>(
        failureSummaryDurationMs,
      ),
      'provisionedUdids': serializer.toJson<List<String>?>(provisionedUdids),
      'ipaUrl': serializer.toJson<String?>(ipaUrl),
      'hasIpa': serializer.toJson<bool?>(hasIpa),
      'bundleId': serializer.toJson<String?>(bundleId),
      'ipaVersion': serializer.toJson<String?>(ipaVersion),
      'appName': serializer.toJson<String?>(appName),
      'githubBaseUrl': serializer.toJson<String?>(githubBaseUrl),
      'githubApiBaseUrl': serializer.toJson<String?>(githubApiBaseUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  DriftBuildJob copyWith({
    String? id,
    BuildJobStatus? status,
    String? owner,
    String? repo,
    String? workflowName,
    Value<String?> teamId = const Value.absent(),
    Value<String?> workflowId = const Value.absent(),
    Value<String?> workflowFileName = const Value.absent(),
    Value<String?> commitSha = const Value.absent(),
    Value<int?> pullRequestNumber = const Value.absent(),
    Value<int?> runCount = const Value.absent(),
    Value<String?> latestRunId = const Value.absent(),
    Value<String?> tagName = const Value.absent(),
    Value<String?> branch = const Value.absent(),
    Value<String?> jobKey = const Value.absent(),
    Value<String?> workflowJobKey = const Value.absent(),
    Value<Map<String, Object?>?> matrix = const Value.absent(),
    Value<String?> matrixLabel = const Value.absent(),
    Value<String?> workflowRunId = const Value.absent(),
    Value<List<String>?> needs = const Value.absent(),
    Value<String?> failureSummary = const Value.absent(),
    Value<String?> failureSummaryModel = const Value.absent(),
    Value<String?> failureSummaryStatus = const Value.absent(),
    Value<int?> failureSummaryDurationMs = const Value.absent(),
    Value<List<String>?> provisionedUdids = const Value.absent(),
    Value<String?> ipaUrl = const Value.absent(),
    Value<bool?> hasIpa = const Value.absent(),
    Value<String?> bundleId = const Value.absent(),
    Value<String?> ipaVersion = const Value.absent(),
    Value<String?> appName = const Value.absent(),
    Value<String?> githubBaseUrl = const Value.absent(),
    Value<String?> githubApiBaseUrl = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => DriftBuildJob(
    id: id ?? this.id,
    status: status ?? this.status,
    owner: owner ?? this.owner,
    repo: repo ?? this.repo,
    workflowName: workflowName ?? this.workflowName,
    teamId: teamId.present ? teamId.value : this.teamId,
    workflowId: workflowId.present ? workflowId.value : this.workflowId,
    workflowFileName: workflowFileName.present
        ? workflowFileName.value
        : this.workflowFileName,
    commitSha: commitSha.present ? commitSha.value : this.commitSha,
    pullRequestNumber: pullRequestNumber.present
        ? pullRequestNumber.value
        : this.pullRequestNumber,
    runCount: runCount.present ? runCount.value : this.runCount,
    latestRunId: latestRunId.present ? latestRunId.value : this.latestRunId,
    tagName: tagName.present ? tagName.value : this.tagName,
    branch: branch.present ? branch.value : this.branch,
    jobKey: jobKey.present ? jobKey.value : this.jobKey,
    workflowJobKey: workflowJobKey.present
        ? workflowJobKey.value
        : this.workflowJobKey,
    matrix: matrix.present ? matrix.value : this.matrix,
    matrixLabel: matrixLabel.present ? matrixLabel.value : this.matrixLabel,
    workflowRunId: workflowRunId.present
        ? workflowRunId.value
        : this.workflowRunId,
    needs: needs.present ? needs.value : this.needs,
    failureSummary: failureSummary.present
        ? failureSummary.value
        : this.failureSummary,
    failureSummaryModel: failureSummaryModel.present
        ? failureSummaryModel.value
        : this.failureSummaryModel,
    failureSummaryStatus: failureSummaryStatus.present
        ? failureSummaryStatus.value
        : this.failureSummaryStatus,
    failureSummaryDurationMs: failureSummaryDurationMs.present
        ? failureSummaryDurationMs.value
        : this.failureSummaryDurationMs,
    provisionedUdids: provisionedUdids.present
        ? provisionedUdids.value
        : this.provisionedUdids,
    ipaUrl: ipaUrl.present ? ipaUrl.value : this.ipaUrl,
    hasIpa: hasIpa.present ? hasIpa.value : this.hasIpa,
    bundleId: bundleId.present ? bundleId.value : this.bundleId,
    ipaVersion: ipaVersion.present ? ipaVersion.value : this.ipaVersion,
    appName: appName.present ? appName.value : this.appName,
    githubBaseUrl: githubBaseUrl.present
        ? githubBaseUrl.value
        : this.githubBaseUrl,
    githubApiBaseUrl: githubApiBaseUrl.present
        ? githubApiBaseUrl.value
        : this.githubApiBaseUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  DriftBuildJob copyWithCompanion(BuildJobsCompanion data) {
    return DriftBuildJob(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      owner: data.owner.present ? data.owner.value : this.owner,
      repo: data.repo.present ? data.repo.value : this.repo,
      workflowName: data.workflowName.present
          ? data.workflowName.value
          : this.workflowName,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      workflowId: data.workflowId.present
          ? data.workflowId.value
          : this.workflowId,
      workflowFileName: data.workflowFileName.present
          ? data.workflowFileName.value
          : this.workflowFileName,
      commitSha: data.commitSha.present ? data.commitSha.value : this.commitSha,
      pullRequestNumber: data.pullRequestNumber.present
          ? data.pullRequestNumber.value
          : this.pullRequestNumber,
      runCount: data.runCount.present ? data.runCount.value : this.runCount,
      latestRunId: data.latestRunId.present
          ? data.latestRunId.value
          : this.latestRunId,
      tagName: data.tagName.present ? data.tagName.value : this.tagName,
      branch: data.branch.present ? data.branch.value : this.branch,
      jobKey: data.jobKey.present ? data.jobKey.value : this.jobKey,
      workflowJobKey: data.workflowJobKey.present
          ? data.workflowJobKey.value
          : this.workflowJobKey,
      matrix: data.matrix.present ? data.matrix.value : this.matrix,
      matrixLabel: data.matrixLabel.present
          ? data.matrixLabel.value
          : this.matrixLabel,
      workflowRunId: data.workflowRunId.present
          ? data.workflowRunId.value
          : this.workflowRunId,
      needs: data.needs.present ? data.needs.value : this.needs,
      failureSummary: data.failureSummary.present
          ? data.failureSummary.value
          : this.failureSummary,
      failureSummaryModel: data.failureSummaryModel.present
          ? data.failureSummaryModel.value
          : this.failureSummaryModel,
      failureSummaryStatus: data.failureSummaryStatus.present
          ? data.failureSummaryStatus.value
          : this.failureSummaryStatus,
      failureSummaryDurationMs: data.failureSummaryDurationMs.present
          ? data.failureSummaryDurationMs.value
          : this.failureSummaryDurationMs,
      provisionedUdids: data.provisionedUdids.present
          ? data.provisionedUdids.value
          : this.provisionedUdids,
      ipaUrl: data.ipaUrl.present ? data.ipaUrl.value : this.ipaUrl,
      hasIpa: data.hasIpa.present ? data.hasIpa.value : this.hasIpa,
      bundleId: data.bundleId.present ? data.bundleId.value : this.bundleId,
      ipaVersion: data.ipaVersion.present
          ? data.ipaVersion.value
          : this.ipaVersion,
      appName: data.appName.present ? data.appName.value : this.appName,
      githubBaseUrl: data.githubBaseUrl.present
          ? data.githubBaseUrl.value
          : this.githubBaseUrl,
      githubApiBaseUrl: data.githubApiBaseUrl.present
          ? data.githubApiBaseUrl.value
          : this.githubApiBaseUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftBuildJob(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('owner: $owner, ')
          ..write('repo: $repo, ')
          ..write('workflowName: $workflowName, ')
          ..write('teamId: $teamId, ')
          ..write('workflowId: $workflowId, ')
          ..write('workflowFileName: $workflowFileName, ')
          ..write('commitSha: $commitSha, ')
          ..write('pullRequestNumber: $pullRequestNumber, ')
          ..write('runCount: $runCount, ')
          ..write('latestRunId: $latestRunId, ')
          ..write('tagName: $tagName, ')
          ..write('branch: $branch, ')
          ..write('jobKey: $jobKey, ')
          ..write('workflowJobKey: $workflowJobKey, ')
          ..write('matrix: $matrix, ')
          ..write('matrixLabel: $matrixLabel, ')
          ..write('workflowRunId: $workflowRunId, ')
          ..write('needs: $needs, ')
          ..write('failureSummary: $failureSummary, ')
          ..write('failureSummaryModel: $failureSummaryModel, ')
          ..write('failureSummaryStatus: $failureSummaryStatus, ')
          ..write('failureSummaryDurationMs: $failureSummaryDurationMs, ')
          ..write('provisionedUdids: $provisionedUdids, ')
          ..write('ipaUrl: $ipaUrl, ')
          ..write('hasIpa: $hasIpa, ')
          ..write('bundleId: $bundleId, ')
          ..write('ipaVersion: $ipaVersion, ')
          ..write('appName: $appName, ')
          ..write('githubBaseUrl: $githubBaseUrl, ')
          ..write('githubApiBaseUrl: $githubApiBaseUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    status,
    owner,
    repo,
    workflowName,
    teamId,
    workflowId,
    workflowFileName,
    commitSha,
    pullRequestNumber,
    runCount,
    latestRunId,
    tagName,
    branch,
    jobKey,
    workflowJobKey,
    matrix,
    matrixLabel,
    workflowRunId,
    needs,
    failureSummary,
    failureSummaryModel,
    failureSummaryStatus,
    failureSummaryDurationMs,
    provisionedUdids,
    ipaUrl,
    hasIpa,
    bundleId,
    ipaVersion,
    appName,
    githubBaseUrl,
    githubApiBaseUrl,
    createdAt,
    updatedAt,
    completedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftBuildJob &&
          other.id == this.id &&
          other.status == this.status &&
          other.owner == this.owner &&
          other.repo == this.repo &&
          other.workflowName == this.workflowName &&
          other.teamId == this.teamId &&
          other.workflowId == this.workflowId &&
          other.workflowFileName == this.workflowFileName &&
          other.commitSha == this.commitSha &&
          other.pullRequestNumber == this.pullRequestNumber &&
          other.runCount == this.runCount &&
          other.latestRunId == this.latestRunId &&
          other.tagName == this.tagName &&
          other.branch == this.branch &&
          other.jobKey == this.jobKey &&
          other.workflowJobKey == this.workflowJobKey &&
          other.matrix == this.matrix &&
          other.matrixLabel == this.matrixLabel &&
          other.workflowRunId == this.workflowRunId &&
          other.needs == this.needs &&
          other.failureSummary == this.failureSummary &&
          other.failureSummaryModel == this.failureSummaryModel &&
          other.failureSummaryStatus == this.failureSummaryStatus &&
          other.failureSummaryDurationMs == this.failureSummaryDurationMs &&
          other.provisionedUdids == this.provisionedUdids &&
          other.ipaUrl == this.ipaUrl &&
          other.hasIpa == this.hasIpa &&
          other.bundleId == this.bundleId &&
          other.ipaVersion == this.ipaVersion &&
          other.appName == this.appName &&
          other.githubBaseUrl == this.githubBaseUrl &&
          other.githubApiBaseUrl == this.githubApiBaseUrl &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class BuildJobsCompanion extends UpdateCompanion<DriftBuildJob> {
  final Value<String> id;
  final Value<BuildJobStatus> status;
  final Value<String> owner;
  final Value<String> repo;
  final Value<String> workflowName;
  final Value<String?> teamId;
  final Value<String?> workflowId;
  final Value<String?> workflowFileName;
  final Value<String?> commitSha;
  final Value<int?> pullRequestNumber;
  final Value<int?> runCount;
  final Value<String?> latestRunId;
  final Value<String?> tagName;
  final Value<String?> branch;
  final Value<String?> jobKey;
  final Value<String?> workflowJobKey;
  final Value<Map<String, Object?>?> matrix;
  final Value<String?> matrixLabel;
  final Value<String?> workflowRunId;
  final Value<List<String>?> needs;
  final Value<String?> failureSummary;
  final Value<String?> failureSummaryModel;
  final Value<String?> failureSummaryStatus;
  final Value<int?> failureSummaryDurationMs;
  final Value<List<String>?> provisionedUdids;
  final Value<String?> ipaUrl;
  final Value<bool?> hasIpa;
  final Value<String?> bundleId;
  final Value<String?> ipaVersion;
  final Value<String?> appName;
  final Value<String?> githubBaseUrl;
  final Value<String?> githubApiBaseUrl;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const BuildJobsCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.owner = const Value.absent(),
    this.repo = const Value.absent(),
    this.workflowName = const Value.absent(),
    this.teamId = const Value.absent(),
    this.workflowId = const Value.absent(),
    this.workflowFileName = const Value.absent(),
    this.commitSha = const Value.absent(),
    this.pullRequestNumber = const Value.absent(),
    this.runCount = const Value.absent(),
    this.latestRunId = const Value.absent(),
    this.tagName = const Value.absent(),
    this.branch = const Value.absent(),
    this.jobKey = const Value.absent(),
    this.workflowJobKey = const Value.absent(),
    this.matrix = const Value.absent(),
    this.matrixLabel = const Value.absent(),
    this.workflowRunId = const Value.absent(),
    this.needs = const Value.absent(),
    this.failureSummary = const Value.absent(),
    this.failureSummaryModel = const Value.absent(),
    this.failureSummaryStatus = const Value.absent(),
    this.failureSummaryDurationMs = const Value.absent(),
    this.provisionedUdids = const Value.absent(),
    this.ipaUrl = const Value.absent(),
    this.hasIpa = const Value.absent(),
    this.bundleId = const Value.absent(),
    this.ipaVersion = const Value.absent(),
    this.appName = const Value.absent(),
    this.githubBaseUrl = const Value.absent(),
    this.githubApiBaseUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuildJobsCompanion.insert({
    required String id,
    required BuildJobStatus status,
    required String owner,
    required String repo,
    required String workflowName,
    this.teamId = const Value.absent(),
    this.workflowId = const Value.absent(),
    this.workflowFileName = const Value.absent(),
    this.commitSha = const Value.absent(),
    this.pullRequestNumber = const Value.absent(),
    this.runCount = const Value.absent(),
    this.latestRunId = const Value.absent(),
    this.tagName = const Value.absent(),
    this.branch = const Value.absent(),
    this.jobKey = const Value.absent(),
    this.workflowJobKey = const Value.absent(),
    this.matrix = const Value.absent(),
    this.matrixLabel = const Value.absent(),
    this.workflowRunId = const Value.absent(),
    this.needs = const Value.absent(),
    this.failureSummary = const Value.absent(),
    this.failureSummaryModel = const Value.absent(),
    this.failureSummaryStatus = const Value.absent(),
    this.failureSummaryDurationMs = const Value.absent(),
    this.provisionedUdids = const Value.absent(),
    this.ipaUrl = const Value.absent(),
    this.hasIpa = const Value.absent(),
    this.bundleId = const Value.absent(),
    this.ipaVersion = const Value.absent(),
    this.appName = const Value.absent(),
    this.githubBaseUrl = const Value.absent(),
    this.githubApiBaseUrl = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       owner = Value(owner),
       repo = Value(repo),
       workflowName = Value(workflowName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DriftBuildJob> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<String>? owner,
    Expression<String>? repo,
    Expression<String>? workflowName,
    Expression<String>? teamId,
    Expression<String>? workflowId,
    Expression<String>? workflowFileName,
    Expression<String>? commitSha,
    Expression<int>? pullRequestNumber,
    Expression<int>? runCount,
    Expression<String>? latestRunId,
    Expression<String>? tagName,
    Expression<String>? branch,
    Expression<String>? jobKey,
    Expression<String>? workflowJobKey,
    Expression<String>? matrix,
    Expression<String>? matrixLabel,
    Expression<String>? workflowRunId,
    Expression<String>? needs,
    Expression<String>? failureSummary,
    Expression<String>? failureSummaryModel,
    Expression<String>? failureSummaryStatus,
    Expression<int>? failureSummaryDurationMs,
    Expression<String>? provisionedUdids,
    Expression<String>? ipaUrl,
    Expression<bool>? hasIpa,
    Expression<String>? bundleId,
    Expression<String>? ipaVersion,
    Expression<String>? appName,
    Expression<String>? githubBaseUrl,
    Expression<String>? githubApiBaseUrl,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (owner != null) 'owner': owner,
      if (repo != null) 'repo': repo,
      if (workflowName != null) 'workflow_name': workflowName,
      if (teamId != null) 'team_id': teamId,
      if (workflowId != null) 'workflow_id': workflowId,
      if (workflowFileName != null) 'workflow_file_name': workflowFileName,
      if (commitSha != null) 'commit_sha': commitSha,
      if (pullRequestNumber != null) 'pull_request_number': pullRequestNumber,
      if (runCount != null) 'run_count': runCount,
      if (latestRunId != null) 'latest_run_id': latestRunId,
      if (tagName != null) 'tag_name': tagName,
      if (branch != null) 'branch': branch,
      if (jobKey != null) 'job_key': jobKey,
      if (workflowJobKey != null) 'workflow_job_key': workflowJobKey,
      if (matrix != null) 'matrix': matrix,
      if (matrixLabel != null) 'matrix_label': matrixLabel,
      if (workflowRunId != null) 'workflow_run_id': workflowRunId,
      if (needs != null) 'needs': needs,
      if (failureSummary != null) 'failure_summary': failureSummary,
      if (failureSummaryModel != null)
        'failure_summary_model': failureSummaryModel,
      if (failureSummaryStatus != null)
        'failure_summary_status': failureSummaryStatus,
      if (failureSummaryDurationMs != null)
        'failure_summary_duration_ms': failureSummaryDurationMs,
      if (provisionedUdids != null) 'provisioned_udids': provisionedUdids,
      if (ipaUrl != null) 'ipa_url': ipaUrl,
      if (hasIpa != null) 'has_ipa': hasIpa,
      if (bundleId != null) 'bundle_id': bundleId,
      if (ipaVersion != null) 'ipa_version': ipaVersion,
      if (appName != null) 'app_name': appName,
      if (githubBaseUrl != null) 'github_base_url': githubBaseUrl,
      if (githubApiBaseUrl != null) 'github_api_base_url': githubApiBaseUrl,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuildJobsCompanion copyWith({
    Value<String>? id,
    Value<BuildJobStatus>? status,
    Value<String>? owner,
    Value<String>? repo,
    Value<String>? workflowName,
    Value<String?>? teamId,
    Value<String?>? workflowId,
    Value<String?>? workflowFileName,
    Value<String?>? commitSha,
    Value<int?>? pullRequestNumber,
    Value<int?>? runCount,
    Value<String?>? latestRunId,
    Value<String?>? tagName,
    Value<String?>? branch,
    Value<String?>? jobKey,
    Value<String?>? workflowJobKey,
    Value<Map<String, Object?>?>? matrix,
    Value<String?>? matrixLabel,
    Value<String?>? workflowRunId,
    Value<List<String>?>? needs,
    Value<String?>? failureSummary,
    Value<String?>? failureSummaryModel,
    Value<String?>? failureSummaryStatus,
    Value<int?>? failureSummaryDurationMs,
    Value<List<String>?>? provisionedUdids,
    Value<String?>? ipaUrl,
    Value<bool?>? hasIpa,
    Value<String?>? bundleId,
    Value<String?>? ipaVersion,
    Value<String?>? appName,
    Value<String?>? githubBaseUrl,
    Value<String?>? githubApiBaseUrl,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return BuildJobsCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      owner: owner ?? this.owner,
      repo: repo ?? this.repo,
      workflowName: workflowName ?? this.workflowName,
      teamId: teamId ?? this.teamId,
      workflowId: workflowId ?? this.workflowId,
      workflowFileName: workflowFileName ?? this.workflowFileName,
      commitSha: commitSha ?? this.commitSha,
      pullRequestNumber: pullRequestNumber ?? this.pullRequestNumber,
      runCount: runCount ?? this.runCount,
      latestRunId: latestRunId ?? this.latestRunId,
      tagName: tagName ?? this.tagName,
      branch: branch ?? this.branch,
      jobKey: jobKey ?? this.jobKey,
      workflowJobKey: workflowJobKey ?? this.workflowJobKey,
      matrix: matrix ?? this.matrix,
      matrixLabel: matrixLabel ?? this.matrixLabel,
      workflowRunId: workflowRunId ?? this.workflowRunId,
      needs: needs ?? this.needs,
      failureSummary: failureSummary ?? this.failureSummary,
      failureSummaryModel: failureSummaryModel ?? this.failureSummaryModel,
      failureSummaryStatus: failureSummaryStatus ?? this.failureSummaryStatus,
      failureSummaryDurationMs:
          failureSummaryDurationMs ?? this.failureSummaryDurationMs,
      provisionedUdids: provisionedUdids ?? this.provisionedUdids,
      ipaUrl: ipaUrl ?? this.ipaUrl,
      hasIpa: hasIpa ?? this.hasIpa,
      bundleId: bundleId ?? this.bundleId,
      ipaVersion: ipaVersion ?? this.ipaVersion,
      appName: appName ?? this.appName,
      githubBaseUrl: githubBaseUrl ?? this.githubBaseUrl,
      githubApiBaseUrl: githubApiBaseUrl ?? this.githubApiBaseUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $BuildJobsTable.$converterstatus.toSql(status.value),
      );
    }
    if (owner.present) {
      map['owner'] = Variable<String>(owner.value);
    }
    if (repo.present) {
      map['repo'] = Variable<String>(repo.value);
    }
    if (workflowName.present) {
      map['workflow_name'] = Variable<String>(workflowName.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (workflowId.present) {
      map['workflow_id'] = Variable<String>(workflowId.value);
    }
    if (workflowFileName.present) {
      map['workflow_file_name'] = Variable<String>(workflowFileName.value);
    }
    if (commitSha.present) {
      map['commit_sha'] = Variable<String>(commitSha.value);
    }
    if (pullRequestNumber.present) {
      map['pull_request_number'] = Variable<int>(pullRequestNumber.value);
    }
    if (runCount.present) {
      map['run_count'] = Variable<int>(runCount.value);
    }
    if (latestRunId.present) {
      map['latest_run_id'] = Variable<String>(latestRunId.value);
    }
    if (tagName.present) {
      map['tag_name'] = Variable<String>(tagName.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (jobKey.present) {
      map['job_key'] = Variable<String>(jobKey.value);
    }
    if (workflowJobKey.present) {
      map['workflow_job_key'] = Variable<String>(workflowJobKey.value);
    }
    if (matrix.present) {
      map['matrix'] = Variable<String>(
        $BuildJobsTable.$convertermatrixn.toSql(matrix.value),
      );
    }
    if (matrixLabel.present) {
      map['matrix_label'] = Variable<String>(matrixLabel.value);
    }
    if (workflowRunId.present) {
      map['workflow_run_id'] = Variable<String>(workflowRunId.value);
    }
    if (needs.present) {
      map['needs'] = Variable<String>(
        $BuildJobsTable.$converterneedsn.toSql(needs.value),
      );
    }
    if (failureSummary.present) {
      map['failure_summary'] = Variable<String>(failureSummary.value);
    }
    if (failureSummaryModel.present) {
      map['failure_summary_model'] = Variable<String>(
        failureSummaryModel.value,
      );
    }
    if (failureSummaryStatus.present) {
      map['failure_summary_status'] = Variable<String>(
        failureSummaryStatus.value,
      );
    }
    if (failureSummaryDurationMs.present) {
      map['failure_summary_duration_ms'] = Variable<int>(
        failureSummaryDurationMs.value,
      );
    }
    if (provisionedUdids.present) {
      map['provisioned_udids'] = Variable<String>(
        $BuildJobsTable.$converterprovisionedUdidsn.toSql(
          provisionedUdids.value,
        ),
      );
    }
    if (ipaUrl.present) {
      map['ipa_url'] = Variable<String>(ipaUrl.value);
    }
    if (hasIpa.present) {
      map['has_ipa'] = Variable<bool>(hasIpa.value);
    }
    if (bundleId.present) {
      map['bundle_id'] = Variable<String>(bundleId.value);
    }
    if (ipaVersion.present) {
      map['ipa_version'] = Variable<String>(ipaVersion.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (githubBaseUrl.present) {
      map['github_base_url'] = Variable<String>(githubBaseUrl.value);
    }
    if (githubApiBaseUrl.present) {
      map['github_api_base_url'] = Variable<String>(githubApiBaseUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildJobsCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('owner: $owner, ')
          ..write('repo: $repo, ')
          ..write('workflowName: $workflowName, ')
          ..write('teamId: $teamId, ')
          ..write('workflowId: $workflowId, ')
          ..write('workflowFileName: $workflowFileName, ')
          ..write('commitSha: $commitSha, ')
          ..write('pullRequestNumber: $pullRequestNumber, ')
          ..write('runCount: $runCount, ')
          ..write('latestRunId: $latestRunId, ')
          ..write('tagName: $tagName, ')
          ..write('branch: $branch, ')
          ..write('jobKey: $jobKey, ')
          ..write('workflowJobKey: $workflowJobKey, ')
          ..write('matrix: $matrix, ')
          ..write('matrixLabel: $matrixLabel, ')
          ..write('workflowRunId: $workflowRunId, ')
          ..write('needs: $needs, ')
          ..write('failureSummary: $failureSummary, ')
          ..write('failureSummaryModel: $failureSummaryModel, ')
          ..write('failureSummaryStatus: $failureSummaryStatus, ')
          ..write('failureSummaryDurationMs: $failureSummaryDurationMs, ')
          ..write('provisionedUdids: $provisionedUdids, ')
          ..write('ipaUrl: $ipaUrl, ')
          ..write('hasIpa: $hasIpa, ')
          ..write('bundleId: $bundleId, ')
          ..write('ipaVersion: $ipaVersion, ')
          ..write('appName: $appName, ')
          ..write('githubBaseUrl: $githubBaseUrl, ')
          ..write('githubApiBaseUrl: $githubApiBaseUrl, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TodoItemsTable todoItems = $TodoItemsTable(this);
  late final $BuildJobsTable buildJobs = $BuildJobsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [todoItems, buildJobs];
}

typedef $$TodoItemsTableCreateCompanionBuilder =
    TodoItemsCompanion Function({
      Value<int> id,
      required String title,
      required String content,
      Value<DateTime?> createdAt,
    });
typedef $$TodoItemsTableUpdateCompanionBuilder =
    TodoItemsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> content,
      Value<DateTime?> createdAt,
    });

class $$TodoItemsTableFilterComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TodoItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TodoItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TodoItemsTable> {
  $$TodoItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TodoItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TodoItemsTable,
          TodoItem,
          $$TodoItemsTableFilterComposer,
          $$TodoItemsTableOrderingComposer,
          $$TodoItemsTableAnnotationComposer,
          $$TodoItemsTableCreateCompanionBuilder,
          $$TodoItemsTableUpdateCompanionBuilder,
          (TodoItem, BaseReferences<_$AppDatabase, $TodoItemsTable, TodoItem>),
          TodoItem,
          PrefetchHooks Function()
        > {
  $$TodoItemsTableTableManager(_$AppDatabase db, $TodoItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TodoItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TodoItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TodoItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
              }) => TodoItemsCompanion(
                id: id,
                title: title,
                content: content,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String content,
                Value<DateTime?> createdAt = const Value.absent(),
              }) => TodoItemsCompanion.insert(
                id: id,
                title: title,
                content: content,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TodoItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TodoItemsTable,
      TodoItem,
      $$TodoItemsTableFilterComposer,
      $$TodoItemsTableOrderingComposer,
      $$TodoItemsTableAnnotationComposer,
      $$TodoItemsTableCreateCompanionBuilder,
      $$TodoItemsTableUpdateCompanionBuilder,
      (TodoItem, BaseReferences<_$AppDatabase, $TodoItemsTable, TodoItem>),
      TodoItem,
      PrefetchHooks Function()
    >;
typedef $$BuildJobsTableCreateCompanionBuilder =
    BuildJobsCompanion Function({
      required String id,
      required BuildJobStatus status,
      required String owner,
      required String repo,
      required String workflowName,
      Value<String?> teamId,
      Value<String?> workflowId,
      Value<String?> workflowFileName,
      Value<String?> commitSha,
      Value<int?> pullRequestNumber,
      Value<int?> runCount,
      Value<String?> latestRunId,
      Value<String?> tagName,
      Value<String?> branch,
      Value<String?> jobKey,
      Value<String?> workflowJobKey,
      Value<Map<String, Object?>?> matrix,
      Value<String?> matrixLabel,
      Value<String?> workflowRunId,
      Value<List<String>?> needs,
      Value<String?> failureSummary,
      Value<String?> failureSummaryModel,
      Value<String?> failureSummaryStatus,
      Value<int?> failureSummaryDurationMs,
      Value<List<String>?> provisionedUdids,
      Value<String?> ipaUrl,
      Value<bool?> hasIpa,
      Value<String?> bundleId,
      Value<String?> ipaVersion,
      Value<String?> appName,
      Value<String?> githubBaseUrl,
      Value<String?> githubApiBaseUrl,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$BuildJobsTableUpdateCompanionBuilder =
    BuildJobsCompanion Function({
      Value<String> id,
      Value<BuildJobStatus> status,
      Value<String> owner,
      Value<String> repo,
      Value<String> workflowName,
      Value<String?> teamId,
      Value<String?> workflowId,
      Value<String?> workflowFileName,
      Value<String?> commitSha,
      Value<int?> pullRequestNumber,
      Value<int?> runCount,
      Value<String?> latestRunId,
      Value<String?> tagName,
      Value<String?> branch,
      Value<String?> jobKey,
      Value<String?> workflowJobKey,
      Value<Map<String, Object?>?> matrix,
      Value<String?> matrixLabel,
      Value<String?> workflowRunId,
      Value<List<String>?> needs,
      Value<String?> failureSummary,
      Value<String?> failureSummaryModel,
      Value<String?> failureSummaryStatus,
      Value<int?> failureSummaryDurationMs,
      Value<List<String>?> provisionedUdids,
      Value<String?> ipaUrl,
      Value<bool?> hasIpa,
      Value<String?> bundleId,
      Value<String?> ipaVersion,
      Value<String?> appName,
      Value<String?> githubBaseUrl,
      Value<String?> githubApiBaseUrl,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$BuildJobsTableFilterComposer
    extends Composer<_$AppDatabase, $BuildJobsTable> {
  $$BuildJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BuildJobStatus, BuildJobStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repo => $composableBuilder(
    column: $table.repo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workflowName => $composableBuilder(
    column: $table.workflowName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workflowId => $composableBuilder(
    column: $table.workflowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workflowFileName => $composableBuilder(
    column: $table.workflowFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commitSha => $composableBuilder(
    column: $table.commitSha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pullRequestNumber => $composableBuilder(
    column: $table.pullRequestNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runCount => $composableBuilder(
    column: $table.runCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestRunId => $composableBuilder(
    column: $table.latestRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagName => $composableBuilder(
    column: $table.tagName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobKey => $composableBuilder(
    column: $table.jobKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workflowJobKey => $composableBuilder(
    column: $table.workflowJobKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, Object?>?,
    Map<String, Object>?,
    String
  >
  get matrix => $composableBuilder(
    column: $table.matrix,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get matrixLabel => $composableBuilder(
    column: $table.matrixLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workflowRunId => $composableBuilder(
    column: $table.workflowRunId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
  get needs => $composableBuilder(
    column: $table.needs,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get failureSummary => $composableBuilder(
    column: $table.failureSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureSummaryModel => $composableBuilder(
    column: $table.failureSummaryModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureSummaryStatus => $composableBuilder(
    column: $table.failureSummaryStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failureSummaryDurationMs => $composableBuilder(
    column: $table.failureSummaryDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
  get provisionedUdids => $composableBuilder(
    column: $table.provisionedUdids,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get ipaUrl => $composableBuilder(
    column: $table.ipaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasIpa => $composableBuilder(
    column: $table.hasIpa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bundleId => $composableBuilder(
    column: $table.bundleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ipaVersion => $composableBuilder(
    column: $table.ipaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get githubBaseUrl => $composableBuilder(
    column: $table.githubBaseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get githubApiBaseUrl => $composableBuilder(
    column: $table.githubApiBaseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BuildJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildJobsTable> {
  $$BuildJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get owner => $composableBuilder(
    column: $table.owner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repo => $composableBuilder(
    column: $table.repo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workflowName => $composableBuilder(
    column: $table.workflowName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workflowId => $composableBuilder(
    column: $table.workflowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workflowFileName => $composableBuilder(
    column: $table.workflowFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commitSha => $composableBuilder(
    column: $table.commitSha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pullRequestNumber => $composableBuilder(
    column: $table.pullRequestNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runCount => $composableBuilder(
    column: $table.runCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestRunId => $composableBuilder(
    column: $table.latestRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagName => $composableBuilder(
    column: $table.tagName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobKey => $composableBuilder(
    column: $table.jobKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workflowJobKey => $composableBuilder(
    column: $table.workflowJobKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrix => $composableBuilder(
    column: $table.matrix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matrixLabel => $composableBuilder(
    column: $table.matrixLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workflowRunId => $composableBuilder(
    column: $table.workflowRunId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get needs => $composableBuilder(
    column: $table.needs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureSummary => $composableBuilder(
    column: $table.failureSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureSummaryModel => $composableBuilder(
    column: $table.failureSummaryModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureSummaryStatus => $composableBuilder(
    column: $table.failureSummaryStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failureSummaryDurationMs => $composableBuilder(
    column: $table.failureSummaryDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provisionedUdids => $composableBuilder(
    column: $table.provisionedUdids,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipaUrl => $composableBuilder(
    column: $table.ipaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasIpa => $composableBuilder(
    column: $table.hasIpa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bundleId => $composableBuilder(
    column: $table.bundleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipaVersion => $composableBuilder(
    column: $table.ipaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get githubBaseUrl => $composableBuilder(
    column: $table.githubBaseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get githubApiBaseUrl => $composableBuilder(
    column: $table.githubApiBaseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BuildJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildJobsTable> {
  $$BuildJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BuildJobStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get owner =>
      $composableBuilder(column: $table.owner, builder: (column) => column);

  GeneratedColumn<String> get repo =>
      $composableBuilder(column: $table.repo, builder: (column) => column);

  GeneratedColumn<String> get workflowName => $composableBuilder(
    column: $table.workflowName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get workflowId => $composableBuilder(
    column: $table.workflowId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workflowFileName => $composableBuilder(
    column: $table.workflowFileName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commitSha =>
      $composableBuilder(column: $table.commitSha, builder: (column) => column);

  GeneratedColumn<int> get pullRequestNumber => $composableBuilder(
    column: $table.pullRequestNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runCount =>
      $composableBuilder(column: $table.runCount, builder: (column) => column);

  GeneratedColumn<String> get latestRunId => $composableBuilder(
    column: $table.latestRunId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagName =>
      $composableBuilder(column: $table.tagName, builder: (column) => column);

  GeneratedColumn<String> get branch =>
      $composableBuilder(column: $table.branch, builder: (column) => column);

  GeneratedColumn<String> get jobKey =>
      $composableBuilder(column: $table.jobKey, builder: (column) => column);

  GeneratedColumn<String> get workflowJobKey => $composableBuilder(
    column: $table.workflowJobKey,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, Object?>?, String> get matrix =>
      $composableBuilder(column: $table.matrix, builder: (column) => column);

  GeneratedColumn<String> get matrixLabel => $composableBuilder(
    column: $table.matrixLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workflowRunId => $composableBuilder(
    column: $table.workflowRunId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>?, String> get needs =>
      $composableBuilder(column: $table.needs, builder: (column) => column);

  GeneratedColumn<String> get failureSummary => $composableBuilder(
    column: $table.failureSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureSummaryModel => $composableBuilder(
    column: $table.failureSummaryModel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureSummaryStatus => $composableBuilder(
    column: $table.failureSummaryStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failureSummaryDurationMs => $composableBuilder(
    column: $table.failureSummaryDurationMs,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>?, String>
  get provisionedUdids => $composableBuilder(
    column: $table.provisionedUdids,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ipaUrl =>
      $composableBuilder(column: $table.ipaUrl, builder: (column) => column);

  GeneratedColumn<bool> get hasIpa =>
      $composableBuilder(column: $table.hasIpa, builder: (column) => column);

  GeneratedColumn<String> get bundleId =>
      $composableBuilder(column: $table.bundleId, builder: (column) => column);

  GeneratedColumn<String> get ipaVersion => $composableBuilder(
    column: $table.ipaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get githubBaseUrl => $composableBuilder(
    column: $table.githubBaseUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get githubApiBaseUrl => $composableBuilder(
    column: $table.githubApiBaseUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$BuildJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BuildJobsTable,
          DriftBuildJob,
          $$BuildJobsTableFilterComposer,
          $$BuildJobsTableOrderingComposer,
          $$BuildJobsTableAnnotationComposer,
          $$BuildJobsTableCreateCompanionBuilder,
          $$BuildJobsTableUpdateCompanionBuilder,
          (
            DriftBuildJob,
            BaseReferences<_$AppDatabase, $BuildJobsTable, DriftBuildJob>,
          ),
          DriftBuildJob,
          PrefetchHooks Function()
        > {
  $$BuildJobsTableTableManager(_$AppDatabase db, $BuildJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<BuildJobStatus> status = const Value.absent(),
                Value<String> owner = const Value.absent(),
                Value<String> repo = const Value.absent(),
                Value<String> workflowName = const Value.absent(),
                Value<String?> teamId = const Value.absent(),
                Value<String?> workflowId = const Value.absent(),
                Value<String?> workflowFileName = const Value.absent(),
                Value<String?> commitSha = const Value.absent(),
                Value<int?> pullRequestNumber = const Value.absent(),
                Value<int?> runCount = const Value.absent(),
                Value<String?> latestRunId = const Value.absent(),
                Value<String?> tagName = const Value.absent(),
                Value<String?> branch = const Value.absent(),
                Value<String?> jobKey = const Value.absent(),
                Value<String?> workflowJobKey = const Value.absent(),
                Value<Map<String, Object?>?> matrix = const Value.absent(),
                Value<String?> matrixLabel = const Value.absent(),
                Value<String?> workflowRunId = const Value.absent(),
                Value<List<String>?> needs = const Value.absent(),
                Value<String?> failureSummary = const Value.absent(),
                Value<String?> failureSummaryModel = const Value.absent(),
                Value<String?> failureSummaryStatus = const Value.absent(),
                Value<int?> failureSummaryDurationMs = const Value.absent(),
                Value<List<String>?> provisionedUdids = const Value.absent(),
                Value<String?> ipaUrl = const Value.absent(),
                Value<bool?> hasIpa = const Value.absent(),
                Value<String?> bundleId = const Value.absent(),
                Value<String?> ipaVersion = const Value.absent(),
                Value<String?> appName = const Value.absent(),
                Value<String?> githubBaseUrl = const Value.absent(),
                Value<String?> githubApiBaseUrl = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BuildJobsCompanion(
                id: id,
                status: status,
                owner: owner,
                repo: repo,
                workflowName: workflowName,
                teamId: teamId,
                workflowId: workflowId,
                workflowFileName: workflowFileName,
                commitSha: commitSha,
                pullRequestNumber: pullRequestNumber,
                runCount: runCount,
                latestRunId: latestRunId,
                tagName: tagName,
                branch: branch,
                jobKey: jobKey,
                workflowJobKey: workflowJobKey,
                matrix: matrix,
                matrixLabel: matrixLabel,
                workflowRunId: workflowRunId,
                needs: needs,
                failureSummary: failureSummary,
                failureSummaryModel: failureSummaryModel,
                failureSummaryStatus: failureSummaryStatus,
                failureSummaryDurationMs: failureSummaryDurationMs,
                provisionedUdids: provisionedUdids,
                ipaUrl: ipaUrl,
                hasIpa: hasIpa,
                bundleId: bundleId,
                ipaVersion: ipaVersion,
                appName: appName,
                githubBaseUrl: githubBaseUrl,
                githubApiBaseUrl: githubApiBaseUrl,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required BuildJobStatus status,
                required String owner,
                required String repo,
                required String workflowName,
                Value<String?> teamId = const Value.absent(),
                Value<String?> workflowId = const Value.absent(),
                Value<String?> workflowFileName = const Value.absent(),
                Value<String?> commitSha = const Value.absent(),
                Value<int?> pullRequestNumber = const Value.absent(),
                Value<int?> runCount = const Value.absent(),
                Value<String?> latestRunId = const Value.absent(),
                Value<String?> tagName = const Value.absent(),
                Value<String?> branch = const Value.absent(),
                Value<String?> jobKey = const Value.absent(),
                Value<String?> workflowJobKey = const Value.absent(),
                Value<Map<String, Object?>?> matrix = const Value.absent(),
                Value<String?> matrixLabel = const Value.absent(),
                Value<String?> workflowRunId = const Value.absent(),
                Value<List<String>?> needs = const Value.absent(),
                Value<String?> failureSummary = const Value.absent(),
                Value<String?> failureSummaryModel = const Value.absent(),
                Value<String?> failureSummaryStatus = const Value.absent(),
                Value<int?> failureSummaryDurationMs = const Value.absent(),
                Value<List<String>?> provisionedUdids = const Value.absent(),
                Value<String?> ipaUrl = const Value.absent(),
                Value<bool?> hasIpa = const Value.absent(),
                Value<String?> bundleId = const Value.absent(),
                Value<String?> ipaVersion = const Value.absent(),
                Value<String?> appName = const Value.absent(),
                Value<String?> githubBaseUrl = const Value.absent(),
                Value<String?> githubApiBaseUrl = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BuildJobsCompanion.insert(
                id: id,
                status: status,
                owner: owner,
                repo: repo,
                workflowName: workflowName,
                teamId: teamId,
                workflowId: workflowId,
                workflowFileName: workflowFileName,
                commitSha: commitSha,
                pullRequestNumber: pullRequestNumber,
                runCount: runCount,
                latestRunId: latestRunId,
                tagName: tagName,
                branch: branch,
                jobKey: jobKey,
                workflowJobKey: workflowJobKey,
                matrix: matrix,
                matrixLabel: matrixLabel,
                workflowRunId: workflowRunId,
                needs: needs,
                failureSummary: failureSummary,
                failureSummaryModel: failureSummaryModel,
                failureSummaryStatus: failureSummaryStatus,
                failureSummaryDurationMs: failureSummaryDurationMs,
                provisionedUdids: provisionedUdids,
                ipaUrl: ipaUrl,
                hasIpa: hasIpa,
                bundleId: bundleId,
                ipaVersion: ipaVersion,
                appName: appName,
                githubBaseUrl: githubBaseUrl,
                githubApiBaseUrl: githubApiBaseUrl,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BuildJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BuildJobsTable,
      DriftBuildJob,
      $$BuildJobsTableFilterComposer,
      $$BuildJobsTableOrderingComposer,
      $$BuildJobsTableAnnotationComposer,
      $$BuildJobsTableCreateCompanionBuilder,
      $$BuildJobsTableUpdateCompanionBuilder,
      (
        DriftBuildJob,
        BaseReferences<_$AppDatabase, $BuildJobsTable, DriftBuildJob>,
      ),
      DriftBuildJob,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TodoItemsTableTableManager get todoItems =>
      $$TodoItemsTableTableManager(_db, _db.todoItems);
  $$BuildJobsTableTableManager get buildJobs =>
      $$BuildJobsTableTableManager(_db, _db.buildJobs);
}
