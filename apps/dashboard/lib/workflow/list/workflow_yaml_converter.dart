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

class WorkflowYamlConfig {
  WorkflowYamlConfig({
    required this.name,
    this.triggers = const {
      'push': ['main'],
    },
    this.steps = const [],
  });

  final String name;
  final Map<String, List<String>> triggers;
  final List<WorkflowYamlStep> steps;
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
  buffer.writeln('  build:');
  buffer.writeln('    steps:');
  for (final step in config.steps) {
    buffer.writeln('      - name: ${step.name}');
    if (step.type == StepType.uses) {
      buffer.writeln('        uses: ${step.uses}');
      if (step.withParams.isNotEmpty) {
        buffer.writeln('        with:');
        for (final entry in step.withParams.entries) {
          buffer.writeln('          ${entry.key}: ${entry.value}');
        }
      }
    } else {
      final runLines = step.run.split('\n');
      if (runLines.length == 1) {
        buffer.writeln('        run: ${step.run}');
      } else {
        buffer.writeln('        run: |');
        for (final line in runLines) {
          buffer.writeln('          $line');
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

    final steps = <WorkflowYamlStep>[];
    final jobs = doc['jobs'];
    if (jobs is YamlMap) {
      for (final jobKey in jobs.keys) {
        final job = jobs[jobKey];
        if (job is YamlMap && job['steps'] is YamlList) {
          for (final step in job['steps'] as YamlList) {
            if (step is YamlMap) {
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
      }
    }

    return WorkflowYamlConfig(
      name: name,
      triggers: triggers,
      steps: steps,
    );
  } catch (_) {
    return null;
  }
}
