import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'app_minimizer_plus',
    dartOut: 'lib/app_minimizer_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Classes/AppMinimizerApi.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
@HostApi()
abstract class AppMinimizerHostApi {
  void minimize();
}
