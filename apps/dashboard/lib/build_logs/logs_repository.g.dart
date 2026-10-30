// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logs_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(logsConnector)
final logsConnectorProvider = LogsConnectorProvider._();

final class LogsConnectorProvider
    extends
        $FunctionalProvider<
          AsyncValue<LogsConnector>,
          LogsConnector,
          FutureOr<LogsConnector>
        >
    with $FutureModifier<LogsConnector>, $FutureProvider<LogsConnector> {
  LogsConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logsConnectorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logsConnectorHash();

  @$internal
  @override
  $FutureProviderElement<LogsConnector> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LogsConnector> create(Ref ref) {
    return logsConnector(ref);
  }
}

String _$logsConnectorHash() => r'9d5ed17293b388fcd0680f648bc8d7e07d1074dc';

@ProviderFor(logsRepository)
final logsRepositoryProvider = LogsRepositoryProvider._();

final class LogsRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<LogsRepository>,
          LogsRepository,
          FutureOr<LogsRepository>
        >
    with $FutureModifier<LogsRepository>, $FutureProvider<LogsRepository> {
  LogsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logsRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<LogsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LogsRepository> create(Ref ref) {
    return logsRepository(ref);
  }
}

String _$logsRepositoryHash() => r'eb5f35c89c01ddeee33b16c70d0464039abcfe0a';
