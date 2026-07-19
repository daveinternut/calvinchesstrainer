import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import '../models/letter_game_state.dart';

/// Localized display name for a piece.
String pieceNameFor(AppLocalizations l10n, LetterPiece piece) {
  return switch (piece) {
    LetterPiece.king => l10n.king,
    LetterPiece.queen => l10n.queen,
    LetterPiece.rook => l10n.rook,
    LetterPiece.bishop => l10n.bishop,
    LetterPiece.knight => l10n.knight,
    LetterPiece.pawn => l10n.pawn,
  };
}

/// The fun one-liner shown in Explore mode when a piece is tapped.
String mnemonicFor(AppLocalizations l10n, LetterPiece piece) {
  return switch (piece) {
    LetterPiece.king => l10n.mnemonicKing,
    LetterPiece.queen => l10n.mnemonicQueen,
    LetterPiece.rook => l10n.mnemonicRook,
    LetterPiece.bishop => l10n.mnemonicBishop,
    LetterPiece.knight => l10n.mnemonicKnight,
    LetterPiece.pawn => l10n.mnemonicPawn,
  };
}

/// The reveal line after an answer: "N = Knight!" — or the pawn's
/// no-letter fact, since "= Pawn!" would read as a broken string.
String revealLineFor(AppLocalizations l10n, LetterPiece piece) {
  if (!piece.hasLetter) return l10n.pawnNoLetterFact;
  return l10n.letterEquals(piece.letter, pieceNameFor(l10n, piece));
}
