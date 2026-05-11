// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_check_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UpdateCheck)
final updateCheckProvider = UpdateCheckProvider._();

final class UpdateCheckProvider
    extends $NotifierProvider<UpdateCheck, UpdateCheckState> {
  UpdateCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateCheckProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateCheckHash();

  @$internal
  @override
  UpdateCheck create() => UpdateCheck();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateCheckState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateCheckState>(value),
    );
  }
}

String _$updateCheckHash() => r'3dec5602ef624f1fc82fbdc7033b5ec0d4bfa626';

abstract class _$UpdateCheck extends $Notifier<UpdateCheckState> {
  UpdateCheckState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UpdateCheckState, UpdateCheckState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateCheckState, UpdateCheckState>,
              UpdateCheckState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
