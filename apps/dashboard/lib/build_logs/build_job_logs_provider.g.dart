// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_job_logs_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildLog _$BuildLogFromJson(Map<String, dynamic> json) => _BuildLog(
  message: json['message'] as String,
  level: json['level'] as String,
  timestamp: _$JsonConverterFromJson<Object, DateTime>(
    json['timestamp'],
    const DateTimeConverter().fromJson,
  ),
);

Map<String, dynamic> _$BuildLogToJson(_BuildLog instance) => <String, dynamic>{
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
          AsyncValue<List<BuildLog>>,
          List<BuildLog>,
          FutureOr<List<BuildLog>>
        >
    with $FutureModifier<List<BuildLog>>, $FutureProvider<List<BuildLog>> {
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
  $FutureProviderElement<List<BuildLog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BuildLog>> create(Ref ref) {
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

String _$buildJobLogsHash() => r'87e05c6cd6efb14d53f3ade089b5be4e6a860039';

final class BuildJobLogsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<BuildLog>>,
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
