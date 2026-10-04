import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter/material.dart' show Color;

import '../../core/theme/app_theme.dart';
import '../../core/ui/drill_glyph.dart';
import '../chess_vision/models/chess_vision_state.dart';
import '../chess_vision/providers/chess_vision_provider.dart';
import '../file_rank_trainer/models/file_rank_game_state.dart';
import '../file_rank_trainer/providers/file_rank_game_provider.dart';
import '../letter_trainer/models/letter_game_state.dart';
import '../letter_trainer/providers/letter_game_provider.dart';
import '../move_trainer/models/move_game_state.dart';
import '../move_trainer/providers/move_game_provider.dart';
import '../pieces/models/which_side_wins_state.dart';
import '../pieces/providers/which_side_wins_provider.dart';
import 'models/drill.dart';

/// A heading and the drills under it on a section screen.
typedef DrillGroup = ({String Function(AppLocalizations) title, List<DrillId> drills});

/// What the app knows about each drill: names, glyph, modes, options, where
/// it runs and where its personal best is kept. Home, the section screens,
/// Continue and the warm-up all read from here, so a drill is described in
/// exactly one place.
extension DrillCatalog on DrillId {
  // ---------------------------------------------------------------- naming

  String title(AppLocalizations l10n) => switch (this) {
        DrillId.findChecks => l10n.scanDrillChecks,
        DrillId.findCaptures => l10n.scanDrillCaptures,
        DrillId.hangingPieces => l10n.scanDrillHanging,
        DrillId.forksAndSkewers => l10n.forksAndSkewers,
        DrillId.knightSight => l10n.knightSight,
        DrillId.knightFlight => l10n.knightFlight,
        DrillId.pawnAttack => l10n.pawnAttack,
        DrillId.mateInOne => l10n.scanDrillMate,
        DrillId.squares => l10n.squares,
        DrillId.filesRanks => l10n.drillFilesRanks,
        DrillId.readMoves => l10n.drillReadMoves,
        DrillId.pieceLetters => l10n.drillPieceLetters,
        DrillId.pieceValues => l10n.drillPieceValues,
      };

  String description(AppLocalizations l10n) => switch (this) {
        DrillId.findChecks => l10n.drillDescFindChecks,
        DrillId.findCaptures => l10n.drillDescFindCaptures,
        DrillId.hangingPieces => l10n.drillDescHanging,
        DrillId.forksAndSkewers => l10n.drillDescForks,
        DrillId.knightSight => l10n.drillDescKnightSight,
        DrillId.knightFlight => l10n.drillDescKnightFlight,
        DrillId.pawnAttack => l10n.drillDescPawnAttack,
        DrillId.mateInOne => l10n.drillDescMate,
        DrillId.squares => l10n.drillDescSquares,
        DrillId.filesRanks => l10n.drillDescFilesRanks,
        DrillId.readMoves => l10n.drillDescReadMoves,
        DrillId.pieceLetters => l10n.drillDescLetters,
        DrillId.pieceValues => l10n.drillDescValues,
      };

  GlyphSpec get glyph => drillGlyphs[this]!;

  // ---------------------------------------------------------------- engine

  /// The Chess Vision drill this runs as, for the vision section.
  VisionDrillType? get visionType => switch (this) {
        DrillId.findChecks => VisionDrillType.findChecks,
        DrillId.findCaptures => VisionDrillType.findCaptures,
        DrillId.hangingPieces => VisionDrillType.hangingPieces,
        DrillId.forksAndSkewers => VisionDrillType.forksAndSkewers,
        DrillId.knightSight => VisionDrillType.knightSight,
        DrillId.knightFlight => VisionDrillType.knightFlight,
        DrillId.pawnAttack => VisionDrillType.pawnAttack,
        DrillId.mateInOne => VisionDrillType.mateInOne,
        _ => null,
      };

  /// The drill a vision game screen is showing, from its engine type.
  static DrillId forVision(VisionDrillType type) =>
      DrillId.values.firstWhere((d) => d.visionType == type);

  // ---------------------------------------------------------------- modes

  List<DrillMode> get modes => switch (this) {
        DrillId.forksAndSkewers => const [
            DrillMode.practice,
            DrillMode.speed,
            DrillMode.concentric,
          ],
        DrillId.knightSight || DrillId.knightFlight => const [DrillMode.practice],
        DrillId.squares || DrillId.filesRanks || DrillId.pieceLetters => const [
            DrillMode.explore,
            DrillMode.practice,
            DrillMode.speed,
          ],
        _ => const [DrillMode.practice, DrillMode.speed],
      };

  String modeLabel(DrillMode mode, AppLocalizations l10n) => switch (mode) {
        DrillMode.explore => l10n.explore,
        DrillMode.practice => l10n.practice,
        DrillMode.concentric => l10n.concentric,
        DrillMode.speed => switch (this) {
            DrillId.pawnAttack => l10n.timed,
            DrillId.mateInOne => l10n.blitz,
            _ => l10n.speedRound,
          },
      };

