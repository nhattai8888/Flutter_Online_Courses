import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_state.dart';
import '../modules/auth/index.dart';
import '../modules/curriculum/routes.dart';
import '../modules/tabs/routes.dart';
import 'main_shell_screen.dart';

class AppRouter {
  final AuthState authState;

  AppRouter({required this.authState});

  late final GoRouter router = GoRouter(
    refreshListenable: authState,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      ...authRoutes,
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(
          child: child,
          location: state.matchedLocation,
        ),
        routes: [
          ...tabsRoutes,
          ...curriculumRoutes,
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthed = authState.token != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthed && !isLoginRoute) {
        return '/login';
      }

      if (isAuthed && isLoginRoute) {
        return '/home';
      }

      return null;
    },
  );
}
