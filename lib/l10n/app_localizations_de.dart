// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Calvin Chess Trainer';

  @override
  String get about => 'Über';

  @override
  String get calvinChessTrainer => 'Calvin Chess\nTrainer';

  @override
  String get masterTheFundamentals => 'Meistere die Grundlagen!';

  @override
  String get chessNotation => 'Schachnotation';

  @override
  String get learnTheBoard => 'Lerne das Brett!';

  @override
  String get chessVision => 'Schachvision';

  @override
  String get seeTheBoard => 'Sieh das Brett!';

  @override
  String get comingSoon => 'DEMNÄCHST';

  @override
  String get start => 'Starten';

  @override
  String get menu => 'Menü';

  @override
  String get playAgain => 'Nochmal spielen';

  @override
  String get newRecord => 'Neuer Rekord!';

  @override
  String get whatToPractice => 'Was üben?';

  @override
  String get chooseAMode => 'Wähle einen Modus';

  @override
  String get files => 'Linien';

  @override
  String get ranks => 'Reihen';

  @override
  String get squares => 'Felder';

  @override
  String get moves => 'Züge';

  @override
  String get explore => 'Erkunden';

  @override
  String get exploreDesc => 'Tippe zum Lernen — kein Druck, keine Punkte';

  @override
  String get practice => 'Übung';

  @override
  String get practiceDesc => 'Teste dich — baue deine Serie auf!';

  @override
  String get speedRound => 'Schnellrunde';

  @override
  String get speedRoundDesc => '30 Sekunden — wie viele schaffst du?';

  @override
  String get hardMode => 'SCHWERER MODUS';

  @override
  String get hardModeBlack => 'Spieler spielt mit Schwarz!';

  @override
  String get hardModeFlipped => 'Brett gedreht — Perspektive von Schwarz!';

  @override
  String get timesUp => 'Zeit abgelaufen!';

  @override
  String get correct => 'Richtig';

  @override
  String get accuracy => 'Genauigkeit';

  @override
  String get bestStreak => 'Beste Serie';

  @override
  String bestLabel(int value) {
    return 'Rekord: $value';
  }

  @override
  String get tapFileToHear => 'Tippe auf eine Linie, um ihren Namen zu hören';

  @override
  String get tapRankToHear => 'Tippe auf eine Reihe, um ihren Namen zu hören';

  @override
  String get tapSquareToHear => 'Tippe auf ein Feld, um seinen Namen zu hören';

  @override
  String get tapFile => 'Tippe die Linie';

  @override
  String get tapRank => 'Tippe die Reihe';

  @override
  String get tapSquare => 'Tippe das Feld';

  @override
  String get milestoneNice => 'Schön!';

  @override
  String get milestoneAmazing => 'Erstaunlich!';

  @override
  String get milestoneIncredible => 'Unglaublich!';

  @override
  String get milestoneUnstoppable => 'Unaufhaltbar!';

  @override
  String get milestoneLegendary => 'Legendär!';

  @override
  String get milestoneGreat => 'Toll!';

  @override
  String streakMilestone(int count) {
    return '$count in Folge!';
  }

  @override
  String get hurry => 'Schnell!';

  @override
  String get drillType => 'Übungstyp';

  @override
  String get forksAndSkewers => 'Gabeln und Spieße';

  @override
  String get pawnAttack => 'Bauernangriff';

  @override
  String get knightSight => 'Springersicht';

  @override
  String get knightFlight => 'Springerflug';

  @override
  String get chooseYourPiece => 'Wähle deine Figur';

  @override
  String get targetPiece => 'Zielfigur';

  @override
  String get queen => 'Dame';

  @override
  String get rook => 'Turm';

  @override
  String get bishop => 'Läufer';

  @override
  String get knight => 'Springer';

  @override
  String get findForksNoTimer => 'Finde Gabeln und Spieße — ohne Zeitlimit';

  @override
  String get speedRound60Desc => '60 Sekunden — löse so viele wie möglich!';

  @override
  String get concentricDrill => 'Konzentrische Übung';

  @override
  String get concentricDrillDesc =>
      'Löse alle Positionen — schlage deine Zeit!';

  @override
  String get captureAllPawnsNoTimer => 'Schlage alle Bauern — ohne Zeitlimit';

  @override
  String get timed => 'Auf Zeit';

  @override
  String get timedPawnAttackDesc =>
      'Schlage 3 bis 8 Bauern — schlage deine Zeit!';

  @override
  String get concentric => 'Konzentrisch';

  @override
  String get retry => 'Nochmal';

  @override
  String get skip => 'Überspringen';

  @override
  String get none => 'Keine';

  @override
  String minimumMoves(int count) {
    return 'Minimum: $count';
  }

  @override
  String yourMoves(int count) {
    return 'Deine Züge: $count';
  }

  @override
  String pawnsRemaining(int count) {
    return 'Bauern: $count';
  }

  @override
  String levelOfEight(int level) {
    return 'Stufe $level von 8';
  }

  @override
  String movesCount(int count) {
    return 'Züge: $count';
  }

  @override
  String positionOfTotal(int current, int total) {
    return 'Position $current von $total';
  }

  @override
  String get tapNoneHint => 'Tippe Keine, wenn keine Lösungen existieren';

  @override
  String get found => 'Gefunden';

  @override
  String foundOfTotal(int found, int total) {
    return '$found von $total';
  }

  @override
  String get drillComplete => 'Übung abgeschlossen!';

  @override
  String get allClear => 'Alles gelöst!';

  @override
  String get time => 'Zeit';

  @override
  String get errors => 'Fehler';

  @override
  String get rounds => 'Runden';

  @override
  String solvedCount(int count) {
    return '$count gelöst';
  }

  @override
  String titleForksAndSkewers(String piece, String mode) {
    return '$piece — $mode';
  }

  @override
  String titlePawnAttack(String piece, String mode) {
    return 'Bauernangriff — $piece $mode';
  }

  @override
  String titleMovesGame(String mode) {
    return 'Züge - $mode';
  }

  @override
  String titleFileRankGame(String subject, String mode) {
    return '$subject - $mode';
  }

  @override
  String get makeTheMove => 'Mache den Zug';

  @override
  String get castleKingside => 'Kurze Rochade';

  @override
  String get castleQueenside => 'Lange Rochade';

  @override
  String pieceTakesOn(String piece, String square) {
    return '$piece schlägt auf $square';
  }

  @override
  String pieceToSquare(String piece, String square) {
    return '$piece nach $square';
  }

  @override
  String get seePositionMakeMove => 'Sieh eine Stellung, mache den Zug!';

  @override
  String get aboutWhatIs => 'Was ist Calvin Chess Trainer?';

  @override
  String get aboutWhatIsBody =>
      'Eine unterhaltsame, interaktive App, die Kindern die Grundlagen des Schachs beibringt. Lerne Linien, Reihen, Felder und Figurenzüge durch Übungen, Quiz und zeitgesteuerte Herausforderungen — alles mit Audio-Feedback und Serientracking, um dich zu motivieren!';

  @override
  String get aboutTrainingModes => 'Trainingsmodi';

  @override
  String get aboutTrainingModesBody =>
      '• Erkunden — lerne in deinem Tempo\n• Übung — teste dich und baue Serien auf\n• Schnellrunde — 30 Sekunden, wie viele schaffst du?\n• Schwerer Modus — verberge Koordinaten für eine echte Herausforderung';

  @override
  String get aboutCredits => 'Credits und Danksagungen';

  @override
  String get aboutCreditsBody =>
      '• Schachpuzzles aus der Lichess-Datenbank (CC0-Lizenz)\n• Brett-UI von Lichess chessground\n• Schachlogik von Lichess dartchess\n• Sprachclips von ElevenLabs\n• Entwickelt mit Flutter & Dart';

  @override
  String get aboutInspired => 'Inspiriert von Rapid Chess Improvement';

  @override
  String get aboutInspiredBody =>
      'Diese App verdankt viel dem Buch von Michael de la Maza Rapid Chess Improvement (Everyman Chess, 2002). Sein Konzept der \\\"Schachvision\\\" — die Fähigkeit, taktische Muster und Figurenbeziehungen sofort zu erkennen — hat meine Denkweise über das Training verändert. Seine Ideen haben mir geholfen, mein eigenes Spiel dramatisch zu verbessern, und ich habe Calvin Chess Trainer in der Hoffnung entwickelt, dass sein Ansatz zur Schachvision einer neuen Generation von Spielern hilft, das Brett klarer zu sehen. Danke, Michael!';

  @override
  String get aboutInternut => 'Über Internut Education';

  @override
  String get aboutInternutBody =>
      'Internut Education entwickelt ansprechende Lern-Apps für Kinder. Wir glauben, dass man am besten durch Spielen, Üben und positive Bestärkung lernt.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutByInternut => 'von Internut Education';

  @override
  String get aboutFooter => 'Mit ❤️ gemacht für junge Schachspieler überall';

  @override
  String get feedbackTitle => 'Sende uns Feedback';

  @override
  String get feedbackBody =>
      'Wir möchten diese App immer besser machen! Ob eine Idee, ein Fehler oder etwas, das du liebst — wir freuen uns über deine Rückmeldung.';

  @override
  String get feedbackHint => 'Schreibe dein Feedback hier...';

  @override
  String get feedbackSend => 'Feedback senden';

  @override
  String get feedbackSending => 'Wird gesendet...';

  @override
  String get feedbackThanks => 'Danke für dein Feedback!';

  @override
  String get feedbackError =>
      'Senden fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get feedbackEmpty => 'Bitte schreibe etwas, bevor du sendest.';

  @override
  String get tacticsTrainer => 'Taktiktrainer';

  @override
  String get tacticsComingSoon => 'Taktiktrainer kommt bald';

  @override
  String get squareTrainer => 'Feldertrainer';

  @override
  String get squareComingSoon => 'Feldertrainer kommt bald';

  @override
  String get moveTrainer => 'Zugtrainer';

  @override
  String get moveComingSoon => 'Zugtrainer kommt bald';

  @override
  String get promptSquare => 'Feld';

  @override
  String get promptFile => 'Linie';

  @override
  String get promptRank => 'Reihe';

  @override
  String get openingFundamentals => 'Eröffnungs\nExplorer';

  @override
  String get playTheOpening => 'Eröffnungen erkunden!';

  @override
  String get openingPractice => 'Eröffnungsübung';

  @override
  String get openingChallenge => 'Eröffnungsherausforderung';

  @override
  String get playAs => 'Spiele als';

  @override
  String get playAsWhite => 'Weiß';

  @override
  String get playAsBlack => 'Schwarz';

  @override
  String get difficulty => 'Schwierigkeit';

  @override
  String get easy => 'Leicht';

  @override
  String get medium => 'Mittel';

  @override
  String get hard => 'Schwer';

  @override
  String get challenge => 'Herausforderung';

  @override
  String get practiceHintsDesc =>
      'Spiele mit Hinweisen — die 3 besten Züge als Pfeile angezeigt';

  @override
  String get challengeDesc =>
      'Teste deine Eröffnungskenntnisse — verdiene Medaillen!';

  @override
  String get engineThinking => 'Engine analysiert...';

  @override
  String get yourTurn => 'Du bist dran';

  @override
  String get gameOver => 'Spiel vorbei';

  @override
  String youSurvivedMoves(int count) {
    return 'Du hast $count Zug/Züge überstanden';
  }

  @override
  String get reviewGame => 'Spiel überprüfen';

  @override
  String get openingTip => 'Eröffnungstipp';

  @override
  String get gotIt => 'Verstanden!';

  @override
  String get medalBronze => 'Bronze!';

  @override
  String get medalSilver => 'Silber!';

  @override
  String get medalGold => 'Gold!';

  @override
  String get previousMove => 'Vorheriger Zug';

  @override
  String get nextMove => 'Nächster Zug';

  @override
  String get done => 'Fertig';

  @override
  String get thePieces => 'The Pieces';

  @override
  String get knowYourPieces => 'Know your pieces!';

  @override
  String get whichSideWins => 'Which Side Wins?';

  @override
  String get whichSideWinsDesc =>
      'Compare groups of pieces — tap the side worth more!';

  @override
  String get tapTheSideWorthMore => 'Tap the side worth more';

  @override
  String get whichSideWinsPracticeDesc =>
      'Build your streak — difficulty increases as you go!';
}
