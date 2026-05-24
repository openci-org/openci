import 'package:flutter/material.dart';
import 'package:macos_updater/macos_updater.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _macosUpdater = MacosUpdater();
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _macosUpdater.checkResults.listen((result) {
      setState(() {
        _status = 'Result: ${result.type.name} - ${result.message}';
      });
    });
  }

  Future<void> _checkUpdates() async {
    setState(() {
      _status = 'Checking...';
    });
    try {
      await _macosUpdater.setFeedUrl(
        'https://raw.githubusercontent.com/openci-org/openci/develop/apps/dashboard/macos/appcast.xml',
      );
      await _macosUpdater.checkForUpdates();
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Sparkle Updater Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Status: $_status'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkUpdates,
                child: const Text('Check for Updates'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
