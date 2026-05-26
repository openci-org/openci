import 'package:dashboard/app_strings.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr/qr.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class AppDistributionsBody extends HookConsumerWidget {
  const AppDistributionsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final buildJobsAsync = ref.watch(buildJobsProvider);
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            t.common.error(error: error.toString()),
            style: TextStyle(color: colors.error),
          ),
        ),
      ),
      data: (user) {
        return buildJobsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                t.common.error(error: error.toString()),
                style: TextStyle(color: colors.error),
              ),
            ),
          ),
          data: (jobs) {
            // 本物の成功ビルド＆ipaが存在するもののみ表示
            final otaJobs = jobs
                .where(
                  (job) =>
                      job.status == BuildJobStatus.SUCCESS &&
                      job.ipaUrl != null &&
                      job.ipaUrl!.isNotEmpty,
                )
                .toList();

            if (otaJobs.isEmpty) {
              return Column(
                children: [
                  _DeviceEnrollmentHeader(user: user, colors: colors),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.install_mobile_rounded,
                              size: 64,
                              color: colors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '配信可能なビルドがありません',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'iOS OTA配信可能なビルドが成功すると、ここにインストール用ビルドが並びます。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // バージョンごとにグループ化
            final groupedJobs = <String, List<BuildJob>>{};
            for (final job in otaJobs) {
              final version = job.ipaVersion ?? '1.0.0';
              groupedJobs.putIfAbsent(version, () => []).add(job);
            }

            // 各バージョンの最新ジョブの createdAt に基づいてバージョンをソート
            final sortedVersions = groupedJobs.keys.toList()
              ..sort((a, b) {
                final aLatest = groupedJobs[a]!
                    .map((j) => j.createdAt)
                    .reduce((x, y) => x.isAfter(y) ? x : y);
                final bLatest = groupedJobs[b]!
                    .map((j) => j.createdAt)
                    .reduce((x, y) => x.isAfter(y) ? x : y);
                return bLatest.compareTo(aLatest);
              });

            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    _DeviceEnrollmentHeader(user: user, colors: colors),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: sortedVersions.length,
                        itemBuilder: (context, index) {
                          final version = sortedVersions[index];
                          final versionJobs = groupedJobs[version]!;

                          final latestJob = versionJobs.reduce(
                            (x, y) => x.createdAt.isAfter(y.createdAt) ? x : y,
                          );
                          final latestDateText =
                              '${latestJob.createdAt.toLocal().year}/${latestJob.createdAt.toLocal().month.toString().padLeft(2, '0')}/${latestJob.createdAt.toLocal().day.toString().padLeft(2, '0')} ${latestJob.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${latestJob.createdAt.toLocal().minute.toString().padLeft(2, '0')}';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            clipBehavior: Clip.antiAlias,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                initiallyExpanded: index == 0,
                                leading: Icon(
                                  Icons.inventory_2_outlined,
                                  color: colors.accent,
                                ),
                                title: Text(
                                  'バージョン $version',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  '最終ビルド: $latestDateText  (${versionJobs.length} 個のビルド)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                children: [
                                  const Divider(height: 1),
                                  ...versionJobs.map(
                                    (job) => _BuildListItem(
                                      buildJob: job,
                                      user: user,
                                    ),
                                  ),
                                ],
                              ),
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
        );
      },
    );
  }
}

String _maskUdid(String udid) {
  if (udid.length <= 8) {
    return '••••';
  }
  return '${udid.substring(0, 4)}••••${udid.substring(udid.length - 4)}';
}

class _DeviceEnrollmentHeader extends HookWidget {
  const _DeviceEnrollmentHeader({
    required this.user,
    required this.colors,
  });

  final OpenCIUser user;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final hasUdid = user.udid != null && user.udid!.isNotEmpty;
    final isUdidVisible = useState(false);

