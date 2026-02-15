// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_connection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(isGitHubConnected)
final isGitHubConnectedProvider = IsGitHubConnectedProvider._();

final class IsGitHubConnectedProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  IsGitHubConnectedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isGitHubConnectedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isGitHubConnectedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isGitHubConnected(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isGitHubConnectedHash() => r'217809588fde4c74d9159bc66f2ddb2e9f477cb7';