  String modeHelp(DrillMode mode, AppLocalizations l10n) {
    if (this == DrillId.knightSight || this == DrillId.knightFlight) {
      return l10n.setupKnightPracticeOnly;
    }
    return switch ((this, mode)) {
      (_, DrillMode.explore) => l10n.exploreDesc,
      (DrillId.forksAndSkewers, DrillMode.practice) => l10n.findForksNoTimer,
      (DrillId.forksAndSkewers, DrillMode.concentric) =>
        l10n.concentricDrillDesc,
      (DrillId.pawnAttack, DrillMode.practice) => l10n.captureAllPawnsNoTimer,
      (DrillId.pawnAttack, DrillMode.speed) => l10n.timedPawnAttackDesc,
      (DrillId.mateInOne, DrillMode.speed) => l10n.scanBlitzDesc,
      (DrillId.pieceValues, DrillMode.practice) =>
        l10n.whichSideWinsPracticeDesc,
      (_, DrillMode.practice) when section == DrillSection.vision =>
        l10n.scanPracticeDesc,
      (_, DrillMode.speed) when section == DrillSection.vision =>
        l10n.speedRound60Desc,
      (_, DrillMode.practice) => l10n.practiceDesc,
      (_, DrillMode.speed) => l10n.speedRoundDesc,
      (_, DrillMode.concentric) => l10n.concentricDrillDesc,
    };
  }

  // ---------------------------------------------------------------- options

  bool get usesPiece =>
      this == DrillId.forksAndSkewers || this == DrillId.pawnAttack;

  bool get usesTarget => this == DrillId.forksAndSkewers;

  bool get usesLines => this == DrillId.filesRanks;

  /// Whether [mode] offers the Black-side ("hard mode") option.
  bool usesSide(DrillMode mode) =>
      mode != DrillMode.explore &&
      (this == DrillId.squares ||
          this == DrillId.filesRanks ||
          this == DrillId.readMoves ||
          this == DrillId.pieceLetters);

  /// Knight vs knight has no fork anywhere (the knights can always take each
  /// other), so a knight can't pick the knight target.
  static bool isTargetAllowed(TargetPiece target, WhitePiece piece) =>
      !(piece == WhitePiece.knight && target == TargetPiece.knight);

  DrillConfig get defaultConfig => DrillConfig(
        drill: this,
        mode: modes.contains(DrillMode.explore)
            ? DrillMode.explore
            : DrillMode.practice,
      );

  /// [config] with every choice coerced onto one this drill really offers.
  DrillConfig normalize(DrillConfig config) {
    var c = config;
    if (!modes.contains(c.mode)) c = c.copyWith(mode: defaultConfig.mode);
    if (!isTargetAllowed(c.target, c.piece)) {
      c = c.copyWith(target: TargetPiece.rook);
    }
    if (!usesSide(c.mode) && c.blackSide) c = c.copyWith(blackSide: false);
    return c;
  }

  // ---------------------------------------------------------------- routes

  /// Where [config] plays. [warmup] marks it as a step of the daily warm-up.
  String location(DrillConfig config, {bool warmup = false}) {
    final c = normalize(config);
    final w = warmup ? '&warmup=1' : '';
    final hard = c.blackSide;
    switch (this) {
      case DrillId.squares:
      case DrillId.filesRanks:
        final subject = this == DrillId.squares
            ? TrainerSubject.squares
            : (c.lines == DrillLines.files
                ? TrainerSubject.files
                : TrainerSubject.ranks);
        return '/file-rank-trainer/game?subject=${subject.name}'
            '&mode=${_trainerMode(c.mode).name}&hardMode=$hard$w';
      case DrillId.readMoves:
        return '/move-trainer/game?mode=${_moveMode(c.mode).name}'
            '&hardMode=$hard$w';
      case DrillId.pieceLetters:
        return '/letter-trainer/game?mode=${_letterMode(c.mode).name}'
            '&hardMode=$hard$w';
      case DrillId.pieceValues:
        return '/the-pieces/which-side-wins?mode=${_valuesMode(c.mode).name}$w';
      default:
        final type = visionType!;
        return '/chess-vision/game?drill=${type.name}&piece=${c.piece.name}'
            '&target=${c.target.name}'
            '&mode=${type.effectiveMode(_visionMode(c.mode)).name}$w';
    }
  }

  // ---------------------------------------------------------------- bests

