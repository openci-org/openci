// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openci_server_url_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(openciServerUrl)
final openciServerUrlProvider = OpenciServerUrlProvider._();

final class OpenciServerUrlProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  OpenciServerUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openciServerUrlProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openciServerUrlHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return openciServerUrl(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$openciServerUrlHash() => r'7993ab8aaa318395b1724b599a856b7ac2ba50fc';
