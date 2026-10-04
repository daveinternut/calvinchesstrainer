import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/core/services/puzzle_service.dart';
import 'package:calvinchesstrainer/core/services/scan_position_service.dart';
import 'package:calvinchesstrainer/features/chess_vision/models/chess_vision_state.dart';
import 'package:calvinchesstrainer/features/chess_vision/screens/chess_vision_game_screen.dart';
import 'package:calvinchesstrainer/features/chess_vision/widgets/found_progress_indicator.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:chessground/chessground.dart' show Chessboard;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Render-level smoke tests for the scanning drills UI (the notifier flows
/// are covered in scan_drills_flow_test.dart).
class _SilentAudioService implements AudioService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoopAnalyticsService implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _sharedOverrides = [
  audioServiceProvider.overrideWithValue(_SilentAudioService()),
  analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
];

Widget _wrap(Widget home, {List<Object>? extraOverrides}) {
  return ProviderScope(
    overrides: [
      ..._sharedOverrides,
      ...?extraOverrides?.cast(),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

/// Positions are served randomly with either side to move, so exactly one of
/// the two badges must be present.
void _expectSideToPlayBadge(WidgetTester tester) {
  final white = find.text('White to play').evaluate().length;
  final black = find.text('Black to play').evaluate().length;
  expect(white + black, 1,
      reason: 'expected exactly one side-to-play badge '
          '(white: $white, black: $black)');
}

void main() {
  group('ChessVisionGameScreen (scanning)', () {
    late ScanPositionService scanService;
    late PuzzleService mateService;

    setUp(() {
      scanService = ScanPositionService();
      mateService =
          PuzzleService(assetPath: 'assets/puzzles/mate_in_one_puzzles.json');
    });

    List<Object> overrides() => [
          scanPositionServiceProvider.overrideWithValue(scanService),
          mateInOnePuzzleServiceProvider.overrideWithValue(mateService),
        ];

    Future<void> preload(WidgetTester tester) => tester.runAsync(() async {
          await scanService.load(ScanSetKind.checks);
          await scanService.load(ScanSetKind.captures);
          await scanService.load(ScanSetKind.hanging);
          await mateService.loadPuzzles();
        });

    testWidgets('findChecks practice renders prompt, dots, board and Skip',
        (tester) async {
      await preload(tester);
      await tester.pumpWidget(_wrap(
        const ChessVisionGameScreen(
          drill: VisionDrillType.findChecks,
          piece: WhitePiece.queen,
          mode: VisionMode.practice,
        ),
        extraOverrides: overrides(),
      ));
      // Post-frame startGame + the (pre-warmed, so instant) async load.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Tap every square where you can give check!'),
          findsOneWidget);
      expect(find.byType(FoundProgressIndicator), findsOneWidget);
      expect(find.byType(Chessboard), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('None'), findsNothing); // forks-only button
      _expectSideToPlayBadge(tester);
    });

    testWidgets('mateInOne practice renders prompt and interactive board',
        (tester) async {
      await preload(tester);
      await tester.pumpWidget(_wrap(
        const ChessVisionGameScreen(
          drill: VisionDrillType.mateInOne,
          piece: WhitePiece.queen,
          mode: VisionMode.practice,
        ),
        extraOverrides: overrides(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Mate in 1'), findsOneWidget); // AppBar title
      expect(find.text('Find the checkmate in one move!'), findsOneWidget);
      expect(find.byType(Chessboard), findsOneWidget);
      expect(find.byType(FoundProgressIndicator), findsNothing);
      expect(find.text('Skip'), findsNothing);
      _expectSideToPlayBadge(tester);
    });
  });
}
