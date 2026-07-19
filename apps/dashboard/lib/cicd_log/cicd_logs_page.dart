import 'package:flutter/material.dart';

class CicdLogsPage extends StatelessWidget {
  const CicdLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CI/CDログ',
        ),
      ),
      body: const Center(
        child: Text("CI/CD ログページ"),
      ),
    );
  }
}
