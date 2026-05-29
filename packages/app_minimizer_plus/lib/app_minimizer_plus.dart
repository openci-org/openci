import 'app_minimizer_api.g.dart';

class AppMinimizer {
  static final _api = AppMinimizerHostApi();

  static Future<void> minimize() async {
    await _api.minimize();
  }
}
