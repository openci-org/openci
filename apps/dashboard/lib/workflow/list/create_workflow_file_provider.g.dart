// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_workflow_file_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CreateWorkflowFileNotifier)
final createWorkflowFileProvider = CreateWorkflowFileNotifierProvider._();

final class CreateWorkflowFileNotifierProvider
    extends $NotifierProvider<CreateWorkflowFileNotifier, AsyncValue<void>> {
  CreateWorkflowFileNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createWorkflowFileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createWorkflowFileNotifierHash();

  @$internal
  @override
  CreateWorkflowFileNotifier create() => CreateWorkflowFileNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$createWorkflowFileNotifierHash() =>
    r'8d33e95bc9731efe58c273cf2f7a09d979c1a933';

abstract class _$CreateWorkflowFileNotifier
    extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
