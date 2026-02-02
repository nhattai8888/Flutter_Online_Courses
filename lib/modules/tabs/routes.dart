import 'package:go_router/go_router.dart';
import 'ui/home_tab.dart';
import 'ui/learning_tab.dart';
import 'ui/speaking_tab.dart';
import 'ui/review_tab.dart';
import 'ui/profile_tab.dart';

List<RouteBase> tabsRoutes = [
  GoRoute(
    path: '/home',
    builder: (context, state) => const HomeTab(),
  ),
  GoRoute(
    path: '/learning',
    builder: (context, state) => const LearningTab(),
  ),
  GoRoute(
    path: '/speaking',
    builder: (context, state) => const SpeakingTab(),
  ),
  GoRoute(
    path: '/review',
    builder: (context, state) => const ReviewTab(),
  ),
  GoRoute(
    path: '/profile',
    builder: (context, state) => const ProfileTab(),
  ),
];
