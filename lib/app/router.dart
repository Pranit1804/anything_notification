import 'package:go_router/go_router.dart';

import '../features/categories/presentation/categories_page.dart';
import '../features/history/presentation/history_page.dart';
import '../features/reminders/presentation/cubit/reminder_editor_cubit.dart';
import '../features/reminders/presentation/pages/reminder_editor_page.dart';
import '../features/reminders/presentation/pages/upcoming_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const upcoming = '/upcoming';
  static const history = '/history';
  static const settings = '/settings';
  static const categories = '/settings/categories';
  static const newReminder = '/reminder/new';

  static String editReminder(int id) => '/reminder/$id';
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.upcoming,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.upcoming,
                builder: (context, state) => const UpcomingPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'categories',
                    builder: (context, state) => const CategoriesPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen, above the tab bar. `new` must precede `:id`.
      GoRoute(
        path: AppRoutes.newReminder,
        builder: (context, state) =>
            ReminderEditorPage(prefill: state.extra as ReminderPrefill?),
      ),
      GoRoute(
        path: '/reminder/:id',
        builder: (context, state) => ReminderEditorPage(
          reminderId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
    ],
  );
}
