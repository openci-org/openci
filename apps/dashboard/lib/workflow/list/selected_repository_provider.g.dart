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
    extends $AsyncNotifierProvider<SelectedRepository, String?> {
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
}

String _$selectedRepositoryHash() =>
    r'c87535c025638ddd956692b5541d41172d799c70';

abstract class _$SelectedRepository extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
