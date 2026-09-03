// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _commitMessageMeta = const VerificationMeta(
    'commitMessage',
  );
  @override
  late final GeneratedColumn<String> commitMessage = GeneratedColumn<String>(
    'commit_message',
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
  static const VerificationMeta _runsOnMeta = const VerificationMeta('runsOn');
  @override
  late final GeneratedColumn<String> runsOn = GeneratedColumn<String>(
    'runs_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
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
  static const VerificationMeta _vmNameMeta = const VerificationMeta('vmName');
  @override
  late final GeneratedColumn<String> vmName = GeneratedColumn<String>(
    'vm_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workerHostMeta = const VerificationMeta(
    'workerHost',
  );
  @override
  late final GeneratedColumn<String> workerHost = GeneratedColumn<String>(
    'worker_host',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installationIdMeta = const VerificationMeta(
    'installationId',
  );
  @override
  late final GeneratedColumn<String> installationId = GeneratedColumn<String>(
    'installation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkRunIdMeta = const VerificationMeta(
    'checkRunId',
  );
  @override
  late final GeneratedColumn<String> checkRunId = GeneratedColumn<String>(
    'check_run_id',
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
    commitMessage,
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
    runsOn,
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
    vmName,
    workerHost,
    installationId,
    checkRunId,
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
    } else if (isInserting) {
      context.missing(_workflowFileNameMeta);
    }
    if (data.containsKey('commit_sha')) {
      context.handle(
        _commitShaMeta,
        commitSha.isAcceptableOrUnknown(data['commit_sha']!, _commitShaMeta),
      );
    }
    if (data.containsKey('commit_message')) {
      context.handle(
        _commitMessageMeta,
        commitMessage.isAcceptableOrUnknown(
          data['commit_message']!,
          _commitMessageMeta,
        ),
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
    if (data.containsKey('runs_on')) {
      context.handle(
        _runsOnMeta,
        runsOn.isAcceptableOrUnknown(data['runs_on']!, _runsOnMeta),
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
    if (data.containsKey('vm_name')) {
      context.handle(
        _vmNameMeta,
        vmName.isAcceptableOrUnknown(data['vm_name']!, _vmNameMeta),
      );
    }
    if (data.containsKey('worker_host')) {
      context.handle(
        _workerHostMeta,
        workerHost.isAcceptableOrUnknown(data['worker_host']!, _workerHostMeta),
      );
    }
    if (data.containsKey('installation_id')) {
      context.handle(
        _installationIdMeta,
        installationId.isAcceptableOrUnknown(
          data['installation_id']!,
          _installationIdMeta,
        ),
      );
    }
    if (data.containsKey('check_run_id')) {
      context.handle(
        _checkRunIdMeta,
        checkRunId.isAcceptableOrUnknown(
          data['check_run_id']!,
          _checkRunIdMeta,
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
      )!,
      commitSha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commit_sha'],
      ),
      commitMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commit_message'],
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
      runsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}runs_on'],
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
      vmName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vm_name'],
      ),
      workerHost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_host'],
      ),
      installationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}installation_id'],
      ),
      checkRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}check_run_id'],
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
  final String workflowFileName;
  final String? commitSha;
  final String? commitMessage;
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
  final String? runsOn;
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
  final String? vmName;
  final String? workerHost;
  final String? installationId;
  final String? checkRunId;
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
    required this.workflowFileName,
    this.commitSha,
    this.commitMessage,
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
    this.runsOn,
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
    this.vmName,
    this.workerHost,
    this.installationId,
    this.checkRunId,
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
    map['workflow_file_name'] = Variable<String>(workflowFileName);
    if (!nullToAbsent || commitSha != null) {
      map['commit_sha'] = Variable<String>(commitSha);
    }
    if (!nullToAbsent || commitMessage != null) {
      map['commit_message'] = Variable<String>(commitMessage);
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
    if (!nullToAbsent || runsOn != null) {
      map['runs_on'] = Variable<String>(runsOn);
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
    if (!nullToAbsent || vmName != null) {
      map['vm_name'] = Variable<String>(vmName);
    }
    if (!nullToAbsent || workerHost != null) {
      map['worker_host'] = Variable<String>(workerHost);
    }
    if (!nullToAbsent || installationId != null) {
      map['installation_id'] = Variable<String>(installationId);
    }
    if (!nullToAbsent || checkRunId != null) {
      map['check_run_id'] = Variable<String>(checkRunId);
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
      workflowFileName: Value(workflowFileName),
      commitSha: commitSha == null && nullToAbsent
          ? const Value.absent()
          : Value(commitSha),
      commitMessage: commitMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(commitMessage),
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
      runsOn: runsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(runsOn),
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
      vmName: vmName == null && nullToAbsent
          ? const Value.absent()
          : Value(vmName),
      workerHost: workerHost == null && nullToAbsent
          ? const Value.absent()
          : Value(workerHost),
      installationId: installationId == null && nullToAbsent
          ? const Value.absent()
          : Value(installationId),
      checkRunId: checkRunId == null && nullToAbsent
          ? const Value.absent()
          : Value(checkRunId),
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
      workflowFileName: serializer.fromJson<String>(json['workflowFileName']),
      commitSha: serializer.fromJson<String?>(json['commitSha']),
      commitMessage: serializer.fromJson<String?>(json['commitMessage']),
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
      runsOn: serializer.fromJson<String?>(json['runsOn']),
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
      vmName: serializer.fromJson<String?>(json['vmName']),
      workerHost: serializer.fromJson<String?>(json['workerHost']),
      installationId: serializer.fromJson<String?>(json['installationId']),
      checkRunId: serializer.fromJson<String?>(json['checkRunId']),
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
      'workflowFileName': serializer.toJson<String>(workflowFileName),
      'commitSha': serializer.toJson<String?>(commitSha),
      'commitMessage': serializer.toJson<String?>(commitMessage),
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
      'runsOn': serializer.toJson<String?>(runsOn),
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
      'vmName': serializer.toJson<String?>(vmName),
      'workerHost': serializer.toJson<String?>(workerHost),
      'installationId': serializer.toJson<String?>(installationId),
      'checkRunId': serializer.toJson<String?>(checkRunId),
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
    String? workflowFileName,
    Value<String?> commitSha = const Value.absent(),
    Value<String?> commitMessage = const Value.absent(),
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
    Value<String?> runsOn = const Value.absent(),
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
    Value<String?> vmName = const Value.absent(),
    Value<String?> workerHost = const Value.absent(),
    Value<String?> installationId = const Value.absent(),
    Value<String?> checkRunId = const Value.absent(),
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
    workflowFileName: workflowFileName ?? this.workflowFileName,
    commitSha: commitSha.present ? commitSha.value : this.commitSha,
    commitMessage: commitMessage.present
        ? commitMessage.value
        : this.commitMessage,
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
    runsOn: runsOn.present ? runsOn.value : this.runsOn,
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
    vmName: vmName.present ? vmName.value : this.vmName,
    workerHost: workerHost.present ? workerHost.value : this.workerHost,
    installationId: installationId.present
        ? installationId.value
        : this.installationId,
    checkRunId: checkRunId.present ? checkRunId.value : this.checkRunId,
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
      commitMessage: data.commitMessage.present
          ? data.commitMessage.value
          : this.commitMessage,
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
      runsOn: data.runsOn.present ? data.runsOn.value : this.runsOn,
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
      vmName: data.vmName.present ? data.vmName.value : this.vmName,
      workerHost: data.workerHost.present
          ? data.workerHost.value
          : this.workerHost,
      installationId: data.installationId.present
          ? data.installationId.value
          : this.installationId,
      checkRunId: data.checkRunId.present
          ? data.checkRunId.value
          : this.checkRunId,
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
          ..write('commitMessage: $commitMessage, ')
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
          ..write('runsOn: $runsOn, ')
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
          ..write('vmName: $vmName, ')
          ..write('workerHost: $workerHost, ')
          ..write('installationId: $installationId, ')
          ..write('checkRunId: $checkRunId, ')
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
    commitMessage,
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
    runsOn,
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
    vmName,
    workerHost,
    installationId,
    checkRunId,
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
          other.commitMessage == this.commitMessage &&
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
          other.runsOn == this.runsOn &&
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
          other.vmName == this.vmName &&
          other.workerHost == this.workerHost &&
          other.installationId == this.installationId &&
          other.checkRunId == this.checkRunId &&
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
  final Value<String> workflowFileName;
  final Value<String?> commitSha;
  final Value<String?> commitMessage;
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
  final Value<String?> runsOn;
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
  final Value<String?> vmName;
  final Value<String?> workerHost;
  final Value<String?> installationId;
  final Value<String?> checkRunId;
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
    this.commitMessage = const Value.absent(),
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
    this.runsOn = const Value.absent(),
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
    this.vmName = const Value.absent(),
    this.workerHost = const Value.absent(),
    this.installationId = const Value.absent(),
    this.checkRunId = const Value.absent(),
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
    required String workflowFileName,
    this.commitSha = const Value.absent(),
    this.commitMessage = const Value.absent(),
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
    this.runsOn = const Value.absent(),
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
    this.vmName = const Value.absent(),
    this.workerHost = const Value.absent(),
    this.installationId = const Value.absent(),
    this.checkRunId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       owner = Value(owner),
       repo = Value(repo),
       workflowName = Value(workflowName),
       workflowFileName = Value(workflowFileName),
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
    Expression<String>? commitMessage,
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
    Expression<String>? runsOn,
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
    Expression<String>? vmName,
    Expression<String>? workerHost,
    Expression<String>? installationId,
    Expression<String>? checkRunId,
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
      if (commitMessage != null) 'commit_message': commitMessage,
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
      if (runsOn != null) 'runs_on': runsOn,
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
      if (vmName != null) 'vm_name': vmName,
      if (workerHost != null) 'worker_host': workerHost,
      if (installationId != null) 'installation_id': installationId,
      if (checkRunId != null) 'check_run_id': checkRunId,
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
    Value<String>? workflowFileName,
    Value<String?>? commitSha,
    Value<String?>? commitMessage,
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
    Value<String?>? runsOn,
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
    Value<String?>? vmName,
    Value<String?>? workerHost,
    Value<String?>? installationId,
    Value<String?>? checkRunId,
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
      commitMessage: commitMessage ?? this.commitMessage,
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
      runsOn: runsOn ?? this.runsOn,
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
      vmName: vmName ?? this.vmName,
      workerHost: workerHost ?? this.workerHost,
      installationId: installationId ?? this.installationId,
      checkRunId: checkRunId ?? this.checkRunId,
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
    if (commitMessage.present) {
      map['commit_message'] = Variable<String>(commitMessage.value);
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
    if (runsOn.present) {
      map['runs_on'] = Variable<String>(runsOn.value);
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
    if (vmName.present) {
      map['vm_name'] = Variable<String>(vmName.value);
    }
    if (workerHost.present) {
      map['worker_host'] = Variable<String>(workerHost.value);
    }
    if (installationId.present) {
      map['installation_id'] = Variable<String>(installationId.value);
    }
    if (checkRunId.present) {
      map['check_run_id'] = Variable<String>(checkRunId.value);
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
          ..write('commitMessage: $commitMessage, ')
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
          ..write('runsOn: $runsOn, ')
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
          ..write('vmName: $vmName, ')
          ..write('workerHost: $workerHost, ')
          ..write('installationId: $installationId, ')
          ..write('checkRunId: $checkRunId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BuildJobLogsTable extends BuildJobLogs
    with TableInfo<$BuildJobLogsTable, DriftBuildJobLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildJobLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logContentMeta = const VerificationMeta(
    'logContent',
  );
  @override
  late final GeneratedColumn<String> logContent = GeneratedColumn<String>(
    'log_content',
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, runId, logContent, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'build_job_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftBuildJobLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('log_content')) {
      context.handle(
        _logContentMeta,
        logContent.isAcceptableOrUnknown(data['log_content']!, _logContentMeta),
      );
    } else if (isInserting) {
      context.missing(_logContentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftBuildJobLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftBuildJobLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      logContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BuildJobLogsTable createAlias(String alias) {
    return $BuildJobLogsTable(attachedDatabase, alias);
  }
}

class DriftBuildJobLog extends DataClass
    implements Insertable<DriftBuildJobLog> {
  final int id;
  final String runId;
  final String logContent;
  final DateTime createdAt;
  const DriftBuildJobLog({
    required this.id,
    required this.runId,
    required this.logContent,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['run_id'] = Variable<String>(runId);
    map['log_content'] = Variable<String>(logContent);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BuildJobLogsCompanion toCompanion(bool nullToAbsent) {
    return BuildJobLogsCompanion(
      id: Value(id),
      runId: Value(runId),
      logContent: Value(logContent),
      createdAt: Value(createdAt),
    );
  }

  factory DriftBuildJobLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftBuildJobLog(
      id: serializer.fromJson<int>(json['id']),
      runId: serializer.fromJson<String>(json['runId']),
      logContent: serializer.fromJson<String>(json['logContent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'runId': serializer.toJson<String>(runId),
      'logContent': serializer.toJson<String>(logContent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DriftBuildJobLog copyWith({
    int? id,
    String? runId,
    String? logContent,
    DateTime? createdAt,
  }) => DriftBuildJobLog(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    logContent: logContent ?? this.logContent,
    createdAt: createdAt ?? this.createdAt,
  );
  DriftBuildJobLog copyWithCompanion(BuildJobLogsCompanion data) {
    return DriftBuildJobLog(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      logContent: data.logContent.present
          ? data.logContent.value
          : this.logContent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftBuildJobLog(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('logContent: $logContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, runId, logContent, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftBuildJobLog &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.logContent == this.logContent &&
          other.createdAt == this.createdAt);
}

class BuildJobLogsCompanion extends UpdateCompanion<DriftBuildJobLog> {
  final Value<int> id;
  final Value<String> runId;
  final Value<String> logContent;
  final Value<DateTime> createdAt;
  const BuildJobLogsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.logContent = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BuildJobLogsCompanion.insert({
    this.id = const Value.absent(),
    required String runId,
    required String logContent,
    required DateTime createdAt,
  }) : runId = Value(runId),
       logContent = Value(logContent),
       createdAt = Value(createdAt);
  static Insertable<DriftBuildJobLog> custom({
    Expression<int>? id,
    Expression<String>? runId,
    Expression<String>? logContent,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (logContent != null) 'log_content': logContent,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BuildJobLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? runId,
    Value<String>? logContent,
    Value<DateTime>? createdAt,
  }) {
    return BuildJobLogsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      logContent: logContent ?? this.logContent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (logContent.present) {
      map['log_content'] = Variable<String>(logContent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildJobLogsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('logContent: $logContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BuildStepsTable extends BuildSteps
    with TableInfo<$BuildStepsTable, DriftBuildStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
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
      ).withConverter<BuildJobStatus>($BuildStepsTable.$converterstatus);
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepOrderMeta = const VerificationMeta(
    'stepOrder',
  );
  @override
  late final GeneratedColumn<int> stepOrder = GeneratedColumn<int>(
    'step_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    name,
    status,
    durationMs,
    stepOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'build_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftBuildStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('step_order')) {
      context.handle(
        _stepOrderMeta,
        stepOrder.isAcceptableOrUnknown(data['step_order']!, _stepOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_stepOrderMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftBuildStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftBuildStep(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      status: $BuildStepsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      stepOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BuildStepsTable createAlias(String alias) {
    return $BuildStepsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BuildJobStatus, String, String> $converterstatus =
      const EnumNameConverter<BuildJobStatus>(BuildJobStatus.values);
}

class DriftBuildStep extends DataClass implements Insertable<DriftBuildStep> {
  final String id;
  final String runId;
  final String name;
  final BuildJobStatus status;
  final int durationMs;
  final int stepOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DriftBuildStep({
    required this.id,
    required this.runId,
    required this.name,
    required this.status,
    required this.durationMs,
    required this.stepOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['name'] = Variable<String>(name);
    {
      map['status'] = Variable<String>(
        $BuildStepsTable.$converterstatus.toSql(status),
      );
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['step_order'] = Variable<int>(stepOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BuildStepsCompanion toCompanion(bool nullToAbsent) {
    return BuildStepsCompanion(
      id: Value(id),
      runId: Value(runId),
      name: Value(name),
      status: Value(status),
      durationMs: Value(durationMs),
      stepOrder: Value(stepOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DriftBuildStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftBuildStep(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['runId']),
      name: serializer.fromJson<String>(json['name']),
      status: $BuildStepsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      stepOrder: serializer.fromJson<int>(json['stepOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'runId': serializer.toJson<String>(runId),
      'name': serializer.toJson<String>(name),
      'status': serializer.toJson<String>(
        $BuildStepsTable.$converterstatus.toJson(status),
      ),
      'durationMs': serializer.toJson<int>(durationMs),
      'stepOrder': serializer.toJson<int>(stepOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DriftBuildStep copyWith({
    String? id,
    String? runId,
    String? name,
    BuildJobStatus? status,
    int? durationMs,
    int? stepOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DriftBuildStep(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    name: name ?? this.name,
    status: status ?? this.status,
    durationMs: durationMs ?? this.durationMs,
    stepOrder: stepOrder ?? this.stepOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DriftBuildStep copyWithCompanion(BuildStepsCompanion data) {
    return DriftBuildStep(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      name: data.name.present ? data.name.value : this.name,
      status: data.status.present ? data.status.value : this.status,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      stepOrder: data.stepOrder.present ? data.stepOrder.value : this.stepOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftBuildStep(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('durationMs: $durationMs, ')
          ..write('stepOrder: $stepOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    name,
    status,
    durationMs,
    stepOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftBuildStep &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.name == this.name &&
          other.status == this.status &&
          other.durationMs == this.durationMs &&
          other.stepOrder == this.stepOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BuildStepsCompanion extends UpdateCompanion<DriftBuildStep> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> name;
  final Value<BuildJobStatus> status;
  final Value<int> durationMs;
  final Value<int> stepOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BuildStepsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.stepOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuildStepsCompanion.insert({
    required String id,
    required String runId,
    required String name,
    required BuildJobStatus status,
    required int durationMs,
    required int stepOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       name = Value(name),
       status = Value(status),
       durationMs = Value(durationMs),
       stepOrder = Value(stepOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DriftBuildStep> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? name,
    Expression<String>? status,
    Expression<int>? durationMs,
    Expression<int>? stepOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (durationMs != null) 'duration_ms': durationMs,
      if (stepOrder != null) 'step_order': stepOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuildStepsCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? name,
    Value<BuildJobStatus>? status,
    Value<int>? durationMs,
    Value<int>? stepOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BuildStepsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      name: name ?? this.name,
      status: status ?? this.status,
      durationMs: durationMs ?? this.durationMs,
      stepOrder: stepOrder ?? this.stepOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $BuildStepsTable.$converterstatus.toSql(status.value),
      );
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (stepOrder.present) {
      map['step_order'] = Variable<int>(stepOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildStepsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('durationMs: $durationMs, ')
          ..write('stepOrder: $stepOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BuildStepLogsTable extends BuildStepLogs
    with TableInfo<$BuildStepLogsTable, DriftBuildStepLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildStepLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _stepIdMeta = const VerificationMeta('stepId');
  @override
  late final GeneratedColumn<String> stepId = GeneratedColumn<String>(
    'step_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _logContentMeta = const VerificationMeta(
    'logContent',
  );
  @override
  late final GeneratedColumn<String> logContent = GeneratedColumn<String>(
    'log_content',
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
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, stepId, logContent, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'build_step_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftBuildStepLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('step_id')) {
      context.handle(
        _stepIdMeta,
        stepId.isAcceptableOrUnknown(data['step_id']!, _stepIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stepIdMeta);
    }
    if (data.containsKey('log_content')) {
      context.handle(
        _logContentMeta,
        logContent.isAcceptableOrUnknown(data['log_content']!, _logContentMeta),
      );
    } else if (isInserting) {
      context.missing(_logContentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftBuildStepLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftBuildStepLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stepId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step_id'],
      )!,
      logContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BuildStepLogsTable createAlias(String alias) {
    return $BuildStepLogsTable(attachedDatabase, alias);
  }
}

class DriftBuildStepLog extends DataClass
    implements Insertable<DriftBuildStepLog> {
  final int id;
  final String stepId;
  final String logContent;
  final DateTime createdAt;
  const DriftBuildStepLog({
    required this.id,
    required this.stepId,
    required this.logContent,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['step_id'] = Variable<String>(stepId);
    map['log_content'] = Variable<String>(logContent);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BuildStepLogsCompanion toCompanion(bool nullToAbsent) {
    return BuildStepLogsCompanion(
      id: Value(id),
      stepId: Value(stepId),
      logContent: Value(logContent),
      createdAt: Value(createdAt),
    );
  }

  factory DriftBuildStepLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftBuildStepLog(
      id: serializer.fromJson<int>(json['id']),
      stepId: serializer.fromJson<String>(json['stepId']),
      logContent: serializer.fromJson<String>(json['logContent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stepId': serializer.toJson<String>(stepId),
      'logContent': serializer.toJson<String>(logContent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DriftBuildStepLog copyWith({
    int? id,
    String? stepId,
    String? logContent,
    DateTime? createdAt,
  }) => DriftBuildStepLog(
    id: id ?? this.id,
    stepId: stepId ?? this.stepId,
    logContent: logContent ?? this.logContent,
    createdAt: createdAt ?? this.createdAt,
  );
  DriftBuildStepLog copyWithCompanion(BuildStepLogsCompanion data) {
    return DriftBuildStepLog(
      id: data.id.present ? data.id.value : this.id,
      stepId: data.stepId.present ? data.stepId.value : this.stepId,
      logContent: data.logContent.present
          ? data.logContent.value
          : this.logContent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftBuildStepLog(')
          ..write('id: $id, ')
          ..write('stepId: $stepId, ')
          ..write('logContent: $logContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, stepId, logContent, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftBuildStepLog &&
          other.id == this.id &&
          other.stepId == this.stepId &&
          other.logContent == this.logContent &&
          other.createdAt == this.createdAt);
}

class BuildStepLogsCompanion extends UpdateCompanion<DriftBuildStepLog> {
  final Value<int> id;
  final Value<String> stepId;
  final Value<String> logContent;
  final Value<DateTime> createdAt;
  const BuildStepLogsCompanion({
    this.id = const Value.absent(),
    this.stepId = const Value.absent(),
    this.logContent = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BuildStepLogsCompanion.insert({
    this.id = const Value.absent(),
    required String stepId,
    required String logContent,
    required DateTime createdAt,
  }) : stepId = Value(stepId),
       logContent = Value(logContent),
       createdAt = Value(createdAt);
  static Insertable<DriftBuildStepLog> custom({
    Expression<int>? id,
    Expression<String>? stepId,
    Expression<String>? logContent,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stepId != null) 'step_id': stepId,
      if (logContent != null) 'log_content': logContent,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BuildStepLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? stepId,
    Value<String>? logContent,
    Value<DateTime>? createdAt,
  }) {
    return BuildStepLogsCompanion(
      id: id ?? this.id,
      stepId: stepId ?? this.stepId,
      logContent: logContent ?? this.logContent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stepId.present) {
      map['step_id'] = Variable<String>(stepId.value);
    }
    if (logContent.present) {
      map['log_content'] = Variable<String>(logContent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildStepLogsCompanion(')
          ..write('id: $id, ')
          ..write('stepId: $stepId, ')
          ..write('logContent: $logContent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BuildRunsTable extends BuildRuns
    with TableInfo<$BuildRunsTable, DriftBuildRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buildJobIdMeta = const VerificationMeta(
    'buildJobId',
  );
  @override
  late final GeneratedColumn<String> buildJobId = GeneratedColumn<String>(
    'build_job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES build_jobs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conclusionMeta = const VerificationMeta(
    'conclusion',
  );
  @override
  late final GeneratedColumn<String> conclusion = GeneratedColumn<String>(
    'conclusion',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    buildJobId,
    status,
    conclusion,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'build_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftBuildRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('build_job_id')) {
      context.handle(
        _buildJobIdMeta,
        buildJobId.isAcceptableOrUnknown(
          data['build_job_id']!,
          _buildJobIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_buildJobIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('conclusion')) {
      context.handle(
        _conclusionMeta,
        conclusion.isAcceptableOrUnknown(data['conclusion']!, _conclusionMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftBuildRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftBuildRun(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      buildJobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}build_job_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      conclusion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conclusion'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BuildRunsTable createAlias(String alias) {
    return $BuildRunsTable(attachedDatabase, alias);
  }
}

class DriftBuildRun extends DataClass implements Insertable<DriftBuildRun> {
  final String id;
  final String buildJobId;
  final String status;
  final String? conclusion;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DriftBuildRun({
    required this.id,
    required this.buildJobId,
    required this.status,
    this.conclusion,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['build_job_id'] = Variable<String>(buildJobId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || conclusion != null) {
      map['conclusion'] = Variable<String>(conclusion);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BuildRunsCompanion toCompanion(bool nullToAbsent) {
    return BuildRunsCompanion(
      id: Value(id),
      buildJobId: Value(buildJobId),
      status: Value(status),
      conclusion: conclusion == null && nullToAbsent
          ? const Value.absent()
          : Value(conclusion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DriftBuildRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftBuildRun(
      id: serializer.fromJson<String>(json['id']),
      buildJobId: serializer.fromJson<String>(json['buildJobId']),
      status: serializer.fromJson<String>(json['status']),
      conclusion: serializer.fromJson<String?>(json['conclusion']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'buildJobId': serializer.toJson<String>(buildJobId),
      'status': serializer.toJson<String>(status),
      'conclusion': serializer.toJson<String?>(conclusion),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DriftBuildRun copyWith({
    String? id,
    String? buildJobId,
    String? status,
    Value<String?> conclusion = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DriftBuildRun(
    id: id ?? this.id,
    buildJobId: buildJobId ?? this.buildJobId,
    status: status ?? this.status,
    conclusion: conclusion.present ? conclusion.value : this.conclusion,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DriftBuildRun copyWithCompanion(BuildRunsCompanion data) {
    return DriftBuildRun(
      id: data.id.present ? data.id.value : this.id,
      buildJobId: data.buildJobId.present
          ? data.buildJobId.value
          : this.buildJobId,
      status: data.status.present ? data.status.value : this.status,
      conclusion: data.conclusion.present
          ? data.conclusion.value
          : this.conclusion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftBuildRun(')
          ..write('id: $id, ')
          ..write('buildJobId: $buildJobId, ')
          ..write('status: $status, ')
          ..write('conclusion: $conclusion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, buildJobId, status, conclusion, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftBuildRun &&
          other.id == this.id &&
          other.buildJobId == this.buildJobId &&
          other.status == this.status &&
          other.conclusion == this.conclusion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BuildRunsCompanion extends UpdateCompanion<DriftBuildRun> {
  final Value<String> id;
  final Value<String> buildJobId;
  final Value<String> status;
  final Value<String?> conclusion;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BuildRunsCompanion({
    this.id = const Value.absent(),
    this.buildJobId = const Value.absent(),
    this.status = const Value.absent(),
    this.conclusion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuildRunsCompanion.insert({
    required String id,
    required String buildJobId,
    required String status,
    this.conclusion = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       buildJobId = Value(buildJobId),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DriftBuildRun> custom({
    Expression<String>? id,
    Expression<String>? buildJobId,
    Expression<String>? status,
    Expression<String>? conclusion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (buildJobId != null) 'build_job_id': buildJobId,
      if (status != null) 'status': status,
      if (conclusion != null) 'conclusion': conclusion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuildRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? buildJobId,
    Value<String>? status,
    Value<String?>? conclusion,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BuildRunsCompanion(
      id: id ?? this.id,
      buildJobId: buildJobId ?? this.buildJobId,
      status: status ?? this.status,
      conclusion: conclusion ?? this.conclusion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (buildJobId.present) {
      map['build_job_id'] = Variable<String>(buildJobId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (conclusion.present) {
      map['conclusion'] = Variable<String>(conclusion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildRunsCompanion(')
          ..write('id: $id, ')
          ..write('buildJobId: $buildJobId, ')
          ..write('status: $status, ')
          ..write('conclusion: $conclusion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamsTable extends Teams with TableInfo<$TeamsTable, DriftTeam> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  late final GeneratedColumnWithTypeConverter<List<int>, String>
  installationIds = GeneratedColumn<String>(
    'installation_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<int>>($TeamsTable.$converterinstallationIds);
  static const VerificationMeta _aiEnabledMeta = const VerificationMeta(
    'aiEnabled',
  );
  @override
  late final GeneratedColumn<bool> aiEnabled = GeneratedColumn<bool>(
    'ai_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runNumberMeta = const VerificationMeta(
    'runNumber',
  );
  @override
  late final GeneratedColumn<int> runNumber = GeneratedColumn<int>(
    'run_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    githubBaseUrl,
    installationIds,
    aiEnabled,
    runNumber,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftTeam> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
    if (data.containsKey('ai_enabled')) {
      context.handle(
        _aiEnabledMeta,
        aiEnabled.isAcceptableOrUnknown(data['ai_enabled']!, _aiEnabledMeta),
      );
    } else if (isInserting) {
      context.missing(_aiEnabledMeta);
    }
    if (data.containsKey('run_number')) {
      context.handle(
        _runNumberMeta,
        runNumber.isAcceptableOrUnknown(data['run_number']!, _runNumberMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftTeam map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftTeam(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      githubBaseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}github_base_url'],
      ),
      installationIds: $TeamsTable.$converterinstallationIds.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}installation_ids'],
        )!,
      ),
      aiEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ai_enabled'],
      )!,
      runNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_number'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TeamsTable createAlias(String alias) {
    return $TeamsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<int>, String> $converterinstallationIds =
      const IntListConverter();
}

class DriftTeam extends DataClass implements Insertable<DriftTeam> {
  final String id;
  final String name;
  final String? githubBaseUrl;
  final List<int> installationIds;
  final bool aiEnabled;
  final int runNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DriftTeam({
    required this.id,
    required this.name,
    this.githubBaseUrl,
    required this.installationIds,
    required this.aiEnabled,
    required this.runNumber,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || githubBaseUrl != null) {
      map['github_base_url'] = Variable<String>(githubBaseUrl);
    }
    {
      map['installation_ids'] = Variable<String>(
        $TeamsTable.$converterinstallationIds.toSql(installationIds),
      );
    }
    map['ai_enabled'] = Variable<bool>(aiEnabled);
    map['run_number'] = Variable<int>(runNumber);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(
      id: Value(id),
      name: Value(name),
      githubBaseUrl: githubBaseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(githubBaseUrl),
      installationIds: Value(installationIds),
      aiEnabled: Value(aiEnabled),
      runNumber: Value(runNumber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DriftTeam.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftTeam(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      githubBaseUrl: serializer.fromJson<String?>(json['githubBaseUrl']),
      installationIds: serializer.fromJson<List<int>>(json['installationIds']),
      aiEnabled: serializer.fromJson<bool>(json['aiEnabled']),
      runNumber: serializer.fromJson<int>(json['runNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'githubBaseUrl': serializer.toJson<String?>(githubBaseUrl),
      'installationIds': serializer.toJson<List<int>>(installationIds),
      'aiEnabled': serializer.toJson<bool>(aiEnabled),
      'runNumber': serializer.toJson<int>(runNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DriftTeam copyWith({
    String? id,
    String? name,
    Value<String?> githubBaseUrl = const Value.absent(),
    List<int>? installationIds,
    bool? aiEnabled,
    int? runNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DriftTeam(
    id: id ?? this.id,
    name: name ?? this.name,
    githubBaseUrl: githubBaseUrl.present
        ? githubBaseUrl.value
        : this.githubBaseUrl,
    installationIds: installationIds ?? this.installationIds,
    aiEnabled: aiEnabled ?? this.aiEnabled,
    runNumber: runNumber ?? this.runNumber,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DriftTeam copyWithCompanion(TeamsCompanion data) {
    return DriftTeam(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      githubBaseUrl: data.githubBaseUrl.present
          ? data.githubBaseUrl.value
          : this.githubBaseUrl,
      installationIds: data.installationIds.present
          ? data.installationIds.value
          : this.installationIds,
      aiEnabled: data.aiEnabled.present ? data.aiEnabled.value : this.aiEnabled,
      runNumber: data.runNumber.present ? data.runNumber.value : this.runNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftTeam(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('githubBaseUrl: $githubBaseUrl, ')
          ..write('installationIds: $installationIds, ')
          ..write('aiEnabled: $aiEnabled, ')
          ..write('runNumber: $runNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    githubBaseUrl,
    installationIds,
    aiEnabled,
    runNumber,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftTeam &&
          other.id == this.id &&
          other.name == this.name &&
          other.githubBaseUrl == this.githubBaseUrl &&
          other.installationIds == this.installationIds &&
          other.aiEnabled == this.aiEnabled &&
          other.runNumber == this.runNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TeamsCompanion extends UpdateCompanion<DriftTeam> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> githubBaseUrl;
  final Value<List<int>> installationIds;
  final Value<bool> aiEnabled;
  final Value<int> runNumber;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TeamsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.githubBaseUrl = const Value.absent(),
    this.installationIds = const Value.absent(),
    this.aiEnabled = const Value.absent(),
    this.runNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamsCompanion.insert({
    required String id,
    required String name,
    this.githubBaseUrl = const Value.absent(),
    required List<int> installationIds,
    required bool aiEnabled,
    this.runNumber = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       installationIds = Value(installationIds),
       aiEnabled = Value(aiEnabled),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DriftTeam> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? githubBaseUrl,
    Expression<String>? installationIds,
    Expression<bool>? aiEnabled,
    Expression<int>? runNumber,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (githubBaseUrl != null) 'github_base_url': githubBaseUrl,
      if (installationIds != null) 'installation_ids': installationIds,
      if (aiEnabled != null) 'ai_enabled': aiEnabled,
      if (runNumber != null) 'run_number': runNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? githubBaseUrl,
    Value<List<int>>? installationIds,
    Value<bool>? aiEnabled,
    Value<int>? runNumber,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TeamsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      githubBaseUrl: githubBaseUrl ?? this.githubBaseUrl,
      installationIds: installationIds ?? this.installationIds,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      runNumber: runNumber ?? this.runNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (githubBaseUrl.present) {
      map['github_base_url'] = Variable<String>(githubBaseUrl.value);
    }
    if (installationIds.present) {
      map['installation_ids'] = Variable<String>(
        $TeamsTable.$converterinstallationIds.toSql(installationIds.value),
      );
    }
    if (aiEnabled.present) {
      map['ai_enabled'] = Variable<bool>(aiEnabled.value);
    }
    if (runNumber.present) {
      map['run_number'] = Variable<int>(runNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('githubBaseUrl: $githubBaseUrl, ')
          ..write('installationIds: $installationIds, ')
          ..write('aiEnabled: $aiEnabled, ')
          ..write('runNumber: $runNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamMembersTable extends TeamMembers
    with TableInfo<$TeamMembersTable, DriftTeamMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamMembersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teams (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, teamId, userId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'team_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftTeamMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {teamId, userId},
  ];
  @override
  DriftTeamMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftTeamMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
    );
  }

  @override
  $TeamMembersTable createAlias(String alias) {
    return $TeamMembersTable(attachedDatabase, alias);
  }
}

class DriftTeamMember extends DataClass implements Insertable<DriftTeamMember> {
  final int id;
  final String teamId;
  final String userId;
  const DriftTeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['team_id'] = Variable<String>(teamId);
    map['user_id'] = Variable<String>(userId);
    return map;
  }

  TeamMembersCompanion toCompanion(bool nullToAbsent) {
    return TeamMembersCompanion(
      id: Value(id),
      teamId: Value(teamId),
      userId: Value(userId),
    );
  }

  factory DriftTeamMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftTeamMember(
      id: serializer.fromJson<int>(json['id']),
      teamId: serializer.fromJson<String>(json['teamId']),
      userId: serializer.fromJson<String>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'teamId': serializer.toJson<String>(teamId),
      'userId': serializer.toJson<String>(userId),
    };
  }

  DriftTeamMember copyWith({int? id, String? teamId, String? userId}) =>
      DriftTeamMember(
        id: id ?? this.id,
        teamId: teamId ?? this.teamId,
        userId: userId ?? this.userId,
      );
  DriftTeamMember copyWithCompanion(TeamMembersCompanion data) {
    return DriftTeamMember(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      userId: data.userId.present ? data.userId.value : this.userId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftTeamMember(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, teamId, userId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftTeamMember &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.userId == this.userId);
}

class TeamMembersCompanion extends UpdateCompanion<DriftTeamMember> {
  final Value<int> id;
  final Value<String> teamId;
  final Value<String> userId;
  const TeamMembersCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.userId = const Value.absent(),
  });
  TeamMembersCompanion.insert({
    this.id = const Value.absent(),
    required String teamId,
    required String userId,
  }) : teamId = Value(teamId),
       userId = Value(userId);
  static Insertable<DriftTeamMember> custom({
    Expression<int>? id,
    Expression<String>? teamId,
    Expression<String>? userId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (userId != null) 'user_id': userId,
    });
  }

  TeamMembersCompanion copyWith({
    Value<int>? id,
    Value<String>? teamId,
    Value<String>? userId,
  }) {
    return TeamMembersCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      userId: userId ?? this.userId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamMembersCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }
}

class $SecretsTable extends Secrets with TableInfo<$SecretsTable, DriftSecret> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SecretsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teams (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _encryptedValueMeta = const VerificationMeta(
    'encryptedValue',
  );
  @override
  late final GeneratedColumn<String> encryptedValue = GeneratedColumn<String>(
    'encrypted_value',
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
  @override
  List<GeneratedColumn> get $columns => [
    name,
    teamId,
    encryptedValue,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'secrets';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftSecret> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('encrypted_value')) {
      context.handle(
        _encryptedValueMeta,
        encryptedValue.isAcceptableOrUnknown(
          data['encrypted_value']!,
          _encryptedValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedValueMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {teamId, name};
  @override
  DriftSecret map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftSecret(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      encryptedValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SecretsTable createAlias(String alias) {
    return $SecretsTable(attachedDatabase, alias);
  }
}

class SecretsCompanion extends UpdateCompanion<DriftSecret> {
  final Value<String> name;
  final Value<String> teamId;
  final Value<String> encryptedValue;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SecretsCompanion({
    this.name = const Value.absent(),
    this.teamId = const Value.absent(),
    this.encryptedValue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SecretsCompanion.insert({
    required String name,
    required String teamId,
    required String encryptedValue,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       teamId = Value(teamId),
       encryptedValue = Value(encryptedValue),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DriftSecret> custom({
    Expression<String>? name,
    Expression<String>? teamId,
    Expression<String>? encryptedValue,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (teamId != null) 'team_id': teamId,
      if (encryptedValue != null) 'encrypted_value': encryptedValue,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SecretsCompanion copyWith({
    Value<String>? name,
    Value<String>? teamId,
    Value<String>? encryptedValue,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SecretsCompanion(
      name: name ?? this.name,
      teamId: teamId ?? this.teamId,
      encryptedValue: encryptedValue ?? this.encryptedValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (encryptedValue.present) {
      map['encrypted_value'] = Variable<String>(encryptedValue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SecretsCompanion(')
          ..write('name: $name, ')
          ..write('teamId: $teamId, ')
          ..write('encryptedValue: $encryptedValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WebhookTasksTable extends WebhookTasks
    with TableInfo<$WebhookTasksTable, DriftWebhookTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WebhookTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryIdMeta = const VerificationMeta(
    'deliveryId',
  );
  @override
  late final GeneratedColumn<String> deliveryId = GeneratedColumn<String>(
    'delivery_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _leaseUntilMeta = const VerificationMeta(
    'leaseUntil',
  );
  @override
  late final GeneratedColumn<DateTime> leaseUntil = GeneratedColumn<DateTime>(
    'lease_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deliveryId,
    eventType,
    payload,
    status,
    leaseUntil,
    nextRetryAt,
    retryCount,
    errorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'webhook_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftWebhookTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('delivery_id')) {
      context.handle(
        _deliveryIdMeta,
        deliveryId.isAcceptableOrUnknown(data['delivery_id']!, _deliveryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deliveryIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('lease_until')) {
      context.handle(
        _leaseUntilMeta,
        leaseUntil.isAcceptableOrUnknown(data['lease_until']!, _leaseUntilMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftWebhookTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftWebhookTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deliveryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      leaseUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lease_until'],
      ),
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WebhookTasksTable createAlias(String alias) {
    return $WebhookTasksTable(attachedDatabase, alias);
  }
}

class DriftWebhookTask extends DataClass
    implements Insertable<DriftWebhookTask> {
  final String id;
  final String deliveryId;
  final String eventType;
  final String payload;
  final String status;
  final DateTime? leaseUntil;
  final DateTime? nextRetryAt;
  final int retryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DriftWebhookTask({
    required this.id,
    required this.deliveryId,
    required this.eventType,
    required this.payload,
    required this.status,
    this.leaseUntil,
    this.nextRetryAt,
    required this.retryCount,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['delivery_id'] = Variable<String>(deliveryId);
    map['event_type'] = Variable<String>(eventType);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || leaseUntil != null) {
      map['lease_until'] = Variable<DateTime>(leaseUntil);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WebhookTasksCompanion toCompanion(bool nullToAbsent) {
    return WebhookTasksCompanion(
      id: Value(id),
      deliveryId: Value(deliveryId),
      eventType: Value(eventType),
      payload: Value(payload),
      status: Value(status),
      leaseUntil: leaseUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(leaseUntil),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      retryCount: Value(retryCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DriftWebhookTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftWebhookTask(
      id: serializer.fromJson<String>(json['id']),
      deliveryId: serializer.fromJson<String>(json['deliveryId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      leaseUntil: serializer.fromJson<DateTime?>(json['leaseUntil']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deliveryId': serializer.toJson<String>(deliveryId),
      'eventType': serializer.toJson<String>(eventType),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'leaseUntil': serializer.toJson<DateTime?>(leaseUntil),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DriftWebhookTask copyWith({
    String? id,
    String? deliveryId,
    String? eventType,
    String? payload,
    String? status,
    Value<DateTime?> leaseUntil = const Value.absent(),
    Value<DateTime?> nextRetryAt = const Value.absent(),
    int? retryCount,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DriftWebhookTask(
    id: id ?? this.id,
    deliveryId: deliveryId ?? this.deliveryId,
    eventType: eventType ?? this.eventType,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    leaseUntil: leaseUntil.present ? leaseUntil.value : this.leaseUntil,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    retryCount: retryCount ?? this.retryCount,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DriftWebhookTask copyWithCompanion(WebhookTasksCompanion data) {
    return DriftWebhookTask(
      id: data.id.present ? data.id.value : this.id,
      deliveryId: data.deliveryId.present
          ? data.deliveryId.value
          : this.deliveryId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      leaseUntil: data.leaseUntil.present
          ? data.leaseUntil.value
          : this.leaseUntil,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftWebhookTask(')
          ..write('id: $id, ')
          ..write('deliveryId: $deliveryId, ')
          ..write('eventType: $eventType, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('leaseUntil: $leaseUntil, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deliveryId,
    eventType,
    payload,
    status,
    leaseUntil,
    nextRetryAt,
    retryCount,
    errorMessage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftWebhookTask &&
          other.id == this.id &&
          other.deliveryId == this.deliveryId &&
          other.eventType == this.eventType &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.leaseUntil == this.leaseUntil &&
          other.nextRetryAt == this.nextRetryAt &&
          other.retryCount == this.retryCount &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WebhookTasksCompanion extends UpdateCompanion<DriftWebhookTask> {
  final Value<String> id;
  final Value<String> deliveryId;
  final Value<String> eventType;
  final Value<String> payload;
  final Value<String> status;
  final Value<DateTime?> leaseUntil;
  final Value<DateTime?> nextRetryAt;
  final Value<int> retryCount;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WebhookTasksCompanion({
    this.id = const Value.absent(),
    this.deliveryId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.leaseUntil = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WebhookTasksCompanion.insert({
    required String id,
    required String deliveryId,
    required String eventType,
    required String payload,
    this.status = const Value.absent(),
    this.leaseUntil = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deliveryId = Value(deliveryId),
       eventType = Value(eventType),
       payload = Value(payload),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DriftWebhookTask> custom({
    Expression<String>? id,
    Expression<String>? deliveryId,
    Expression<String>? eventType,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<DateTime>? leaseUntil,
    Expression<DateTime>? nextRetryAt,
    Expression<int>? retryCount,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deliveryId != null) 'delivery_id': deliveryId,
      if (eventType != null) 'event_type': eventType,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (leaseUntil != null) 'lease_until': leaseUntil,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WebhookTasksCompanion copyWith({
    Value<String>? id,
    Value<String>? deliveryId,
    Value<String>? eventType,
    Value<String>? payload,
    Value<String>? status,
    Value<DateTime?>? leaseUntil,
    Value<DateTime?>? nextRetryAt,
    Value<int>? retryCount,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WebhookTasksCompanion(
      id: id ?? this.id,
      deliveryId: deliveryId ?? this.deliveryId,
      eventType: eventType ?? this.eventType,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      leaseUntil: leaseUntil ?? this.leaseUntil,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deliveryId.present) {
      map['delivery_id'] = Variable<String>(deliveryId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (leaseUntil.present) {
      map['lease_until'] = Variable<DateTime>(leaseUntil.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WebhookTasksCompanion(')
          ..write('id: $id, ')
          ..write('deliveryId: $deliveryId, ')
          ..write('eventType: $eventType, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('leaseUntil: $leaseUntil, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkerHeartbeatsTable extends WorkerHeartbeats
    with TableInfo<$WorkerHeartbeatsTable, DriftWorkerHeartbeat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkerHeartbeatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    version,
    platform,
    status,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'worker_heartbeats';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftWorkerHeartbeat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftWorkerHeartbeat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftWorkerHeartbeat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
    );
  }

  @override
  $WorkerHeartbeatsTable createAlias(String alias) {
    return $WorkerHeartbeatsTable(attachedDatabase, alias);
  }
}

class DriftWorkerHeartbeat extends DataClass
    implements Insertable<DriftWorkerHeartbeat> {
  final String id;
  final String? version;
  final String? platform;
  final String? status;
  final DateTime lastSeenAt;
  const DriftWorkerHeartbeat({
    required this.id,
    this.version,
    this.platform,
    this.status,
    required this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    if (!nullToAbsent || platform != null) {
      map['platform'] = Variable<String>(platform);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    return map;
  }

  WorkerHeartbeatsCompanion toCompanion(bool nullToAbsent) {
    return WorkerHeartbeatsCompanion(
      id: Value(id),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      platform: platform == null && nullToAbsent
          ? const Value.absent()
          : Value(platform),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      lastSeenAt: Value(lastSeenAt),
    );
  }

  factory DriftWorkerHeartbeat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftWorkerHeartbeat(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<String?>(json['version']),
      platform: serializer.fromJson<String?>(json['platform']),
      status: serializer.fromJson<String?>(json['status']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<String?>(version),
      'platform': serializer.toJson<String?>(platform),
      'status': serializer.toJson<String?>(status),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
    };
  }

  DriftWorkerHeartbeat copyWith({
    String? id,
    Value<String?> version = const Value.absent(),
    Value<String?> platform = const Value.absent(),
    Value<String?> status = const Value.absent(),
    DateTime? lastSeenAt,
  }) => DriftWorkerHeartbeat(
    id: id ?? this.id,
    version: version.present ? version.value : this.version,
    platform: platform.present ? platform.value : this.platform,
    status: status.present ? status.value : this.status,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
  );
  DriftWorkerHeartbeat copyWithCompanion(WorkerHeartbeatsCompanion data) {
    return DriftWorkerHeartbeat(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      platform: data.platform.present ? data.platform.value : this.platform,
      status: data.status.present ? data.status.value : this.status,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftWorkerHeartbeat(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('platform: $platform, ')
          ..write('status: $status, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, platform, status, lastSeenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftWorkerHeartbeat &&
          other.id == this.id &&
          other.version == this.version &&
          other.platform == this.platform &&
          other.status == this.status &&
          other.lastSeenAt == this.lastSeenAt);
}

class WorkerHeartbeatsCompanion extends UpdateCompanion<DriftWorkerHeartbeat> {
  final Value<String> id;
  final Value<String?> version;
  final Value<String?> platform;
  final Value<String?> status;
  final Value<DateTime> lastSeenAt;
  final Value<int> rowid;
  const WorkerHeartbeatsCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.platform = const Value.absent(),
    this.status = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkerHeartbeatsCompanion.insert({
    required String id,
    this.version = const Value.absent(),
    this.platform = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime lastSeenAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<DriftWorkerHeartbeat> custom({
    Expression<String>? id,
    Expression<String>? version,
    Expression<String>? platform,
    Expression<String>? status,
    Expression<DateTime>? lastSeenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (platform != null) 'platform': platform,
      if (status != null) 'status': status,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkerHeartbeatsCompanion copyWith({
    Value<String>? id,
    Value<String?>? version,
    Value<String?>? platform,
    Value<String?>? status,
    Value<DateTime>? lastSeenAt,
    Value<int>? rowid,
  }) {
    return WorkerHeartbeatsCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkerHeartbeatsCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('platform: $platform, ')
          ..write('status: $status, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserDevicesTable extends UserDevices
    with TableInfo<$UserDevicesTable, DriftUserDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teams (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _udidMeta = const VerificationMeta('udid');
  @override
  late final GeneratedColumn<String> udid = GeneratedColumn<String>(
    'udid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 25,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceProductMeta = const VerificationMeta(
    'deviceProduct',
  );
  @override
  late final GeneratedColumn<String> deviceProduct = GeneratedColumn<String>(
    'device_product',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceOsVersionMeta = const VerificationMeta(
    'deviceOsVersion',
  );
  @override
  late final GeneratedColumn<String> deviceOsVersion = GeneratedColumn<String>(
    'device_os_version',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    teamId,
    udid,
    deviceProduct,
    deviceOsVersion,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftUserDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('udid')) {
      context.handle(
        _udidMeta,
        udid.isAcceptableOrUnknown(data['udid']!, _udidMeta),
      );
    } else if (isInserting) {
      context.missing(_udidMeta);
    }
    if (data.containsKey('device_product')) {
      context.handle(
        _deviceProductMeta,
        deviceProduct.isAcceptableOrUnknown(
          data['device_product']!,
          _deviceProductMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceProductMeta);
    }
    if (data.containsKey('device_os_version')) {
      context.handle(
        _deviceOsVersionMeta,
        deviceOsVersion.isAcceptableOrUnknown(
          data['device_os_version']!,
          _deviceOsVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceOsVersionMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, teamId, udid},
  ];
  @override
  DriftUserDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftUserDevice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      udid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}udid'],
      )!,
      deviceProduct: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_product'],
      )!,
      deviceOsVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_os_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserDevicesTable createAlias(String alias) {
    return $UserDevicesTable(attachedDatabase, alias);
  }
}

class UserDevicesCompanion extends UpdateCompanion<DriftUserDevice> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> teamId;
  final Value<String> udid;
  final Value<String> deviceProduct;
  final Value<String> deviceOsVersion;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserDevicesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.teamId = const Value.absent(),
    this.udid = const Value.absent(),
    this.deviceProduct = const Value.absent(),
    this.deviceOsVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserDevicesCompanion.insert({
    required String id,
    required String userId,
    required String teamId,
    required String udid,
    required String deviceProduct,
    required String deviceOsVersion,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       teamId = Value(teamId),
       udid = Value(udid),
       deviceProduct = Value(deviceProduct),
       deviceOsVersion = Value(deviceOsVersion),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DriftUserDevice> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? teamId,
    Expression<String>? udid,
    Expression<String>? deviceProduct,
    Expression<String>? deviceOsVersion,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (teamId != null) 'team_id': teamId,
      if (udid != null) 'udid': udid,
      if (deviceProduct != null) 'device_product': deviceProduct,
      if (deviceOsVersion != null) 'device_os_version': deviceOsVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserDevicesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? teamId,
    Value<String>? udid,
    Value<String>? deviceProduct,
    Value<String>? deviceOsVersion,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserDevicesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      udid: udid ?? this.udid,
      deviceProduct: deviceProduct ?? this.deviceProduct,
      deviceOsVersion: deviceOsVersion ?? this.deviceOsVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (udid.present) {
      map['udid'] = Variable<String>(udid.value);
    }
    if (deviceProduct.present) {
      map['device_product'] = Variable<String>(deviceProduct.value);
    }
    if (deviceOsVersion.present) {
      map['device_os_version'] = Variable<String>(deviceOsVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserDevicesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('teamId: $teamId, ')
          ..write('udid: $udid, ')
          ..write('deviceProduct: $deviceProduct, ')
          ..write('deviceOsVersion: $deviceOsVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UdidRequestsTable extends UdidRequests
    with TableInfo<$UdidRequestsTable, DriftUdidRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UdidRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teams (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _udidMeta = const VerificationMeta('udid');
  @override
  late final GeneratedColumn<String> udid = GeneratedColumn<String>(
    'udid',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    teamId,
    udid,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'udid_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftUdidRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('udid')) {
      context.handle(
        _udidMeta,
        udid.isAcceptableOrUnknown(data['udid']!, _udidMeta),
      );
    } else if (isInserting) {
      context.missing(_udidMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftUdidRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftUdidRequest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      udid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}udid'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UdidRequestsTable createAlias(String alias) {
    return $UdidRequestsTable(attachedDatabase, alias);
  }
}

class UdidRequestsCompanion extends UpdateCompanion<DriftUdidRequest> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> teamId;
  final Value<String> udid;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UdidRequestsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.teamId = const Value.absent(),
    this.udid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UdidRequestsCompanion.insert({
    required String id,
    required String userId,
    required String teamId,
    required String udid,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       teamId = Value(teamId),
       udid = Value(udid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DriftUdidRequest> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? teamId,
    Expression<String>? udid,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (teamId != null) 'team_id': teamId,
      if (udid != null) 'udid': udid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UdidRequestsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? teamId,
    Value<String>? udid,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UdidRequestsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      udid: udid ?? this.udid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (udid.present) {
      map['udid'] = Variable<String>(udid.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UdidRequestsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('teamId: $teamId, ')
          ..write('udid: $udid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvitationsTable extends Invitations
    with TableInfo<$InvitationsTable, Invitation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvitationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES teams (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tokenMeta = const VerificationMeta('token');
  @override
  late final GeneratedColumn<String> token = GeneratedColumn<String>(
    'token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<InvitationStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<InvitationStatus>($InvitationsTable.$converterstatus);
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    teamId,
    token,
    status,
    expiresAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invitations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Invitation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_teamIdMeta);
    }
    if (data.containsKey('token')) {
      context.handle(
        _tokenMeta,
        token.isAcceptableOrUnknown(data['token']!, _tokenMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Invitation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Invitation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      token: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token'],
      )!,
      status: $InvitationsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InvitationsTable createAlias(String alias) {
    return $InvitationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<InvitationStatus, String, String> $converterstatus =
      const EnumNameConverter<InvitationStatus>(InvitationStatus.values);
}

class Invitation extends DataClass implements Insertable<Invitation> {
  final String id;
  final String email;
  final String teamId;
  final String token;
  final InvitationStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Invitation({
    required this.id,
    required this.email,
    required this.teamId,
    required this.token,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['team_id'] = Variable<String>(teamId);
    map['token'] = Variable<String>(token);
    {
      map['status'] = Variable<String>(
        $InvitationsTable.$converterstatus.toSql(status),
      );
    }
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InvitationsCompanion toCompanion(bool nullToAbsent) {
    return InvitationsCompanion(
      id: Value(id),
      email: Value(email),
      teamId: Value(teamId),
      token: Value(token),
      status: Value(status),
      expiresAt: Value(expiresAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Invitation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Invitation(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      teamId: serializer.fromJson<String>(json['teamId']),
      token: serializer.fromJson<String>(json['token']),
      status: $InvitationsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'teamId': serializer.toJson<String>(teamId),
      'token': serializer.toJson<String>(token),
      'status': serializer.toJson<String>(
        $InvitationsTable.$converterstatus.toJson(status),
      ),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Invitation copyWith({
    String? id,
    String? email,
    String? teamId,
    String? token,
    InvitationStatus? status,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Invitation(
    id: id ?? this.id,
    email: email ?? this.email,
    teamId: teamId ?? this.teamId,
    token: token ?? this.token,
    status: status ?? this.status,
    expiresAt: expiresAt ?? this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Invitation copyWithCompanion(InvitationsCompanion data) {
    return Invitation(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      token: data.token.present ? data.token.value : this.token,
      status: data.status.present ? data.status.value : this.status,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Invitation(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('teamId: $teamId, ')
          ..write('token: $token, ')
          ..write('status: $status, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    teamId,
    token,
    status,
    expiresAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Invitation &&
          other.id == this.id &&
          other.email == this.email &&
          other.teamId == this.teamId &&
          other.token == this.token &&
          other.status == this.status &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InvitationsCompanion extends UpdateCompanion<Invitation> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> teamId;
  final Value<String> token;
  final Value<InvitationStatus> status;
  final Value<DateTime> expiresAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InvitationsCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.teamId = const Value.absent(),
    this.token = const Value.absent(),
    this.status = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvitationsCompanion.insert({
    required String id,
    required String email,
    required String teamId,
    required String token,
    required InvitationStatus status,
    required DateTime expiresAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       teamId = Value(teamId),
       token = Value(token),
       status = Value(status),
       expiresAt = Value(expiresAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Invitation> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? teamId,
    Expression<String>? token,
    Expression<String>? status,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (teamId != null) 'team_id': teamId,
      if (token != null) 'token': token,
      if (status != null) 'status': status,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvitationsCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? teamId,
    Value<String>? token,
    Value<InvitationStatus>? status,
    Value<DateTime>? expiresAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InvitationsCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      teamId: teamId ?? this.teamId,
      token: token ?? this.token,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (token.present) {
      map['token'] = Variable<String>(token.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $InvitationsTable.$converterstatus.toSql(status.value),
      );
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvitationsCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('teamId: $teamId, ')
          ..write('token: $token, ')
          ..write('status: $status, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BuildJobsTable buildJobs = $BuildJobsTable(this);
  late final $BuildJobLogsTable buildJobLogs = $BuildJobLogsTable(this);
  late final $BuildStepsTable buildSteps = $BuildStepsTable(this);
  late final $BuildStepLogsTable buildStepLogs = $BuildStepLogsTable(this);
  late final $BuildRunsTable buildRuns = $BuildRunsTable(this);
  late final $TeamsTable teams = $TeamsTable(this);
  late final $TeamMembersTable teamMembers = $TeamMembersTable(this);
  late final $SecretsTable secrets = $SecretsTable(this);
  late final $WebhookTasksTable webhookTasks = $WebhookTasksTable(this);
  late final $WorkerHeartbeatsTable workerHeartbeats = $WorkerHeartbeatsTable(
    this,
  );
  late final $UserDevicesTable userDevices = $UserDevicesTable(this);
  late final $UdidRequestsTable udidRequests = $UdidRequestsTable(this);
  late final $InvitationsTable invitations = $InvitationsTable(this);
  late final BuildJobDao buildJobDao = BuildJobDao(this as AppDatabase);
  late final BuildRunDao buildRunDao = BuildRunDao(this as AppDatabase);
  late final TeamDao teamDao = TeamDao(this as AppDatabase);
  late final WebhookTaskDao webhookTaskDao = WebhookTaskDao(
    this as AppDatabase,
  );
  late final SecretDao secretDao = SecretDao(this as AppDatabase);
  late final WorkerHeartbeatDao workerHeartbeatDao = WorkerHeartbeatDao(
    this as AppDatabase,
  );
  late final DeviceDao deviceDao = DeviceDao(this as AppDatabase);
  late final UdidRequestDao udidRequestDao = UdidRequestDao(
    this as AppDatabase,
  );
  late final SeedDao seedDao = SeedDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    buildJobs,
    buildJobLogs,
    buildSteps,
    buildStepLogs,
    buildRuns,
    teams,
    teamMembers,
    secrets,
    webhookTasks,
    workerHeartbeats,
    userDevices,
    udidRequests,
    invitations,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'build_jobs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('build_runs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'teams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('team_members', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'teams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('secrets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'teams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_devices', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'teams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('udid_requests', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'teams',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('invitations', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BuildJobsTableCreateCompanionBuilder =
    BuildJobsCompanion Function({
      required String id,
      required BuildJobStatus status,
      required String owner,
      required String repo,
      required String workflowName,
      Value<String?> teamId,
      Value<String?> workflowId,
      required String workflowFileName,
      Value<String?> commitSha,
      Value<String?> commitMessage,
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
      Value<String?> runsOn,
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
      Value<String?> vmName,
      Value<String?> workerHost,
      Value<String?> installationId,
      Value<String?> checkRunId,
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
      Value<String> workflowFileName,
      Value<String?> commitSha,
      Value<String?> commitMessage,
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
      Value<String?> runsOn,
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
      Value<String?> vmName,
      Value<String?> workerHost,
      Value<String?> installationId,
      Value<String?> checkRunId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

final class $$BuildJobsTableReferences
    extends BaseReferences<_$AppDatabase, $BuildJobsTable, DriftBuildJob> {
  $$BuildJobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BuildRunsTable, List<DriftBuildRun>>
  _buildRunsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.buildRuns,
    aliasName: $_aliasNameGenerator(db.buildJobs.id, db.buildRuns.buildJobId),
  );

  $$BuildRunsTableProcessedTableManager get buildRunsRefs {
    final manager = $$BuildRunsTableTableManager(
      $_db,
      $_db.buildRuns,
    ).filter((f) => f.buildJobId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_buildRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get commitMessage => $composableBuilder(
    column: $table.commitMessage,
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

  ColumnFilters<String> get runsOn => $composableBuilder(
    column: $table.runsOn,
    builder: (column) => ColumnFilters(column),
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

  ColumnFilters<String> get vmName => $composableBuilder(
    column: $table.vmName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerHost => $composableBuilder(
    column: $table.workerHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkRunId => $composableBuilder(
    column: $table.checkRunId,
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

  Expression<bool> buildRunsRefs(
    Expression<bool> Function($$BuildRunsTableFilterComposer f) f,
  ) {
    final $$BuildRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.buildRuns,
      getReferencedColumn: (t) => t.buildJobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildRunsTableFilterComposer(
            $db: $db,
            $table: $db.buildRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get commitMessage => $composableBuilder(
    column: $table.commitMessage,
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

  ColumnOrderings<String> get runsOn => $composableBuilder(
    column: $table.runsOn,
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

  ColumnOrderings<String> get vmName => $composableBuilder(
    column: $table.vmName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerHost => $composableBuilder(
    column: $table.workerHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkRunId => $composableBuilder(
    column: $table.checkRunId,
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

  GeneratedColumn<String> get commitMessage => $composableBuilder(
    column: $table.commitMessage,
    builder: (column) => column,
  );

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

  GeneratedColumn<String> get runsOn =>
      $composableBuilder(column: $table.runsOn, builder: (column) => column);

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

  GeneratedColumn<String> get vmName =>
      $composableBuilder(column: $table.vmName, builder: (column) => column);

  GeneratedColumn<String> get workerHost => $composableBuilder(
    column: $table.workerHost,
    builder: (column) => column,
  );

  GeneratedColumn<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checkRunId => $composableBuilder(
    column: $table.checkRunId,
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

  Expression<T> buildRunsRefs<T extends Object>(
    Expression<T> Function($$BuildRunsTableAnnotationComposer a) f,
  ) {
    final $$BuildRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.buildRuns,
      getReferencedColumn: (t) => t.buildJobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.buildRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (DriftBuildJob, $$BuildJobsTableReferences),
          DriftBuildJob,
          PrefetchHooks Function({bool buildRunsRefs})
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
                Value<String> workflowFileName = const Value.absent(),
                Value<String?> commitSha = const Value.absent(),
                Value<String?> commitMessage = const Value.absent(),
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
                Value<String?> runsOn = const Value.absent(),
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
                Value<String?> vmName = const Value.absent(),
                Value<String?> workerHost = const Value.absent(),
                Value<String?> installationId = const Value.absent(),
                Value<String?> checkRunId = const Value.absent(),
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
                commitMessage: commitMessage,
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
                runsOn: runsOn,
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
                vmName: vmName,
                workerHost: workerHost,
                installationId: installationId,
                checkRunId: checkRunId,
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
                required String workflowFileName,
                Value<String?> commitSha = const Value.absent(),
                Value<String?> commitMessage = const Value.absent(),
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
                Value<String?> runsOn = const Value.absent(),
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
                Value<String?> vmName = const Value.absent(),
                Value<String?> workerHost = const Value.absent(),
                Value<String?> installationId = const Value.absent(),
                Value<String?> checkRunId = const Value.absent(),
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
                commitMessage: commitMessage,
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
                runsOn: runsOn,
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
                vmName: vmName,
                workerHost: workerHost,
                installationId: installationId,
                checkRunId: checkRunId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BuildJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({buildRunsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (buildRunsRefs) db.buildRuns],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (buildRunsRefs)
                    await $_getPrefetchedData<
                      DriftBuildJob,
                      $BuildJobsTable,
                      DriftBuildRun
                    >(
                      currentTable: table,
                      referencedTable: $$BuildJobsTableReferences
                          ._buildRunsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BuildJobsTableReferences(
                            db,
                            table,
                            p0,
                          ).buildRunsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.buildJobId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
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
      (DriftBuildJob, $$BuildJobsTableReferences),
      DriftBuildJob,
      PrefetchHooks Function({bool buildRunsRefs})
    >;
typedef $$BuildJobLogsTableCreateCompanionBuilder =
    BuildJobLogsCompanion Function({
      Value<int> id,
      required String runId,
      required String logContent,
      required DateTime createdAt,
    });
typedef $$BuildJobLogsTableUpdateCompanionBuilder =
    BuildJobLogsCompanion Function({
      Value<int> id,
      Value<String> runId,
      Value<String> logContent,
      Value<DateTime> createdAt,
    });

class $$BuildJobLogsTableFilterComposer
    extends Composer<_$AppDatabase, $BuildJobLogsTable> {
  $$BuildJobLogsTableFilterComposer({
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

  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logContent => $composableBuilder(
    column: $table.logContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BuildJobLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildJobLogsTable> {
  $$BuildJobLogsTableOrderingComposer({
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

  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logContent => $composableBuilder(
    column: $table.logContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BuildJobLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildJobLogsTable> {
  $$BuildJobLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<String> get logContent => $composableBuilder(
    column: $table.logContent,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BuildJobLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BuildJobLogsTable,
          DriftBuildJobLog,
          $$BuildJobLogsTableFilterComposer,
          $$BuildJobLogsTableOrderingComposer,
          $$BuildJobLogsTableAnnotationComposer,
          $$BuildJobLogsTableCreateCompanionBuilder,
          $$BuildJobLogsTableUpdateCompanionBuilder,
          (
            DriftBuildJobLog,
            BaseReferences<_$AppDatabase, $BuildJobLogsTable, DriftBuildJobLog>,
          ),
          DriftBuildJobLog,
          PrefetchHooks Function()
        > {
  $$BuildJobLogsTableTableManager(_$AppDatabase db, $BuildJobLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildJobLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildJobLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildJobLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> logContent = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BuildJobLogsCompanion(
                id: id,
                runId: runId,
                logContent: logContent,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String runId,
                required String logContent,
                required DateTime createdAt,
              }) => BuildJobLogsCompanion.insert(
                id: id,
                runId: runId,
                logContent: logContent,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BuildJobLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BuildJobLogsTable,
      DriftBuildJobLog,
      $$BuildJobLogsTableFilterComposer,
      $$BuildJobLogsTableOrderingComposer,
      $$BuildJobLogsTableAnnotationComposer,
      $$BuildJobLogsTableCreateCompanionBuilder,
      $$BuildJobLogsTableUpdateCompanionBuilder,
      (
        DriftBuildJobLog,
        BaseReferences<_$AppDatabase, $BuildJobLogsTable, DriftBuildJobLog>,
      ),
      DriftBuildJobLog,
      PrefetchHooks Function()
    >;
typedef $$BuildStepsTableCreateCompanionBuilder =
    BuildStepsCompanion Function({
      required String id,
      required String runId,
      required String name,
      required BuildJobStatus status,
      required int durationMs,
      required int stepOrder,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BuildStepsTableUpdateCompanionBuilder =
    BuildStepsCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> name,
      Value<BuildJobStatus> status,
      Value<int> durationMs,
      Value<int> stepOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BuildStepsTableFilterComposer
    extends Composer<_$AppDatabase, $BuildStepsTable> {
  $$BuildStepsTableFilterComposer({
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

  ColumnFilters<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BuildJobStatus, BuildJobStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepOrder => $composableBuilder(
    column: $table.stepOrder,
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
}

class $$BuildStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildStepsTable> {
  $$BuildStepsTableOrderingComposer({
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

  ColumnOrderings<String> get runId => $composableBuilder(
    column: $table.runId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepOrder => $composableBuilder(
    column: $table.stepOrder,
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
}

class $$BuildStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildStepsTable> {
  $$BuildStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get runId =>
      $composableBuilder(column: $table.runId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BuildJobStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stepOrder =>
      $composableBuilder(column: $table.stepOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BuildStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BuildStepsTable,
          DriftBuildStep,
          $$BuildStepsTableFilterComposer,
          $$BuildStepsTableOrderingComposer,
          $$BuildStepsTableAnnotationComposer,
          $$BuildStepsTableCreateCompanionBuilder,
          $$BuildStepsTableUpdateCompanionBuilder,
          (
            DriftBuildStep,
            BaseReferences<_$AppDatabase, $BuildStepsTable, DriftBuildStep>,
          ),
          DriftBuildStep,
          PrefetchHooks Function()
        > {
  $$BuildStepsTableTableManager(_$AppDatabase db, $BuildStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<BuildJobStatus> status = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> stepOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BuildStepsCompanion(
                id: id,
                runId: runId,
                name: name,
                status: status,
                durationMs: durationMs,
                stepOrder: stepOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String name,
                required BuildJobStatus status,
                required int durationMs,
                required int stepOrder,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BuildStepsCompanion.insert(
                id: id,
                runId: runId,
                name: name,
                status: status,
                durationMs: durationMs,
                stepOrder: stepOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BuildStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BuildStepsTable,
      DriftBuildStep,
      $$BuildStepsTableFilterComposer,
      $$BuildStepsTableOrderingComposer,
      $$BuildStepsTableAnnotationComposer,
      $$BuildStepsTableCreateCompanionBuilder,
      $$BuildStepsTableUpdateCompanionBuilder,
      (
        DriftBuildStep,
        BaseReferences<_$AppDatabase, $BuildStepsTable, DriftBuildStep>,
      ),
      DriftBuildStep,
      PrefetchHooks Function()
    >;
typedef $$BuildStepLogsTableCreateCompanionBuilder =
    BuildStepLogsCompanion Function({
      Value<int> id,
      required String stepId,
      required String logContent,
      required DateTime createdAt,
    });
typedef $$BuildStepLogsTableUpdateCompanionBuilder =
    BuildStepLogsCompanion Function({
      Value<int> id,
      Value<String> stepId,
      Value<String> logContent,
      Value<DateTime> createdAt,
    });

class $$BuildStepLogsTableFilterComposer
    extends Composer<_$AppDatabase, $BuildStepLogsTable> {
  $$BuildStepLogsTableFilterComposer({
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

  ColumnFilters<String> get stepId => $composableBuilder(
    column: $table.stepId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logContent => $composableBuilder(
    column: $table.logContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BuildStepLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildStepLogsTable> {
  $$BuildStepLogsTableOrderingComposer({
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

  ColumnOrderings<String> get stepId => $composableBuilder(
    column: $table.stepId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logContent => $composableBuilder(
    column: $table.logContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BuildStepLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildStepLogsTable> {
  $$BuildStepLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stepId =>
      $composableBuilder(column: $table.stepId, builder: (column) => column);

  GeneratedColumn<String> get logContent => $composableBuilder(
    column: $table.logContent,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BuildStepLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BuildStepLogsTable,
          DriftBuildStepLog,
          $$BuildStepLogsTableFilterComposer,
          $$BuildStepLogsTableOrderingComposer,
          $$BuildStepLogsTableAnnotationComposer,
          $$BuildStepLogsTableCreateCompanionBuilder,
          $$BuildStepLogsTableUpdateCompanionBuilder,
          (
            DriftBuildStepLog,
            BaseReferences<
              _$AppDatabase,
              $BuildStepLogsTable,
              DriftBuildStepLog
            >,
          ),
          DriftBuildStepLog,
          PrefetchHooks Function()
        > {
  $$BuildStepLogsTableTableManager(_$AppDatabase db, $BuildStepLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildStepLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildStepLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildStepLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> stepId = const Value.absent(),
                Value<String> logContent = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BuildStepLogsCompanion(
                id: id,
                stepId: stepId,
                logContent: logContent,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String stepId,
                required String logContent,
                required DateTime createdAt,
              }) => BuildStepLogsCompanion.insert(
                id: id,
                stepId: stepId,
                logContent: logContent,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BuildStepLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BuildStepLogsTable,
      DriftBuildStepLog,
      $$BuildStepLogsTableFilterComposer,
      $$BuildStepLogsTableOrderingComposer,
      $$BuildStepLogsTableAnnotationComposer,
      $$BuildStepLogsTableCreateCompanionBuilder,
      $$BuildStepLogsTableUpdateCompanionBuilder,
      (
        DriftBuildStepLog,
        BaseReferences<_$AppDatabase, $BuildStepLogsTable, DriftBuildStepLog>,
      ),
      DriftBuildStepLog,
      PrefetchHooks Function()
    >;
typedef $$BuildRunsTableCreateCompanionBuilder =
    BuildRunsCompanion Function({
      required String id,
      required String buildJobId,
      required String status,
      Value<String?> conclusion,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BuildRunsTableUpdateCompanionBuilder =
    BuildRunsCompanion Function({
      Value<String> id,
      Value<String> buildJobId,
      Value<String> status,
      Value<String?> conclusion,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BuildRunsTableReferences
    extends BaseReferences<_$AppDatabase, $BuildRunsTable, DriftBuildRun> {
  $$BuildRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BuildJobsTable _buildJobIdTable(_$AppDatabase db) =>
      db.buildJobs.createAlias(
        $_aliasNameGenerator(db.buildRuns.buildJobId, db.buildJobs.id),
      );

  $$BuildJobsTableProcessedTableManager get buildJobId {
    final $_column = $_itemColumn<String>('build_job_id')!;

    final manager = $$BuildJobsTableTableManager(
      $_db,
      $_db.buildJobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_buildJobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BuildRunsTableFilterComposer
    extends Composer<_$AppDatabase, $BuildRunsTable> {
  $$BuildRunsTableFilterComposer({
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conclusion => $composableBuilder(
    column: $table.conclusion,
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

  $$BuildJobsTableFilterComposer get buildJobId {
    final $$BuildJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.buildJobId,
      referencedTable: $db.buildJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildJobsTableFilterComposer(
            $db: $db,
            $table: $db.buildJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BuildRunsTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildRunsTable> {
  $$BuildRunsTableOrderingComposer({
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

  ColumnOrderings<String> get conclusion => $composableBuilder(
    column: $table.conclusion,
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

  $$BuildJobsTableOrderingComposer get buildJobId {
    final $$BuildJobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.buildJobId,
      referencedTable: $db.buildJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildJobsTableOrderingComposer(
            $db: $db,
            $table: $db.buildJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BuildRunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildRunsTable> {
  $$BuildRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get conclusion => $composableBuilder(
    column: $table.conclusion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BuildJobsTableAnnotationComposer get buildJobId {
    final $$BuildJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.buildJobId,
      referencedTable: $db.buildJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.buildJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BuildRunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BuildRunsTable,
          DriftBuildRun,
          $$BuildRunsTableFilterComposer,
          $$BuildRunsTableOrderingComposer,
          $$BuildRunsTableAnnotationComposer,
          $$BuildRunsTableCreateCompanionBuilder,
          $$BuildRunsTableUpdateCompanionBuilder,
          (DriftBuildRun, $$BuildRunsTableReferences),
          DriftBuildRun,
          PrefetchHooks Function({bool buildJobId})
        > {
  $$BuildRunsTableTableManager(_$AppDatabase db, $BuildRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> buildJobId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> conclusion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BuildRunsCompanion(
                id: id,
                buildJobId: buildJobId,
                status: status,
                conclusion: conclusion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String buildJobId,
                required String status,
                Value<String?> conclusion = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BuildRunsCompanion.insert(
                id: id,
                buildJobId: buildJobId,
                status: status,
                conclusion: conclusion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BuildRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({buildJobId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (buildJobId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.buildJobId,
                                referencedTable: $$BuildRunsTableReferences
                                    ._buildJobIdTable(db),
                                referencedColumn: $$BuildRunsTableReferences
                                    ._buildJobIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BuildRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BuildRunsTable,
      DriftBuildRun,
      $$BuildRunsTableFilterComposer,
      $$BuildRunsTableOrderingComposer,
      $$BuildRunsTableAnnotationComposer,
      $$BuildRunsTableCreateCompanionBuilder,
      $$BuildRunsTableUpdateCompanionBuilder,
      (DriftBuildRun, $$BuildRunsTableReferences),
      DriftBuildRun,
      PrefetchHooks Function({bool buildJobId})
    >;
typedef $$TeamsTableCreateCompanionBuilder =
    TeamsCompanion Function({
      required String id,
      required String name,
      Value<String?> githubBaseUrl,
      required List<int> installationIds,
      required bool aiEnabled,
      Value<int> runNumber,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TeamsTableUpdateCompanionBuilder =
    TeamsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> githubBaseUrl,
      Value<List<int>> installationIds,
      Value<bool> aiEnabled,
      Value<int> runNumber,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TeamsTableReferences
    extends BaseReferences<_$AppDatabase, $TeamsTable, DriftTeam> {
  $$TeamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TeamMembersTable, List<DriftTeamMember>>
  _teamMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.teamMembers,
    aliasName: $_aliasNameGenerator(db.teams.id, db.teamMembers.teamId),
  );

  $$TeamMembersTableProcessedTableManager get teamMembersRefs {
    final manager = $$TeamMembersTableTableManager(
      $_db,
      $_db.teamMembers,
    ).filter((f) => f.teamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_teamMembersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SecretsTable, List<DriftSecret>>
  _secretsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.secrets,
    aliasName: $_aliasNameGenerator(db.teams.id, db.secrets.teamId),
  );

  $$SecretsTableProcessedTableManager get secretsRefs {
    final manager = $$SecretsTableTableManager(
      $_db,
      $_db.secrets,
    ).filter((f) => f.teamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_secretsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserDevicesTable, List<DriftUserDevice>>
  _userDevicesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userDevices,
    aliasName: $_aliasNameGenerator(db.teams.id, db.userDevices.teamId),
  );

  $$UserDevicesTableProcessedTableManager get userDevicesRefs {
    final manager = $$UserDevicesTableTableManager(
      $_db,
      $_db.userDevices,
    ).filter((f) => f.teamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_userDevicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UdidRequestsTable, List<DriftUdidRequest>>
  _udidRequestsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.udidRequests,
    aliasName: $_aliasNameGenerator(db.teams.id, db.udidRequests.teamId),
  );

  $$UdidRequestsTableProcessedTableManager get udidRequestsRefs {
    final manager = $$UdidRequestsTableTableManager(
      $_db,
      $_db.udidRequests,
    ).filter((f) => f.teamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_udidRequestsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InvitationsTable, List<Invitation>>
  _invitationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.invitations,
    aliasName: $_aliasNameGenerator(db.teams.id, db.invitations.teamId),
  );

  $$InvitationsTableProcessedTableManager get invitationsRefs {
    final manager = $$InvitationsTableTableManager(
      $_db,
      $_db.invitations,
    ).filter((f) => f.teamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_invitationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TeamsTableFilterComposer extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get githubBaseUrl => $composableBuilder(
    column: $table.githubBaseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<int>, List<int>, String>
  get installationIds => $composableBuilder(
    column: $table.installationIds,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get aiEnabled => $composableBuilder(
    column: $table.aiEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runNumber => $composableBuilder(
    column: $table.runNumber,
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

  Expression<bool> teamMembersRefs(
    Expression<bool> Function($$TeamMembersTableFilterComposer f) f,
  ) {
    final $$TeamMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamMembers,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamMembersTableFilterComposer(
            $db: $db,
            $table: $db.teamMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> secretsRefs(
    Expression<bool> Function($$SecretsTableFilterComposer f) f,
  ) {
    final $$SecretsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.secrets,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SecretsTableFilterComposer(
            $db: $db,
            $table: $db.secrets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> userDevicesRefs(
    Expression<bool> Function($$UserDevicesTableFilterComposer f) f,
  ) {
    final $$UserDevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userDevices,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserDevicesTableFilterComposer(
            $db: $db,
            $table: $db.userDevices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> udidRequestsRefs(
    Expression<bool> Function($$UdidRequestsTableFilterComposer f) f,
  ) {
    final $$UdidRequestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.udidRequests,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UdidRequestsTableFilterComposer(
            $db: $db,
            $table: $db.udidRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> invitationsRefs(
    Expression<bool> Function($$InvitationsTableFilterComposer f) f,
  ) {
    final $$InvitationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invitations,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvitationsTableFilterComposer(
            $db: $db,
            $table: $db.invitations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeamsTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get githubBaseUrl => $composableBuilder(
    column: $table.githubBaseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installationIds => $composableBuilder(
    column: $table.installationIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get aiEnabled => $composableBuilder(
    column: $table.aiEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runNumber => $composableBuilder(
    column: $table.runNumber,
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
}

class $$TeamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get githubBaseUrl => $composableBuilder(
    column: $table.githubBaseUrl,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<int>, String> get installationIds =>
      $composableBuilder(
        column: $table.installationIds,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get aiEnabled =>
      $composableBuilder(column: $table.aiEnabled, builder: (column) => column);

  GeneratedColumn<int> get runNumber =>
      $composableBuilder(column: $table.runNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> teamMembersRefs<T extends Object>(
    Expression<T> Function($$TeamMembersTableAnnotationComposer a) f,
  ) {
    final $$TeamMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teamMembers,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.teamMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> secretsRefs<T extends Object>(
    Expression<T> Function($$SecretsTableAnnotationComposer a) f,
  ) {
    final $$SecretsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.secrets,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SecretsTableAnnotationComposer(
            $db: $db,
            $table: $db.secrets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> userDevicesRefs<T extends Object>(
    Expression<T> Function($$UserDevicesTableAnnotationComposer a) f,
  ) {
    final $$UserDevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userDevices,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserDevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.userDevices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> udidRequestsRefs<T extends Object>(
    Expression<T> Function($$UdidRequestsTableAnnotationComposer a) f,
  ) {
    final $$UdidRequestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.udidRequests,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UdidRequestsTableAnnotationComposer(
            $db: $db,
            $table: $db.udidRequests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> invitationsRefs<T extends Object>(
    Expression<T> Function($$InvitationsTableAnnotationComposer a) f,
  ) {
    final $$InvitationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.invitations,
      getReferencedColumn: (t) => t.teamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InvitationsTableAnnotationComposer(
            $db: $db,
            $table: $db.invitations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TeamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamsTable,
          DriftTeam,
          $$TeamsTableFilterComposer,
          $$TeamsTableOrderingComposer,
          $$TeamsTableAnnotationComposer,
          $$TeamsTableCreateCompanionBuilder,
          $$TeamsTableUpdateCompanionBuilder,
          (DriftTeam, $$TeamsTableReferences),
          DriftTeam,
          PrefetchHooks Function({
            bool teamMembersRefs,
            bool secretsRefs,
            bool userDevicesRefs,
            bool udidRequestsRefs,
            bool invitationsRefs,
          })
        > {
  $$TeamsTableTableManager(_$AppDatabase db, $TeamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> githubBaseUrl = const Value.absent(),
                Value<List<int>> installationIds = const Value.absent(),
                Value<bool> aiEnabled = const Value.absent(),
                Value<int> runNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TeamsCompanion(
                id: id,
                name: name,
                githubBaseUrl: githubBaseUrl,
                installationIds: installationIds,
                aiEnabled: aiEnabled,
                runNumber: runNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> githubBaseUrl = const Value.absent(),
                required List<int> installationIds,
                required bool aiEnabled,
                Value<int> runNumber = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TeamsCompanion.insert(
                id: id,
                name: name,
                githubBaseUrl: githubBaseUrl,
                installationIds: installationIds,
                aiEnabled: aiEnabled,
                runNumber: runNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TeamsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                teamMembersRefs = false,
                secretsRefs = false,
                userDevicesRefs = false,
                udidRequestsRefs = false,
                invitationsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (teamMembersRefs) db.teamMembers,
                    if (secretsRefs) db.secrets,
                    if (userDevicesRefs) db.userDevices,
                    if (udidRequestsRefs) db.udidRequests,
                    if (invitationsRefs) db.invitations,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (teamMembersRefs)
                        await $_getPrefetchedData<
                          DriftTeam,
                          $TeamsTable,
                          DriftTeamMember
                        >(
                          currentTable: table,
                          referencedTable: $$TeamsTableReferences
                              ._teamMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamsTableReferences(
                                db,
                                table,
                                p0,
                              ).teamMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (secretsRefs)
                        await $_getPrefetchedData<
                          DriftTeam,
                          $TeamsTable,
                          DriftSecret
                        >(
                          currentTable: table,
                          referencedTable: $$TeamsTableReferences
                              ._secretsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamsTableReferences(db, table, p0).secretsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userDevicesRefs)
                        await $_getPrefetchedData<
                          DriftTeam,
                          $TeamsTable,
                          DriftUserDevice
                        >(
                          currentTable: table,
                          referencedTable: $$TeamsTableReferences
                              ._userDevicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamsTableReferences(
                                db,
                                table,
                                p0,
                              ).userDevicesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (udidRequestsRefs)
                        await $_getPrefetchedData<
                          DriftTeam,
                          $TeamsTable,
                          DriftUdidRequest
                        >(
                          currentTable: table,
                          referencedTable: $$TeamsTableReferences
                              ._udidRequestsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamsTableReferences(
                                db,
                                table,
                                p0,
                              ).udidRequestsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (invitationsRefs)
                        await $_getPrefetchedData<
                          DriftTeam,
                          $TeamsTable,
                          Invitation
                        >(
                          currentTable: table,
                          referencedTable: $$TeamsTableReferences
                              ._invitationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TeamsTableReferences(
                                db,
                                table,
                                p0,
                              ).invitationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.teamId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TeamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamsTable,
      DriftTeam,
      $$TeamsTableFilterComposer,
      $$TeamsTableOrderingComposer,
      $$TeamsTableAnnotationComposer,
      $$TeamsTableCreateCompanionBuilder,
      $$TeamsTableUpdateCompanionBuilder,
      (DriftTeam, $$TeamsTableReferences),
      DriftTeam,
      PrefetchHooks Function({
        bool teamMembersRefs,
        bool secretsRefs,
        bool userDevicesRefs,
        bool udidRequestsRefs,
        bool invitationsRefs,
      })
    >;
typedef $$TeamMembersTableCreateCompanionBuilder =
    TeamMembersCompanion Function({
      Value<int> id,
      required String teamId,
      required String userId,
    });
typedef $$TeamMembersTableUpdateCompanionBuilder =
    TeamMembersCompanion Function({
      Value<int> id,
      Value<String> teamId,
      Value<String> userId,
    });

final class $$TeamMembersTableReferences
    extends BaseReferences<_$AppDatabase, $TeamMembersTable, DriftTeamMember> {
  $$TeamMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TeamsTable _teamIdTable(_$AppDatabase db) => db.teams.createAlias(
    $_aliasNameGenerator(db.teamMembers.teamId, db.teams.id),
  );

  $$TeamsTableProcessedTableManager get teamId {
    final $_column = $_itemColumn<String>('team_id')!;

    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TeamMembersTableFilterComposer
    extends Composer<_$AppDatabase, $TeamMembersTable> {
  $$TeamMembersTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  $$TeamsTableFilterComposer get teamId {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamMembersTable> {
  $$TeamMembersTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  $$TeamsTableOrderingComposer get teamId {
    final $$TeamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableOrderingComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamMembersTable> {
  $$TeamMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  $$TeamsTableAnnotationComposer get teamId {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TeamMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeamMembersTable,
          DriftTeamMember,
          $$TeamMembersTableFilterComposer,
          $$TeamMembersTableOrderingComposer,
          $$TeamMembersTableAnnotationComposer,
          $$TeamMembersTableCreateCompanionBuilder,
          $$TeamMembersTableUpdateCompanionBuilder,
          (DriftTeamMember, $$TeamMembersTableReferences),
          DriftTeamMember,
          PrefetchHooks Function({bool teamId})
        > {
  $$TeamMembersTableTableManager(_$AppDatabase db, $TeamMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<String> userId = const Value.absent(),
              }) =>
                  TeamMembersCompanion(id: id, teamId: teamId, userId: userId),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String teamId,
                required String userId,
              }) => TeamMembersCompanion.insert(
                id: id,
                teamId: teamId,
                userId: userId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TeamMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({teamId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (teamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.teamId,
                                referencedTable: $$TeamMembersTableReferences
                                    ._teamIdTable(db),
                                referencedColumn: $$TeamMembersTableReferences
                                    ._teamIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TeamMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeamMembersTable,
      DriftTeamMember,
      $$TeamMembersTableFilterComposer,
      $$TeamMembersTableOrderingComposer,
      $$TeamMembersTableAnnotationComposer,
      $$TeamMembersTableCreateCompanionBuilder,
      $$TeamMembersTableUpdateCompanionBuilder,
      (DriftTeamMember, $$TeamMembersTableReferences),
      DriftTeamMember,
      PrefetchHooks Function({bool teamId})
    >;
typedef $$SecretsTableCreateCompanionBuilder =
    SecretsCompanion Function({
      required String name,
      required String teamId,
      required String encryptedValue,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SecretsTableUpdateCompanionBuilder =
    SecretsCompanion Function({
      Value<String> name,
      Value<String> teamId,
      Value<String> encryptedValue,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SecretsTableReferences
    extends BaseReferences<_$AppDatabase, $SecretsTable, DriftSecret> {
  $$SecretsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TeamsTable _teamIdTable(_$AppDatabase db) => db.teams.createAlias(
    $_aliasNameGenerator(db.secrets.teamId, db.teams.id),
  );

  $$TeamsTableProcessedTableManager get teamId {
    final $_column = $_itemColumn<String>('team_id')!;

    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SecretsTableFilterComposer
    extends Composer<_$AppDatabase, $SecretsTable> {
  $$SecretsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedValue => $composableBuilder(
    column: $table.encryptedValue,
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

  $$TeamsTableFilterComposer get teamId {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SecretsTableOrderingComposer
    extends Composer<_$AppDatabase, $SecretsTable> {
  $$SecretsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedValue => $composableBuilder(
    column: $table.encryptedValue,
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

  $$TeamsTableOrderingComposer get teamId {
    final $$TeamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableOrderingComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SecretsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SecretsTable> {
  $$SecretsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get encryptedValue => $composableBuilder(
    column: $table.encryptedValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TeamsTableAnnotationComposer get teamId {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SecretsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SecretsTable,
          DriftSecret,
          $$SecretsTableFilterComposer,
          $$SecretsTableOrderingComposer,
          $$SecretsTableAnnotationComposer,
          $$SecretsTableCreateCompanionBuilder,
          $$SecretsTableUpdateCompanionBuilder,
          (DriftSecret, $$SecretsTableReferences),
          DriftSecret,
          PrefetchHooks Function({bool teamId})
        > {
  $$SecretsTableTableManager(_$AppDatabase db, $SecretsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SecretsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SecretsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SecretsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<String> encryptedValue = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SecretsCompanion(
                name: name,
                teamId: teamId,
                encryptedValue: encryptedValue,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String teamId,
                required String encryptedValue,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SecretsCompanion.insert(
                name: name,
                teamId: teamId,
                encryptedValue: encryptedValue,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SecretsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({teamId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (teamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.teamId,
                                referencedTable: $$SecretsTableReferences
                                    ._teamIdTable(db),
                                referencedColumn: $$SecretsTableReferences
                                    ._teamIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SecretsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SecretsTable,
      DriftSecret,
      $$SecretsTableFilterComposer,
      $$SecretsTableOrderingComposer,
      $$SecretsTableAnnotationComposer,
      $$SecretsTableCreateCompanionBuilder,
      $$SecretsTableUpdateCompanionBuilder,
      (DriftSecret, $$SecretsTableReferences),
      DriftSecret,
      PrefetchHooks Function({bool teamId})
    >;
typedef $$WebhookTasksTableCreateCompanionBuilder =
    WebhookTasksCompanion Function({
      required String id,
      required String deliveryId,
      required String eventType,
      required String payload,
      Value<String> status,
      Value<DateTime?> leaseUntil,
      Value<DateTime?> nextRetryAt,
      Value<int> retryCount,
      Value<String?> errorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WebhookTasksTableUpdateCompanionBuilder =
    WebhookTasksCompanion Function({
      Value<String> id,
      Value<String> deliveryId,
      Value<String> eventType,
      Value<String> payload,
      Value<String> status,
      Value<DateTime?> leaseUntil,
      Value<DateTime?> nextRetryAt,
      Value<int> retryCount,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$WebhookTasksTableFilterComposer
    extends Composer<_$AppDatabase, $WebhookTasksTable> {
  $$WebhookTasksTableFilterComposer({
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

  ColumnFilters<String> get deliveryId => $composableBuilder(
    column: $table.deliveryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leaseUntil => $composableBuilder(
    column: $table.leaseUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
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
}

class $$WebhookTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $WebhookTasksTable> {
  $$WebhookTasksTableOrderingComposer({
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

  ColumnOrderings<String> get deliveryId => $composableBuilder(
    column: $table.deliveryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leaseUntil => $composableBuilder(
    column: $table.leaseUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
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
}

class $$WebhookTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $WebhookTasksTable> {
  $$WebhookTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deliveryId => $composableBuilder(
    column: $table.deliveryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get leaseUntil => $composableBuilder(
    column: $table.leaseUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WebhookTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WebhookTasksTable,
          DriftWebhookTask,
          $$WebhookTasksTableFilterComposer,
          $$WebhookTasksTableOrderingComposer,
          $$WebhookTasksTableAnnotationComposer,
          $$WebhookTasksTableCreateCompanionBuilder,
          $$WebhookTasksTableUpdateCompanionBuilder,
          (
            DriftWebhookTask,
            BaseReferences<_$AppDatabase, $WebhookTasksTable, DriftWebhookTask>,
          ),
          DriftWebhookTask,
          PrefetchHooks Function()
        > {
  $$WebhookTasksTableTableManager(_$AppDatabase db, $WebhookTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WebhookTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WebhookTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WebhookTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deliveryId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> leaseUntil = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WebhookTasksCompanion(
                id: id,
                deliveryId: deliveryId,
                eventType: eventType,
                payload: payload,
                status: status,
                leaseUntil: leaseUntil,
                nextRetryAt: nextRetryAt,
                retryCount: retryCount,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deliveryId,
                required String eventType,
                required String payload,
                Value<String> status = const Value.absent(),
                Value<DateTime?> leaseUntil = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WebhookTasksCompanion.insert(
                id: id,
                deliveryId: deliveryId,
                eventType: eventType,
                payload: payload,
                status: status,
                leaseUntil: leaseUntil,
                nextRetryAt: nextRetryAt,
                retryCount: retryCount,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WebhookTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WebhookTasksTable,
      DriftWebhookTask,
      $$WebhookTasksTableFilterComposer,
      $$WebhookTasksTableOrderingComposer,
      $$WebhookTasksTableAnnotationComposer,
      $$WebhookTasksTableCreateCompanionBuilder,
      $$WebhookTasksTableUpdateCompanionBuilder,
      (
        DriftWebhookTask,
        BaseReferences<_$AppDatabase, $WebhookTasksTable, DriftWebhookTask>,
      ),
      DriftWebhookTask,
      PrefetchHooks Function()
    >;
typedef $$WorkerHeartbeatsTableCreateCompanionBuilder =
    WorkerHeartbeatsCompanion Function({
      required String id,
      Value<String?> version,
      Value<String?> platform,
      Value<String?> status,
      required DateTime lastSeenAt,
      Value<int> rowid,
    });
typedef $$WorkerHeartbeatsTableUpdateCompanionBuilder =
    WorkerHeartbeatsCompanion Function({
      Value<String> id,
      Value<String?> version,
      Value<String?> platform,
      Value<String?> status,
      Value<DateTime> lastSeenAt,
      Value<int> rowid,
    });

class $$WorkerHeartbeatsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkerHeartbeatsTable> {
  $$WorkerHeartbeatsTableFilterComposer({
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

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkerHeartbeatsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkerHeartbeatsTable> {
  $$WorkerHeartbeatsTableOrderingComposer({
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

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkerHeartbeatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkerHeartbeatsTable> {
  $$WorkerHeartbeatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );
}

class $$WorkerHeartbeatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkerHeartbeatsTable,
          DriftWorkerHeartbeat,
          $$WorkerHeartbeatsTableFilterComposer,
          $$WorkerHeartbeatsTableOrderingComposer,
          $$WorkerHeartbeatsTableAnnotationComposer,
          $$WorkerHeartbeatsTableCreateCompanionBuilder,
          $$WorkerHeartbeatsTableUpdateCompanionBuilder,
          (
            DriftWorkerHeartbeat,
            BaseReferences<
              _$AppDatabase,
              $WorkerHeartbeatsTable,
              DriftWorkerHeartbeat
            >,
          ),
          DriftWorkerHeartbeat,
          PrefetchHooks Function()
        > {
  $$WorkerHeartbeatsTableTableManager(
    _$AppDatabase db,
    $WorkerHeartbeatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkerHeartbeatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkerHeartbeatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkerHeartbeatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String?> platform = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkerHeartbeatsCompanion(
                id: id,
                version: version,
                platform: platform,
                status: status,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> version = const Value.absent(),
                Value<String?> platform = const Value.absent(),
                Value<String?> status = const Value.absent(),
                required DateTime lastSeenAt,
                Value<int> rowid = const Value.absent(),
              }) => WorkerHeartbeatsCompanion.insert(
                id: id,
                version: version,
                platform: platform,
                status: status,
                lastSeenAt: lastSeenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkerHeartbeatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkerHeartbeatsTable,
      DriftWorkerHeartbeat,
      $$WorkerHeartbeatsTableFilterComposer,
      $$WorkerHeartbeatsTableOrderingComposer,
      $$WorkerHeartbeatsTableAnnotationComposer,
      $$WorkerHeartbeatsTableCreateCompanionBuilder,
      $$WorkerHeartbeatsTableUpdateCompanionBuilder,
      (
        DriftWorkerHeartbeat,
        BaseReferences<
          _$AppDatabase,
          $WorkerHeartbeatsTable,
          DriftWorkerHeartbeat
        >,
      ),
      DriftWorkerHeartbeat,
      PrefetchHooks Function()
    >;
typedef $$UserDevicesTableCreateCompanionBuilder =
    UserDevicesCompanion Function({
      required String id,
      required String userId,
      required String teamId,
      required String udid,
      required String deviceProduct,
      required String deviceOsVersion,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UserDevicesTableUpdateCompanionBuilder =
    UserDevicesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> teamId,
      Value<String> udid,
      Value<String> deviceProduct,
      Value<String> deviceOsVersion,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$UserDevicesTableReferences
    extends BaseReferences<_$AppDatabase, $UserDevicesTable, DriftUserDevice> {
  $$UserDevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TeamsTable _teamIdTable(_$AppDatabase db) => db.teams.createAlias(
    $_aliasNameGenerator(db.userDevices.teamId, db.teams.id),
  );

  $$TeamsTableProcessedTableManager get teamId {
    final $_column = $_itemColumn<String>('team_id')!;

    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserDevicesTableFilterComposer
    extends Composer<_$AppDatabase, $UserDevicesTable> {
  $$UserDevicesTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get udid => $composableBuilder(
    column: $table.udid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceProduct => $composableBuilder(
    column: $table.deviceProduct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceOsVersion => $composableBuilder(
    column: $table.deviceOsVersion,
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

  $$TeamsTableFilterComposer get teamId {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserDevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserDevicesTable> {
  $$UserDevicesTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get udid => $composableBuilder(
    column: $table.udid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceProduct => $composableBuilder(
    column: $table.deviceProduct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceOsVersion => $composableBuilder(
    column: $table.deviceOsVersion,
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

  $$TeamsTableOrderingComposer get teamId {
    final $$TeamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableOrderingComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserDevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserDevicesTable> {
  $$UserDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get udid =>
      $composableBuilder(column: $table.udid, builder: (column) => column);

  GeneratedColumn<String> get deviceProduct => $composableBuilder(
    column: $table.deviceProduct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceOsVersion => $composableBuilder(
    column: $table.deviceOsVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TeamsTableAnnotationComposer get teamId {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserDevicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserDevicesTable,
          DriftUserDevice,
          $$UserDevicesTableFilterComposer,
          $$UserDevicesTableOrderingComposer,
          $$UserDevicesTableAnnotationComposer,
          $$UserDevicesTableCreateCompanionBuilder,
          $$UserDevicesTableUpdateCompanionBuilder,
          (DriftUserDevice, $$UserDevicesTableReferences),
          DriftUserDevice,
          PrefetchHooks Function({bool teamId})
        > {
  $$UserDevicesTableTableManager(_$AppDatabase db, $UserDevicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<String> udid = const Value.absent(),
                Value<String> deviceProduct = const Value.absent(),
                Value<String> deviceOsVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserDevicesCompanion(
                id: id,
                userId: userId,
                teamId: teamId,
                udid: udid,
                deviceProduct: deviceProduct,
                deviceOsVersion: deviceOsVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String teamId,
                required String udid,
                required String deviceProduct,
                required String deviceOsVersion,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserDevicesCompanion.insert(
                id: id,
                userId: userId,
                teamId: teamId,
                udid: udid,
                deviceProduct: deviceProduct,
                deviceOsVersion: deviceOsVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserDevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({teamId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (teamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.teamId,
                                referencedTable: $$UserDevicesTableReferences
                                    ._teamIdTable(db),
                                referencedColumn: $$UserDevicesTableReferences
                                    ._teamIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserDevicesTable,
      DriftUserDevice,
      $$UserDevicesTableFilterComposer,
      $$UserDevicesTableOrderingComposer,
      $$UserDevicesTableAnnotationComposer,
      $$UserDevicesTableCreateCompanionBuilder,
      $$UserDevicesTableUpdateCompanionBuilder,
      (DriftUserDevice, $$UserDevicesTableReferences),
      DriftUserDevice,
      PrefetchHooks Function({bool teamId})
    >;
typedef $$UdidRequestsTableCreateCompanionBuilder =
    UdidRequestsCompanion Function({
      required String id,
      required String userId,
      required String teamId,
      required String udid,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$UdidRequestsTableUpdateCompanionBuilder =
    UdidRequestsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> teamId,
      Value<String> udid,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$UdidRequestsTableReferences
    extends
        BaseReferences<_$AppDatabase, $UdidRequestsTable, DriftUdidRequest> {
  $$UdidRequestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TeamsTable _teamIdTable(_$AppDatabase db) => db.teams.createAlias(
    $_aliasNameGenerator(db.udidRequests.teamId, db.teams.id),
  );

  $$TeamsTableProcessedTableManager get teamId {
    final $_column = $_itemColumn<String>('team_id')!;

    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UdidRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $UdidRequestsTable> {
  $$UdidRequestsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get udid => $composableBuilder(
    column: $table.udid,
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

  $$TeamsTableFilterComposer get teamId {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UdidRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $UdidRequestsTable> {
  $$UdidRequestsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get udid => $composableBuilder(
    column: $table.udid,
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

  $$TeamsTableOrderingComposer get teamId {
    final $$TeamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableOrderingComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UdidRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UdidRequestsTable> {
  $$UdidRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get udid =>
      $composableBuilder(column: $table.udid, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TeamsTableAnnotationComposer get teamId {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UdidRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UdidRequestsTable,
          DriftUdidRequest,
          $$UdidRequestsTableFilterComposer,
          $$UdidRequestsTableOrderingComposer,
          $$UdidRequestsTableAnnotationComposer,
          $$UdidRequestsTableCreateCompanionBuilder,
          $$UdidRequestsTableUpdateCompanionBuilder,
          (DriftUdidRequest, $$UdidRequestsTableReferences),
          DriftUdidRequest,
          PrefetchHooks Function({bool teamId})
        > {
  $$UdidRequestsTableTableManager(_$AppDatabase db, $UdidRequestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UdidRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UdidRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UdidRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<String> udid = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UdidRequestsCompanion(
                id: id,
                userId: userId,
                teamId: teamId,
                udid: udid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String teamId,
                required String udid,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UdidRequestsCompanion.insert(
                id: id,
                userId: userId,
                teamId: teamId,
                udid: udid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UdidRequestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({teamId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (teamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.teamId,
                                referencedTable: $$UdidRequestsTableReferences
                                    ._teamIdTable(db),
                                referencedColumn: $$UdidRequestsTableReferences
                                    ._teamIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UdidRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UdidRequestsTable,
      DriftUdidRequest,
      $$UdidRequestsTableFilterComposer,
      $$UdidRequestsTableOrderingComposer,
      $$UdidRequestsTableAnnotationComposer,
      $$UdidRequestsTableCreateCompanionBuilder,
      $$UdidRequestsTableUpdateCompanionBuilder,
      (DriftUdidRequest, $$UdidRequestsTableReferences),
      DriftUdidRequest,
      PrefetchHooks Function({bool teamId})
    >;
typedef $$InvitationsTableCreateCompanionBuilder =
    InvitationsCompanion Function({
      required String id,
      required String email,
      required String teamId,
      required String token,
      required InvitationStatus status,
      required DateTime expiresAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$InvitationsTableUpdateCompanionBuilder =
    InvitationsCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> teamId,
      Value<String> token,
      Value<InvitationStatus> status,
      Value<DateTime> expiresAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$InvitationsTableReferences
    extends BaseReferences<_$AppDatabase, $InvitationsTable, Invitation> {
  $$InvitationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TeamsTable _teamIdTable(_$AppDatabase db) => db.teams.createAlias(
    $_aliasNameGenerator(db.invitations.teamId, db.teams.id),
  );

  $$TeamsTableProcessedTableManager get teamId {
    final $_column = $_itemColumn<String>('team_id')!;

    final manager = $$TeamsTableTableManager(
      $_db,
      $_db.teams,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_teamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InvitationsTableFilterComposer
    extends Composer<_$AppDatabase, $InvitationsTable> {
  $$InvitationsTableFilterComposer({
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

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<InvitationStatus, InvitationStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
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

  $$TeamsTableFilterComposer get teamId {
    final $$TeamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableFilterComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvitationsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvitationsTable> {
  $$InvitationsTableOrderingComposer({
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

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get token => $composableBuilder(
    column: $table.token,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
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

  $$TeamsTableOrderingComposer get teamId {
    final $$TeamsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableOrderingComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvitationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvitationsTable> {
  $$InvitationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get token =>
      $composableBuilder(column: $table.token, builder: (column) => column);

  GeneratedColumnWithTypeConverter<InvitationStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TeamsTableAnnotationComposer get teamId {
    final $$TeamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.teamId,
      referencedTable: $db.teams,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeamsTableAnnotationComposer(
            $db: $db,
            $table: $db.teams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InvitationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvitationsTable,
          Invitation,
          $$InvitationsTableFilterComposer,
          $$InvitationsTableOrderingComposer,
          $$InvitationsTableAnnotationComposer,
          $$InvitationsTableCreateCompanionBuilder,
          $$InvitationsTableUpdateCompanionBuilder,
          (Invitation, $$InvitationsTableReferences),
          Invitation,
          PrefetchHooks Function({bool teamId})
        > {
  $$InvitationsTableTableManager(_$AppDatabase db, $InvitationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvitationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvitationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvitationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<String> token = const Value.absent(),
                Value<InvitationStatus> status = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvitationsCompanion(
                id: id,
                email: email,
                teamId: teamId,
                token: token,
                status: status,
                expiresAt: expiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                required String teamId,
                required String token,
                required InvitationStatus status,
                required DateTime expiresAt,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => InvitationsCompanion.insert(
                id: id,
                email: email,
                teamId: teamId,
                token: token,
                status: status,
                expiresAt: expiresAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InvitationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({teamId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (teamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.teamId,
                                referencedTable: $$InvitationsTableReferences
                                    ._teamIdTable(db),
                                referencedColumn: $$InvitationsTableReferences
                                    ._teamIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InvitationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvitationsTable,
      Invitation,
      $$InvitationsTableFilterComposer,
      $$InvitationsTableOrderingComposer,
      $$InvitationsTableAnnotationComposer,
      $$InvitationsTableCreateCompanionBuilder,
      $$InvitationsTableUpdateCompanionBuilder,
      (Invitation, $$InvitationsTableReferences),
      Invitation,
      PrefetchHooks Function({bool teamId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BuildJobsTableTableManager get buildJobs =>
      $$BuildJobsTableTableManager(_db, _db.buildJobs);
  $$BuildJobLogsTableTableManager get buildJobLogs =>
      $$BuildJobLogsTableTableManager(_db, _db.buildJobLogs);
  $$BuildStepsTableTableManager get buildSteps =>
      $$BuildStepsTableTableManager(_db, _db.buildSteps);
  $$BuildStepLogsTableTableManager get buildStepLogs =>
      $$BuildStepLogsTableTableManager(_db, _db.buildStepLogs);
  $$BuildRunsTableTableManager get buildRuns =>
      $$BuildRunsTableTableManager(_db, _db.buildRuns);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db, _db.teams);
  $$TeamMembersTableTableManager get teamMembers =>
      $$TeamMembersTableTableManager(_db, _db.teamMembers);
  $$SecretsTableTableManager get secrets =>
      $$SecretsTableTableManager(_db, _db.secrets);
  $$WebhookTasksTableTableManager get webhookTasks =>
      $$WebhookTasksTableTableManager(_db, _db.webhookTasks);
  $$WorkerHeartbeatsTableTableManager get workerHeartbeats =>
      $$WorkerHeartbeatsTableTableManager(_db, _db.workerHeartbeats);
  $$UserDevicesTableTableManager get userDevices =>
      $$UserDevicesTableTableManager(_db, _db.userDevices);
  $$UdidRequestsTableTableManager get udidRequests =>
      $$UdidRequestsTableTableManager(_db, _db.udidRequests);
  $$InvitationsTableTableManager get invitations =>
      $$InvitationsTableTableManager(_db, _db.invitations);
}
