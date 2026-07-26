import 'dart:io';
import 'package:http/io_client.dart';
import 'package:openci_job_processor_shared/src/orchard/orchard_api_client.dart';

Future<void> main() async {
  print('--- Starting Orchard Provisioning Test Script ---');

  final ioHttpClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;
  final httpClient = IOClient(ioHttpClient);

  final baseUrl =
      Platform.environment['ORCHARD_API_URL'] ?? 'https://127.0.0.1:6120';
  final serviceAccountName =
      Platform.environment['ORCHARD_SERVICE_ACCOUNT_NAME'] ?? 'bootstrap-admin';
  final serviceAccountToken =
      Platform.environment['ORCHARD_SERVICE_ACCOUNT_TOKEN'] ??
      '10nv,IQ+9_x<5V}=%t7]a82E6>3u4bO@';

  print('Connecting to Orchard Controller at: $baseUrl');
  print('Using Service Account: $serviceAccountName');

  final client = OrchardApiClient(
    baseUrl: baseUrl,
    serviceAccountName: serviceAccountName,
    serviceAccountToken: serviceAccountToken,
    httpClient: httpClient,
  );

  try {
    print('\n[1/2] Testing createLease() against Orchard Controller...');
    const testImage = 'base-macos';
    print('Sending createLease request for image: "$testImage"...');

    try {
      final lease = await client.createLease(imageName: testImage);
      print('Lease Created Successfully!');
      print('  Lease ID  : ${lease.id}');
      print('  VM Name   : ${lease.vmName}');
      print('  IP Address: ${lease.ipAddress}');
      print('  SSH Port  : ${lease.sshPort}');
      print('  Status    : ${lease.status}');

      print('\n[2/2] Cleaning up VM Lease (deleteLease)...');
      await client.deleteLease(lease.id);
      print('Lease Deleted Successfully!');
    } catch (e) {
      print('Orchard Controller response: $e');
    }
  } catch (e, stack) {
    print('Failed to communicate with Orchard Controller: $e');
    print(stack);
  } finally {
    httpClient.close();
  }

  print('--- Orchard Provisioning Test Script Finished ---');
}
