import 'package:flutter/material.dart';

class DraftsPlaceholderScreen extends StatelessWidget {
  const DraftsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drafts'),
      ),
      body: const SafeArea(
        child: Center(
          child: Text(
            'Drafts shelf: coming in module B',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
