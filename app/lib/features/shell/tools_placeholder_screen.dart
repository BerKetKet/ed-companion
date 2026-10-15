import 'package:flutter/material.dart';

class ToolsPlaceholderScreen extends StatelessWidget {
  const ToolsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
      ),
      body: const SafeArea(
        child: Center(
          child: Text(
            'Tools: coming in module D',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
