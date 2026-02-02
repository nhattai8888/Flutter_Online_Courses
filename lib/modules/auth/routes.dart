import 'package:go_router/go_router.dart';
import 'ui/screen.dart';

List<RouteBase> authRoutes = [
  GoRoute(
    path: '/login',
    builder: (context, state) => const AuthScreen(),
  ),
];
