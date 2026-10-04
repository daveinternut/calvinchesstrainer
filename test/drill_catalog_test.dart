import 'dart:convert';

import 'package:calvinchesstrainer/core/services/personal_bests_service.dart';
import 'package:calvinchesstrainer/features/chess_vision/models/chess_vision_state.dart';
import 'package:calvinchesstrainer/features/chess_vision/providers/chess_vision_provider.dart';
import 'package:calvinchesstrainer/features/drills/drill_catalog.dart';
import 'package:calvinchesstrainer/features/drills/models/drill.dart';
import 'package:calvinchesstrainer/features/drills/providers/drill_prefs_provider.dart';
import 'package:calvinchesstrainer/features/drills/providers/warmup_provider.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/models/file_rank_game_state.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/providers/file_rank_game_provider.dart';
import 'package:calvinchesstrainer/l10n/app_localizations_en.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The drill catalog is the one description of every drill: home, the
/// section screens, Continue and the warm-up all go through it.
void main() {
  final l10n = AppLocalizationsEn();

  group('DrillCatalog', () {
    test('every drill has a name, a description and a glyph', () {
      for (final d in DrillId.values) {
        expect(d.title(l10n), isNotEmpty, reason: d.name);
        expect(d.description(l10n), isNotEmpty, reason: d.name);
        expect(drillGlyphs[d], isNotNull, reason: d.name);
        expect(d.modes, contains(d.defaultConfig.mode), reason: d.name);
      }
    });

    test('the groups list each drill exactly once', () {
      for (final section in DrillSection.values) {
        final grouped = [
          for (final g in DrillCatalog.groups(section)) ...g.drills,
        ];
        expect(grouped.toSet(), DrillId.inSection(section).toSet());
        expect(grouped.length, DrillId.inSection(section).length);
      }
    });

    test('locations carry every choice, coerced onto what the drill offers',
        () {
      String loc(DrillConfig c, {bool warmup = false}) =>
          c.drill.location(c, warmup: warmup);

      // A knight can't fork onto a knight: the target falls back to rook.
      expect(
        loc(const DrillConfig(
          drill: DrillId.forksAndSkewers,
          mode: DrillMode.speed,
          piece: WhitePiece.knight,
          target: TargetPiece.knight,
        )),
        '/chess-vision/game?drill=forksAndSkewers&piece=knight&target=rook'
        '&mode=speed',
      );
      // Knight drills are practice-only.
      expect(
        loc(const DrillConfig(drill: DrillId.knightFlight, mode: DrillMode.speed)),
        contains('mode=practice'),
      );
      // Concentric belongs to Forks & Skewers; Pawn Attack runs it timed.
      expect(
        loc(const DrillConfig(
            drill: DrillId.pawnAttack, mode: DrillMode.concentric)),
        contains('mode=practice'),
      );
      expect(
        loc(const DrillConfig(
          drill: DrillId.squares,
          mode: DrillMode.practice,
          blackSide: true,
        )),
        '/file-rank-trainer/game?subject=squares&mode=practice&hardMode=true',
      );
      // Explore has no Black side.
      expect(
        loc(const DrillConfig(
          drill: DrillId.squares,
          mode: DrillMode.explore,
          blackSide: true,
        )),
        contains('hardMode=false'),
      );
      expect(
        loc(const DrillConfig(
          drill: DrillId.filesRanks,
          mode: DrillMode.speed,
          lines: DrillLines.ranks,
        )),
        '/file-rank-trainer/game?subject=ranks&mode=speed&hardMode=false',
      );
      expect(
        loc(const DrillConfig(drill: DrillId.readMoves, mode: DrillMode.speed)),
        '/move-trainer/game?mode=speed&hardMode=false',
      );
      expect(
        loc(const DrillConfig(
            drill: DrillId.pieceValues, mode: DrillMode.explore)),
        '/the-pieces/which-side-wins?mode=practice',
      );
      expect(
        loc(const DrillConfig(drill: DrillId.mateInOne, mode: DrillMode.speed),
            warmup: true),
        endsWith('&warmup=1'),
      );
    });

    test('best keys match the keys the trainers save under', () {
      expect(
        DrillId.forksAndSkewers.bestKey(const DrillConfig(
          drill: DrillId.forksAndSkewers,
          mode: DrillMode.speed,
          piece: WhitePiece.bishop,
          target: TargetPiece.queen,
        )),
        ChessVisionNotifier.bestKeyFor(VisionDrillType.forksAndSkewers,
            VisionMode.speed, WhitePiece.bishop, TargetPiece.queen),
      );
      expect(
        DrillId.squares.bestKey(const DrillConfig(
          drill: DrillId.squares,
          mode: DrillMode.speed,
          blackSide: true,
        )),
        FileRankGameNotifier.bestKeyFor(
            TrainerSubject.squares, TrainerMode.speed, true),
      );
      // Practice and explore keep no records; neither do the knight drills.
      expect(
        DrillId.findChecks.bestKey(
            const DrillConfig(drill: DrillId.findChecks, mode: DrillMode.practice)),
        isNull,
      );
      expect(
        DrillId.knightSight.bestKey(
            const DrillConfig(drill: DrillId.knightSight, mode: DrillMode.speed)),
        isNull,
      );
      // Concentric is ranked by time.
      const concentric = DrillConfig(
          drill: DrillId.forksAndSkewers, mode: DrillMode.concentric);
      expect(DrillId.forksAndSkewers.bestIsTime(concentric), isTrue);
      expect(DrillCatalog.formatBest(161, isTime: true), '2:41');
      expect(DrillCatalog.formatBest(14, isTime: false), '14');
    });

    test('a tile shows the Speed best for a drill last played in practice', () {
      const practice = DrillConfig(
        drill: DrillId.forksAndSkewers,
        mode: DrillMode.practice,
        piece: WhitePiece.rook,
      );
      final scored = DrillId.forksAndSkewers.scoredConfig(practice)!;
      expect(scored.mode, DrillMode.speed);
      expect(scored.piece, WhitePiece.rook);
      expect(
        DrillId.knightFlight.scoredConfig(
            const DrillConfig(drill: DrillId.knightFlight, mode: DrillMode.practice)),
        isNull,
      );
    });
  });

  group('DrillConfig', () {
    test('round-trips through JSON; junk reads as null', () {
      const config = DrillConfig(
        drill: DrillId.filesRanks,
        mode: DrillMode.speed,
        lines: DrillLines.ranks,
        blackSide: true,
      );
      expect(DrillConfig.fromJson(jsonDecode(jsonEncode(config.toJson()))),
          config);
      expect(DrillConfig.fromJson({'drill': 'gone', 'mode': 'speed'}), isNull);
      expect(DrillConfig.fromJson('nope'), isNull);
    });
  });

  group('DrillPrefs', () {
    test('remembers each drill setup and the last drill, across launches',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ProviderContainer launch() => ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);

      final first = launch();
      expect(first.read(drillPrefsProvider).lastPlayed, isNull);
      expect(first.read(drillPrefsProvider).hasPlayed(DrillId.squares), isFalse);
      first.read(drillPrefsProvider.notifier).recordStart(const DrillConfig(
            drill: DrillId.squares,
            mode: DrillMode.speed,
            blackSide: true,
          ));
      first.dispose();

      final second = launch();
      final restored = second.read(drillPrefsProvider);
      expect(restored.lastPlayed?.drill, DrillId.squares);
      expect(restored.configFor(DrillId.squares).blackSide, isTrue);
      expect(restored.hasPlayed(DrillId.squares), isTrue);
      expect(restored.configFor(DrillId.readMoves),
          DrillId.readMoves.defaultConfig);
      second.dispose();
    });
  });

  group('Warm-up', () {
    test('five timed steps, played in order, then complete', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(warmupProvider.notifier);

      final first = notifier.start(now: DateTime(2026, 10, 5));
      final state = container.read(warmupProvider);
      expect(first.drill, DrillId.findChecks);
      expect(state.steps, hasLength(5));
      for (final step in state.steps) {
        expect(step.drill.bestKey(step), isNotNull,
            reason: '${step.drill} must be a timed, scored round');
      }
      expect(state.steps[3].blackSide, isTrue); // squares from Black's side

      for (var i = 0; i < 4; i++) {
        expect(notifier.completeStep(10 + i), isNotNull);
      }
      expect(container.read(warmupProvider).isLastStep, isTrue);
      expect(notifier.completeStep(3), isNull);
      final done = container.read(warmupProvider);
      expect(done.isComplete, isTrue);
      expect(done.scores, [10, 11, 12, 13, 3]);

      notifier.end();
      expect(container.read(warmupProvider).steps, isEmpty);
    });

    test("Forks & Skewers rotates its piece by the day", () {
      final pieces = {
        for (var d = 0; d < 7; d++)
          WarmupNotifier.stepsFor(DateTime(2026, 10, 5 + d))[2].piece,
      };
      expect(pieces.length, greaterThan(1));
    });
  });
}
