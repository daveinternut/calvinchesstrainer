import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/file_rank_trainer/screens/file_rank_menu_screen.dart';
import 'features/file_rank_trainer/screens/file_rank_game_screen.dart';
import 'features/file_rank_trainer/models/file_rank_game_state.dart';
import 'features/move_trainer/screens/move_game_screen.dart';
import 'features/move_trainer/models/move_game_state.dart';
import 'features/tactics_trainer/screens/tactics_trainer_screen.dart';
import 'features/about/screens/about_screen.dart';
import 'features/move_trainer/screens/move_menu_screen.dart';
import 'features/chess_vision/screens/chess_vision_menu_screen.dart';
import 'features/chess_vision/screens/chess_vision_game_screen.dart';
import 'features/chess_vision/models/chess_vision_state.dart';

final _analytics = FirebaseAnalytics.instance;

final _router = GoRouter(
  initialLocation: '/',
  observers: [
    FirebaseAnalyticsObserver(
      analytics: _analytics,
      nameExtractor: (settings) => settings.name ?? 'unknown',
    ),
  ],
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/file-rank-trainer',
      name: 'file_rank_menu',
      builder: (context, state) {
        final subjectParam = state.uri.queryParameters['subject'];
        final modeParam = state.uri.queryParameters['mode'];
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
          initialHardMode: hardModeParam == 'true',
        );
      },
    ),
    GoRoute(
      path: '/file-rank-trainer/game',
      name: 'file_rank_game',
      builder: (context, state) {
        final subjectParam = state.uri.queryParameters['subject'] ?? 'files';
        final modeParam = state.uri.queryParameters['mode'] ?? 'explore';
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
          isHardMode: hardModeParam == 'true',
        );
      },
    ),
    GoRoute(
      path: '/move-trainer',
      name: 'move_menu',
      builder: (context, state) {
        final modeParam = state.uri.queryParameters['mode'];
        final hardModeParam = state.uri.queryParameters['hardMode'];

        return MoveMenuScreen(
          initialMode: modeParam != null
              ? MoveTrainerMode.values.firstWhere(
                  (m) => m.name == modeParam,
                  orElse: () => MoveTrainerMode.practice,
                )
              : MoveTrainerMode.practice,
          initialHardMode: hardModeParam == 'true',
        );
      },
    ),
    GoRoute(
      path: '/move-trainer/game',
      name: 'move_game',
      builder: (context, state) {
        final modeParam = state.uri.queryParameters['mode'] ?? 'practice';
        final hardModeParam =
            state.uri.queryParameters['hardMode'] ?? 'false';

        final mode = MoveTrainerMode.values.firstWhere(
          (m) => m.name == modeParam,
          orElse: () => MoveTrainerMode.practice,
        );

        return MoveGameScreen(
          mode: mode,
          isHardMode: hardModeParam == 'true',
        );
      },
    ),
    GoRoute(
      path: '/chess-vision',
      name: 'chess_vision_menu',
      builder: (context, state) {
        final drillParam = state.uri.queryParameters['drill'];
        final pieceParam = state.uri.queryParameters['piece'];
        final modeParam = state.uri.queryParameters['mode'];

        return ChessVisionMenuScreen(
          initialDrill: drillParam != null
              ? VisionDrillType.values.firstWhere(
                  (d) => d.name == drillParam,
                  orElse: () => VisionDrillType.forksAndSkewers,
                )
              : VisionDrillType.forksAndSkewers,
          initialPiece: pieceParam != null
              ? WhitePiece.values.firstWhere(
                  (p) => p.name == pieceParam,
                  orElse: () => WhitePiece.queen,
                )
              : WhitePiece.queen,
          initialTarget: state.uri.queryParameters['target'] != null
              ? TargetPiece.values.firstWhere(
                  (t) => t.name == state.uri.queryParameters['target'],
                  orElse: () => TargetPiece.rook,
                )
              : TargetPiece.rook,
          initialMode: modeParam != null
              ? VisionMode.values.firstWhere(
                  (m) => m.name == modeParam,
                  orElse: () => VisionMode.practice,
                )
              : VisionMode.practice,
        );
      },
    ),
    GoRoute(
      path: '/chess-vision/game',
      name: 'chess_vision_game',
      builder: (context, state) {
        final drillParam =
            state.uri.queryParameters['drill'] ?? 'forksAndSkewers';
        final pieceParam = state.uri.queryParameters['piece'] ?? 'queen';
        final targetParam = state.uri.queryParameters['target'] ?? 'rook';
        final modeParam = state.uri.queryParameters['mode'] ?? 'practice';

        final drill = VisionDrillType.values.firstWhere(
          (d) => d.name == drillParam,
          orElse: () => VisionDrillType.forksAndSkewers,
        );
        final piece = WhitePiece.values.firstWhere(
          (p) => p.name == pieceParam,
          orElse: () => WhitePiece.queen,
        );
        final target = TargetPiece.values.firstWhere(
          (t) => t.name == targetParam,
          orElse: () => TargetPiece.rook,
        );
        final mode = VisionMode.values.firstWhere(
          (m) => m.name == modeParam,
          orElse: () => VisionMode.practice,
        );

        return ChessVisionGameScreen(
          drill: drill,
          piece: piece,
          target: target,
          mode: mode,
        );
      },
    ),
    GoRoute(
      path: '/tactics-trainer',
      name: 'tactics_trainer',
      builder: (context, state) => const TacticsTrainerScreen(),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (context, state) => const AboutScreen(),
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
