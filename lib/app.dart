import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/file_rank_trainer/screens/file_rank_menu_screen.dart';
import 'features/file_rank_trainer/screens/file_rank_game_screen.dart';
import 'features/file_rank_trainer/models/file_rank_game_state.dart';
import 'features/tactics_trainer/screens/tactics_trainer_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/file-rank-trainer',
      builder: (context, state) {
        final subjectParam = state.uri.queryParameters['subject'];
        final modeParam = state.uri.queryParameters['mode'];
        final reverseParam = state.uri.queryParameters['reverse'];
        final hardModeParam = state.uri.queryParameters['hardMode'];

        return FileRankMenuScreen(
          initialSubject: subjectParam != null
              ? TrainerSubject.values.firstWhere(
                  (s) => s.name == subjectParam,
                  orElse: () => TrainerSubject.files,
                )
              : TrainerSubject.files,
          initialMode: modeParam != null
              ? TrainerMode.values.firstWhere(
                  (m) => m.name == modeParam,
                  orElse: () => TrainerMode.explore,
                )
              : TrainerMode.explore,
          initialReverse: reverseParam == 'true',
          initialHardMode: hardModeParam == 'true',
        );
      },
    ),
    GoRoute(
      path: '/file-rank-trainer/game',
      builder: (context, state) {
        final subjectParam = state.uri.queryParameters['subject'] ?? 'files';
        final modeParam = state.uri.queryParameters['mode'] ?? 'explore';
        final reverseParam = state.uri.queryParameters['reverse'] ?? 'false';
        final hardModeParam = state.uri.queryParameters['hardMode'] ?? 'false';

        final subject = TrainerSubject.values.firstWhere(
          (s) => s.name == subjectParam,
          orElse: () => TrainerSubject.files,
        );
        final mode = TrainerMode.values.firstWhere(
          (m) => m.name == modeParam,
          orElse: () => TrainerMode.explore,
        );

        return FileRankGameScreen(
          subject: subject,
          mode: mode,
          isReverse: reverseParam == 'true',
          isHardMode: hardModeParam == 'true',
        );
      },
    ),
    GoRoute(
      path: '/tactics-trainer',
      builder: (context, state) => const TacticsTrainerScreen(),
    ),
  ],
);

class CalvinChessTrainerApp extends StatelessWidget {
  const CalvinChessTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Calvin Chess Trainer',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
