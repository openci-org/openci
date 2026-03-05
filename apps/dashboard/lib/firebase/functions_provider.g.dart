// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'functions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Functions)
final functionsProvider = FunctionsProvider._();

final class FunctionsProvider
    extends $NotifierProvider<Functions, FirebaseFunctions> {
  FunctionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'functionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$functionsHash();

  @$internal
  @override
  Functions create() => Functions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFunctions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFunctions>(value),
    );
  }
}

String _$functionsHash() => r'23cdb1ea8b490c4318cefcd79047177b28ba6945';

abstract class _$Functions extends $Notifier<FirebaseFunctions> {
  FirebaseFunctions build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FirebaseFunctions, FirebaseFunctions>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FirebaseFunctions, FirebaseFunctions>,
              FirebaseFunctions,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
