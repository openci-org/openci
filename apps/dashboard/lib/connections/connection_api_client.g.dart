// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(connectionApiClient)
final connectionApiClientProvider = ConnectionApiClientFamily._();

final class ConnectionApiClientProvider
    extends $FunctionalProvider<ChopperClient, ChopperClient, ChopperClient>
    with $Provider<ChopperClient> {
  ConnectionApiClientProvider._({
    required ConnectionApiClientFamily super.from,
    required (ConnectionProfile, SelfHostedConfig) super.argument,
  }) : super(
         retry: null,
         name: r'connectionApiClientProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$connectionApiClientHash();

  @override
  String toString() {
    return r'connectionApiClientProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<ChopperClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChopperClient create(Ref ref) {
    final argument = this.argument as (ConnectionProfile, SelfHostedConfig);
    return connectionApiClient(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChopperClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChopperClient>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionApiClientProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$connectionApiClientHash() =>
    r'ded431dafc35855d11fbff302d518464266d39c5';

final class ConnectionApiClientFamily extends $Family
    with
        $FunctionalFamilyOverride<
          ChopperClient,
          (ConnectionProfile, SelfHostedConfig)
        > {
  ConnectionApiClientFamily._()
    : super(
        retry: null,
        name: r'connectionApiClientProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConnectionApiClientProvider call(
    ConnectionProfile profile,
    SelfHostedConfig config,
  ) => ConnectionApiClientProvider._(argument: (profile, config), from: this);

  @override
  String toString() => r'connectionApiClientProvider';
}
