// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_logs_provider.dart';

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

@ProviderFor(BuildLogs)
final buildLogsProvider = BuildLogsFamily._();

final class BuildLogsProvider
    extends $AsyncNotifierProvider<BuildLogs, List<BuildLog>> {
  BuildLogsProvider._({
    required BuildLogsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'buildLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$buildLogsHash();

  @override
  String toString() {
    return r'buildLogsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  BuildLogs create() => BuildLogs();

  @override
  bool operator ==(Object other) {
    return other is BuildLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildLogsHash() => r'cf56d639153fd7a729e2451b74b3506e4393ee84';

final class BuildLogsFamily extends $Family
    with
        $ClassFamilyOverride<
          BuildLogs,
          AsyncValue<List<BuildLog>>,
          List<BuildLog>,
          FutureOr<List<BuildLog>>,
          (String, String)
        > {
  BuildLogsFamily._()
    : super(
        retry: null,
        name: r'buildLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BuildLogsProvider call(String buildJobId, String runId) =>
      BuildLogsProvider._(argument: (buildJobId, runId), from: this);

  @override
  String toString() => r'buildLogsProvider';
}

abstract class _$BuildLogs extends $AsyncNotifier<List<BuildLog>> {
  late final _$args = ref.$arg as (String, String);
  String get buildJobId => _$args.$1;
  String get runId => _$args.$2;

  FutureOr<List<BuildLog>> build(String buildJobId, String runId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<BuildLog>>, List<BuildLog>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BuildLog>>, List<BuildLog>>,
              AsyncValue<List<BuildLog>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