    return Card(
      color: colors.surfaceHover,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              hasUdid
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
              color: hasUdid ? colors.success : colors.warning,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasUdid ? 'デバイス登録済み' : 'デバイスUDIDが未登録です',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasUdid
                              ? (isUdidVisible.value
                                    ? 'UDID: ${user.udid}'
                                    : 'UDID: ${_maskUdid(user.udid!)}')
                              : 'iOSアプリをインストールするには、この端末のUDID登録が必要です。',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      if (hasUdid) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            isUdidVisible.value
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          splashRadius: 16,
                          onPressed: () =>
                              isUdidVisible.value = !isUdidVisible.value,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: hasUdid ? colors.scaffold : colors.accent,
                foregroundColor: hasUdid ? colors.textPrimary : Colors.white,
                side: hasUdid ? BorderSide(color: colors.border) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final origin = kIsWeb
                    ? Uri.base.origin
                    : 'https://dashboard.openci.org';
                final enrollUrl = '$origin/enroll-udid?userId=${user.id}';
                final uri = Uri.parse(enrollUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('登録ページを開けませんでした。')),
                    );
                  }
                }
              },
              icon: Icon(
                hasUdid ? Icons.sync_rounded : Icons.add_to_home_screen_rounded,
                size: 16,
              ),
              label: Text(
                hasUdid ? '再登録' : 'デバイスを登録',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _UdidStatus { unregistered, provisioned, unprovisioned }

class _UdidBadge extends StatelessWidget {
  const _UdidBadge({
    required this.status,
    required this.colors,
  });

  final _UdidStatus status;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    final String text;
    final IconData icon;

    switch (status) {
      case _UdidStatus.provisioned:
        badgeColor = colors.success;
        text = '登録済み';
        icon = Icons.check_circle_outline_rounded;
        break;
      case _UdidStatus.unprovisioned:
        badgeColor = colors.error;
        text = '未登録';
        icon = Icons.cancel_outlined;
        break;
      case _UdidStatus.unregistered:
        badgeColor = colors.textTertiary;
        text = 'UDID未登録';
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 9,
            color: badgeColor,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildListItem extends HookWidget {
  const _BuildListItem({
    required this.buildJob,
    required this.user,
  });

  final BuildJob buildJob;
  final OpenCIUser user;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isRequested = useState(false);
    final isUdidVisible = useState(false);

    final appName = buildJob.appName ?? 'OpenCI App';
    final runCount = buildJob.runCount ?? 1;
    final commitShaShort =
        buildJob.commitSha != null && buildJob.commitSha!.length > 7
        ? buildJob.commitSha!.substring(0, 7)
        : 'abcdefg';
    final branchName = buildJob.branch ?? 'main';

    final dateText =
        '${buildJob.createdAt.toLocal().year}/${buildJob.createdAt.toLocal().month.toString().padLeft(2, '0')}/${buildJob.createdAt.toLocal().day.toString().padLeft(2, '0')} ${buildJob.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${buildJob.createdAt.toLocal().minute.toString().padLeft(2, '0')}';

    final userUdid = user.udid;
    final isUdidProvisioned =
        userUdid != null &&
        buildJob.provisionedUdids != null &&
        buildJob.provisionedUdids!.contains(userUdid);

    final isDesktopOrWeb =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    final udidStatus = userUdid == null
        ? _UdidStatus.unregistered
        : (isUdidProvisioned
              ? _UdidStatus.provisioned
              : _UdidStatus.unprovisioned);

    final changelog = buildJob.failureSummary ?? '・軽微な不具合の修正およびUIの微調整';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.divider),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 上部：アプリ名、ビルド番号、iOSバッジ、UDID適合バッジ、インストールボタン
          Row(
            children: [
              // ビルド番号バッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$runCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _PlatformBadge(colors: colors),
              const SizedBox(width: 6),
              // UDID適合性バッジ
              _UdidBadge(status: udidStatus, colors: colors),
              const SizedBox(width: 8),
              // アプリ名
              Expanded(
                child: Text(
                  appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // インストールボタン
              SizedBox(
                height: 28,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: (isUdidProvisioned || isDesktopOrWeb)
                        ? const Color(0xFF3FB950)
                        : colors.textTertiary,
                    side: BorderSide(
                      color: (isUdidProvisioned || isDesktopOrWeb)
                          ? const Color(0xFF3FB950)
                          : colors.border,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: (isUdidProvisioned || isDesktopOrWeb)
                      ? () {
                          showDialog<void>(
                            context: context,
                            builder: (context) =>
                                _IosDistributionQrDialog(buildJob: buildJob),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.install_mobile_rounded, size: 12),
                  label: Text(
                    isUdidProvisioned
                        ? 'インストール'
                        : (isDesktopOrWeb ? 'インストール (QR)' : 'インストール不可'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 中部：Git情報（ブランチ、コミット）をチップ風バッジ化
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // ブランチ名チップ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFBC8CFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFBC8CFF).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fork_right_rounded,
                      size: 11,
                      color: Color(0xFFBC8CFF),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      branchName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBC8CFF),
                      ),
                    ),
                  ],
                ),
              ),
              // コミットShaチップ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.scaffold,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.commit_rounded,
                      size: 11,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      commitShaShort,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // ビルド日時表示
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 4),
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: colors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 未登録デバイスの警告バナー & コピー・申請フロー
          if (userUdid != null && !isUdidProvisioned) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.error.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: colors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'この端末 (UDID: ${isUdidVisible.value ? userUdid : _maskUdid(userUdid)}) は Provisioning Profile に未登録です。',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isUdidVisible.value
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 14,
                      color: colors.error,
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    splashRadius: 14,
                    onPressed: () => isUdidVisible.value = !isUdidVisible.value,
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      backgroundColor: colors.error.withValues(alpha: 0.1),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: isRequested.value
                        ? null
                        : () async {
                            try {
                              final requestId = const Uuid().v4();
                              final nowStr = DateTime.now()
                                  .toUtc()
                                  .toIso8601String();
                              await Clipboard.setData(
                                ClipboardData(text: userUdid),
                              );
                              await firestore
                                  .collection(udidRequestsCollection)
                                  .doc(requestId)
                                  .set({
                                    'id': requestId,
                                    'userId': user.id,
                                    'udid': user.udid,
                                    'deviceProduct': 'Unknown',
                                    'deviceOsVersion': 'Unknown',
                                    'teamId': user.selectedTeamId,
                                    'buildJobId': buildJob.id,
                                    'createdAt': nowStr,
                                    'status': 'pending',
                                  });
                              isRequested.value = true;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'UDID (${_maskUdid(userUdid)}) をコピーし、登録申請を送信しました。',
                                    ),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('申請の送信に失敗しました: $e'),
                                    duration: const Duration(seconds: 3),
                                    backgroundColor: colors.error,
                                  ),
                                );
                              }
                            }
                          },
                    icon: Icon(
                      isRequested.value
                          ? Icons.check_rounded
                          : Icons.send_rounded,
                      size: 12,
                      color: isRequested.value
                          ? colors.textTertiary
                          : colors.error,
                    ),
                    label: Text(
                      isRequested.value ? '申請済み' : 'UDIDを申請',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isRequested.value
                            ? colors.textTertiary
                            : colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (userUdid == null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.textTertiary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.textTertiary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colors.textTertiary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'この端末のUDIDが登録されていません。上のヘッダーからデバイス登録を行ってください。',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 下部：変更内容 (Changelog) コンテナ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.scaffold,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 11,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '変更内容:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  changelog,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                    height: 1.45,
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

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF007AFF).withValues(alpha: 0.2),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.apple,
            size: 9,
            color: Color(0xFF007AFF),
          ),
          SizedBox(width: 2),
          Text(
            'iOS',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    );
  }
}

