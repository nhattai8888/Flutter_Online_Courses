import 'package:go_router/go_router.dart';
import 'ui/screen.dart';

final List<RouteBase> curriculumRoutes = [
  GoRoute(
    path: '/curriculum',
    builder: (context, state) => const CurriculumScreen(),
  ),
];
