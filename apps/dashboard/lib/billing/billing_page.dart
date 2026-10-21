import 'dart:async';

import 'package:dashboard/billing/billing_actions.dart';
import 'package:dashboard/billing/billing_error_message.dart';
import 'package:dashboard/billing/billing_identity.dart';
import 'package:dashboard/billing/billing_provider.dart';
import 'package:dashboard/billing/billing_response.dart';
import 'package:dashboard/billing/billing_view.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingPage extends ConsumerWidget {
  const BillingPage({this.teamId, this.result, super.key});

  final String? teamId;
  final String? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(billingIdentityProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('課金'),
        leading: CloseButton(onPressed: () => context.go('/')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: identity == null
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Cloudにサインインすると、このページを利用できます。'),
                )
              : _BillingTeam(
                  key: ValueKey((identity, teamId)),
                  teamId: teamId,
                  result: result,
                ),
        ),
      ),
    );
  }
}

class _BillingTeam extends ConsumerWidget {
  const _BillingTeam({required this.teamId, required this.result, super.key});

  final String? teamId;
  final String? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamListProvider);
    if (teams.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (teams.hasError) {
      return _BillingError(
        message: 'チームを読み込めませんでした。',
        onReload: () => ref.invalidate(teamListProvider),
      );
    }
    String? id = teamId;
    if (id == null) {
      final selected = ref.watch(selectedTeamIdProvider);
      if (selected.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      id = selected.asData?.value;
    }
    final team = teams.requireValue.where((team) => team.id == id).firstOrNull;
    if (team == null) {
      return _BillingError(
        message: 'このチームにアクセスできません。ダッシュボードでチームを確認してください。',
        onReload: () => ref.invalidate(teamListProvider),
      );
    }
    return _TeamBillingPage(key: ValueKey(team.id), team: team, result: result);
  }
}

class _TeamBillingPage extends ConsumerStatefulWidget {
  const _TeamBillingPage({required this.team, required this.result, super.key});

  final Team team;
  final String? result;

  @override
  ConsumerState<_TeamBillingPage> createState() => _TeamBillingPageState();
}

class _TeamBillingPageState extends ConsumerState<_TeamBillingPage> {
  bool _pending = false;
  bool _accessLost = false;
  String? _error;

  @override
  void didUpdateWidget(covariant _TeamBillingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reload();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(billingStatusProvider(widget.team.id));
    ref.watch(billingActionsProvider(widget.team.id));
    if (_accessLost) return _BillingError(message: _error!, onReload: _reload);
    if (status.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (status.hasError) {
      return _BillingError(
        message: billingErrorMessage(status.error!),
        onReload: _reload,
      );
    }
    final data = status.asData?.value;
    if (data == null) return const SizedBox.shrink();
    return BillingView(
      teamName: widget.team.name,
      status: data,
      pending: _pending,
      error: _error,
      returnedFromStripe: {
        'success',
        'cancel',
        'portal',
      }.contains(widget.result),
      onCheckout: (planId) => unawaited(_openStripe(planId: planId)),
      onPortal: () => unawaited(_openStripe()),
      onReload: _reload,
    );
  }

  void _reload() {
    if (_pending) return;
    setState(() {
      _error = null;
      _accessLost = false;
    });
    ref.invalidate(billingActionsProvider(widget.team.id));
    ref.invalidate(billingStatusProvider(widget.team.id));
  }

  Future<void> _openStripe({String? planId}) async {
    if (_pending) return;
    final identity = ref.read(billingIdentityProvider);
    final actions = ref.read(billingActionsProvider(widget.team.id));
    if (identity == null || actions == null) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final uri = planId == null
          ? await actions.portal()
          : await actions.checkout(planId);
      if (!mounted || ref.read(billingIdentityProvider) != identity) return;
      if (!await launchUrl(uri, webOnlyWindowName: '_self')) {
        throw const BillingException('launch_failed');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = billingErrorMessage(error);
        _accessLost =
            error is BillingException &&
            {
              'forbidden',
              'authentication_required',
              'context_changed',
            }.contains(error.code);
      });
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }
}

class _BillingError extends StatelessWidget {
  const _BillingError({required this.message, required this.onReload});

  final String message;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 16),
        TextButton(onPressed: onReload, child: const Text('再読み込み')),
      ],
    ),
  );
}
