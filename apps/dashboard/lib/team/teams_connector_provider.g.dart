// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teams_connector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamsConnector)
final teamsConnectorProvider = TeamsConnectorProvider._();

final class TeamsConnectorProvider
    extends
        $FunctionalProvider<
          AsyncValue<TeamsConnector>,
          TeamsConnector,
          FutureOr<TeamsConnector>
        >
    with $FutureModifier<TeamsConnector>, $FutureProvider<TeamsConnector> {
  TeamsConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamsConnectorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamsConnectorHash();

  @$internal
  @override
  $FutureProviderElement<TeamsConnector> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TeamsConnector> create(Ref ref) {
    return teamsConnector(ref);
  }
}

String _$teamsConnectorHash() => r'ce7b5a5abdb411e279b29d2b83483ee998bcc87e';
