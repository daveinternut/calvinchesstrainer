import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/services/analytics_service.dart'
    show AnalyticsService, ScreenViewObserver;
import 'core/services/stockfish_service.dart' show kEngineAvailable;
import 'core/theme/app_theme.dart';
import 'features/drills/models/drill.dart';
import 'features/drills/screens/drill_section_screen.dart';
import 'features/drills/screens/warmup_done_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/file_rank_trainer/screens/file_rank_game_screen.dart';
import 'features/file_rank_trainer/models/file_rank_game_state.dart';
import 'features/move_trainer/screens/move_game_screen.dart';
import 'features/move_trainer/models/move_game_state.dart';
import 'features/letter_trainer/screens/letter_game_screen.dart';
import 'features/letter_trainer/models/letter_game_state.dart';
import 'features/tactics_trainer/screens/tactics_trainer_screen.dart';
import 'features/about/screens/about_screen.dart';
import 'features/chess_vision/screens/chess_vision_game_screen.dart';
import 'features/chess_vision/models/chess_vision_state.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'features/opening_trainer/screens/opening_game_screen.dart';
import 'features/opening_trainer/models/opening_game_state.dart';
import 'features/pieces/screens/which_side_wins_screen.dart';
import 'features/pieces/models/which_side_wins_state.dart';

final _router = GoRouter(
  initialLocation: '/',
  // Screen views by route name. Safe before Firebase is up: events are
  // dropped until main()'s background init marks it ready.
  observers: [ScreenViewObserver(AnalyticsService())],
  // An unknown path (a stale bookmark or a typo on web) goes home instead of
  // GoRouter's default English error page.
  onException: (context, state, router) => router.go('/'),
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/file-rank-trainer',
      name: 'file_rank_menu',
      // The Notation section. `?drill=` selects a drill; the old
      // `?subject=` links still land on the matching one.
      builder: (context, state) => DrillSectionScreen(
        section: DrillSection.notation,
        initialDrill: _drillParam(state.uri) ??
            switch (state.uri.queryParameters['subject']) {
              'squares' => DrillId.squares,
              'files' || 'ranks' => DrillId.filesRanks,
              'moves' => DrillId.readMoves,
              'letters' => DrillId.pieceLetters,
              'pieceValue' => DrillId.pieceValues,
              _ => null,
            },
      ),
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
          warmup: _isWarmup(state.uri),
        );
      },
    ),
    GoRoute(
      path: '/move-trainer',
      name: 'move_menu',
      builder: (context, state) => const DrillSectionScreen(
        section: DrillSection.notation,
        initialDrill: DrillId.readMoves,
      ),
    ),
    GoRoute(
      path: '/move-trainer/game',
      name: 'move_game',
      builder: (context, state) {
        final modeParam = state.uri.queryParameters['mode'] ?? 'practice';
        final hardModeParam = state.uri.queryParameters['hardMode'] ?? 'false';

        final mode = MoveTrainerMode.values.firstWhere(
          (m) => m.name == modeParam,
          orElse: () => MoveTrainerMode.practice,
        );

        return MoveGameScreen(
          mode: mode,
          isHardMode: hardModeParam == 'true',
          warmup: _isWarmup(state.uri),
        );
      },
    ),
    GoRoute(
      path: '/letter-trainer/game',
      name: 'letter_game',
      builder: (context, state) {
        final modeParam = state.uri.queryParameters['mode'] ?? 'explore';
        final hardModeParam = state.uri.queryParameters['hardMode'] ?? 'false';

        final mode = LetterTrainerMode.values.firstWhere(
          (m) => m.name == modeParam,
          orElse: () => LetterTrainerMode.explore,
        );

        return LetterGameScreen(
          mode: mode,
          isHardMode: hardModeParam == 'true',
          warmup: _isWarmup(state.uri),
        );
      },
    ),
    GoRoute(
      path: '/chess-vision',
      name: 'chess_vision_menu',
      // The Vision section; `?drill=` selects a drill.
      builder: (context, state) => DrillSectionScreen(
        section: DrillSection.vision,
        initialDrill: _drillParam(state.uri),
      ),
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
          warmup: _isWarmup(state.uri),
        );
      },
    ),
    GoRoute(
      path: '/opening-trainer',
      name: 'opening_trainer',
      // The only engine-backed trainer. Every current target has an engine
      // (native Stockfish, or Stockfish WASM on web), so this redirect is a
      // no-op today; it is the seam for any future engine-less target, where
      // a deep link should land on home rather than on a board that can never
      // move. The route stays registered so its name (and analytics screen
      // view) is valid everywhere.
      redirect: (context, state) => kEngineAvailable ? null : '/',
      builder: (context, state) => const OpeningGameScreen(
        mode: OpeningMode.practice,
        difficulty: OpeningDifficulty.easy,
        playerColor: Side.white,
      ),
    ),
    GoRoute(
      path: '/the-pieces/which-side-wins',
      name: 'which_side_wins',
      builder: (context, state) {
        final modeParam =
            state.uri.queryParameters['mode'] ?? 'practice';
        final mode = WhichSideWinsMode.values.firstWhere(
          (m) => m.name == modeParam,
          orElse: () => WhichSideWinsMode.practice,
        );
        return WhichSideWinsScreen(mode: mode, warmup: _isWarmup(state.uri));
      },
    ),
    GoRoute(
      path: '/warm-up/done',
      name: 'warmup_done',
      builder: (context, state) => const WarmupDoneScreen(),
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

/// `?drill=` as a drill: its catalog name, or a Chess Vision drill's name.
DrillId? _drillParam(Uri uri) {
  final name = uri.queryParameters['drill'];
  if (name == null) return null;
  for (final d in DrillId.values) {
    if (d.name == name) return d;
  }
  return null;
}

/// Whether a game route is a step of the daily warm-up.
bool _isWarmup(Uri uri) => uri.queryParameters['warmup'] == '1';

class CalvinChessTrainerApp extends StatelessWidget {
  const CalvinChessTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Calvin Chess Trainer',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
