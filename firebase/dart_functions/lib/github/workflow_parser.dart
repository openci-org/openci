/// Pure functions for matching workflow triggers and extracting jobs
/// from parsed .openci/ YAML files.
library;

/// Determines whether a parsed workflow YAML matches
/// the given trigger type and branch.
///
/// The `on` field in the YAML can be:
/// - A string: `on: push`
/// - A list: `on: [push, pull_request]`
/// - A map with optional branch filters:
///   ```yaml
///   on:
///     push:
///       branches: [main, develop]
///   ```
bool matchesTrigger(
  Map<String, dynamic> parsed,
  String triggerType,
  String? triggerBranch,
) {
  final on = parsed['on'];
  if (on == null) return false;

  // Map Dart trigger type to YAML key
  final yamlTriggerKey = triggerType == 'pullRequest'
      ? 'pull_request'
      : triggerType;

  // on: "push"
  if (on is String) {
    return on == yamlTriggerKey;
  }

  // on: [push, pull_request]
  if (on is List) {
    return on.contains(yamlTriggerKey);
  }

  // on: { push: { branches: [main] } }
  if (on is Map) {
    final triggerConfig = on[yamlTriggerKey];
    if (triggerConfig == null && !on.containsKey(yamlTriggerKey)) return false;
    if (triggerConfig == null) return true; // key exists with null value

    if (triggerConfig is Map && triggerConfig['branches'] != null) {
      final branches = triggerConfig['branches'];
      final branchList = branches is List
          ? branches.cast<String>()
          : [branches.toString()];
      if (triggerBranch != null && !branchList.contains(triggerBranch)) {
        return false;
      }
    }

    return true;
  }

  return false;
}

/// Information about a single job extracted from a workflow YAML.
class JobInfo {
  final String jobKey;
  final List<String> needs;
  final String? runsOn;
  final List<JobStep> steps;

  JobInfo({
    required this.jobKey,
    required this.needs,
    required this.runsOn,
    required this.steps,
  });
}

/// A single step within a job.
class JobStep {
  final String name;
  final String? run;
  final String? uses;
  final Map<String, String>? withParams;

  JobStep({required this.name, this.run, this.uses, this.withParams});
}

/// Extracts job definitions from a parsed workflow YAML.
///
/// Returns an empty list if no valid jobs are found.
List<JobInfo> extractJobs(Map<String, dynamic> parsed) {
  final jobs = parsed['jobs'];
  if (jobs == null || jobs is! Map) return [];

  final jobInfos = <JobInfo>[];

  for (final entry in jobs.entries) {
    final jobKey = entry.key as String;
    final job = entry.value;
    if (job == null || job is! Map) continue;

    final stepsList = job['steps'];
    if (stepsList == null || stepsList is! List) continue;

    final runsOn = job['runs-on'] is String ? job['runs-on'] as String : null;

    final steps = <JobStep>[];
    for (final step in stepsList) {
      if (step == null || step is! Map) continue;

      final name = (step['name'] as String?) ?? '';

      if (step['uses'] != null) {
        Map<String, String>? withParams;
        if (step['with'] is Map) {
          withParams = {};
          for (final e in (step['with'] as Map).entries) {
            withParams[e.key.toString()] = e.value.toString();
          }
        }
        steps.add(
          JobStep(
            name: name,
            uses: step['uses'] as String,
            withParams: withParams,
          ),
        );
      } else if (step['run'] != null) {
        steps.add(JobStep(name: name, run: step['run'] as String));
      }
    }

    if (steps.isEmpty) continue;

    // Parse needs
    final needs = <String>[];
    final rawNeeds = job['needs'];
    if (rawNeeds is List) {
      needs.addAll(rawNeeds.cast<String>());
    } else if (rawNeeds is String) {
      needs.add(rawNeeds);
    }

    jobInfos.add(
      JobInfo(jobKey: jobKey, needs: needs, runsOn: runsOn, steps: steps),
    );
  }

  return jobInfos;
}

/// Generate a stable document ID for a workflow file.
String workflowFileDocId(
  String teamId,
  String repository,
  String branch,
  String fileName,
) {
  return '${teamId}_${repository.replaceAll('/', '_')}_${branch}_$fileName';
}
