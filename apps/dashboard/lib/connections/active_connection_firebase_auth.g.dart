// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_connection_firebase_auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeConnectionFirebaseAuth)
final activeConnectionFirebaseAuthProvider =
    ActiveConnectionFirebaseAuthProvider._();

final class ActiveConnectionFirebaseAuthProvider
    extends
        $FunctionalProvider<
          AsyncValue<FirebaseAuth>,
          FirebaseAuth,
          FutureOr<FirebaseAuth>
        >
    with $FutureModifier<FirebaseAuth>, $FutureProvider<FirebaseAuth> {
  ActiveConnectionFirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeConnectionFirebaseAuthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeConnectionFirebaseAuthHash();

  @$internal
  @override
  $FutureProviderElement<FirebaseAuth> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FirebaseAuth> create(Ref ref) {
    return activeConnectionFirebaseAuth(ref);
  }
}

String _$activeConnectionFirebaseAuthHash() =>
    r'344738f856477564c56938139e34c7a88b91ba93';
