import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// The one board look every trainer uses: pale sage squares, so the brand
/// green (found), amber (target) and vermilion (miss) all read clearly.
///
/// Coordinates are drawn outside the board by `BoardFrame`, never inside the
/// squares, so [settings] turns chessground's own coordinates off.
class AppBoard {
  static const radius = 14.0;

  static const colorScheme = ChessboardColorScheme(
    lightSquare: AppColors.boardLight,
    darkSquare: AppColors.boardDark,
    background: SolidColorChessboardBackground(
      lightSquare: AppColors.boardLight,
      darkSquare: AppColors.boardDark,
    ),
    whiteCoordBackground: SolidColorChessboardBackground(
      lightSquare: AppColors.boardLight,
      darkSquare: AppColors.boardDark,
      coordinates: true,
    ),
    blackCoordBackground: SolidColorChessboardBackground(
      lightSquare: AppColors.boardLight,
      darkSquare: AppColors.boardDark,
      coordinates: true,
      orientation: Side.black,
    ),
    lastMove: HighlightDetails(solidColor: Color(0x66E8A33D)),
    selected: HighlightDetails(solidColor: Color(0x660F6B4C)),
    validMoves: Color(0x4D0E1B16),
    validPremoves: Color(0x40203085),
  );

  static ChessboardSettings settings({
    bool showValidMoves = true,
    bool showLastMove = true,
    bool autoQueenPromotion = false,
    Duration animationDuration = const Duration(milliseconds: 200),
    double radius = AppBoard.radius,
  }) {
    return ChessboardSettings(
      colorScheme: colorScheme,
      pieceAssets: PieceSet.cburnett.assets,
      enableCoordinates: false,
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      animationDuration: animationDuration,
      showValidMoves: showValidMoves,
      showLastMove: showLastMove,
      autoQueenPromotion: autoQueenPromotion,
    );
  }
}
