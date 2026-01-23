import 'package:dashboard/workflow/editor/initial_workflow_setup/initial_workflow_setup_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InitialWorkflowSetupBottomSheet extends ConsumerWidget {
  const InitialWorkflowSetupBottomSheet({super.key});

  static const _width = 260.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(initialWorkflowSetupProvider);
    final controller = ref.read(initialWorkflowSetupProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 30.0,
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
            DropdownMenu(
              width: _width,
              controller: TextEditingController(text: state.selectedRepository),
              label: const Text('Repository'),
              dropdownMenuEntries: [
                DropdownMenuEntry(
                  value: 'open-ci-io/openci',
                  label: 'open-ci-io/openci',
                ),
                DropdownMenuEntry(value: 'mafreud/test', label: 'mafreud/test'),
              ],
              onSelected: (value) {
                if (value == null) return;
                controller.updateSelectedRepository(value);
              },
            ),
            DropdownMenu(
              width: _width,
              controller: TextEditingController(
                text: state.selectedWorkingDirectory,
              ),
              label: const Text('Current Working Directory'),
              helperText: 'Use default if you don\'t use monorepo',
              dropdownMenuEntries: [
                DropdownMenuEntry(value: '/', label: '/'),
                DropdownMenuEntry(value: '/frontend', label: '/frontend'),
                DropdownMenuEntry(
                  value: '/frontend/dashboard',
                  label: '/frontend/dashboard',
                ),
              ],
              onSelected: (value) {
                if (value == null) return;
                controller.updateSelectedWorkingDirectory(value);
              },
            ),
            DropdownMenu(
              width: _width,
              controller: TextEditingController(
                text: state.selectedTriggerType.toString(),
              ),
              label: const Text('Trigger Type'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'push', label: 'push'),
                DropdownMenuEntry(value: 'pull_request', label: 'pull_request'),
              ],
              onSelected: (value) {
                if (value == null) return;
                controller.updateSelectedTriggerType(
                  TriggerType.fromValue(value),
                );
              },
            ),
            DropdownMenu(
              width: _width,
              controller: TextEditingController(
                text: state.selectedTriggerBranch,
              ),
              label: const Text('Trigger Branch'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'main', label: 'main'),
                DropdownMenuEntry(value: 'develop', label: 'develop'),
              ],
              onSelected: (value) {
                if (value == null) return;
                controller.updateSelectedTriggerBranch(value);
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(_width, 48),
              ),
              onPressed: () async {
                await controller.save();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Workflow created successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
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
