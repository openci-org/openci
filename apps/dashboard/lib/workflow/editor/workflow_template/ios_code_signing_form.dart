import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/workflow/workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class IosCodeSigningForm extends HookConsumerWidget {
  const IosCodeSigningForm({
    super.key,
    required this.documentId,
    this.insertAt,
  });

  final String documentId;
  final int? insertAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleIdController = useTextEditingController();
    final appleTeamIdController = useTextEditingController();
    final xcodeProjectPathController = useTextEditingController(
      text: 'ios/Runner.xcodeproj',
    );
    final schemeController = useTextEditingController(text: 'Runner');
    final workspacePathController = useTextEditingController(
      text: 'ios/Runner.xcworkspace',
    );
    final isLoading = useState(false);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'iOS Code Signing & Build',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'openci ios-sign コマンドのシェルステップを生成します',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Bundle ID
              _FieldLabel(label: 'Bundle ID'),
              const SizedBox(height: 8),
              TextFormField(
                controller: bundleIdController,
                decoration: const InputDecoration(
                  hintText: 'com.example.app',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Apple Team ID
              _FieldLabel(label: 'Apple Team ID'),
              const SizedBox(height: 4),
              Text(
                'Apple Developer Portal の Team ID',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: appleTeamIdController,
                decoration: const InputDecoration(
                  hintText: 'ABCD1234EF',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Xcode Project Path
              _FieldLabel(label: 'Xcode Project Path (.xcodeproj)'),
              const SizedBox(height: 4),
              Text(
                'Working directory からの相対パス',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: xcodeProjectPathController,
                decoration: const InputDecoration(
                  hintText: 'ios/Runner.xcodeproj',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Workspace Path
              _FieldLabel(label: 'Workspace Path (.xcworkspace)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: workspacePathController,
                decoration: const InputDecoration(
                  hintText: 'ios/Runner.xcworkspace',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Scheme
              _FieldLabel(label: 'Scheme'),
              const SizedBox(height: 8),
              TextFormField(
                controller: schemeController,
                decoration: const InputDecoration(
                  hintText: 'Runner',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '事前準備',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).hintColor,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Secret Manager に ASC_KEY_ID / ASC_ISSUER_ID / ASC_PRIVATE_KEY を登録\n'
                        '• このステップは openci CLI をVM内にインストールして実行します',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: isLoading.value
                ? null
                : () async {
                    final bundleId = bundleIdController.text.trim();
                    final appleTeamId = appleTeamIdController.text.trim();
                    final xcodeProjectPath =
                        xcodeProjectPathController.text.trim();
                    final scheme = schemeController.text.trim();
                    final workspacePath = workspacePathController.text.trim();

                    if (bundleId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bundle ID を入力してください'),
                        ),
                      );
                      return;
                    }
                    if (appleTeamId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Apple Team ID を入力してください'),
                        ),
                      );
                      return;
                    }
                    if (xcodeProjectPath.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Xcode Project Path を入力してください'),
                        ),
                      );
                      return;
                    }
                    if (scheme.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scheme を入力してください'),
                        ),
                      );
                      return;
                    }
                    if (workspacePath.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Workspace Path を入力してください'),
                        ),
                      );
                      return;
                    }

                    isLoading.value = true;

                    // Generate the shell command for openci CLI
                    // ASC credentials (ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY)
                    // should be added as workflow secrets.
                    final shellCommand = [
                      'dart pub global activate openci_vm_cli',
                      'export PATH="\$PATH":"\$HOME/.pub-cache/bin"',
                      'openci_vm ios-sign \\',
                      '  --bundle-id "$bundleId" \\',
                      '  --apple-team-id "$appleTeamId" \\',
                      '  --scheme "$scheme" \\',
                      '  --workspace "$workspacePath" \\',
                      '  --xcodeproj "$xcodeProjectPath"',
                    ].join('\n');

                    final newStep = WorkflowStep(
                      name: 'iOS Code Signing & Build',
                      command: shellCommand,
                      isCompleted: true,
                    );

                    final docRef = ref
                        .watch(firestoreProvider)
                        .collection(workflowsCollection)
                        .doc(documentId);

                    if (insertAt != null) {
                      final snapshot = await docRef.get();
                      final data = snapshot.data() as Map<String, dynamic>;
                      final steps = List<Map<String, dynamic>>.from(
                        data['workflowSteps'] as List,
                      );
                      steps.insert(insertAt!, newStep.toJson());
                      await docRef.update({'workflowSteps': steps});
                    } else {
                      await docRef.update({
                        'workflowSteps': FieldValue.arrayUnion([
                          newStep.toJson(),
                        ]),
                      });
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
            icon: isLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Add Step'),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleSmall);
  }
}
