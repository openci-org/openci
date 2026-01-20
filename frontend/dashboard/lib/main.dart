import 'package:dashboard/create_workflow/create_workflow_page.dart';
import 'package:dashboard/firebase_options.dart';
import 'package:dashboard/list/list_page.dart';
import 'package:dashboard/root.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pages = [CreateWorkflowPage(), ListPage()];
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(ProviderScope(child: Root()));
}
