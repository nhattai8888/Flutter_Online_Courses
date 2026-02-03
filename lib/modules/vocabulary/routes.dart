import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'ui/screen.dart';

final List<RouteBase> vocabRoutes = <RouteBase>[
  GoRoute(
    path: '/speaking',
    builder: (BuildContext context, GoRouterState state) {
      // NOTE: language_id should come from selected language in Curriculum.
      // For now, it can be passed via query param (?language_id=...)
      final langId = state.uri.queryParameters['language_id'] ?? '';
      return VocabularyScreen(languageId: langId);
    },
  ),
];
