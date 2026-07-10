// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_job_logs_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildJobLog _$BuildJobLogFromJson(Map<String, dynamic> json) => _BuildJobLog(
  message: json['message'] as String,
  level: json['level'] as String,
  timestamp: _$JsonConverterFromJson<Object, DateTime>(
    json['timestamp'],
    const DateTimeConverter().fromJson,
  ),
);

Map<String, dynamic> _$BuildJobLogToJson(_BuildJobLog instance) =>
    <String, dynamic>{
      'message': instance.message,
      'level': instance.level,
      'timestamp': _$JsonConverterToJson<Object, DateTime>(
        instance.timestamp,
        const DateTimeConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(buildJobLogs)
final buildJobLogsProvider = BuildJobLogsFamily._();

final class BuildJobLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BuildJobLog>>,
          List<BuildJobLog>,
          FutureOr<List<BuildJobLog>>
        >
    with
        $FutureModifier<List<BuildJobLog>>,
        $FutureProvider<List<BuildJobLog>> {
  BuildJobLogsProvider._({
    required BuildJobLogsFamily super.from,
    required (String, String, BuildJobStatus) super.argument,
  }) : super(
         retry: null,
         name: r'buildJobLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildJobLogsHash();

  @override
  String toString() {
    return r'buildJobLogsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<BuildJobLog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BuildJobLog>> create(Ref ref) {
    final argument = this.argument as (String, String, BuildJobStatus);
    return buildJobLogs(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is BuildJobLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildJobLogsHash() => r'6cdf221b0d06db23dd44ae336c413660644d198d';

final class BuildJobLogsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<BuildJobLog>>,
          (String, String, BuildJobStatus)
        > {
  BuildJobLogsFamily._()
    : super(
        retry: null,
        name: r'buildJobLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildJobLogsProvider call(
    String buildJobId,
    String runId,
    BuildJobStatus buildStatus,
  ) => BuildJobLogsProvider._(
    argument: (buildJobId, runId, buildStatus),
    from: this,
  );

  @override
  String toString() => r'buildJobLogsProvider';
}
