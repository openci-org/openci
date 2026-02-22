// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firestore_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Firestore)
final firestoreProvider = FirestoreProvider._();

final class FirestoreProvider
    extends $NotifierProvider<Firestore, FirebaseFirestore> {
  FirestoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'firestoreProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$firestoreHash();

  @$internal
  @override
  Firestore create() => Firestore();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firestoreHash() => r'0d4c598acd51d5b580407be422e98eb81e8432a6';

abstract class _$Firestore extends $Notifier<FirebaseFirestore> {
  FirebaseFirestore build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FirebaseFirestore, FirebaseFirestore>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<FirebaseFirestore, FirebaseFirestore>,
        FirebaseFirestore,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
