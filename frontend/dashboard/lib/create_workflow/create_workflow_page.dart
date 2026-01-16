import 'package:flutter/material.dart';

class CreateWorkflowPage extends StatelessWidget {
  const CreateWorkflowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (_) => Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).canvasColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              height: MediaQuery.of(context).size.height * 0.8,
              child: CreateWorkflowBottomSheet(),
            ),
          ),
          child: Text('Let\'s Create New Workflow'),
        ),
      ),
    );
  }
}

class CreateWorkflowBottomSheet extends StatelessWidget {
  const CreateWorkflowBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Initial Setup"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
