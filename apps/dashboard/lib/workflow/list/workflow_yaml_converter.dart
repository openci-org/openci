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
    this.triggerType = 'push',
    this.triggerBranches = const ['main'],
    this.steps = const [],
  });

  final String name;
  final String triggerType;
  final List<String> triggerBranches;
  final List<WorkflowYamlStep> steps;
}

String stepsToYaml(WorkflowYamlConfig config) {
  final buffer = StringBuffer();
  buffer.writeln('name: ${config.name}');
  buffer.writeln();
  buffer.writeln('on:');
  buffer.writeln('  ${config.triggerType}:');
  buffer.writeln('    branches:');
  for (final branch in config.triggerBranches) {
    buffer.writeln('      - $branch');
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

    var triggerType = 'push';
    var triggerBranches = <String>['main'];
    final on = doc['on'];
    if (on is YamlMap) {
      final trigger = on.keys.first?.toString() ?? 'push';
      triggerType = trigger;
      final triggerConfig = on[trigger];
      if (triggerConfig is YamlMap) {
        final branches = triggerConfig['branches'];
        if (branches is YamlList) {
          triggerBranches = branches.map((b) => b.toString()).toList();
        }
      }
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
      triggerType: triggerType,
      triggerBranches: triggerBranches,
      steps: steps,
    );
  } catch (_) {
    return null;
  }
}
