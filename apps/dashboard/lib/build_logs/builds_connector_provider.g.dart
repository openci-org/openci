// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'builds_connector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(buildsConnector)
final buildsConnectorProvider = BuildsConnectorProvider._();

final class BuildsConnectorProvider
    extends
        $FunctionalProvider<
          AsyncValue<BuildsConnector>,
          BuildsConnector,
          FutureOr<BuildsConnector>
        >
    with $FutureModifier<BuildsConnector>, $FutureProvider<BuildsConnector> {
  BuildsConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'buildsConnectorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$buildsConnectorHash();

  @$internal
  @override
  $FutureProviderElement<BuildsConnector> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BuildsConnector> create(Ref ref) {
    return buildsConnector(ref);
  }
}

String _$buildsConnectorHash() => r'fdb7b4388f9522eb42f778ab9c2768d4f04ac945';
