import 'package:avf_dart/avf_dart.dart';

void main() async {
  print('Fetching latest supported macOS IPSW URL from Apple...');
  try {
    final url = await AppleVirtualization.fetchLatestIpswUrl();
    print('\nLatest supported IPSW URL:\n$url');
  } catch (e) {
    print('Error fetching IPSW URL: $e');
  }
}
