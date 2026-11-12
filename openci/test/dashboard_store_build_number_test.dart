import 'package:openci_workflows/dashboard_store_build_number.dart';
import 'package:test/test.dart';

void main() {
  test('OpenCI build numbers continue past the existing store builds', () {
    expect(dashboardStoreBuildNumber(1), 14617);
    expect(dashboardStoreBuildNumber(2), 14618);
  });
}
