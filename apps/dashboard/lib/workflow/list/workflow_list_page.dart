import 'dart:async';

import 'package:dashboard/firebase/data_connect_service_id_page.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/issues/issue_board_page.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WorkflowListPage extends HookConsumerWidget {
  const WorkflowListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final selfHostedConfig = ref.watch(selfHostedConfigProvider).value;
    final showDataConnectSettings = useState(false);

    useEffect(() {
      showDataConnectSettings.value = false;
      if (!userAsync.isLoading || selfHostedConfig == null) return null;

      final timer = Timer(const Duration(seconds: 4), () {
        showDataConnectSettings.value = true;
      });
      return timer.cancel;
    }, [userAsync.isLoading, selfHostedConfig?.projectId]);

    return userAsync.when(
      loading: () {
        final config = selfHostedConfig;
        if (showDataConnectSettings.value && config != null) {
          return DataConnectServiceIdPage(
            config: config,
            title: 'Data Connect is still loading',
            message:
                'Check the Data Connect service ID for ${config.projectId}.',
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator.adaptive()),
        );
      },
      error: (error, stackTrace) {
        final config = selfHostedConfig;
        if (config != null) {
          return DataConnectServiceIdPage(
            config: config,
            title: 'Data Connect failed to load',
            message:
                'Check the Data Connect service ID for ${config.projectId}.\n$error',
          );
        }
        return asyncErrorWidget(error, stackTrace);
      },
      data: (_) => const IssueBoardBody(),
    );
  }
}
