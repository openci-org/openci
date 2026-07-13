import 'package:openci_build_job_processor/src/tailscale/tailscale_device_extension.dart';
import 'package:openci_build_job_processor/src/tailscale/tailscale_models.dart';
import 'package:test/test.dart';

void main() {
  group('TailscaleDeviceExtension', () {
    group('isActiveMacOs', () {
      test('should return true for online macOS devices', () {
        const device = TailscaleDevice(
          os: 'macos',
          connectedToControl: true,
          addresses: [],
        );
        expect(device.isActiveMacOs, isTrue);
      });

      test('should handle uppercase OS names correctly', () {
        const device = TailscaleDevice(
          os: 'MacOS',
          connectedToControl: true,
          addresses: [],
        );
        expect(device.isActiveMacOs, isTrue);
      });

      test('should return false for offline macOS devices', () {
        const device = TailscaleDevice(
          os: 'macos',
          connectedToControl: false,
          addresses: [],
        );
        expect(device.isActiveMacOs, isFalse);
      });

      test('should return false for other OS even if online', () {
        const device = TailscaleDevice(
          os: 'linux',
          connectedToControl: true,
          addresses: [],
        );
        expect(device.isActiveMacOs, isFalse);
      });

      test('should handle null values safely', () {
        const device = TailscaleDevice(
          os: null,
          connectedToControl: null,
          addresses: null,
        );
        expect(device.isActiveMacOs, isFalse);
      });
    });

    group('ipv4Address', () {
      test('should return the first IPv4 address (no colon)', () {
        const device = TailscaleDevice(
          os: 'macos',
          connectedToControl: true,
          addresses: ['fd7a:115c:a1e0::8b39:c25', '100.66.12.37'],
        );
        expect(device.ipv4Address, '100.66.12.37');
      });

      test('should return null if there is no IPv4 address', () {
        const device = TailscaleDevice(
          os: 'macos',
          connectedToControl: true,
          addresses: ['fd7a:115c:a1e0::8b39:c25'],
        );
        expect(device.ipv4Address, isNull);
      });

      test('should return null if addresses list is empty', () {
        const device = TailscaleDevice(
          os: 'macos',
          connectedToControl: true,
          addresses: [],
        );
        expect(device.ipv4Address, isNull);
      });

      test('should return null if addresses is null', () {
        const device = TailscaleDevice(
          os: 'macos',
          connectedToControl: true,
          addresses: null,
        );
        expect(device.ipv4Address, isNull);
      });
    });
  });

  group('TailscaleDevicesResponseExtension', () {
    group('getActiveMacOsIps', () {
      test('should extract only IPv4 addresses of online macOS devices', () {
        const response = TailscaleDevicesResponse(
          devices: [
            TailscaleDevice(
              os: 'macos',
              connectedToControl: true,
              addresses: ['100.66.12.37', 'fd7a:115c:a1e0::8b39:c25'],
            ),
            TailscaleDevice(
              os: 'macos',
              connectedToControl: false,
              addresses: ['100.112.30.120'],
            ),
            TailscaleDevice(
              os: 'linux',
              connectedToControl: true,
              addresses: ['100.83.142.124'],
            ),
          ],
        );
        expect(response.getActiveMacOsIps(), ['100.66.12.37']);
      });

      test('should return empty list if devices list is null', () {
        const response = TailscaleDevicesResponse(devices: null);
        expect(response.getActiveMacOsIps(), isEmpty);
      });
    });
  });
}
