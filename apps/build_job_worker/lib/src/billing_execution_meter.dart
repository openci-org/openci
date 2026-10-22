import 'dart:async';

import 'package:openci_shared/openci_shared.dart';

class BillingExecutionMeter {
  BillingExecutionMeter({
    required this.api,
    required this.job,
    required this.runId,
    required this.onError,
  });

  final OpenCIApiService api;
  final BuildJob job;
  final String runId;
  final void Function(Object, StackTrace) onError;
  Timer? _timer;
  Future<void>? _pendingHeartbeat;
  var _stopped = false;

  Map<String, dynamic> get _identity => {
    'admissionId': job.billingAdmissionId,
    'jobId': job.id,
    'runId': runId,
    'workerHost': job.workerHost,
  };

  Future<void> start() async {
    if (job.billingAdmissionId == null ||
        job.billingAdmissionId!.isEmpty ||
        job.workerHost == null ||
        job.workerHost!.isEmpty ||
        _stopped ||
        _timer != null) {
      throw StateError('A current worker billing admission is required.');
    }
    final body = await _request(start: true);
    if (body['active'] != true || body['measurementIncomplete'] != false) {
      throw StateError('Billing execution admission is no longer active.');
    }
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(heartbeat());
    });
  }

  Future<void> heartbeat() {
    if (_stopped) return Future.value();
    return _pendingHeartbeat ??= _heartbeat().whenComplete(
      () => _pendingHeartbeat = null,
    );
  }

  Future<void> _heartbeat() async {
    try {
      final body = await _request();
      if (body['active'] != true || body['measurementIncomplete'] != false) {
        _timer?.cancel();
        _stopped = true;
        throw StateError('Billing execution measurement is no longer active.');
      }
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }

  Future<void> finish(BuildJobStatus status) async {
    _stopped = true;
    _timer?.cancel();
    final outcome = switch (status) {
      BuildJobStatus.SUCCESS => 'success',
      BuildJobStatus.FAILURE => 'failure',
      BuildJobStatus.CANCELLED => 'cancelled',
      BuildJobStatus.TIMED_OUT => 'timed_out',
      _ => throw ArgumentError.value(
        status,
        'status',
        'A completed execution status is required.',
      ),
    };
    final body = await _request(outcome: outcome);
    if (body['active'] != false || body['measurementIncomplete'] != false) {
      throw StateError('Billing execution completion could not be confirmed.');
    }
  }

  Future<Map<String, dynamic>> _request({
    bool start = false,
    String? outcome,
  }) async {
    final Map<String, dynamic>? body;
    final int status;
    try {
      final payload = {..._identity, 'outcome': ?outcome};
      final response =
          await (start
                  ? api.startBillingExecution(payload)
                  : api.reportBillingExecution(payload))
              .timeout(const Duration(seconds: 10));
      body = response.body;
      status = response.statusCode;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StateError('Billing execution request failed: ${error.runtimeType}.'),
        stackTrace,
      );
    }
    if (status != 200) {
      throw StateError('Billing execution request failed: HTTP $status.');
    }
    if (body == null ||
        body['active'] is! bool ||
        body['measurementIncomplete'] is! bool) {
      throw StateError('Invalid billing execution acknowledgement.');
    }
    return body;
  }
}
