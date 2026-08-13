import 'command_runner.dart';
import 'workspace.dart';

class GenuineCI {
  GenuineCI._({
    required this.workflowName,
    required this.triggerBranch,
    required this.push,
    required this.pullRequest,
    required this.machine,
    this.currentWorkingDirectory,
    required this.githubRepositoryUrl,
    required Workspace workspace,
  }) : _workspace = workspace;

  final String workflowName;
  final String triggerBranch;
  final bool push;
  final bool pullRequest;
  final String machine;
  final String? currentWorkingDirectory;
  final String githubRepositoryUrl;
  final Workspace _workspace;

  static Future<GenuineCI> init({
    required String workflowName,
    required String triggerBranch,
    required bool push,
    required bool pullRequest,
    required String machine,
    String? currentWorkingDirectory,
    required String githubRepositoryUrl,
  }) async {
    final workspace = await Workspace.create();
    final instance = GenuineCI._(
      workflowName: workflowName,
      triggerBranch: triggerBranch,
      push: push,
      pullRequest: pullRequest,
      machine: machine,
      currentWorkingDirectory: currentWorkingDirectory,
      githubRepositoryUrl: githubRepositoryUrl,
      workspace: workspace,
    );

    await workspace.checkout(
      url: githubRepositoryUrl,
      branch: triggerBranch,
    );

    return instance;
  }

  Future<void> run(
    String command, {
    String? workingDirectory,
  }) async {
    await runCommand(
      command,
      workingDirectory: _workspace.resolve(
        workingDirectory ?? currentWorkingDirectory,
      ),
    );
  }
}
