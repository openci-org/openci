// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_firebase_auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(connectionFirebaseAuth)
final connectionFirebaseAuthProvider = ConnectionFirebaseAuthFamily._();

final class ConnectionFirebaseAuthProvider
    extends
        $FunctionalProvider<
          AsyncValue<FirebaseAuth>,
          FirebaseAuth,
          FutureOr<FirebaseAuth>
        >
    with $FutureModifier<FirebaseAuth>, $FutureProvider<FirebaseAuth> {
  ConnectionFirebaseAuthProvider._({
    required ConnectionFirebaseAuthFamily super.from,
    required (String, SelfHostedConfig) super.argument,
  }) : super(
         retry: null,
         name: r'connectionFirebaseAuthProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$connectionFirebaseAuthHash();

  @override
  String toString() {
    return r'connectionFirebaseAuthProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<FirebaseAuth> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FirebaseAuth> create(Ref ref) {
    final argument = this.argument as (String, SelfHostedConfig);
    return connectionFirebaseAuth(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionFirebaseAuthProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$connectionFirebaseAuthHash() =>
    r'4d06901fb171b0fbf125fada2bbf52d56aebbb29';

final class ConnectionFirebaseAuthFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<FirebaseAuth>,
          (String, SelfHostedConfig)
        > {
  ConnectionFirebaseAuthFamily._()
    : super(
        retry: null,
        name: r'connectionFirebaseAuthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  ConnectionFirebaseAuthProvider call(
    String profileId,
    SelfHostedConfig config,
  ) => ConnectionFirebaseAuthProvider._(
    argument: (profileId, config),
    from: this,
  );

  @override
  String toString() => r'connectionFirebaseAuthProvider';
}
