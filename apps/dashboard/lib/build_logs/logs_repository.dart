import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../connections/active_connection_firebase_auth.dart';
import '../connections/local_development_connection.dart';
import '../generated/logs/logs.dart';
import 'log_reader.dart';

part 'logs_repository.g.dart';

@riverpod
Future<LogsConnector> logsConnector(Ref ref) async {
  final auth = await ref.watch(activeConnectionFirebaseAuthProvider.future);
  final local = ref.watch(localDevelopmentConnectionProvider);
  final dc = FirebaseDataConnect.instanceFor(
    app: auth.app,
    connectorConfig: LogsConnector.connectorConfig,
    sdkType: CallerSDKType.generated,
  );
  if (local != null) dc.useDataConnectEmulator(local.emulatorHost, 9399);
  return LogsConnector(dataConnect: dc);
}

@riverpod
Future<LogsRepository> logsRepository(Ref ref) async =>
    LogsRepository(await ref.watch(logsConnectorProvider.future));

class LogsRepository {
  LogsRepository(this.connector);
  final LogsConnector connector;

  Stream<RunLogs> watch(String teamId, String jobId, String runId) =>
      readRunLogs(
        states: connector
            .getBuildLogState(teamId: teamId, jobId: jobId, runId: runId)
            .ref()
            .subscribe()
            .map((result) {
              final run = result.data.run!;
              return LogState(
                lastSequence: run.lastLogSequence,
                completed: run.status == 'completed',
                expired:
                    run.logsExpireAt?.toDateTime().isBefore(DateTime.now()) ??
                    false,
                steps: run.allSteps
                    .map(
                      (step) => BuildStep(
                        id: step.stepId,
                        runId: runId,
                        name: step.name,
                        status: BuildJobStatus.values.byName(step.status),
                        durationMs: step.durationMs.toInt(),
                        stepOrder: step.stepOrder,
                        createdAt: step.createdAt.toDateTime(),
                        updatedAt: step.updatedAt.toDateTime(),
                      ),
                    )
                    .toList(),
              );
            }),
        fetch: (after) async {
          final result = await connector
              .getBuildLogs(teamId: teamId, runId: runId)
              .afterSequence(after)
              .limit(200)
              .ref()
              .execute(fetchPolicy: QueryFetchPolicy.serverOnly);
          return result.data.run!.logEntries
              .map((log) => LogEntry(log.sequence, log.stepId, log.message))
              .toList();
        },
      );
}
