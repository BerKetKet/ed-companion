import 'package:flutter/material.dart';

class NewTaskPlaceholderScreen extends StatelessWidget {
  const NewTaskPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New task'),
      ),
      body: const SafeArea(
        child: Center(
          child: Text(
            'New task: coming in module B',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