  /// Where [config]'s personal best is kept, or null if its mode keeps none
  /// (explore and practice never end, so they set no records).
  String? bestKey(DrillConfig config) {
    final c = normalize(config);
    final type = visionType;
    if (type != null) {
      if (c.mode != DrillMode.speed && c.mode != DrillMode.concentric) {
        return null;
      }
      if (type.isKnightDrill) return null;
      return ChessVisionNotifier.bestKeyFor(
        type,
        type.effectiveMode(_visionMode(c.mode)),
        c.piece,
        c.target,
      );
    }
    if (c.mode != DrillMode.speed) return null;
    return switch (this) {
      DrillId.squares => FileRankGameNotifier.bestKeyFor(
          TrainerSubject.squares, TrainerMode.speed, c.blackSide),
      DrillId.filesRanks => FileRankGameNotifier.bestKeyFor(
          c.lines == DrillLines.files
              ? TrainerSubject.files
              : TrainerSubject.ranks,
          TrainerMode.speed,
          c.blackSide),
      DrillId.readMoves =>
        MoveGameNotifier.bestKeyFor(MoveTrainerMode.speed, c.blackSide),
      DrillId.pieceLetters =>
        LetterGameNotifier.bestKeyFor(LetterTrainerMode.speed, c.blackSide),
      DrillId.pieceValues =>
        WhichSideWinsNotifier.bestKeyFor(WhichSideWinsMode.speed),
      _ => null,
    };
  }

  /// Concentric and timed Pawn Attack keep a time (lower is better).
  bool bestIsTime(DrillConfig config) {
    final type = visionType;
    if (type == null) return false;
    return ChessVisionNotifier.isTimedByStopwatchFor(
      type,
      type.effectiveMode(_visionMode(normalize(config).mode)),
    );
  }

  /// The config whose best a tile shows for [config]: itself if its mode
  /// keeps one, else the same options in Speed. Null for practice-only drills.
  DrillConfig? scoredConfig(DrillConfig config) {
    final c = normalize(config);
    if (bestKey(c) != null) return c;
    if (!modes.contains(DrillMode.speed)) return null;
    return normalize(c.copyWith(mode: DrillMode.speed));
  }

