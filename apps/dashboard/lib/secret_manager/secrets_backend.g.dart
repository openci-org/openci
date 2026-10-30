// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secrets_backend.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(secretsConnector)
final secretsConnectorProvider = SecretsConnectorProvider._();

final class SecretsConnectorProvider
    extends
        $FunctionalProvider<
          AsyncValue<SecretsConnector>,
          SecretsConnector,
          FutureOr<SecretsConnector>
        >
    with $FutureModifier<SecretsConnector>, $FutureProvider<SecretsConnector> {
  SecretsConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secretsConnectorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secretsConnectorHash();

  @$internal
  @override
  $FutureProviderElement<SecretsConnector> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SecretsConnector> create(Ref ref) {
    return secretsConnector(ref);
  }
}

String _$secretsConnectorHash() => r'436f655b825a28ba8a7c58ef8a5c766c89e973e6';

@ProviderFor(teamSecretsCallable)
final teamSecretsCallableProvider = TeamSecretsCallableProvider._();

final class TeamSecretsCallableProvider
    extends
        $FunctionalProvider<
          AsyncValue<HttpsCallable>,
          HttpsCallable,
          FutureOr<HttpsCallable>
        >
    with $FutureModifier<HttpsCallable>, $FutureProvider<HttpsCallable> {
  TeamSecretsCallableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamSecretsCallableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamSecretsCallableHash();

  @$internal
  @override
  $FutureProviderElement<HttpsCallable> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HttpsCallable> create(Ref ref) {
    return teamSecretsCallable(ref);
  }
}

String _$teamSecretsCallableHash() =>
    r'5686b6e72688d025879045bf7507aa603ffb6acb';
