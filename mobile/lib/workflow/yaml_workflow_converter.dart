import 'package:dashboard/workflow/yaml_workflow.dart';

class YamlWorkflowConverter {
  static String toYamlString(YamlWorkflow workflow) {
    final buffer = StringBuffer();

    buffer.writeln('name: ${workflow.name}');
    buffer.writeln();

    buffer.writeln('on:');
    final trigger = workflow.on;
    if (trigger.push != null) {
      buffer.writeln('  push:');
      if (trigger.push!.branches.isNotEmpty) {
        buffer.writeln('    branches:');
        for (final branch in trigger.push!.branches) {
          buffer.writeln('      - $branch');
        }
      }
    }
    if (trigger.pullRequest != null) {
      buffer.writeln('  pull_request:');
      if (trigger.pullRequest!.branches.isNotEmpty) {
        buffer.writeln('    branches:');
        for (final branch in trigger.pullRequest!.branches) {
          buffer.writeln('      - $branch');
        }
      }
    }
    if (trigger.tag == true) {
      buffer.writeln('  create:');
      buffer.writeln('    tags: true');
    }
    if (trigger.release != null) {
      buffer.writeln('  release:');
      buffer.writeln('    types:');
      for (final type in trigger.release!.types) {
        buffer.writeln('      - $type');
      }
    }

    if (workflow.workingDirectory != '.') {
      buffer.writeln();
      buffer.writeln('working_directory: ${workflow.workingDirectory}');
    }

    if (workflow.steps.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('steps:');
      for (final step in workflow.steps) {
        buffer.writeln('  - name: ${step.name}');
        if (step.uses != null && step.uses!.isNotEmpty) {
          buffer.writeln('    uses: ${step.uses}');
          if (step.withParams.isNotEmpty) {
            buffer.writeln('    with:');
            for (final entry in step.withParams.entries) {
              buffer.writeln('      ${entry.key}: ${entry.value}');
            }
          }
        } else if (step.run != null && step.run!.isNotEmpty) {
          if (step.run!.contains('\n')) {
            buffer.writeln('    run: |');
            for (final line in step.run!.split('\n')) {
              if (line.trim().isEmpty) continue;
              buffer.writeln('      $line');
            }
          } else {
            buffer.writeln('    run: ${step.run}');
          }
        }
      }
    }

    return buffer.toString();
  }

  static YamlWorkflow fromYamlMap(Map<String, dynamic> map) {
    final name = map['name'] as String? ?? 'Untitled';

    final onRaw = map['on'];
    final trigger = _parseTrigger(onRaw);

    final workingDirectory = map['working_directory'] as String? ?? '.';

    final stepsRaw = map['steps'] as List<dynamic>? ?? [];
    final steps = stepsRaw.map((s) {
      final stepMap = Map<String, dynamic>.from(s as Map);
      final withRaw = stepMap['with'];
      final withParams = <String, String>{};
      if (withRaw is Map) {
        for (final entry in withRaw.entries) {
          withParams[entry.key.toString()] = entry.value.toString();
        }
      }
      return YamlWorkflowStep(
        name: stepMap['name'] as String? ?? '',
        run: stepMap['run'] as String?,
        uses: stepMap['uses'] as String?,
        withParams: withParams,
      );
    }).toList();

    return YamlWorkflow(
      name: name,
      on: trigger,
      workingDirectory: workingDirectory,
      steps: steps,
    );
  }

  static YamlWorkflowTrigger _parseTrigger(dynamic onRaw) {
    if (onRaw == null) {
      return const YamlWorkflowTrigger();
    }

    if (onRaw is String) {
      return _singleEventTrigger(onRaw);
    }

    if (onRaw is List) {
      YamlTriggerConfig? push;
      YamlTriggerConfig? pullRequest;
      bool? tag;
      YamlReleaseTriggerConfig? release;

      for (final event in onRaw) {
        if (event == 'push') push = const YamlTriggerConfig();
        if (event == 'pull_request') pullRequest = const YamlTriggerConfig();
        if (event == 'create') tag = true;
        if (event == 'release') {
          release = const YamlReleaseTriggerConfig();
        }
      }

      return YamlWorkflowTrigger(
        push: push,
        pullRequest: pullRequest,
        tag: tag,
        release: release,
      );
    }

    if (onRaw is Map) {
      final map = Map<String, dynamic>.from(onRaw);
      YamlTriggerConfig? push;
      YamlTriggerConfig? pullRequest;
      bool? tag;
      YamlReleaseTriggerConfig? release;

      if (map.containsKey('push')) {
        final pushConfig = map['push'];
        if (pushConfig is Map) {
          final branches =
              (pushConfig['branches'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          push = YamlTriggerConfig(branches: branches);
        } else {
          push = const YamlTriggerConfig();
        }
      }

      if (map.containsKey('pull_request')) {
        final prConfig = map['pull_request'];
        if (prConfig is Map) {
          final branches =
              (prConfig['branches'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          pullRequest = YamlTriggerConfig(branches: branches);
        } else {
          pullRequest = const YamlTriggerConfig();
        }
      }

      if (map.containsKey('create')) {
        tag = true;
      }

      if (map.containsKey('release')) {
        final releaseConfig = map['release'];
        if (releaseConfig is Map) {
          final types =
              (releaseConfig['types'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['published'];
          release = YamlReleaseTriggerConfig(types: types);
        } else {
          release = const YamlReleaseTriggerConfig();
        }
      }

      return YamlWorkflowTrigger(
        push: push,
        pullRequest: pullRequest,
        tag: tag,
        release: release,
      );
    }

    return const YamlWorkflowTrigger();
  }

  static YamlWorkflowTrigger _singleEventTrigger(String event) {
    switch (event) {
      case 'push':
        return const YamlWorkflowTrigger(push: YamlTriggerConfig());
      case 'pull_request':
        return const YamlWorkflowTrigger(pullRequest: YamlTriggerConfig());
      case 'create':
        return const YamlWorkflowTrigger(tag: true);
      case 'release':
        return const YamlWorkflowTrigger(
          release: YamlReleaseTriggerConfig(),
        );
      default:
        return const YamlWorkflowTrigger();
    }
  }

  static String triggerSummary(YamlWorkflowTrigger trigger) {
    final parts = <String>[];
    if (trigger.push != null) {
      final branches = trigger.push!.branches;
      parts.add(
        branches.isEmpty ? 'push' : 'push → ${branches.join(', ')}',
      );
    }
    if (trigger.pullRequest != null) {
      final branches = trigger.pullRequest!.branches;
      parts.add(
        branches.isEmpty
            ? 'pull_request'
            : 'pull_request → ${branches.join(', ')}',
      );
    }
    if (trigger.tag == true) {
      parts.add('tag');
    }
    if (trigger.release != null) {
      parts.add('release');
    }
    return parts.isEmpty ? 'No trigger' : parts.join(', ');
  }
}
