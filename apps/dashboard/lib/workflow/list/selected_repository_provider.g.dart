// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedRepository)
final selectedRepositoryProvider = SelectedRepositoryProvider._();

final class SelectedRepositoryProvider
    extends $NotifierProvider<SelectedRepository, String?> {
  SelectedRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedRepositoryHash();

  @$internal
  @override
  SelectedRepository create() => SelectedRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedRepositoryHash() =>
    r'cac373aef72a6aaad56e841a664306de4300bd9e';

abstract class _$SelectedRepository extends $Notifier<String?> {
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
