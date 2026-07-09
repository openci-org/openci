// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selected_team_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedTeamId)
final selectedTeamIdProvider = SelectedTeamIdProvider._();

final class SelectedTeamIdProvider
    extends $AsyncNotifierProvider<SelectedTeamId, String?> {
  SelectedTeamIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedTeamIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedTeamIdHash();

  @$internal
  @override
  SelectedTeamId create() => SelectedTeamId();
}

String _$selectedTeamIdHash() => r'68ef31ba55d8216a2af573a1f80b62b8147a4b91';

abstract class _$SelectedTeamId extends $AsyncNotifier<String?> {
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
