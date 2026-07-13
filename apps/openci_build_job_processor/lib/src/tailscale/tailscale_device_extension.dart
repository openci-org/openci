import 'tailscale_models.dart';

extension TailscaleDeviceExtension on TailscaleDevice {
  bool get isActiveMacOs =>
      os?.toLowerCase() == 'macos' && (connectedToControl ?? false);

  String? get ipv4Address {
    final addresses = this.addresses;
    if (addresses == null || addresses.isEmpty) return null;
    final ip = addresses
        .map((addr) => addr.toString())
        .firstWhere((addr) => !addr.contains(':'), orElse: () => '');
    return ip.isEmpty ? null : ip;
  }
}

extension TailscaleDevicesResponseExtension on TailscaleDevicesResponse {
  List<String> getActiveMacOsIps() {
    final devices = this.devices;
    if (devices == null) return [];
    return devices
        .where((d) => d.isActiveMacOs)
        .map((d) => d.ipv4Address)
        .whereType<String>()
        .toList();
  }
}
