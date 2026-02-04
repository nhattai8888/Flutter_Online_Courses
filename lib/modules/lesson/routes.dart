import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'ui/screen.dart';

final List<RouteBase> lessonRoutes = <RouteBase>[
  GoRoute(
    path: '/lesson/:lessonId',
    builder: (BuildContext context, GoRouterState state) {
      final lessonId = state.pathParameters['lessonId'] ?? '';
      return LessonScreen(lessonId: lessonId);
    },
  ),
];
