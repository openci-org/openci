import 'package:freezed_annotation/freezed_annotation.dart';

part 'claim_job_request.freezed.dart';
part 'claim_job_request.g.dart';

@freezed
abstract class ClaimJobRequest with _$ClaimJobRequest {
  const factory ClaimJobRequest({
    String? vmName,
    String? workerHost,
    int? maxConcurrentJobs,
  }) = _ClaimJobRequest;

  factory ClaimJobRequest.fromJson(Map<String, Object?> json) =>
      _$ClaimJobRequestFromJson(json);
}
