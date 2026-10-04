import '../../chess_vision/models/chess_vision_state.dart'
    show TargetPiece, WhitePiece;

/// The two families of drills on the home screen.
enum DrillSection { vision, notation }

/// Every drill the app offers, in the order the section screens list them.
///
/// A drill is what the player picks; under the hood each one runs on an
/// existing trainer (the Chess Vision engine, the file/rank trainer, the
/// move trainer, the letter trainer, Which Side Wins). The catalog
/// (`drill_catalog.dart`) maps between the two.
enum DrillId {
  findChecks(DrillSection.vision),
  findCaptures(DrillSection.vision),
  hangingPieces(DrillSection.vision),
  forksAndSkewers(DrillSection.vision),
  knightSight(DrillSection.vision),
  knightFlight(DrillSection.vision),
  pawnAttack(DrillSection.vision),
  mateInOne(DrillSection.vision),
  squares(DrillSection.notation),
  filesRanks(DrillSection.notation),
  readMoves(DrillSection.notation),
  pieceLetters(DrillSection.notation),
  pieceValues(DrillSection.notation);

  const DrillId(this.section);

  final DrillSection section;

  static List<DrillId> inSection(DrillSection section) =>
      values.where((d) => d.section == section).toList();
}

/// The modes across all drills. Each drill offers a subset
/// (`DrillCatalog.modes`).
enum DrillMode { explore, practice, speed, concentric }

/// Files & Ranks drills one kind of line at a time.
enum DrillLines { files, ranks }

/// Everything needed to start a drill: what the setup panel edits, what
/// Continue resumes and what each warm-up step is.
class DrillConfig {
  const DrillConfig({
    required this.drill,
    required this.mode,
    this.piece = WhitePiece.queen,
    this.target = TargetPiece.rook,
    this.lines = DrillLines.files,
    this.blackSide = false,
  });

  final DrillId drill;
  final DrillMode mode;

  /// Forks & Skewers and Pawn Attack: the piece you play.
  final WhitePiece piece;

  /// Forks & Skewers: what the fork hits besides the king.
  final TargetPiece target;

  /// Files & Ranks: which lines to drill.
  final DrillLines lines;

  /// Notation drills: play from Black's side ("hard mode").
  final bool blackSide;

  DrillConfig copyWith({
    DrillMode? mode,
    WhitePiece? piece,
    TargetPiece? target,
    DrillLines? lines,
    bool? blackSide,
  }) {
    return DrillConfig(
      drill: drill,
      mode: mode ?? this.mode,
      piece: piece ?? this.piece,
      target: target ?? this.target,
      lines: lines ?? this.lines,
      blackSide: blackSide ?? this.blackSide,
    );
  }

  Map<String, Object> toJson() => {
        'drill': drill.name,
        'mode': mode.name,
        'piece': piece.name,
        'target': target.name,
        'lines': lines.name,
        'blackSide': blackSide,
      };

  /// Reads a saved config; anything unreadable (a renamed drill, a hand-
  /// edited value) gives null rather than throwing.
  static DrillConfig? fromJson(Object? json) {
    if (json is! Map) return null;
    T? byName<T extends Enum>(List<T> values, Object? name) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return null;
    }

    final drill = byName(DrillId.values, json['drill']);
    final mode = byName(DrillMode.values, json['mode']);
    if (drill == null || mode == null) return null;
    return DrillConfig(
      drill: drill,
      mode: mode,
      piece: byName(WhitePiece.values, json['piece']) ?? WhitePiece.queen,
      target: byName(TargetPiece.values, json['target']) ?? TargetPiece.rook,
      lines: byName(DrillLines.values, json['lines']) ?? DrillLines.files,
      blackSide: json['blackSide'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DrillConfig &&
      other.drill == drill &&
      other.mode == mode &&
      other.piece == piece &&
      other.target == target &&
      other.lines == lines &&
      other.blackSide == blackSide;

  @override
  int get hashCode => Object.hash(drill, mode, piece, target, lines, blackSide);

  @override
  String toString() => 'DrillConfig(${toJson()})';
}
