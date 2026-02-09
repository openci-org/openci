import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/workflow/editor/initial_workflow_setup/initial_workflow_setup_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class InitialWorkflowSetupBottomSheet extends HookConsumerWidget {
  const InitialWorkflowSetupBottomSheet({super.key});

  static const _width = 260.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(initialWorkflowSetupProvider);
    final controller = ref.read(initialWorkflowSetupProvider.notifier);

    final nameController = useTextEditingController();
    final repositoryController = useTextEditingController();
    final workingDirectoryController = useTextEditingController();
    final triggerBranchController = useTextEditingController();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: Text(
                    'Initial Setup',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),

            if (state.selectedRepository.isNotEmpty &&
                state.selectedWorkingDirectory.isNotEmpty &&
                state.selectedTriggerBranch.isNotEmpty)
              InitialSetupSummary(
                state: state,
              ),
            TextButton(
              onPressed: () async {
                await url_launcher.launchUrl(
                  Uri.parse('https://github.com/apps/openci-org'),
                );
              },
              child: Text('Install GitHub App'),
            ),
            SizedBox(
              width: _width,
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Workflow Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            SizedBox(
              width: _width,
              child: TextFormField(
                controller: repositoryController,
                decoration: InputDecoration(
                  labelText: 'Repository',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            SizedBox(
              width: _width,
              child: TextFormField(
                controller: workingDirectoryController,
                decoration: InputDecoration(
                  labelText: 'Current Working Directory',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            DropdownMenu(
              width: _width,
              controller: TextEditingController(
                text: state.selectedTriggerType.toString(),
              ),
              label: const Text('Trigger Type'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'push', label: 'push'),
                DropdownMenuEntry(value: 'pullRequest', label: 'pullRequest'),
                DropdownMenuEntry(value: 'tag', label: 'tag'),
              ],
              onSelected: (value) {
                if (value == null) return;
                controller.updateSelectedTriggerType(
                  TriggerType.fromValue(value),
                );
              },
            ),
            if (state.selectedTriggerType != TriggerType.tag) ...[
              SizedBox(height: 20.0),
              SizedBox(
                width: _width,
                child: TextFormField(
                  controller: triggerBranchController,
                  decoration: InputDecoration(
                    labelText: 'Trigger Branch',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
            SizedBox(height: 24.0),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(_width, 48),
              ),
              onPressed: () async {
                final triggerBranch =
                    state.selectedTriggerType == TriggerType.tag
                    ? null
                    : triggerBranchController.text;

                await controller.save(
                  name: nameController.text,
                  selectedRepository: repositoryController.text,
                  selectedWorkingDirectory: workingDirectoryController.text,
                  selectedTriggerBranch: triggerBranch,
                );

                if (!context.mounted) return;
                context.showSnackBarMessage(
                  'Workflow created successfully',
                );

                Navigator.of(context).pop();
              },
              icon: Icon(Icons.check),
              label: Text('OK, let\'s go!'),
            ),
          ],
        ),
      ),
    );
  }
}

class InitialSetupSummary extends StatelessWidget {
  const InitialSetupSummary({super.key, required this.state});
  final InitialWorkflowSetupState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: InitialWorkflowSetupBottomSheet._width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8.0,
        children: [
          Text(
            'Summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'In the '),
                TextSpan(
                  text: state.selectedRepository,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' repository, when a '),
                TextSpan(
                  text: state.selectedTriggerType.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' is created to the '),
                TextSpan(
                  text: state.selectedTriggerBranch,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' branch, the workflow will run using the ',
                ),
                TextSpan(
                  text: state.selectedWorkingDirectory,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' directory.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
