import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/store_release/store_release_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

// ═══════════════════════════════════════════════════════════════════
// Design Tokens (ui.sh)
// ═══════════════════════════════════════════════════════════════════
const _cardBg = Color(0xFF18181B);
const _cardBorder = Color(0xFF27272A);
const _inputBg = Color(0xFF1C1C1E);
const _accentBlue = Color(0xFF3B82F6);
const _textPrimary = Color(0xFFFAFAFA);
const _textSecondary = Color(0xFFA1A1AA);
const _textTertiary = Color(0xFF71717A);
const _radius = 12.0;

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
              backgroundColor: const Color(0xFF09090B),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
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
      loading: () => const Center(
        child: CircularProgressIndicator.adaptive(
          valueColor: AlwaysStoppedAnimation(_accentBlue),
        ),
      ),
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
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _accentBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_outlined,
                    size: 32,
                    color: _accentBlue,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  releaseT.setupTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  releaseT.setupDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StyledTextField(
                        controller: issuerIdController,
                        label: releaseT.issuerId,
                        icon: Icons.badge_outlined,
                        validator: (v) => v == null || v.isEmpty
                            ? releaseT.enterIssuerId
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: keyIdController,
                        label: releaseT.keyId,
                        icon: Icons.vpn_key_outlined,
                        validator: (v) => v == null || v.isEmpty
                            ? releaseT.enterKeyId
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _StyledTextField(
                        controller: privateKeyController,
                        label: releaseT.privateKey,
                        hint: releaseT.privateKeyHint,
                        icon: Icons.lock_outline,
                        maxLines: 4,
                        validator: (v) => v == null || v.isEmpty
                            ? releaseT.enterPrivateKey
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Help toggle
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => showHelp.value = !showHelp.value,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            showHelp.value
                                ? Icons.expand_less
                                : Icons.help_outline,
                            size: 16,
                            color: _accentBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            releaseT.howToGetCredentials,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _accentBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showHelp.value) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _accentBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(
                        color: _accentBlue.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: _accentBlue.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            releaseT.credentialsHelp,
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Connect Button
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_radius),
                      ),
                    ),
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
                                    privateKey:
                                        privateKeyController.text.trim(),
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
                    child: isLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.link, size: 18),
                              const SizedBox(width: 8),
                              Text(releaseT.connect),
                            ],
                          ),
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
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: const Icon(
                      Icons.apps_outlined,
                      size: 32,
                      color: _textTertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    releaseT.noApps,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    releaseT.noAppsHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
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
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.rocket_launch,
                          size: 16,
                          color: _accentBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        releaseT.selectApp,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      releaseT.selectAppHint,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                ),
                // App list
                Expanded(
                  child: Scrollbar(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: apps.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final app = apps[index];
                        return _AppCard(
                          app: app,
                          onTap: () => onAppSelected(app),
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.rocket_launch,
                          size: 16,
                          color: _accentBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        releaseT.selectApp,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      releaseT.selectAppHint,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
                    ),
                  ),
                ),
                // Loading hint
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _accentBlue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _accentBlue.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: _accentBlue.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            releaseT.ascLoadingHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        return _AppCard(
                          app: app,
                          onTap: null,
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
// App Card
// ═══════════════════════════════════════════════════════════════════
class _AppCard extends StatelessWidget {
  const _AppCard({required this.app, required this.onTap});

  final AscApp app;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.apps, size: 20, color: _accentBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.bundleId,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: _textTertiary,
              ),
            ],
          ),
        ),
      ),
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

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _cardBorder),
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: _textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.apps,
                  size: 16,
                  color: _accentBlue,
                ),
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
                        fontSize: 15,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      app.bundleId,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                    const CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation(_accentBlue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.storeRelease.ascLoadingHint,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 8),

              // Status description
              Text(
                statusDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
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
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: _textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        releaseT.estimatedWait,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Build info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(_radius),
                  border: Border.all(color: _cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      icon: Icons.build_outlined,
                      title: releaseT.submittedBuild,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 1,
                      color: _cardBorder,
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      label: releaseT.versionString,
                      value: releaseT.version(
                        version: reviewBuild.version,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      label: releaseT.buildNumber(
                        number: reviewBuild.buildNumber,
                      ),
                      value: reviewBuild.platform,
                    ),
                    if (uploadedAt != null) ...[
                      const SizedBox(height: 14),
                      _InfoRow(
                        label: releaseT.submittedOn,
                        value:
                            '${uploadedAt.year}/${uploadedAt.month}/${uploadedAt.day} '
                            '${uploadedAt.hour}:${uploadedAt.minute.toString().padLeft(2, '0')}',
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      height: 1,
                      color: _cardBorder,
                    ),
                    const SizedBox(height: 14),
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
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: _cardBorder),
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
                      SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textSecondary,
                            side: const BorderSide(color: _cardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_radius),
                            ),
                          ),
                          onPressed: goBack,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back, size: 16),
                              const SizedBox(width: 6),
                              Text(releaseT.back),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (currentStep.value < 2)
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                canProceed ? _accentBlue : _cardBg,
                            foregroundColor:
                                canProceed ? Colors.white : _textTertiary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_radius),
                              side: BorderSide(
                                color: canProceed
                                    ? Colors.transparent
                                    : _cardBorder,
                              ),
                            ),
                          ),
                          onPressed: canProceed ? goNext : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(releaseT.next),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_radius),
                            ),
                          ),
                          onPressed:
                              isSubmitting.value ? null : submitForReview,
                          child: isSubmitting.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.publish, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      isSubmitting.value
                                          ? releaseT.submittingReview
                                          : releaseT.confirmSubmit,
                                    ),
                                  ],
                                ),
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
                color: isCompleted ? _accentBlue : _cardBorder,
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
                color: isCompleted || isCurrent
                    ? _accentBlue
                    : _cardBg,
                border: Border.all(
                  color: isCompleted || isCurrent
                      ? _accentBlue
                      : _cardBorder,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Icon(
                        stepIcons[stepIndex],
                        size: 16,
                        color: isCurrent ? Colors.white : _textTertiary,
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
                    ? _accentBlue
                    : _textTertiary,
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
    final buildsAsync = ref.watch(ascBuildsProvider(appId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            releaseT.selectBuildTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            releaseT.selectBuildHint,
            style: const TextStyle(
              fontSize: 13,
              color: _textSecondary,
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
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          size: 32,
                          color: _textTertiary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        releaseT.noBuilds,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        releaseT.noBuildsHint,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
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
                color: _accentBlue,
                child: Scrollbar(
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
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: isSelected
              ? _accentBlue
              : _cardBorder,
          width: isSelected ? 1.5 : 1,
        ),
        color: isSelected
            ? _accentBlue.withValues(alpha: 0.06)
            : isDisabled
            ? const Color(0xFF0F0F11)
            : _cardBg,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
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
                          ? _accentBlue
                          : isDisabled
                          ? _cardBorder
                          : _textTertiary,
                      width: 2,
                    ),
                    color: isSelected ? _accentBlue : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
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
                              color: isDisabled
                                  ? _textTertiary
                                  : _textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            releaseT.buildNumber(number: ascBuild.buildNumber),
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                          const Spacer(),
                          if (uploadedLabel.isNotEmpty)
                            Text(
                              uploadedLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textTertiary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Status row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _StatusChip(
                            label: ascBuild.platform,
                            color: _textSecondary,
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              releaseT.releaseDetailsHint,
              style: const TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Form card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: _cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Version String
                  _StyledTextField(
                    controller: versionController,
                    label: releaseT.versionString,
                    hint: releaseT.enterVersionString,
                    icon: Icons.tag,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? releaseT.versionRequired
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // What's New
                  _StyledTextField(
                    controller: whatsNewController,
                    label: releaseT.whatsNew,
                    hint: releaseT.whatsNewHint,
                    icon: Icons.notes,
                    maxLines: 6,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? releaseT.whatsNewRequired
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Existing App Store Info (read-only preview)
            _SectionHeader(
              icon: Icons.info_outline,
              title: releaseT.existingInfo,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: _cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: releaseT.appDescription,
                    value:
                        'Your app description will be shown here once connected to App Store Connect.',
                    isPlaceholder: true,
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: _cardBorder),
                  const SizedBox(height: 14),
                  _InfoRow(
                    label: releaseT.keywordsLabel,
                    value: 'ci, cd, mobile, build, deploy',
                    isPlaceholder: true,
                  ),
                ],
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            releaseT.reviewTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            releaseT.reviewHint,
            style: const TextStyle(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // ── Summary Card ──
          _SectionHeader(
            icon: Icons.summarize_outlined,
            title: releaseT.summarySection,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: _cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App info
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _accentBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.apps,
                        size: 20,
                        color: _accentBlue,
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
                              color: _textPrimary,
                            ),
                          ),
                          Text(
                            app.bundleId,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: _cardBorder),
                const SizedBox(height: 14),
                // Build info
                _InfoRow(
                  label: releaseT.selectedBuildLabel,
                  value:
                      '${releaseT.version(version: selectedBuild.version)} '
                      '(${releaseT.buildNumber(number: selectedBuild.buildNumber)})',
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: _cardBorder),
                const SizedBox(height: 14),
                // Version
                _InfoRow(
                  label: releaseT.versionString,
                  value: versionString,
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: _cardBorder),
                const SizedBox(height: 14),
                // What's New
                _InfoRow(
                  label: releaseT.whatsNew,
                  value: whatsNew,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Screenshots Preview ──
          _SectionHeader(
            icon: Icons.photo_library_outlined,
            title: releaseT.screenshotsTitle,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: _cardBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: _textTertiary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '',
                    style: TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                  Text(
                    releaseT.noScreenshots,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    releaseT.screenshotsHint,
                    style: TextStyle(
                      color: _textTertiary.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Notice ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accentBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: _accentBlue.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: _accentBlue.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    releaseT.submitForReviewConfirm(
                      version: versionString,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textSecondary,
                      height: 1.5,
                    ),
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

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            color: _textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: _textTertiary.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: _inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _accentBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.red.withValues(alpha: 0.5),
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 14 : 12,
            ),
            prefixIcon: icon != null
                ? Padding(
                    padding: EdgeInsets.only(
                      bottom: maxLines > 1 ? (maxLines - 1) * 20.0 : 0,
                    ),
                    child: Icon(icon, size: 18, color: _textTertiary),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _accentBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _accentBlue,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: isPlaceholder
                ? _textTertiary.withValues(alpha: 0.6)
                : _textPrimary,
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
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
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
    'PENDING_DEVELOPER_RELEASE' => _accentBlue,
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
