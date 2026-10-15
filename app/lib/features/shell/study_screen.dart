import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: const SafeArea(
        child: Center(
          child: Text(
            'Study library: coming in module E',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
