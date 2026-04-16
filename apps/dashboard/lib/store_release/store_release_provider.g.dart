// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_release_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether ASC API credentials are configured for the current team.

@ProviderFor(IsAscConfigured)
final isAscConfiguredProvider = IsAscConfiguredProvider._();

/// Whether ASC API credentials are configured for the current team.
final class IsAscConfiguredProvider
    extends $StreamNotifierProvider<IsAscConfigured, bool> {
  /// Whether ASC API credentials are configured for the current team.
  IsAscConfiguredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAscConfiguredProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAscConfiguredHash();

  @$internal
  @override
  IsAscConfigured create() => IsAscConfigured();
}

String _$isAscConfiguredHash() => r'bf342315813e6be964b9fbf310a41a8a0d5c9cfe';

/// Whether ASC API credentials are configured for the current team.

abstract class _$IsAscConfigured extends $StreamNotifier<bool> {
  Stream<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Fetch the list of apps from App Store Connect.

@ProviderFor(AscApps)
final ascAppsProvider = AscAppsProvider._();

/// Fetch the list of apps from App Store Connect.
final class AscAppsProvider
    extends $AsyncNotifierProvider<AscApps, List<AscApp>> {
  /// Fetch the list of apps from App Store Connect.
  AscAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ascAppsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ascAppsHash();

  @$internal
  @override
  AscApps create() => AscApps();
}

String _$ascAppsHash() => r'30b51fe07980256867378f288e36ea52609e11c9';

/// Fetch the list of apps from App Store Connect.

abstract class _$AscApps extends $AsyncNotifier<List<AscApp>> {
  FutureOr<List<AscApp>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<AscApp>>, List<AscApp>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AscApp>>, List<AscApp>>,
              AsyncValue<List<AscApp>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Fetch builds for a specific app.

@ProviderFor(AscBuilds)
final ascBuildsProvider = AscBuildsFamily._();

/// Fetch builds for a specific app.
final class AscBuildsProvider
    extends $AsyncNotifierProvider<AscBuilds, List<AscBuild>> {
  /// Fetch builds for a specific app.
  AscBuildsProvider._({
    required AscBuildsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ascBuildsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ascBuildsHash();

  @override
  String toString() {
    return r'ascBuildsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AscBuilds create() => AscBuilds();

  @override
  bool operator ==(Object other) {
    return other is AscBuildsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ascBuildsHash() => r'2956b0a8ecd98d04431a9dcc5b49eb5ffd4f5343';

/// Fetch builds for a specific app.

final class AscBuildsFamily extends $Family
    with
        $ClassFamilyOverride<
          AscBuilds,
          AsyncValue<List<AscBuild>>,
          List<AscBuild>,
          FutureOr<List<AscBuild>>,
          String
        > {
  AscBuildsFamily._()
    : super(
        retry: null,
        name: r'ascBuildsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetch builds for a specific app.

  AscBuildsProvider call(String appId) =>
      AscBuildsProvider._(argument: appId, from: this);

  @override
  String toString() => r'ascBuildsProvider';
}

/// Fetch builds for a specific app.

abstract class _$AscBuilds extends $AsyncNotifier<List<AscBuild>> {
  late final _$args = ref.$arg as String;
  String get appId => _$args;

  FutureOr<List<AscBuild>> build(String appId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<AscBuild>>, List<AscBuild>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AscBuild>>, List<AscBuild>>,
              AsyncValue<List<AscBuild>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Submit a build to TestFlight (external beta testing).

@ProviderFor(SubmitToTestFlight)
final submitToTestFlightProvider = SubmitToTestFlightProvider._();

/// Submit a build to TestFlight (external beta testing).
final class SubmitToTestFlightProvider
    extends $AsyncNotifierProvider<SubmitToTestFlight, void> {
  /// Submit a build to TestFlight (external beta testing).
  SubmitToTestFlightProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitToTestFlightProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitToTestFlightHash();

  @$internal
  @override
  SubmitToTestFlight create() => SubmitToTestFlight();
}

String _$submitToTestFlightHash() =>
    r'0beeb6d8683baa5da51ba3f6aa95d8ee915226d6';

/// Submit a build to TestFlight (external beta testing).

abstract class _$SubmitToTestFlight extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Submit a build for App Store Review.

@ProviderFor(SubmitForReview)
final submitForReviewProvider = SubmitForReviewProvider._();

/// Submit a build for App Store Review.
final class SubmitForReviewProvider
    extends $AsyncNotifierProvider<SubmitForReview, void> {
  /// Submit a build for App Store Review.
  SubmitForReviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'submitForReviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$submitForReviewHash();

  @$internal
  @override
  SubmitForReview create() => SubmitForReview();
}

String _$submitForReviewHash() => r'b6ebaa7a2087d6f641c1a42ca8acdaf83c24daad';

/// Submit a build for App Store Review.

abstract class _$SubmitForReview extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Setup ASC API credentials.

@ProviderFor(SetupAscCredentials)
final setupAscCredentialsProvider = SetupAscCredentialsProvider._();

/// Setup ASC API credentials.
final class SetupAscCredentialsProvider
    extends $AsyncNotifierProvider<SetupAscCredentials, void> {
  /// Setup ASC API credentials.
  SetupAscCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setupAscCredentialsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setupAscCredentialsHash();

  @$internal
  @override
  SetupAscCredentials create() => SetupAscCredentials();
}

String _$setupAscCredentialsHash() =>
    r'f272a12d9f6f95d9bdc0844026e46fb8c30fdafd';

/// Setup ASC API credentials.

abstract class _$SetupAscCredentials extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
