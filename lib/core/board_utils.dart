import 'package:flutter/widgets.dart';
import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

IMap<Square, SquareHighlight> highlightFile(int fileIndex, Color color) {
  final highlight = SquareHighlight(details: HighlightDetails(solidColor: color));
  return IMap({
    for (int rank = 0; rank < 8; rank++)
      Square.fromCoords(File(fileIndex), Rank(rank)): highlight,
  });
}

IMap<Square, SquareHighlight> highlightRank(int rankIndex, Color color) {
  final highlight = SquareHighlight(details: HighlightDetails(solidColor: color));
  return IMap({
    for (int file = 0; file < 8; file++)
      Square.fromCoords(File(file), Rank(rankIndex)): highlight,
  });
}

IMap<Square, SquareHighlight> highlightSquare(
  int fileIndex,
  int rankIndex,
  Color color,
) {
  return IMap({
    Square.fromCoords(File(fileIndex), Rank(rankIndex)):
        SquareHighlight(details: HighlightDetails(solidColor: color)),
  });
}
