import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'features/shell/about_screen.dart';
import 'features/shell/chrome/gestures_help.dart';
import 'features/shell/chrome/modal_tracker.dart';
import 'features/shell/chrome/quick_button_widget.dart';
import 'features/shell/drafts_placeholder_screen.dart';
import 'features/shell/navigation_shell.dart';
import 'features/shell/new_task_placeholder_screen.dart';
import 'features/shell/settings_provider.dart';
import 'features/shell/settings_screen.dart';
import 'features/shell/study_screen.dart';
import 'features/shell/tools_placeholder_screen.dart';
import 'features/shell/work_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/work',
    observers: [
      ModalTrackerObserver(ref),
    ],
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShellWidget(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/work',
                builder: (context, state) => const WorkScreen(),
                routes: [
                  GoRoute(
                    path: 'tools',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ToolsPlaceholderScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/study',
                builder: (context, state) => const StudyScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/drafts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DraftsPlaceholderScreen(),
      ),
      GoRoute(
        path: '/new-task',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewTaskPlaceholderScreen(),
      ),
      GoRoute(
        path: '/gestures',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const GesturesHelpScreen(),
      ),
    ],
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPrefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EdCompanionApp(),
    ),
  );
}

class EdCompanionApp extends ConsumerWidget {
  const EdCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: kAppName,
      themeMode: settings.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.textSize.scale),
          ),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const QuickButtonOverlay(),
            ],
          ),
        );
      },
      routerConfig: router,
    );
  }
}
