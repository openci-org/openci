import 'dart:convert';

import 'package:app_minimizer_plus/app_minimizer_plus.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:qr/qr.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDistributionsBody extends HookConsumerWidget {
  const AppDistributionsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final buildJobsAsync = ref.watch(otaBuildJobsProvider);
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
                              color: colors.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '配信可能なビルドがありません',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'iOS OTA配信可能なビルドが成功すると、ここにインストール用ビルドが並びます。',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.onSurfaceVariant,
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
                                  color: colors.primary,
                                ),
                                title: Text(
                                  'バージョン $version',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  '最終ビルド: $latestDateText  (${versionJobs.length} 個のビルド)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
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

class _DeviceEnrollmentHeader extends HookConsumerWidget {
  const _DeviceEnrollmentHeader({
    required this.user,
    required this.colors,
  });

  final OpenCIUser user;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverUrl = ref.watch(openciServerUrlProvider);
    final selectedTeamId = ref.watch(selectedTeamIdProvider).value;
    final devicesAsync = ref.watch(userDevicesProvider);

    String? userUdid;
    if (devicesAsync.value != null && selectedTeamId != null) {
      for (final d in devicesAsync.value!) {
        if (d.teamId == selectedTeamId) {
          userUdid = d.udid;
          break;
        }
      }
    }
    final hasUdid = userUdid != null && userUdid.isNotEmpty;
    final isUdidVisible = useState(false);

    return Card(
      color: colors.onSurface.withValues(alpha: 0.08),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              hasUdid
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
              color: hasUdid ? Colors.green : Colors.orange,
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
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasUdid
                              ? (isUdidVisible.value
                                    ? 'UDID: $userUdid'
                                    : 'UDID: ${_maskUdid(userUdid)}')
                              : 'iOSアプリをインストールするには、この端末のUDID登録が必要です。',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
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
                            color: colors.onSurfaceVariant,
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
                backgroundColor: hasUdid
                    ? Theme.of(context).scaffoldBackgroundColor
                    : colors.primary,
                foregroundColor: hasUdid ? colors.onSurface : Colors.white,
                side: hasUdid ? BorderSide(color: colors.outlineVariant) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final origin = kIsWeb
                    ? Uri.base.origin
                    : 'https://dashboard.openci.org';
                final enrollUrl =
                    '$serverUrl/devices/mobile-config?userId=${user.id}&teamId=$selectedTeamId&redirectOrigin=${Uri.encodeComponent(origin)}';
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
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    final String text;
    final IconData icon;

    switch (status) {
      case _UdidStatus.provisioned:
        badgeColor = Colors.green;
        text = '登録済み';
        icon = Icons.check_circle_outline_rounded;
        break;
      case _UdidStatus.unprovisioned:
        badgeColor = colors.error;
        text = '未登録';
        icon = Icons.cancel_outlined;
        break;
      case _UdidStatus.unregistered:
        badgeColor = colors.outline;
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

class _BuildListItem extends HookConsumerWidget {
  const _BuildListItem({
    required this.buildJob,
    required this.user,
  });

  final BuildJob buildJob;
  final OpenCIUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final serverUrl = ref.watch(openciServerUrlProvider);
    final isRequested = useState(false);
    final isUdidVisible = useState(false);

    final isAndroid =
        buildJob.ipaUrl != null && buildJob.ipaUrl!.endsWith('.apk');

    final appName = buildJob.appName ?? 'OpenCI App';
    final runCount = buildJob.runCount ?? 1;
    final commitShaShort =
        buildJob.commitSha != null && buildJob.commitSha!.length > 7
        ? buildJob.commitSha!.substring(0, 7)
        : 'abcdefg';
    final branchName = buildJob.branch ?? 'main';

    final dateText =
        '${buildJob.createdAt.toLocal().year}/${buildJob.createdAt.toLocal().month.toString().padLeft(2, '0')}/${buildJob.createdAt.toLocal().day.toString().padLeft(2, '0')} ${buildJob.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${buildJob.createdAt.toLocal().minute.toString().padLeft(2, '0')}';

    final selectedTeamId = ref.watch(selectedTeamIdProvider).value;
    final devicesAsync = ref.watch(userDevicesProvider);
    String? userUdid;
    if (devicesAsync.value != null && selectedTeamId != null) {
      for (final d in devicesAsync.value!) {
        if (d.teamId == selectedTeamId) {
          userUdid = d.udid;
          break;
        }
      }
    }
    final isUdidProvisioned =
        isAndroid ||
        (userUdid != null &&
            buildJob.provisionedUdids != null &&
            buildJob.provisionedUdids!.contains(userUdid));

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
          bottom: BorderSide(color: theme.dividerColor),
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
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#$runCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _PlatformBadge(isAndroid: isAndroid, colors: colors),
              const SizedBox(width: 6),
              // UDID適合性バッジ
              if (!isAndroid) ...[
                _UdidBadge(status: udidStatus, colors: colors),
                const SizedBox(width: 8),
              ],
              // アプリ名
              Expanded(
                child: Text(
                  appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
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
                        : colors.outline,
                    side: BorderSide(
                      color: (isUdidProvisioned || isDesktopOrWeb)
                          ? const Color(0xFF3FB950)
                          : colors.outlineVariant,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: (isUdidProvisioned || isDesktopOrWeb)
                      ? () {
                          if (isAndroid) {
                            showDialog<void>(
                              context: context,
                              builder: (context) =>
                                  _AndroidDistributionQrDialog(
                                    buildJob: buildJob,
                                  ),
                            );
                          } else {
                            showDialog<void>(
                              context: context,
                              builder: (context) =>
                                  _IosDistributionQrDialog(buildJob: buildJob),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.install_mobile_rounded, size: 12),
                  label: Text(
                    isAndroid
                        ? (isDesktopOrWeb ? 'インストール (QR)' : 'ダウンロード')
                        : (isUdidProvisioned
                              ? 'インストール'
                              : (isDesktopOrWeb ? 'インストール (QR)' : 'インストール不可')),
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
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.commit_rounded,
                      size: 11,
                      color: colors.outline,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      commitShaShort,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                        color: colors.onSurfaceVariant,
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
                    color: colors.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colors.onSurfaceVariant,
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
                              await Clipboard.setData(
                                ClipboardData(text: userUdid!),
                              );
                              final url = Uri.parse(
                                '$serverUrl/teams/$selectedTeamId/udid-requests',
                              );
                              final token = await ref.read(
                                authedFirebaseIdTokenProvider.future,
                              );
                              final response = await http.post(
                                url,
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({
                                  'udid': userUdid,
                                }),
                              );
                              if (response.statusCode != 201) {
                                throw StateError(
                                  'Failed to register UDID: ${response.statusCode} ${response.body}',
                                );
                              }
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
                      color: isRequested.value ? colors.outline : colors.error,
                    ),
                    label: Text(
                      isRequested.value ? '申請済み' : 'UDIDを申請',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isRequested.value
                            ? colors.outline
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
                color: colors.outline.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colors.outline,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'この端末のUDIDが登録されていません。上のヘッダーからデバイス登録を行ってください。',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
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
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 11,
                      color: colors.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '変更内容:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  changelog,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.onSurfaceVariant,
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
  const _PlatformBadge({required this.isAndroid, required this.colors});

  final bool isAndroid;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final badgeColor = isAndroid
        ? const Color(0xFF3DDC84)
        : const Color(0xFF007AFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAndroid ? Icons.android : Icons.apple,
            size: 9,
            color: badgeColor,
          ),
          const SizedBox(width: 2),
          Text(
            isAndroid ? 'Android' : 'iOS',
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCopied = useState(false);

    final origin = kIsWeb ? Uri.base.origin : 'https://dashboard.openci.org';
    final manifestUrl = '$origin/iosManifest?buildJobId=${buildJob.id}';
    final installUrl =
        'itms-services://?action=download-manifest&url=${Uri.encodeComponent(manifestUrl)}';
    final installPageUrl = '$origin/install-ota?buildJobId=${buildJob.id}';

    return AlertDialog(
      backgroundColor: colors.onSurface.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      title: Row(
        children: [
          Icon(Icons.install_mobile_rounded, color: Colors.green, size: 22),
          const SizedBox(width: 8),
          Text(
            'iOS アプリのインストール',
            style: TextStyle(
              color: colors.onSurface,
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
                color: colors.onSurfaceVariant,
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
                  border: Border.all(color: colors.outlineVariant),
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
                  color: colors.outline,
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
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Text(
                        installPageUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: colors.onSurfaceVariant,
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
                          ? Colors.green
                          : colors.onSurfaceVariant,
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
                    foregroundColor: colors.onSurface,
                    side: BorderSide(color: colors.outlineVariant),
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
                    color: isCopied.value ? Colors.green : colors.onSurface,
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
                  color: colors.outline,
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
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: colors.onSurface.withValues(
                          alpha: 0.08,
                        ),
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                        title: const Text('インストールの開始'),
                        content: const Text(
                          'アプリをホーム画面に戻し、上書きインストールの準備を開始します。よろしいですか？\n\n'
                          '※ホーム画面に戻った後、iOSシステムから「インストールしますか？」というダイアログが表示されます。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'キャンセル',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('開始する'),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    try {
                      final uri = Uri.parse(installUrl);
                      await launchUrl(uri);
                      if (!kIsWeb) {
                        await AppMinimizer.minimize();
                      }
                    } catch (e) {
                      debugPrint('Error calling sendToBackground: $e');
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
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _AndroidDistributionQrDialog extends HookWidget {
  const _AndroidDistributionQrDialog({required this.buildJob});

  final BuildJob buildJob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isCopied = useState(false);

    final downloadUrl = buildJob.ipaUrl ?? '';

    return AlertDialog(
      backgroundColor: colors.onSurface.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      title: Row(
        children: [
          Icon(Icons.install_mobile_rounded, color: Colors.green, size: 22),
          const SizedBox(width: 8),
          Text(
            'Android アプリのインストール',
            style: TextStyle(
              color: colors.onSurface,
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
              '実機のカメラ等で以下のQRコードを読み取るか、直接ダウンロードボタンを押してインストールしてください。',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            // QR Code Container
            if (downloadUrl.isNotEmpty)
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: QrCodeWidget(
                    data: downloadUrl,
                    size: 160,
                    color: Colors.black,
                  ),
                ),
              ),
            if (defaultTargetPlatform != TargetPlatform.android) ...[
              const SizedBox(height: 14),
              Text(
                'ダウンロード用URL:',
                style: TextStyle(
                  color: colors.outline,
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
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Text(
                        downloadUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: colors.onSurfaceVariant,
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
                          ? Colors.green
                          : colors.onSurfaceVariant,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: downloadUrl));
                      isCopied.value = true;
                      Future.delayed(const Duration(seconds: 2), () {
                        isCopied.value = false;
                      });
                    },
                  ),
                ],
              ),
            ],
            if (defaultTargetPlatform == TargetPlatform.android || kIsWeb) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (downloadUrl.isNotEmpty) {
                      try {
                        await launchUrl(Uri.parse(downloadUrl));
                      } catch (e) {
                        debugPrint('Error launching url: $e');
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('このデバイスに直接ダウンロード'),
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
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