  static String formatBest(int value, {required bool isTime}) {
    if (!isTime) return '$value';
    final m = value ~/ 60;
    final s = value % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------- groups

  static List<DrillGroup> groups(DrillSection section) => switch (section) {
        DrillSection.vision => [
            (
              title: (l) => l.groupScan,
              drills: const [
                DrillId.findChecks,
                DrillId.findCaptures,
                DrillId.hangingPieces,
              ],
            ),
            (
              title: (l) => l.groupGeometry,
              drills: const [
                DrillId.forksAndSkewers,
                DrillId.knightSight,
                DrillId.knightFlight,
                DrillId.pawnAttack,
              ],
            ),
            (title: (l) => l.groupFinish, drills: const [DrillId.mateInOne]),
          ],
        DrillSection.notation => [
            (
              title: (l) => l.groupBoard,
              drills: const [DrillId.squares, DrillId.filesRanks],
            ),
            (title: (l) => l.moves, drills: const [DrillId.readMoves]),
            (
              title: (l) => l.groupPieces,
              drills: const [DrillId.pieceLetters, DrillId.pieceValues],
            ),
          ],
      };
}

VisionMode _visionMode(DrillMode mode) => switch (mode) {
      DrillMode.speed => VisionMode.speed,
      DrillMode.concentric => VisionMode.concentric,
      _ => VisionMode.practice,
    };

TrainerMode _trainerMode(DrillMode mode) => switch (mode) {
      DrillMode.explore => TrainerMode.explore,
      DrillMode.speed => TrainerMode.speed,
      _ => TrainerMode.practice,
    };

MoveTrainerMode _moveMode(DrillMode mode) =>
    mode == DrillMode.speed ? MoveTrainerMode.speed : MoveTrainerMode.practice;

LetterTrainerMode _letterMode(DrillMode mode) => switch (mode) {
      DrillMode.explore => LetterTrainerMode.explore,
      DrillMode.speed => LetterTrainerMode.speed,
      _ => LetterTrainerMode.practice,
    };

WhichSideWinsMode _valuesMode(DrillMode mode) => mode == DrillMode.speed
    ? WhichSideWinsMode.speed
    : WhichSideWinsMode.practice;

// ------------------------------------------------------------------ glyphs

const _attack = Color(0xFFE9B9A8);
const _fileTint = Color(0xFFA9D3BF);

/// The Opening Explorer's glyph (it isn't a drill, but sits on home).
const openingsGlyph = GlyphSpec(
  pieces: {
    (0, 3): PieceKind.whitePawn,
    (1, 3): PieceKind.whitePawn,
    (2, 3): PieceKind.whitePawn,
    (3, 3): PieceKind.whitePawn,
    (4, 3): PieceKind.whitePawn,
    (0, 4): PieceKind.whiteQueen,
    (1, 4): PieceKind.whiteKing,
    (2, 4): PieceKind.whiteBishop,
    (3, 4): PieceKind.whiteKnight,
    (4, 4): PieceKind.whiteRook,
  },
  arrows: [GlyphArrow((1, 3), (1, 1)), GlyphArrow((3, 4), (2, 2))],
);

/// Each drill's glyph: its idea, drawn on a 5×5 corner of a board.
const drillGlyphs = <DrillId, GlyphSpec>{
  DrillId.findChecks: GlyphSpec(
    pieces: {
      (3, 1): PieceKind.blackKing,
      (0, 1): PieceKind.whiteRook,
      (1, 2): PieceKind.whiteKnight,
    },
    arrows: [GlyphArrow((0, 1), (3, 1)), GlyphArrow((1, 2), (3, 1))],
  ),
  DrillId.findCaptures: GlyphSpec(
    pieces: {
      (0, 4): PieceKind.whiteBishop,
      (3, 1): PieceKind.blackKnight,
      (4, 3): PieceKind.whiteRook,
      (4, 0): PieceKind.blackPawn,
    },
    arrows: [GlyphArrow((0, 4), (3, 1)), GlyphArrow((4, 3), (4, 0))],
  ),
  DrillId.hangingPieces: GlyphSpec(
    pieces: {
      (2, 1): PieceKind.blackKnight,
      (2, 4): PieceKind.whiteRook,
      (4, 0): PieceKind.blackKing,
    },
    rings: {(2, 1): GlyphRing(AppColors.verm, dashed: true)},
    arrows: [GlyphArrow((2, 4), (2, 1))],
  ),
  DrillId.forksAndSkewers: GlyphSpec(
    pieces: {
      (2, 2): PieceKind.whiteKnight,
      (1, 0): PieceKind.blackKing,
      (4, 1): PieceKind.blackRook,
    },
    fills: {(2, 2): AppColors.amber},
    arrows: [GlyphArrow((2, 2), (1, 0)), GlyphArrow((2, 2), (4, 1))],
  ),
  DrillId.knightSight: GlyphSpec(
    pieces: {(2, 2): PieceKind.whiteKnight},
    dots: {
      (0, 1): AppColors.brand,
      (0, 3): AppColors.brand,
      (1, 0): AppColors.brand,
      (1, 4): AppColors.brand,
      (3, 0): AppColors.brand,
      (3, 4): AppColors.brand,
      (4, 1): AppColors.brand,
      (4, 3): AppColors.brand,
    },
  ),
  DrillId.knightFlight: GlyphSpec(
    pieces: {(0, 4): PieceKind.whiteKnight},
    fills: {(2, 0): AppColors.amber},
    dots: {(1, 2): AppColors.brand},
    paths: [
      GlyphPath([(0, 4), (1, 2), (2, 0)]),
    ],
  ),
  DrillId.pawnAttack: GlyphSpec(
    pieces: {
      (1, 1): PieceKind.blackPawn,
      (3, 1): PieceKind.blackPawn,
      (1, 3): PieceKind.blackPawn,
      (4, 4): PieceKind.whiteKing,
    },
    fills: {
      (0, 2): _attack,
      (2, 2): _attack,
      (4, 2): _attack,
      (0, 4): _attack,
      (2, 4): _attack,
    },
    paths: [
      GlyphPath([(4, 4), (3, 3), (3, 2)]),
    ],
  ),
  DrillId.mateInOne: GlyphSpec(
    pieces: {
      (3, 0): PieceKind.blackKing,
      (2, 1): PieceKind.blackPawn,
      (3, 1): PieceKind.blackPawn,
      (4, 1): PieceKind.blackPawn,
      (0, 4): PieceKind.whiteRook,
    },
    fills: {(0, 0): AppColors.amber},
    arrows: [GlyphArrow((0, 4), (0, 0))],
  ),
  DrillId.squares: GlyphSpec(fills: {(3, 2): AppColors.brand}, pill: 'e3'),
  DrillId.filesRanks: GlyphSpec(
    fills: {
      (2, 0): _fileTint,
      (2, 1): _fileTint,
      (2, 2): _fileTint,
      (2, 3): _fileTint,
      (2, 4): _fileTint,
    },
    pill: 'c',
  ),
  DrillId.readMoves: GlyphSpec(
    pieces: {(1, 4): PieceKind.whiteKnight},
    arrows: [GlyphArrow((1, 4), (2, 2))],
    pill: 'Nf3',
  ),
  DrillId.pieceLetters: GlyphSpec(
    pieces: {(2, 2): PieceKind.whiteKnight},
    pill: 'N',
  ),
  DrillId.pieceValues: GlyphSpec(
    pieces: {(1, 2): PieceKind.whiteKnight, (3, 2): PieceKind.blackRook},
    pill: '3:5',
  ),
};
