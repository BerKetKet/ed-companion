import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'features/shell/about_screen.dart';
import 'features/shell/lock/change_pin_screen.dart';
import 'features/shell/lock/lock_controller.dart';
import 'features/shell/lock/lock_screen.dart';
import 'features/shell/lock/lock_timer.dart';
import 'features/shell/lock/setup_pin_screen.dart';
import 'features/shell/navigation_shell.dart';
import 'features/shell/settings_provider.dart';
import 'features/shell/settings_screen.dart';
import 'features/shell/study_screen.dart';
import 'features/shell/tools_placeholder_screen.dart';
import 'features/shell/work_screen.dart';

/// Notifier to trigger GoRouter re-evaluations on lock state changes.
class RouterListenable extends ChangeNotifier {
  RouterListenable(Ref ref) {
    ref.listen<AppLockState>(lockControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = RouterListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/work',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final lockState = ref.read(lockControllerProvider);
      final isGoingToSetupPin = state.matchedLocation == '/setup-pin';
      final isGoingToLock = state.matchedLocation == '/lock';

      // Rule 1: First launch / no PIN set -> redirect to /setup-pin
      if (!lockState.hasPin) {
        return isGoingToSetupPin ? null : '/setup-pin';
      }

      // Rule 2: App locked -> redirect to /lock
      if (lockState.isLocked) {
        return isGoingToLock ? null : '/lock';
      }

      // Rule 3: Unlocked with PIN set -> prevent staying on lock or setup
      if (isGoingToLock || isGoingToSetupPin) {
        return '/work';
      }

      return null;
    },
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
        path: '/setup-pin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SetupPinScreen(),
      ),
      GoRoute(
        path: '/lock',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LockScreen(),
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
        path: '/change-pin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ChangePinScreen(),
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

  // Initialize lock state from secure storage
  await container.read(lockControllerProvider.notifier).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EdCompanionApp(),
    ),
  );
}

class EdCompanionApp extends ConsumerStatefulWidget {
  const EdCompanionApp({super.key});

  @override
  ConsumerState<EdCompanionApp> createState() => _EdCompanionAppState();
}

class _EdCompanionAppState extends ConsumerState<EdCompanionApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lockState = ref.read(lockControllerProvider);
    if (!lockState.hasPin) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundedAt != null) {
        final timeout = ref.read(settingsProvider).autoLockTimeout;
        if (shouldLock(DateTime.now(), _backgroundedAt, timeout)) {
          ref.read(lockControllerProvider.notifier).lock();
        }
        _backgroundedAt = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
