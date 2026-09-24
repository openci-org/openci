// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_connection_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveConnectionProfile)
final activeConnectionProfileProvider = ActiveConnectionProfileFamily._();

final class ActiveConnectionProfileProvider
    extends $AsyncNotifierProvider<ActiveConnectionProfile, ConnectionProfile> {
  ActiveConnectionProfileProvider._({
    required ActiveConnectionProfileFamily super.from,
    required ConnectionStore super.argument,
  }) : super(
         retry: null,
         name: r'activeConnectionProfileProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeConnectionProfileHash();

  @override
  String toString() {
    return r'activeConnectionProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ActiveConnectionProfile create() => ActiveConnectionProfile();

  @override
  bool operator ==(Object other) {
    return other is ActiveConnectionProfileProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeConnectionProfileHash() =>
    r'd52765ffcd07567372d7a8e57ddd06dbb99b04e1';

final class ActiveConnectionProfileFamily extends $Family
    with
        $ClassFamilyOverride<
          ActiveConnectionProfile,
          AsyncValue<ConnectionProfile>,
          ConnectionProfile,
          FutureOr<ConnectionProfile>,
          ConnectionStore
        > {
  ActiveConnectionProfileFamily._()
    : super(
        retry: null,
        name: r'activeConnectionProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ActiveConnectionProfileProvider call(ConnectionStore store) =>
      ActiveConnectionProfileProvider._(argument: store, from: this);

  @override
  String toString() => r'activeConnectionProfileProvider';
}

abstract class _$ActiveConnectionProfile
    extends $AsyncNotifier<ConnectionProfile> {
  late final _$args = ref.$arg as ConnectionStore;
  ConnectionStore get store => _$args;

  FutureOr<ConnectionProfile> build(ConnectionStore store);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ConnectionProfile>, ConnectionProfile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ConnectionProfile>, ConnectionProfile>,
              AsyncValue<ConnectionProfile>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
