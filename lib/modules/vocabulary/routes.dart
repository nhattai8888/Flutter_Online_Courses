import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'ui/screen.dart';

final List<RouteBase> vocabularyRoutes = <RouteBase>[
  GoRoute(
    path: '/vocab/lesson/:lessonId',
    builder: (BuildContext context, GoRouterState state) {
      final lessonId = state.pathParameters['lessonId']!;
      return VocabularyScreen(lessonId: lessonId);
    },
  ),
  GoRoute(
    path: '/vocab/lexeme/:lexemeId',
    builder: (BuildContext context, GoRouterState state) {
      final lexemeId = state.pathParameters['lexemeId']!;
      return VocabularyScreen(lexemeId: lexemeId);
    },
  ),
];
