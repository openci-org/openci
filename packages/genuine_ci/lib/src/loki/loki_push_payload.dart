import 'package:freezed_annotation/freezed_annotation.dart';

import 'loki_labels.dart';

part 'loki_push_payload.freezed.dart';

@freezed
abstract class LokiStream with _$LokiStream {
  const factory LokiStream({
    required LokiLabels labels,
    required List<List<String>> values,
  }) = _LokiStream;

  const LokiStream._();

  Map<String, dynamic> toMap() {
    return {
      'stream': labels.toLabelsMap(),
      'values': values,
    };
  }
}

@freezed
abstract class LokiPushPayload with _$LokiPushPayload {
  const factory LokiPushPayload({
    required List<LokiStream> streams,
  }) = _LokiPushPayload;

  const LokiPushPayload._();

  factory LokiPushPayload.single({
    required LokiLabels labels,
    required String timestampNanos,
    required String message,
  }) {
    return LokiPushPayload(
      streams: [
        LokiStream(
          labels: labels,
          values: [
            [timestampNanos, message],
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'streams': streams.map((s) => s.toMap()).toList(),
    };
  }
}
