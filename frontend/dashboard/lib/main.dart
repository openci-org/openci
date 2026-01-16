import 'package:dashboard/create_workflow/create_workflow_page.dart';
import 'package:dashboard/list/list_page.dart';
import 'package:dashboard/navigation_bar_page.dart';
import 'package:dashboard/root.dart';
import 'package:flutter/material.dart';

final pages = [CreateWorkflowPage(), ListPage()];
void main() => runApp(Root(NavigationBarPage(pages)));
