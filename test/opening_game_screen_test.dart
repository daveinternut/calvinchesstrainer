import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/core/services/opening_book_service.dart';
import 'package:calvinchesstrainer/core/services/stockfish_service.dart';
import 'package:calvinchesstrainer/core/widgets/trainer_layout.dart';
import 'package:calvinchesstrainer/features/opening_trainer/models/opening_game_state.dart';
import 'package:calvinchesstrainer/features/opening_trainer/models/uci_move.dart';
import 'package:calvinchesstrainer/features/opening_trainer/providers/opening_game_provider.dart';
import 'package:calvinchesstrainer/features/opening_trainer/screens/opening_game_screen.dart';
import 'package:calvinchesstrainer/features/opening_trainer/widgets/eval_bar.dart';
import 'package:calvinchesstrainer/features/opening_trainer/widgets/move_history_panel.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:chessground/chessground.dart' show Chessboard;
import 'package:dartchess/dartchess.dart' show NormalMove, Side;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every search at once with e2e4 (dropped where illegal).
class _InstantEngine implements StockfishService {
  _InstantEngine({this.failStart = false});

  bool failStart;
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  bool get isBusy => false;

  @override
  Future<void> initialize() async {
    if (failStart) throw const EngineUnavailableException('test');
    _ready = true;
  }

  @override
  void stopSearch() {}

  @override
  Future<EvalResult> evaluate(String fen, {int? depth, int? movetime}) async {
    await initialize();
    return EvalResult(centipawns: 20, depth: depth ?? 10);
  }

  @override
  Future<String?> getBestMove(String fen,
          {int? depth, int? movetime, int skillLevel = 20}) async =>
      null;

  @override
  Future<List<ScoredMove>> getTopMoves(String fen,
      {int count = 3,
      int? depth,
      int? movetime,
      void Function(int depth)? onDepth}) async {
    await initialize();
    onDepth?.call(depth ?? 1);
    return const [ScoredMove(uci: 'e2e4', centipawns: 20, multipvIndex: 1)];
  }

  @override
  void disposeWhenIdle() {}

  @override
  void dispose() {}
}

class _SilentAudioService implements AudioService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoopAnalyticsService implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  final book = OpeningBookService();
  setUpAll(() => book.load());

  Widget app(StockfishService engine, {Locale? locale}) => ProviderScope(
        overrides: [
          stockfishServiceProvider.overrideWithValue(engine),
          openingBookServiceProvider.overrideWithValue(book),
          audioServiceProvider.overrideWithValue(_SilentAudioService()),
          analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OpeningGameScreen(
            mode: OpeningMode.practice,
            difficulty: OpeningDifficulty.easy,
            playerColor: Side.white,
          ),
        ),
      );

  OpeningGameNotifier notifierOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(OpeningGameScreen)))
          .read(openingGameProvider.notifier);

  // The longest line in the dataset, to fill the move panel.
  String longestLine() => book
      .getAllOpenings()
      .reduce((a, b) => a.pgn.length >= b.pgn.length ? a : b)
      .pgn;

  const sizes = <String, Size>{
    'narrowest split view': Size(320, 568),
    'iPhone SE portrait': Size(375, 667),
    'iPad portrait': Size(820, 1180),
    'iPad landscape': Size(1180, 820),
    'small Stage Manager window': Size(700, 500),
    'narrow Stage Manager window': Size(500, 640),
    'short landscape window': Size(640, 400),
    'phone browser on its side': Size(750, 369),
    'small phone browser on its side': Size(568, 320),
  };

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('lays out without overflow: $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(app(_InstantEngine()));
      await tester.pump(); // startGame (post-frame)
      await tester.pump(const Duration(milliseconds: 500));

      await notifierOf(tester).startFromOpening(longestLine());
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.text('Opening Explorer'), findsOneWidget);
      expect(find.byType(MoveHistoryPanel), findsOneWidget);

      final board = tester.getRect(find.byType(Chessboard));
      final evalBar = tester.getRect(find.byType(EvalBar));
      final landscape = TrainerLayout.isLandscape(BoxConstraints.loose(size));
      if (landscape) {
        expect(evalBar.left, greaterThanOrEqualTo(board.right),
            reason: 'board left, panel right');
      } else {
        expect(evalBar.bottom, lessThanOrEqualTo(board.top),
            reason: 'eval bar above the board');
      }
      expect(board.right, lessThanOrEqualTo(size.width));
      expect(board.bottom, lessThanOrEqualTo(size.height));
    });
  }

  testWidgets('the board keeps its size as moves and variations appear',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(_InstantEngine()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final before = tester.getSize(find.byType(Chessboard));

    final notifier = notifierOf(tester);
    await notifier.startFromOpening(longestLine());
    await tester.pump(const Duration(milliseconds: 500));

    // Step back and play something else: a second line (variation) row.
    await notifier.scrubBack();
    final recorded = notifier.state.lines.single.moves.last.uci;
    final pos = notifier.currentPosition;
    final alternative = [
      for (final entry in pos.legalMoves.entries)
        for (final to in entry.value.squares)
          standardMove(pos, NormalMove(from: entry.key, to: to)),
    ].firstWhere((m) => m.uci != recorded);
    await notifier.handlePlayerMove(alternative);
    await tester.pump(const Duration(milliseconds: 500));

    expect(notifier.state.lines, hasLength(2));
    expect(tester.getSize(find.byType(Chessboard)), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed engine start shows the banner; Retry clears it',
      (tester) async {
    final engine = _InstantEngine(failStart: true);
    await tester.pumpWidget(app(engine));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("The chess engine didn't start."), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    engine.failStart = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("The chess engine didn't start."), findsNothing);
  });

  testWidgets('long-locale engine banner fits a narrow window', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        app(_InstantEngine(failStart: true), locale: const Locale('de')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final l10n = lookupAppLocalizations(const Locale('de'));
    expect(find.text(l10n.engineUnavailable), findsOneWidget);
    expect(find.text(l10n.retry), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history controls are at least 44 pt', (tester) async {
    await tester.pumpWidget(app(_InstantEngine()));
    await tester.pump();
    await notifierOf(tester).startFromOpening('1. e4 e5 2. Nf3');
    await tester.pump(const Duration(milliseconds: 500));

    final back = find.byIcon(Icons.chevron_left_rounded);
    expect(back, findsOneWidget);
    final backTarget = find.ancestor(of: back, matching: find.byType(InkWell));
    expect(tester.getSize(backTarget.first).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(backTarget.first).width, greaterThanOrEqualTo(44));

    final chip = find.ancestor(of: find.text('Nf3'), matching: find.byType(InkWell));
    expect(tester.getSize(chip.first).height, greaterThanOrEqualTo(44));
  });
}
