import 'package:dashboard/build_logs/chips/job_status.dart';
import 'package:openci_shared/openci_shared.dart';

ChipStatus toChipStatus(BuildJobStatus status) => switch (status) {
  BuildJobStatus.SUCCESS => ChipStatus.success,
  BuildJobStatus.FAILURE ||
  BuildJobStatus.CANCELLED ||
  BuildJobStatus.TIMED_OUT => ChipStatus.fail,
  BuildJobStatus.IN_PROGRESS => ChipStatus.inProgress,
  BuildJobStatus.QUEUED || BuildJobStatus.WAITING => ChipStatus.queued,
  BuildJobStatus.SKIPPED => ChipStatus.skipped,
};
