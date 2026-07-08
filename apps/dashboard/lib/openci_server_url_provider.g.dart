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

String _$openciServerUrlHash() => r'1ecb7e38166102af8b4dd3bd5adb1940b0cef12e';

@ProviderFor(CustomServerUrl)
final customServerUrlProvider = CustomServerUrlProvider._();

final class CustomServerUrlProvider
    extends $NotifierProvider<CustomServerUrl, String?> {
  CustomServerUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customServerUrlProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customServerUrlHash();

  @$internal
  @override
  CustomServerUrl create() => CustomServerUrl();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$customServerUrlHash() => r'0bf45589bddb67dbc772bb843e9b84dc4afdc8a2';

abstract class _$CustomServerUrl extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
