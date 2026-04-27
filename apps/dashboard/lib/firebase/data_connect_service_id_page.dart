import 'dart:async';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/dataconnect.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DataConnectServiceIdPage extends HookConsumerWidget {
  const DataConnectServiceIdPage({
    super.key,
    required this.config,
    this.title = 'Data Connect Service ID is required',
    this.message,
  });

  final SelfHostedConfig config;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: config.dataConnectServiceId.trim().isNotEmpty
          ? config.dataConnectServiceId
          : '${config.projectId}-service',
    );
    final isSaving = useState(false);
    final canInitializeWorkspace = useState(false);
    final statusMessage = useState<String?>(null);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.storage_outlined,
                  size: 36,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message ??
                      'Enter the Data Connect service ID for ${config.projectId}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Data Connect Service ID',
                    hintText: 'project-id-service',
                  ),
                ),
                if (statusMessage.value != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    statusMessage.value!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isSaving.value
                      ? null
                      : () async {
                          final serviceId = controller.text.trim();
                          if (serviceId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Data Connect Service ID is required',
                                ),
                              ),
                            );
                            return;
                          }

                          try {
                            debugPrint(
                              '[OpenCI] Saving Data Connect service ID: $serviceId',
                            );
                            statusMessage.value = 'Saving settings...';
                            isSaving.value = true;
                            final updatedConfig = config.copyWith(
                              dataConnectServiceId: serviceId,
                            );
                            await saveSelfHostedConfig(updatedConfig);
                            initDataConnector(updatedConfig);
                            statusMessage.value = 'Testing Data Connect...';
                            debugPrint(
                              '[OpenCI] Testing Data Connect with service ID: $serviceId',
                            );
                            final result = await dataConnector
                                .getCurrentUser()
                                .execute()
                                .timeout(
                                  const Duration(seconds: 8),
                                  onTimeout: () => throw TimeoutException(
                                    'Timed out while testing Data Connect',
                                  ),
                                );
                            debugPrint(
                              '[OpenCI] Data Connect test succeeded. user=${result.data.user?.id}',
                            );
                            if (result.data.user == null) {
                              statusMessage.value =
                                  'Data Connect connected. User profile is not initialized yet.';
                              canInitializeWorkspace.value = true;
                            } else {
                              statusMessage.value = 'Data Connect connected.';
                              canInitializeWorkspace.value = false;
                            }
                            ref.invalidate(selfHostedConfigProvider);
                            ref.invalidate(userProvider);
                            ref.invalidate(teamListProvider);
                            ref.invalidate(teamStateProvider);
                            debugPrint(
                              '[OpenCI] Data Connect service ID saved: $serviceId',
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Data Connect settings saved'),
                              ),
                            );
                          } catch (e) {
                            debugPrint(
                              '[OpenCI] Failed to save Data Connect service ID: $e',
                            );
                            statusMessage.value = 'Data Connect failed: $e';
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          } finally {
                            isSaving.value = false;
                          }
                        },
                  child: Text(isSaving.value ? 'Saving...' : 'Save and retry'),
                ),
                if (canInitializeWorkspace.value) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: isSaving.value
                        ? null
                        : () async {
                            final user = ref.read(authProvider).value;
                            if (user == null) {
                              statusMessage.value = 'User is not signed in.';
                              return;
                            }

                            try {
                              isSaving.value = true;
                              final teamId = user.uid;
                              statusMessage.value =
                                  'Initializing user profile and team...';
                              debugPrint(
                                '[OpenCI] Initializing self-hosted workspace for user=${user.uid}',
                              );
                              await dataConnector
                                  .createTeamForCurrentUser(
                                    id: teamId,
                                    name: teamId,
                                  )
                                  .execute()
                                  .timeout(
                                    const Duration(seconds: 8),
                                    onTimeout: () => throw TimeoutException(
                                      'Timed out while initializing workspace',
                                    ),
                                  );
                              statusMessage.value = 'Workspace initialized.';
                              canInitializeWorkspace.value = false;
                              ref.invalidate(userProvider);
                              ref.invalidate(teamListProvider);
                              ref.invalidate(teamStateProvider);
                            } catch (e) {
                              debugPrint(
                                '[OpenCI] Failed to initialize self-hosted workspace: $e',
                              );
                              statusMessage.value =
                                  'Failed to initialize workspace: $e';
                            } finally {
                              isSaving.value = false;
                            }
                          },
                    child: Text(
                      isSaving.value
                          ? 'Initializing...'
                          : 'Initialize workspace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
