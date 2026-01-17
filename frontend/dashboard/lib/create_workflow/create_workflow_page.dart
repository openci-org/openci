import 'package:flutter/material.dart';

class CreateWorkflowPage extends StatelessWidget {
  const CreateWorkflowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => CreateWorkflowBottomSheet(),
          ),
          child: Text('Let\'s Create New Workflow'),
        ),
      ),
    );
  }
}

class CreateWorkflowBottomSheet extends StatefulWidget {
  const CreateWorkflowBottomSheet({super.key});

  static const _width = 260.0;

  @override
  State<CreateWorkflowBottomSheet> createState() =>
      _CreateWorkflowBottomSheetState();
}

class _CreateWorkflowBottomSheetState extends State<CreateWorkflowBottomSheet> {
  String selectedRepository = '';
  String selectedWorkingDirectory = '/';
  String selectedTriggerType = 'pull_request';
  String selectedTriggerBranch = 'develop';

  @override
  Widget build(BuildContext context) {
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
            if (selectedRepository.isNotEmpty &&
                selectedWorkingDirectory.isNotEmpty &&
                selectedTriggerType.isNotEmpty &&
                selectedTriggerBranch.isNotEmpty)
              InitialSetupSummary(
                repository: selectedRepository,
                workingDirectory: selectedWorkingDirectory,
                triggerType: selectedTriggerType,
                triggerBranch: selectedTriggerBranch,
              ),
            DropdownMenu(
              width: CreateWorkflowBottomSheet._width,
              controller: TextEditingController(text: selectedRepository),
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
                setState(() {
                  selectedRepository = value;
                });
              },
            ),
            DropdownMenu(
              width: CreateWorkflowBottomSheet._width,
              controller: TextEditingController(text: selectedWorkingDirectory),
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
                setState(() {
                  selectedWorkingDirectory = value;
                });
              },
            ),
            DropdownMenu(
              width: CreateWorkflowBottomSheet._width,
              controller: TextEditingController(text: selectedTriggerType),
              label: const Text('Trigger Type'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'push', label: 'push'),
                DropdownMenuEntry(value: 'pull_request', label: 'pull_request'),
              ],
              onSelected: (value) {
                if (value == null) return;
                setState(() {
                  selectedTriggerType = value;
                });
              },
            ),
            DropdownMenu(
              width: CreateWorkflowBottomSheet._width,
              controller: TextEditingController(text: selectedTriggerBranch),
              label: const Text('Trigger Branch'),
              dropdownMenuEntries: [
                DropdownMenuEntry(value: 'main', label: 'main'),
                DropdownMenuEntry(value: 'develop', label: 'develop'),
              ],
              onSelected: (value) {
                if (value == null) return;
                setState(() {
                  selectedTriggerBranch = value;
                });
              },
            ),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(CreateWorkflowBottomSheet._width, 48),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
  const InitialSetupSummary({
    super.key,
    required this.repository,
    required this.workingDirectory,
    required this.triggerType,
    required this.triggerBranch,
  });
  final String repository;
  final String workingDirectory;
  final String triggerType;
  final String triggerBranch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CreateWorkflowBottomSheet._width,
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
                  text: repository,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' repository, when a '),
                TextSpan(
                  text: triggerType,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' is created to the '),
                TextSpan(
                  text: triggerBranch,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' branch, the workflow will run using the ',
                ),
                TextSpan(
                  text: workingDirectory,
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
