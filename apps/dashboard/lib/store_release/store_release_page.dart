import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/store_release/store_release_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StoreReleasePage extends HookConsumerWidget {
  const StoreReleasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseT = t.storeRelease;
    final isConfiguredAsync = ref.watch(isAscConfiguredProvider);

    return Scaffold(
      appBar: AppBar(title: Text(releaseT.title)),
      body: isConfiguredAsync.when(
        data: (isConfigured) {
          if (!isConfigured) {
            return _AscSetupView();
          }
          return _AppSelectionView();
        },
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: asyncErrorWidget,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// ASC Credentials Setup View
// ═══════════════════════════════════════════════════════════════════
class _AscSetupView extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseT = t.storeRelease;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final issuerIdController = useTextEditingController();
    final keyIdController = useTextEditingController();
    final privateKeyController = useTextEditingController();
    final isLoading = useState(false);
    final showHelp = useState(false);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.rocket_launch_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  releaseT.setupTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  releaseT.setupDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: issuerIdController,
                  decoration: InputDecoration(
                    labelText: releaseT.issuerId,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? releaseT.enterIssuerId : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: keyIdController,
                  decoration: InputDecoration(
                    labelText: releaseT.keyId,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.vpn_key_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? releaseT.enterKeyId : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: privateKeyController,
                  decoration: InputDecoration(
                    labelText: releaseT.privateKey,
                    hintText: releaseT.privateKeyHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (v) =>
                      v == null || v.isEmpty ? releaseT.enterPrivateKey : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => showHelp.value = !showHelp.value,
                    icon: Icon(
                      showHelp.value ? Icons.expand_less : Icons.help_outline,
                      size: 18,
                    ),
                    label: Text(releaseT.howToGetCredentials),
                  ),
                ),
                if (showHelp.value)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        releaseT.credentialsHelp,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          isLoading.value = true;
                          try {
                            await ref
                                .read(setupAscCredentialsProvider.notifier)
                                .setup(
                                  issuerId: issuerIdController.text.trim(),
                                  keyId: keyIdController.text.trim(),
                                  privateKey: privateKeyController.text.trim(),
                                );
                            if (context.mounted) {
                              context.showSnackBarMessage(
                                releaseT.setupSuccess,
                              );
                            }
                          } catch (e, s) {
                            debugPrint(e.toString());
                            debugPrint(s.toString());
                            if (context.mounted) {
                              context.showSnackBarMessage(
                                releaseT.setupFailed(error: e.toString()),
                              );
                            }
                          } finally {
                            isLoading.value = false;
                          }
                        },
                  icon: isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link),
                  label: Text(
                    isLoading.value ? releaseT.connecting : releaseT.connect,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// App Selection View (after credentials set up)
// ═══════════════════════════════════════════════════════════════════
class _AppSelectionView extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseT = t.storeRelease;
    final selectedApp = useState<AscApp?>(null);

    if (selectedApp.value != null) {
      return _BuildsView(
        app: selectedApp.value!,
        onChangeApp: () => selectedApp.value = null,
      );
    }

    final appsAsync = ref.watch(ascAppsProvider);

    return appsAsync.when(
      data: (apps) {
        if (apps.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apps_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    releaseT.noApps,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    releaseT.noAppsHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.rocket_launch,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        releaseT.selectApp,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    releaseT.selectAppHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: apps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final app = apps[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.apps,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            app.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            app.bundleId,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onTap: () => selectedApp.value = app,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Builds View (for a selected app)
// ═══════════════════════════════════════════════════════════════════
class _BuildsView extends HookConsumerWidget {
  const _BuildsView({required this.app, required this.onChangeApp});

  final AscApp app;
  final VoidCallback onChangeApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseT = t.storeRelease;
    final buildsAsync = ref.watch(ascBuildsProvider(app.id));

    return Column(
      children: [
        // App header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              ActionChip(
                avatar: const Icon(Icons.apps, size: 16),
                label: Text(
                  app.name,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: onChangeApp,
              ),
              const SizedBox(width: 8),
              Text(
                app.bundleId,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Builds list
        Expanded(
          child: buildsAsync.when(
            data: (builds) {
              if (builds.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        releaseT.noBuilds,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        releaseT.noBuildsHint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(ascBuildsProvider(app.id));
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: builds.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final build = builds[index];
                        return _BuildCard(
                          ascBuild: build,
                          appId: app.id,
                          appName: app.name,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            error: asyncErrorWidget,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Build Card
// ═══════════════════════════════════════════════════════════════════
class _BuildCard extends HookConsumerWidget {
  const _BuildCard({
    required this.ascBuild,
    required this.appId,
    required this.appName,
  });

  final AscBuild ascBuild;
  final String appId;
  final String appName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseT = t.storeRelease;
    final isSubmitting = useState(false);

    final processingColor = switch (ascBuild.processingState) {
      'VALID' => Colors.green,
      'PROCESSING' => Colors.orange,
      'FAILED' || 'INVALID' => Colors.red,
      _ => Colors.grey,
    };

    final processingLabel = switch (ascBuild.processingState) {
      'VALID' => releaseT.valid,
      'PROCESSING' => releaseT.processing,
      'FAILED' || 'INVALID' => releaseT.invalid,
      _ => ascBuild.processingState ?? '',
    };

    final betaStateLabel = switch (ascBuild.externalBuildState) {
      'READY_FOR_BETA_TESTING' => 'TestFlight Ready',
      'IN_BETA_TESTING' => 'In Testing',
      'EXPIRED' => 'Expired',
      'IN_EXPORT_COMPLIANCE_REVIEW' => 'Compliance Review',
      'WAITING_FOR_BETA_REVIEW' => 'Waiting for Review',
      'IN_BETA_REVIEW' => 'In Review',
      'BETA_REJECTED' => 'Rejected',
      'BETA_APPROVED' => 'Approved',
      _ => null,
    };

    final betaStateColor = switch (ascBuild.externalBuildState) {
      'READY_FOR_BETA_TESTING' ||
      'BETA_APPROVED' ||
      'IN_BETA_TESTING' => Colors.green,
      'WAITING_FOR_BETA_REVIEW' ||
      'IN_BETA_REVIEW' ||
      'IN_EXPORT_COMPLIANCE_REVIEW' => Colors.orange,
      'BETA_REJECTED' || 'EXPIRED' => Colors.red,
      _ => Colors.grey,
    };

    final uploadedAt = ascBuild.uploadedDate != null
        ? DateTime.tryParse(ascBuild.uploadedDate!)
        : null;
    final uploadedLabel = uploadedAt != null
        ? '${uploadedAt.month}/${uploadedAt.day} ${uploadedAt.hour}:${uploadedAt.minute.toString().padLeft(2, '0')}'
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        releaseT.version(version: ascBuild.version),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        releaseT.buildNumber(number: ascBuild.buildNumber),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (uploadedLabel.isNotEmpty)
                  Text(
                    uploadedLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Status badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Processing state
                _StatusChip(
                  label: processingLabel,
                  color: processingColor,
                  icon: ascBuild.processingState == 'PROCESSING'
                      ? null
                      : (ascBuild.processingState == 'VALID'
                            ? Icons.check_circle
                            : Icons.error),
                  isLoading: ascBuild.processingState == 'PROCESSING',
                ),
                // Platform
                _StatusChip(
                  label: ascBuild.platform,
                  color: Theme.of(context).colorScheme.secondary,
                  icon: ascBuild.platform == 'IOS'
                      ? Icons.phone_iphone
                      : Icons.desktop_mac,
                ),
                // Beta state
                if (betaStateLabel != null)
                  _StatusChip(
                    label: betaStateLabel,
                    color: betaStateColor,
                    icon: Icons.flight_takeoff,
                  ),
                // App Store review state
                if (ascBuild.appStoreState != null)
                  _StatusChip(
                    label: _appStoreStateLabel(
                      releaseT,
                      ascBuild.appStoreState!,
                    ),
                    color: _appStoreStateColor(ascBuild.appStoreState!),
                    icon: _appStoreStateIcon(ascBuild.appStoreState!),
                  ),
              ],
            ),
            // Action buttons
            if (ascBuild.isProcessingComplete) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              if (ascBuild.isSubmitted)
                // Show review status instead of submit button
                _ReviewStatusBanner(
                  appStoreState: ascBuild.appStoreState!,
                  releaseT: releaseT,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting.value
                            ? null
                            : () => _submitToTestFlight(
                                context,
                                ref,
                                isSubmitting,
                              ),
                        icon: const Icon(Icons.flight_takeoff, size: 18),
                        label: Text(releaseT.submitToTestFlight),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isSubmitting.value
                            ? null
                            : () => _submitForReview(
                                context,
                                ref,
                                isSubmitting,
                              ),
                        icon: const Icon(Icons.publish, size: 18),
                        label: Text(releaseT.submitForReview),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _submitToTestFlight(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isSubmitting,
  ) async {
    final releaseT = t.storeRelease;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(releaseT.testFlight),
        content: Text(releaseT.submitToTestFlightConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(releaseT.submitToTestFlight),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    isSubmitting.value = true;
    try {
      final groupName = await ref
          .read(submitToTestFlightProvider.notifier)
          .submit(ascBuild.id);
      if (context.mounted) {
        context.showSnackBarMessage(
          releaseT.testFlightSuccess(group: groupName),
        );
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      if (context.mounted) {
        context.showSnackBarMessage(
          releaseT.testFlightFailed(error: e.toString()),
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  void _submitForReview(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isSubmitting,
  ) async {
    final releaseT = t.storeRelease;
    final versionController = TextEditingController(text: ascBuild.version);
    final whatsNewController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(releaseT.appStoreReview),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  releaseT.submitForReviewConfirm(version: ascBuild.version),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: versionController,
                  decoration: InputDecoration(
                    labelText: releaseT.versionString,
                    hintText: releaseT.enterVersionString,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? releaseT.versionRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: whatsNewController,
                  decoration: InputDecoration(
                    labelText: releaseT.whatsNew,
                    hintText: releaseT.whatsNewHint,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (v) =>
                      v == null || v.isEmpty ? releaseT.whatsNewRequired : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: Text(releaseT.submitForReview),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    isSubmitting.value = true;
    try {
      await ref
          .read(submitForReviewProvider.notifier)
          .submit(
            appId: appId,
            buildId: ascBuild.id,
            versionString: versionController.text.trim(),
            whatsNew: whatsNewController.text.trim(),
            platform: ascBuild.platform,
          );
      if (context.mounted) {
        context.showSnackBarMessage(releaseT.reviewSuccess);
        ref.invalidate(ascBuildsProvider(appId));
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      if (context.mounted) {
        context.showSnackBarMessage(
          releaseT.reviewFailed(error: e.toString()),
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Status Chip Widget
// ═══════════════════════════════════════════════════════════════════
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// App Store State Helpers
// ═══════════════════════════════════════════════════════════════════
String _appStoreStateLabel(dynamic releaseT, String state) {
  return switch (state) {
    'WAITING_FOR_REVIEW' => releaseT.waitingForReview,
    'IN_REVIEW' => releaseT.inReview,
    'PENDING_DEVELOPER_RELEASE' => releaseT.pendingRelease,
    'READY_FOR_DISTRIBUTION' ||
    'READY_FOR_SALE' => releaseT.readyForDistribution,
    'DEVELOPER_REJECTED' => releaseT.developerRejected,
    'REJECTED' => releaseT.rejected,
    'PREPARE_FOR_SUBMISSION' => releaseT.prepareForSubmission,
    _ => state.replaceAll('_', ' ').toLowerCase(),
  };
}

Color _appStoreStateColor(String state) {
  return switch (state) {
    'WAITING_FOR_REVIEW' || 'IN_REVIEW' => Colors.orange,
    'PENDING_DEVELOPER_RELEASE' => Colors.blue,
    'READY_FOR_DISTRIBUTION' || 'READY_FOR_SALE' => Colors.green,
    'DEVELOPER_REJECTED' || 'REJECTED' => Colors.red,
    'PREPARE_FOR_SUBMISSION' => Colors.grey,
    _ => Colors.grey,
  };
}

IconData _appStoreStateIcon(String state) {
  return switch (state) {
    'WAITING_FOR_REVIEW' => Icons.hourglass_top,
    'IN_REVIEW' => Icons.rate_review,
    'PENDING_DEVELOPER_RELEASE' => Icons.pause_circle_outline,
    'READY_FOR_DISTRIBUTION' || 'READY_FOR_SALE' => Icons.check_circle,
    'DEVELOPER_REJECTED' || 'REJECTED' => Icons.cancel,
    'PREPARE_FOR_SUBMISSION' => Icons.edit_note,
    _ => Icons.info_outline,
  };
}

// ═══════════════════════════════════════════════════════════════════
// Review Status Banner Widget
// ═══════════════════════════════════════════════════════════════════
class _ReviewStatusBanner extends StatelessWidget {
  const _ReviewStatusBanner({
    required this.appStoreState,
    required this.releaseT,
  });

  final String appStoreState;
  final dynamic releaseT;

  @override
  Widget build(BuildContext context) {
    final color = _appStoreStateColor(appStoreState);
    final icon = _appStoreStateIcon(appStoreState);
    final label = _appStoreStateLabel(releaseT, appStoreState);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  releaseT.appStoreReview as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
