import 'package:yaml/yaml.dart';

enum StepType { run, uses }

class WorkflowYamlStep {
  WorkflowYamlStep({
    required this.name,
    this.type = StepType.run,
    this.run = '',
    this.uses = '',
    this.withParams = const {},
  });

  final String name;
  final StepType type;
  final String run;
  final String uses;
  final Map<String, String> withParams;
}

class WorkflowYamlJob {
  WorkflowYamlJob({
    required this.id,
    this.name,
    this.needs = const [],
    this.runsOn = 'macos-latest',
    this.steps = const [],
  });

  final String id;
  final String? name;
  final List<String> needs;
  final String runsOn;
  final List<WorkflowYamlStep> steps;

  WorkflowYamlJob copyWith({
    String? id,
    String? name,
    List<String>? needs,
    String? runsOn,
    List<WorkflowYamlStep>? steps,
  }) {
    return WorkflowYamlJob(
      id: id ?? this.id,
      name: name ?? this.name,
      needs: needs ?? this.needs,
      runsOn: runsOn ?? this.runsOn,
      steps: steps ?? this.steps,
    );
  }
}

class WorkflowYamlConfig {
  WorkflowYamlConfig({
    required this.name,
    this.triggers = const {
      'push': ['main'],
    },
    this.jobs = const [],
    @Deprecated('Use jobs instead') List<WorkflowYamlStep>? steps,
  }) {
    // Backward compat: if steps provided but no jobs, wrap in a single job
    if (jobs.isEmpty && steps != null && steps.isNotEmpty) {
      jobs = [
        WorkflowYamlJob(
          id: 'build',
          steps: steps,
        ),
      ];
    }
  }

  final String name;
  final Map<String, List<String>> triggers;
  // ignore: avoid_setters_without_getters
  late final List<WorkflowYamlJob> jobs;

  /// Backward compat getter: all steps across all jobs
  List<WorkflowYamlStep> get steps => jobs.expand((j) => j.steps).toList();
}

String stepsToYaml(WorkflowYamlConfig config) {
  final buffer = StringBuffer();
  buffer.writeln('name: ${config.name}');
  buffer.writeln();
  buffer.writeln('on:');
  for (final entry in config.triggers.entries) {
    final triggerType = entry.key;
    final branches = entry.value;
    buffer.writeln('  $triggerType:');
    final needsBranches = triggerType != 'tag' && triggerType != 'release';
    if (needsBranches && branches.isNotEmpty) {
      buffer.writeln('    branches:');
      for (final branch in branches) {
        buffer.writeln('      - $branch');
      }
    }
  }
  buffer.writeln();
  buffer.writeln('jobs:');

  for (final job in config.jobs) {
    buffer.writeln('  ${job.id}:');
    if (job.name != null && job.name!.isNotEmpty) {
      buffer.writeln('    name: ${job.name}');
    }
    buffer.writeln('    runs-on: ${job.runsOn}');
    if (job.needs.isNotEmpty) {
      if (job.needs.length == 1) {
        buffer.writeln('    needs: ${job.needs.first}');
      } else {
        buffer.writeln('    needs: [${job.needs.join(', ')}]');
      }
    }
    buffer.writeln('    steps:');
    buffer.writeln('      - uses: actions/checkout@v4');
    for (final step in job.steps) {
      if (step.name.isNotEmpty) {
        buffer.writeln('      - name: ${step.name}');
      } else {
        buffer.write('      - ');
      }
      if (step.type == StepType.uses) {
        if (step.name.isNotEmpty) {
          buffer.writeln('        uses: ${step.uses}');
        } else {
          buffer.writeln('uses: ${step.uses}');
        }
        if (step.withParams.isNotEmpty) {
          buffer.writeln('        with:');
          for (final entry in step.withParams.entries) {
            buffer.writeln('          ${entry.key}: ${entry.value}');
          }
        }
      } else {
        final runLines = step.run.split('\n');
        if (step.name.isNotEmpty) {
          if (runLines.length == 1) {
            buffer.writeln('        run: ${step.run}');
          } else {
            buffer.writeln('        run: |');
            for (final line in runLines) {
              buffer.writeln('          $line');
            }
          }
        } else {
          if (runLines.length == 1) {
            buffer.writeln('run: ${step.run}');
          } else {
            buffer.writeln('run: |');
            for (final line in runLines) {
              buffer.writeln('          $line');
            }
          }
        }
      }
    }
  }
  return buffer.toString();
}

WorkflowYamlConfig? yamlToConfig(String yamlContent) {
  try {
    final doc = loadYaml(yamlContent);
    if (doc is! YamlMap) return null;

    final name = doc['name']?.toString() ?? 'untitled';

    final triggers = <String, List<String>>{};
    final on = doc['on'];
    if (on is YamlMap) {
      for (final key in on.keys) {
        final triggerType = key.toString();
        final triggerConfig = on[key];
        var branches = <String>[];
        if (triggerConfig is YamlMap) {
          final branchList = triggerConfig['branches'];
          if (branchList is YamlList) {
            branches = branchList.map((b) => b.toString()).toList();
          }
        }
        triggers[triggerType] = branches;
      }
    }
    if (triggers.isEmpty) {
      triggers['push'] = ['main'];
    }

    final jobs = <WorkflowYamlJob>[];
    final jobsMap = doc['jobs'];
    if (jobsMap is YamlMap) {
      for (final jobKey in jobsMap.keys) {
        final jobId = jobKey.toString();
        final job = jobsMap[jobKey];
        if (job is! YamlMap) continue;

        final jobName = job['name']?.toString();
        final runsOn = job['runs-on']?.toString() ?? 'macos-latest';

        // Parse needs
        final needs = <String>[];
        final needsValue = job['needs'];
        if (needsValue is YamlList) {
          needs.addAll(needsValue.map((n) => n.toString()));
        } else if (needsValue is String) {
          needs.add(needsValue);
        }

        // Parse steps
        final steps = <WorkflowYamlStep>[];
        if (job['steps'] is YamlList) {
          for (final step in job['steps'] as YamlList) {
            if (step is YamlMap) {
              final usesValue = step['uses']?.toString() ?? '';
              if (usesValue.startsWith('actions/checkout')) continue;

              final hasUses = step.containsKey('uses');
              final withParams = <String, String>{};
              if (hasUses && step['with'] is YamlMap) {
                final w = step['with'] as YamlMap;
                for (final key in w.keys) {
                  withParams[key.toString()] = w[key].toString();
                }
              }
              steps.add(
                WorkflowYamlStep(
                  name: step['name']?.toString() ?? '',
                  type: hasUses ? StepType.uses : StepType.run,
                  run: step['run']?.toString() ?? '',
                  uses: step['uses']?.toString() ?? '',
                  withParams: withParams,
                ),
              );
            }
          }
        }

        jobs.add(
          WorkflowYamlJob(
            id: jobId,
            name: jobName,
            needs: needs,
            runsOn: runsOn,
            steps: steps,
          ),
        );
      }
    }

    // Fallback: if no jobs parsed, create a single default job
    if (jobs.isEmpty) {
      jobs.add(
        WorkflowYamlJob(
          id: 'build',
          steps: [],
        ),
      );
    }

    return WorkflowYamlConfig(
      name: name,
      triggers: triggers,
      jobs: jobs,
    );
  } catch (_) {
    return null;
  }
}
