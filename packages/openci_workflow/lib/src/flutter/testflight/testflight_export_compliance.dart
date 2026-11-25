/// The answers to Apple's export compliance questions for a TestFlight build.
class TestFlightExportCompliance {
  /// Declares standard encryption implemented outside Apple's operating system.
  const TestFlightExportCompliance.standardEncryption({
    required this.appDescription,
    required this.availableOnFrenchStore,
  });

  /// The description of the app and its purpose submitted to Apple.
  final String appDescription;

  /// Whether the developer intends to distribute the app in France.
  final bool availableOnFrenchStore;
}