class QrPainter extends CustomPainter {
  QrPainter({required this.qrImage, required this.color});

  final QrImage qrImage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final moduleCount = qrImage.moduleCount;
    final pixelSize = size.width / moduleCount;

    for (var row = 0; row < moduleCount; row++) {
      for (var col = 0; col < moduleCount; col++) {
        if (qrImage.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * pixelSize,
              row * pixelSize,
              pixelSize,
              pixelSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrPainter oldDelegate) =>
      oldDelegate.qrImage != qrImage || oldDelegate.color != color;
}

class QrCodeWidget extends StatelessWidget {
  const QrCodeWidget({
    super.key,
    required this.data,
    required this.size,
    required this.color,
  });

  final String data;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    QrImage? qrImage;
    for (var version = 1; version <= 40; version++) {
      try {
        final qrCode = QrCode(version, QrErrorCorrectLevel.M)..addData(data);
        qrImage = QrImage(qrCode);
        break;
      } catch (_) {
        if (version == 40) {
          // If we reach 40 and still fail, qrImage remains null
        }
      }
    }

    if (qrImage == null) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(child: Text('QR Code error')),
      );
    }

    return CustomPaint(
      size: Size(size, size),
      painter: QrPainter(qrImage: qrImage, color: color),
    );
  }
}

