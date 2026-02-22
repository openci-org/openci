// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_logs_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildLog _$BuildLogFromJson(Map<String, dynamic> json) => _BuildLog(
      message: json['message'] as String,
      level: json['level'] as String,
      timestamp: const DateTimeConverter().fromJson(json['timestamp']),
    );

Map<String, dynamic> _$BuildLogToJson(_BuildLog instance) => <String, dynamic>{
      'message': instance.message,
      'level': instance.level,
      'timestamp': _$JsonConverterToJson<dynamic, DateTime>(
          instance.timestamp, const DateTimeConverter().toJson),
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(buildLogs)
final buildLogsProvider = BuildLogsFamily._();

final class BuildLogsProvider extends $FunctionalProvider<
        AsyncValue<List<BuildLog>>, List<BuildLog>, Stream<List<BuildLog>>>
    with $FutureModifier<List<BuildLog>>, $StreamProvider<List<BuildLog>> {
  BuildLogsProvider._(
      {required BuildLogsFamily super.from,
      required (
        String,
        String,
      )
          super.argument})
      : super(
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
  $StreamProviderElement<List<BuildLog>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<BuildLog>> create(Ref ref) {
    final argument = this.argument as (
      String,
      String,
    );
    return buildLogs(
      ref,
      argument.$1,
      argument.$2,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BuildLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$buildLogsHash() => r'55b7b69b0cf6c73b3a52888305ecbd9b5cedd765';

final class BuildLogsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            Stream<List<BuildLog>>,
            (
              String,
              String,
            )> {
  BuildLogsFamily._()
      : super(
          retry: null,
          name: r'buildLogsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  BuildLogsProvider call(
    String buildJobId,
    String runId,
  ) =>
      BuildLogsProvider._(argument: (
        buildJobId,
        runId,
      ), from: this);

  @override
  String toString() => r'buildLogsProvider';
}
