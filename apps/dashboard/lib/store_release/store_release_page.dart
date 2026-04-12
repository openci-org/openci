import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/store_release/store_release_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class StoreReleaseBody extends HookConsumerWidget {
  const StoreReleaseBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConfiguredAsync = ref.watch(isAscConfiguredProvider);

    return isConfiguredAsync.when(
      data: (isConfigured) {
        if (!isConfigured) {
          return _AscSetupView();
        }
        return _AppSelectionView(
          onAppSelected: (app) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (context) {
                return FractionallySizedBox(
                  heightFactor: 0.9,
                  child: _SubmissionWizardPage(
                    app: app,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: asyncErrorWidget,
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
// App Selection View
// ═══════════════════════════════════════════════════════════════════
class _AppSelectionView extends ConsumerWidget {
  const _AppSelectionView({required this.onAppSelected});

  final ValueChanged<AscApp> onAppSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseT = t.storeRelease;

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
                          onTap: () {
                            onAppSelected(app);
                          },
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
      loading: () {
        final dummyApps = List.generate(
          3,
          (index) => AscApp(
            id: 'dummy_$index',
            name: 'Loading App Name',
            bundleId: 'com.example.loading.bundleid',
          ),
        );
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          releaseT.ascLoadingHint,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Skeletonizer(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: dummyApps.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final app = dummyApps[index];
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
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
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: asyncErrorWidget,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Submission Wizard Page (full page with Scaffold)
// ═══════════════════════════════════════════════════════════════════
class _SubmissionWizardPage extends HookConsumerWidget {
  const _SubmissionWizardPage({
    required this.app,
    required this.onBack,
  });

  final AscApp app;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildsAsync = ref.watch(ascBuildsProvider(app.id));
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onBack,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.apps, size: 16, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      app.bundleId,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: buildsAsync.when(
            data: (builds) {
              final activeReviewBuild = builds.where(
                (b) =>
                    b.isInReview ||
                    b.appStoreState == 'PENDING_DEVELOPER_RELEASE',
              );

              if (activeReviewBuild.isNotEmpty) {
                return _InReviewView(
                  app: app,
                  reviewBuild: activeReviewBuild.first,
                );
              }

              return _WizardSteps(
                app: app,
                onBack: onBack,
              );
            },
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator.adaptive(),
                    const SizedBox(height: 16),
                    Text(
                      t.storeRelease.ascLoadingHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            error: asyncErrorWidget,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// In-Review View (locked state)
// ═══════════════════════════════════════════════════════════════════
class _InReviewView extends HookConsumerWidget {
  const _InReviewView({
    required this.app,
    required this.reviewBuild,
  });

  final AscApp app;
  final AscBuild reviewBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseT = t.storeRelease;
    final cs = Theme.of(context).colorScheme;

    final isPending = reviewBuild.appStoreState == 'PENDING_DEVELOPER_RELEASE';
    final isWaiting = reviewBuild.appStoreState == 'WAITING_FOR_REVIEW';

    final statusColor = isPending ? Colors.green : Colors.orange;
    final statusTitle = isPending
        ? releaseT.pendingReleaseTitle
        : releaseT.underReview;
    final statusDescription = isPending
        ? releaseT.pendingReleaseDescription
        : isWaiting
        ? releaseT.waitingForReviewDescription
        : releaseT.underReviewDescription;
    final statusIcon = isPending
        ? Icons.check_circle
        : isWaiting
        ? Icons.hourglass_top
        : Icons.rate_review;

    final uploadedAt = reviewBuild.uploadedDate != null
        ? DateTime.tryParse(reviewBuild.uploadedDate!)
        : null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Status icon with pulsing ring
              _PulsingStatusIcon(
                icon: statusIcon,
                color: statusColor,
                isPulsing: !isPending,
              ),
              const SizedBox(height: 24),

              // Status title
              Text(
                statusTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 8),

              // Status description
              Text(
                statusDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // Estimated wait hint
              if (!isPending)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        releaseT.estimatedWait,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Build info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.build_outlined,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            releaseT.submittedBuild,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _InfoRow(
                        label: releaseT.versionString,
                        value: releaseT.version(
                          version: reviewBuild.version,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: releaseT.buildNumber(
                          number: reviewBuild.buildNumber,
                        ),
                        value: reviewBuild.platform,
                      ),
                      if (uploadedAt != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: releaseT.submittedOn,
                          value:
                              '${uploadedAt.year}/${uploadedAt.month}/${uploadedAt.day} '
                              '${uploadedAt.hour}:${uploadedAt.minute.toString().padLeft(2, '0')}',
                        ),
                      ],
                      const Divider(height: 20),
                      // Review status badge
                      Row(
                        children: [
                          _StatusChip(
                            label: _appStoreStateLabel(
                              releaseT,
                              reviewBuild.appStoreState!,
                            ),
                            color: statusColor,
                            icon: statusIcon,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Pulsing Status Icon (animated ring for review state)
// ═══════════════════════════════════════════════════════════════════
class _PulsingStatusIcon extends HookWidget {
  const _PulsingStatusIcon({
    required this.icon,
    required this.color,
    this.isPulsing = true,
  });

  final IconData icon;
  final Color color;
  final bool isPulsing;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    useEffect(() {
      if (isPulsing) {
        controller.repeat(reverse: true);
      }
      return null;
    }, [isPulsing]);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = isPulsing ? 1.0 + (controller.value * 0.15) : 1.0;
        final opacity = isPulsing ? 0.3 - (controller.value * 0.2) : 0.15;

        return SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: opacity.clamp(0.05, 0.3)),
                      width: 3,
                    ),
                  ),
                ),
              ),
              // Inner solid circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Wizard Steps (the actual 3-step flow)
// ═══════════════════════════════════════════════════════════════════
class _WizardSteps extends HookConsumerWidget {
  const _WizardSteps({
    required this.app,
    required this.onBack,
  });

  final AscApp app;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseT = t.storeRelease;
    final cs = Theme.of(context).colorScheme;

    final currentStep = useState(0);
    final selectedBuild = useState<AscBuild?>(null);
    final versionController = useTextEditingController();
    final whatsNewController = useTextEditingController();
    final isSubmitting = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Listen to text controllers for Next button state
    useListenable(versionController);
    useListenable(whatsNewController);

    final stepTitles = [
      releaseT.stepBuild,
      releaseT.stepDetails,
      releaseT.stepReview,
    ];

    final stepIcons = [
      Icons.build_outlined,
      Icons.edit_note,
      Icons.check_circle_outline,
    ];

    void onBuildSelected(AscBuild build) {
      selectedBuild.value = build;
      if (versionController.text.isEmpty) {
        versionController.text = build.version;
      }
    }

    final canProceed = switch (currentStep.value) {
      0 => selectedBuild.value != null,
      1 =>
        versionController.text.trim().isNotEmpty &&
            whatsNewController.text.trim().isNotEmpty,
      _ => false,
    };

    void goNext() {
      if (currentStep.value == 1) {
        if (!(formKey.currentState?.validate() ?? false)) return;
      }
      currentStep.value++;
    }

    void goBack() {
      if (currentStep.value > 0) {
        currentStep.value--;
      } else {
        onBack();
      }
    }

    Future<void> submitForReview() async {
      if (selectedBuild.value == null) return;
      isSubmitting.value = true;
      try {
        await ref
            .read(submitForReviewProvider.notifier)
            .submit(
              appId: app.id,
              buildId: selectedBuild.value!.id,
              versionString: versionController.text.trim(),
              whatsNew: whatsNewController.text.trim(),
              platform: selectedBuild.value!.platform,
            );
        if (context.mounted) {
          context.showSnackBarMessage(releaseT.reviewSuccess);
          ref.invalidate(ascBuildsProvider(app.id));
          onBack();
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

    return PopScope(
      canPop: currentStep.value == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          currentStep.value--;
        }
      },
      child: Column(
        children: [
          // ── Step Indicator ──
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 8),
            child: _WizardStepBar(
              currentStep: currentStep.value,
              stepTitles: stepTitles,
              stepIcons: stepIcons,
            ),
          ),

          // ── Step Content ──
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: switch (currentStep.value) {
                    0 => _BuildPickerStep(
                      key: const ValueKey('step_build'),
                      appId: app.id,
                      selectedBuild: selectedBuild.value,
                      onBuildSelected: onBuildSelected,
                    ),
                    1 => _DetailsStep(
                      key: const ValueKey('step_details'),
                      formKey: formKey,
                      versionController: versionController,
                      whatsNewController: whatsNewController,
                    ),
                    2 => _ReviewStep(
                      key: const ValueKey('step_review'),
                      app: app,
                      selectedBuild: selectedBuild.value!,
                      versionString: versionController.text,
                      whatsNew: whatsNewController.text,
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ),

          // ── Bottom Navigation ──
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (currentStep.value > 0)
                      OutlinedButton.icon(
                        onPressed: goBack,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(releaseT.back),
                      ),
                    const Spacer(),
                    if (currentStep.value < 2)
                      FilledButton.icon(
                        onPressed: canProceed ? goNext : null,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: Text(releaseT.next),
                      )
                    else
                      FilledButton.icon(
                        onPressed: isSubmitting.value ? null : submitForReview,
                        icon: isSubmitting.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.publish, size: 18),
                        label: Text(
                          isSubmitting.value
                              ? releaseT.submittingReview
                              : releaseT.confirmSubmit,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Wizard Step Bar
// ═══════════════════════════════════════════════════════════════════
class _WizardStepBar extends StatelessWidget {
  const _WizardStepBar({
    required this.currentStep,
    required this.stepTitles,
    required this.stepIcons,
  });

  final int currentStep;
  final List<String> stepTitles;
  final List<IconData> stepIcons;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(stepTitles.length * 2 - 1, (index) {
        if (index.isOdd) {
          final lineIndex = index ~/ 2;
          final isCompleted = lineIndex < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isCompleted ? cs.primary : cs.outlineVariant,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isCurrent = stepIndex == currentStep;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? cs.primary
                    : isCurrent
                    ? cs.primary
                    : cs.surfaceContainerHighest,
                border: Border.all(
                  color: isCompleted || isCurrent
                      ? cs.primary
                      : cs.outlineVariant,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check, size: 18, color: cs.onPrimary)
                    : Icon(
                        stepIcons[stepIndex],
                        size: 16,
                        color: isCurrent ? cs.onPrimary : cs.onSurfaceVariant,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stepTitles[stepIndex],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCompleted || isCurrent
                    ? cs.primary
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Step 1: Build Picker
// ═══════════════════════════════════════════════════════════════════
class _BuildPickerStep extends HookConsumerWidget {
  const _BuildPickerStep({
    super.key,
    required this.appId,
    required this.selectedBuild,
    required this.onBuildSelected,
  });

  final String appId;
  final AscBuild? selectedBuild;
  final ValueChanged<AscBuild> onBuildSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseT = t.storeRelease;
    final cs = Theme.of(context).colorScheme;
    final buildsAsync = ref.watch(ascBuildsProvider(appId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            releaseT.selectBuildTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            releaseT.selectBuildHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        // Build list
        Expanded(
          child: buildsAsync.when(
            data: (builds) {
              final validBuilds = builds
                  .where((b) => b.isProcessingComplete)
                  .toList();
              if (validBuilds.isEmpty) {
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

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ascBuildsProvider(appId));
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: validBuilds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final build = validBuilds[index];
                    final isSelected = selectedBuild?.id == build.id;
                    final isAlreadySubmitted = build.isSubmitted;

                    return _SelectableBuildCard(
                      ascBuild: build,
                      isSelected: isSelected,
                      isDisabled: isAlreadySubmitted,
                      onTap: isAlreadySubmitted
                          ? null
                          : () => onBuildSelected(build),
                    );
                  },
                ),
              );
            },
            loading: () {
              final dummyBuilds = List.generate(
                3,
                (index) => AscBuild(
                  id: 'dummy_$index',
                  version: '1.0.$index',
                  buildNumber: '10$index',
                  platform: 'IOS',
                  appStoreState: 'READY_FOR_TESTING',
                ),
              );
              return Skeletonizer(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: dummyBuilds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    return _SelectableBuildCard(
                      ascBuild: dummyBuilds[index],
                      isSelected: false,
                      isDisabled: false,
                      onTap: null,
                    );
                  },
                ),
              );
            },
            error: asyncErrorWidget,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Selectable Build Card
// ═══════════════════════════════════════════════════════════════════
class _SelectableBuildCard extends StatelessWidget {
  const _SelectableBuildCard({
    required this.ascBuild,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final AscBuild ascBuild;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final releaseT = t.storeRelease;
    final cs = Theme.of(context).colorScheme;

    final uploadedAt = ascBuild.uploadedDate != null
        ? DateTime.tryParse(ascBuild.uploadedDate!)
        : null;
    final uploadedLabel = uploadedAt != null
        ? '${uploadedAt.month}/${uploadedAt.day} ${uploadedAt.hour}:${uploadedAt.minute.toString().padLeft(2, '0')}'
        : '';

    final betaStateLabel = switch (ascBuild.externalBuildState) {
      'READY_FOR_BETA_TESTING' => 'TestFlight Ready',
      'IN_BETA_TESTING' => 'In Testing',
      'EXPIRED' => 'Expired',
      'WAITING_FOR_BETA_REVIEW' => 'Waiting for Review',
      'IN_BETA_REVIEW' => 'In Review',
      'BETA_REJECTED' => 'Rejected',
      'BETA_APPROVED' => 'Approved',
      _ => null,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? cs.primary.withValues(alpha: 0.06)
            : isDisabled
            ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
            : cs.surface,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Radio indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? cs.primary
                          : isDisabled
                          ? cs.outlineVariant
                          : cs.outline,
                      width: 2,
                    ),
                    color: isSelected ? cs.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                      : null,
                ),
                const SizedBox(width: 12),
                // Build info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            releaseT.version(version: ascBuild.version),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDisabled ? cs.onSurfaceVariant : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            releaseT.buildNumber(number: ascBuild.buildNumber),
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          if (uploadedLabel.isNotEmpty)
                            Text(
                              uploadedLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Status row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _StatusChip(
                            label: ascBuild.platform,
                            color: cs.secondary,
                            icon: ascBuild.platform == 'IOS'
                                ? Icons.phone_iphone
                                : Icons.desktop_mac,
                          ),
                          if (betaStateLabel != null)
                            _StatusChip(
                              label: betaStateLabel,
                              color: Colors.orange,
                              icon: Icons.flight_takeoff,
                            ),
                          if (ascBuild.isSubmitted &&
                              ascBuild.appStoreState != null)
                            _StatusChip(
                              label: _appStoreStateLabel(
                                releaseT,
                                ascBuild.appStoreState!,
                              ),
                              color: _appStoreStateColor(
                                ascBuild.appStoreState!,
                              ),
                              icon: _appStoreStateIcon(ascBuild.appStoreState!),
                            ),
                        ],
                      ),
                    ],
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
// Step 2: Release Details
// ═══════════════════════════════════════════════════════════════════
class _DetailsStep extends HookConsumerWidget {
  const _DetailsStep({
    super.key,
    required this.formKey,
    required this.versionController,
    required this.whatsNewController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController versionController;
  final TextEditingController whatsNewController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releaseT = t.storeRelease;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Text(
              releaseT.releaseDetailsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              releaseT.releaseDetailsHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Version String
            TextFormField(
              controller: versionController,
              decoration: InputDecoration(
                labelText: releaseT.versionString,
                hintText: releaseT.enterVersionString,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.tag),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? releaseT.versionRequired
                  : null,
            ),
            const SizedBox(height: 20),

            // What's New
            TextFormField(
              controller: whatsNewController,
              decoration: InputDecoration(
                labelText: releaseT.whatsNew,
                hintText: releaseT.whatsNewHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.notes),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (v) => v == null || v.trim().isEmpty
                  ? releaseT.whatsNewRequired
                  : null,
            ),
            const SizedBox(height: 32),

            // Existing App Store Info (read-only preview)
            // TODO: Replace with real ASC data once backend is wired
            _SectionHeader(
              icon: Icons.info_outline,
              title: releaseT.existingInfo,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: releaseT.appDescription,
                      value:
                          'Your app description will be shown here once connected to App Store Connect.',
                      isPlaceholder: true,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      label: releaseT.keywordsLabel,
                      value: 'ci, cd, mobile, build, deploy',
                      isPlaceholder: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Step 3: Review & Submit
// ═══════════════════════════════════════════════════════════════════
class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.app,
    required this.selectedBuild,
    required this.versionString,
    required this.whatsNew,
  });

  final AscApp app;
  final AscBuild selectedBuild;
  final String versionString;
  final String whatsNew;

  @override
  Widget build(BuildContext context) {
    final releaseT = t.storeRelease;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            releaseT.reviewTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            releaseT.reviewHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // ── Summary Card ──
          _SectionHeader(
            icon: Icons.summarize_outlined,
            title: releaseT.summarySection,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          Icons.apps,
                          size: 20,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              app.bundleId,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Build info
                  _InfoRow(
                    label: releaseT.selectedBuildLabel,
                    value:
                        '${releaseT.version(version: selectedBuild.version)} '
                        '(${releaseT.buildNumber(number: selectedBuild.buildNumber)})',
                  ),
                  const Divider(height: 24),
                  // Version
                  _InfoRow(
                    label: releaseT.versionString,
                    value: versionString,
                  ),
                  const Divider(height: 24),
                  // What's New
                  _InfoRow(
                    label: releaseT.whatsNew,
                    value: whatsNew,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Screenshots Preview ──
          _SectionHeader(
            icon: Icons.photo_library_outlined,
            title: releaseT.screenshotsTitle,
          ),
          const SizedBox(height: 8),
          // TODO: Replace with real screenshots from ASC API
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      releaseT.noScreenshots,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      releaseT.screenshotsHint,
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Notice ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.tertiary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: cs.tertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    releaseT.submitForReviewConfirm(
                      version: versionString,
                    ),
                    style: TextStyle(fontSize: 13, color: cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared Widgets
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isPlaceholder = false,
  });

  final String label;
  final String value;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isPlaceholder
                ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                : cs.onSurface,
            fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

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
          if (icon != null) Icon(icon, size: 12, color: color),
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