class _IosDistributionQrDialog extends HookWidget {
  const _IosDistributionQrDialog({required this.buildJob});

  final BuildJob buildJob;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isCopied = useState(false);

    final origin = kIsWeb ? Uri.base.origin : 'https://dashboard.openci.org';
    final manifestUrl = '$origin/iosManifest?buildJobId=${buildJob.id}';
    final installUrl =
        'itms-services://?action=download-manifest&url=${Uri.encodeComponent(manifestUrl)}';
    final installPageUrl = '$origin/install-ota?buildJobId=${buildJob.id}';

    return AlertDialog(
      backgroundColor: colors.surfaceHover,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      title: Row(
        children: [
          Icon(Icons.install_mobile_rounded, color: colors.success, size: 22),
          const SizedBox(width: 8),
          Text(
            'iOS アプリのインストール',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '実機のカメラ等で以下のQRコードを読み取るか、直接インストールボタンを押してください。',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            // QR Code Container
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: QrCodeWidget(
                  data: installPageUrl,
                  size: 160,
                  color: Colors.black,
                ),
              ),
            ),
            if (defaultTargetPlatform != TargetPlatform.iOS) ...[
              const SizedBox(height: 14),
              Text(
                'インストール用URL:',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.scaffold,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        installPageUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isCopied.value ? Icons.check_rounded : Icons.copy_rounded,
                      size: 16,
                      color: isCopied.value
                          ? colors.success
                          : colors.textSecondary,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: installPageUrl));
                      isCopied.value = true;
                      Future.delayed(const Duration(seconds: 2), () {
                        isCopied.value = false;
                      });
                    },
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: installPageUrl));
                    isCopied.value = true;
                    Future.delayed(const Duration(seconds: 2), () {
                      isCopied.value = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URLをコピーしました。Safariに貼り付けて開いてください。'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: Icon(
                    isCopied.value ? Icons.check_rounded : Icons.copy_rounded,
                    size: 14,
                    color: isCopied.value ? colors.success : colors.textPrimary,
                  ),
                  label: Text(
                    isCopied.value ? 'コピー完了！Safariに貼り付け' : 'Safari用にURLをコピー',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '※ BraveやChromeなどのサードパーティ製ブラウザや、LINE/Slack等のアプリ内ブラウザをお使いの場合は、上のボタンでURLをコピーしてSafariに貼り付けて開いてください。',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              // Direct install button for mobile testing
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse(installUrl);
                    try {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('リンクを開けませんでした。')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('このデバイスに直接インストール'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            t.common.close,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
