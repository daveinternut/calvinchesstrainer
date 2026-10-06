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
  String get learnTheBoard => 'Lerne das Brett!';

  @override
  String get comingSoon => 'DEMNÄCHST';

  @override
  String get start => 'Starten';

  @override
  String get playAgain => 'Nochmal spielen';

  @override
  String get newRecord => 'Neuer Rekord!';

  @override
  String get files => 'Linien';

  @override
  String get ranks => 'Reihen';

  @override
  String get squares => 'Felder';

  @override
  String get moves => 'Züge';

  @override
  String get pieceValue => 'Figurenwert';

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
  String get tapFileToSee => 'Tippe auf eine Linie, um ihren Namen zu sehen';

  @override
  String get tapRankToSee => 'Tippe auf eine Reihe, um ihren Namen zu sehen';

  @override
  String get tapSquareToSee => 'Tippe auf ein Feld, um seinen Namen zu sehen';

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
  String get forksAndSkewers => 'Gabeln und Spieße';

  @override
  String get pawnAttack => 'Bauernangriff';

  @override
  String get knightSight => 'Springersicht';

  @override
  String get knightFlight => 'Springerflug';

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
      'Eine unterhaltsame, interaktive App, die Kindern die Grundlagen des Schachs beibringt. Schachvision trainiert dich, Gabeln, Spieße, Springerzüge, Schachgebote, Schlagmöglichkeiten und ungedeckte Figuren auf einen Blick zu erkennen. Schachnotation bringt dir Linien, Reihen, Felder, Figurenbuchstaben, Züge und Figurenwerte bei. Im Eröffnungs-Explorer probierst du Eröffnungen mit Tipps einer echten Schach-Engine aus. Audio-Feedback, Serien und gespeicherte Bestleistungen halten dich motiviert!';

  @override
  String get aboutTrainingModes => 'Trainingsmodi';

  @override
  String get aboutTrainingModesBody =>
      '• Erkunden — lerne in deinem Tempo\n• Übung — teste dich und baue Serien auf\n• Schnellrunde — spiel gegen die Uhr (30 oder 60 Sekunden) und stell einen neuen Rekord auf\n• Schwerer Modus — spiel von der Seite von Schwarz';

  @override
  String get aboutCredits => 'Credits und Danksagungen';

  @override
  String get aboutCreditsBody =>
      '• Schachberater: Dattasai Kilari\n• Schachpuzzles aus der Lichess-Datenbank (CC0-Lizenz)\n• Brett-UI von Lichess chessground\n• Schachlogik von Lichess dartchess\n• Sprachclips von ElevenLabs\n• Entwickelt mit Flutter & Dart';

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
  String get promptSquare => 'Feld';

  @override
  String get promptFile => 'Linie';

  @override
  String get promptRank => 'Reihe';

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
  String get tapTheSideWorthMore => 'Tippe auf die wertvollere Seite';

  @override
  String get whichSideWinsPracticeDesc =>
      'Baue deine Serie auf — es wird nach und nach schwieriger!';

  @override
  String get letters => 'Buchstaben';

  @override
  String get king => 'König';

  @override
  String get pawn => 'Bauer';

  @override
  String get tapPieceToLearnLetter =>
      'Tippe auf eine Figur, um ihren Buchstaben zu lernen!';

  @override
  String get whichPieceForLetter => 'Welche Figur hat diesen Buchstaben?';

  @override
  String get whichLetterForPiece => 'Welcher Buchstabe gehört zu dieser Figur?';

  @override
  String get tapPieceNoLetter => 'Tippe auf die Figur OHNE Buchstaben!';

  @override
  String get noLetter => 'Kein Buchstabe';

  @override
  String letterEquals(String letter, String piece) {
    return '$letter = $piece!';
  }

  @override
  String get pawnNoLetterFact => 'Bauern brauchen keinen Buchstaben!';

  @override
  String get mnemonicKing => 'K wie King — der König auf Englisch, der Chef!';

  @override
  String get mnemonicQueen => 'Q wie Queen — die Dame auf Englisch!';

  @override
  String get mnemonicRook => 'R wie Rook — der Turm auf Englisch!';

  @override
  String get mnemonicBishop => 'B wie Bishop — der Läufer auf Englisch!';

  @override
  String get mnemonicKnight =>
      'N wie kNight — der Springer! Das K hat schon der König.';

  @override
  String get mnemonicPawn =>
      'Bauern sind so tapfer, sie brauchen keinen Buchstaben!';

  @override
  String get scanDrillChecks => 'Schachs finden';

  @override
  String get scanDrillCaptures => 'Schlagzüge finden';

  @override
  String get scanDrillHanging => 'Hängende Figuren';

  @override
  String get scanDrillMate => 'Matt in 1';

  @override
  String get scanPromptChecks =>
      'Tippe auf jedes Feld, von dem aus du Schach geben kannst!';

  @override
  String get scanPromptCaptures =>
      'Tippe auf jede gegnerische Figur, die du schlagen kannst!';

  @override
  String get scanPromptHanging =>
      'Tippe auf jede gegnerische Figur, die nicht verteidigt ist!';

  @override
  String get scanPromptMate => 'Finde das Matt in einem Zug!';

  @override
  String get scanPracticeDesc => 'Kein Timer — finde sie alle!';

  @override
  String get blitz => 'Blitz';

  @override
  String get scanBlitzDesc => '60 Sekunden — wie viele Matts findest du?';

  @override
  String get whiteToPlay => 'Weiß am Zug';

  @override
  String get blackToPlay => 'Schwarz am Zug';

  @override
  String get openingExplorer => 'Eröffnungs-Explorer';

  @override
  String get startFromOpening => 'Mit einer Eröffnung starten';

  @override
  String get flipBoard => 'Brett drehen';

  @override
  String get showScores => 'Bewertungen zeigen';

  @override
  String get hideScores => 'Bewertungen ausblenden';

  @override
  String get turnSoundOff => 'Ton ausschalten';

  @override
  String get turnSoundOn => 'Ton einschalten';

  @override
  String get searchOpenings => 'Eröffnungen suchen…';

  @override
  String get noOpeningsFound => 'Keine Eröffnungen gefunden';

  @override
  String get popularOpenings => 'Beliebt';

  @override
  String get browseByCategory => 'Nach Kategorie durchsuchen';

  @override
  String get ecoFlankOpenings => 'Flankeneröffnungen';

  @override
  String get ecoSemiOpenGames => 'Halboffene Spiele';

  @override
  String get ecoOpenGames => 'Offene Spiele';

  @override
  String get ecoClosedGames => 'Geschlossene & halbgeschlossene Spiele';

  @override
  String get ecoIndianDefenses => 'Indische Verteidigungen';

  @override
  String get engineUnavailable => 'Die Schach-Engine ist nicht gestartet.';

  @override
  String get visionPromptForks =>
      'Tippe auf jedes Feld, von dem aus deine Figur den König und die andere Figur angreift!';

  @override
  String get visionPromptKnightSight =>
      'Tippe auf jedes Feld, auf das dein Springer springen kann!';

  @override
  String get visionPromptKnightFlight =>
      'Bring deinen Springer mit so wenigen Zügen wie möglich zum Ring!';

  @override
  String get visionPromptPawnAttack =>
      'Schlage alle Bauern — bleib nie auf einem schattierten Feld stehen!';

  @override
  String get startOver => 'Neu starten';

  @override
  String get loadFailed => 'Die Aufgaben konnten nicht geladen werden.';

  @override
  String get checkmate => 'Schachmatt!';

  @override
  String get draw => 'Remis!';

  @override
  String get homeWarmupKicker => 'Tägliches Aufwärmen · 5 Min.';

  @override
  String get homeWarmupTitle => 'Trainiere, was Puzzles auslassen';

  @override
  String get homeWarmupBody =>
      'Fünf schnelle Übungen: Schachs, ungedeckte Figuren, Gabeln, Felder aus Sicht von Schwarz und ein Matt in einem Zug.';

  @override
  String get homeWarmupStart => 'Aufwärmen starten';

  @override
  String get homeContinue => 'Weitermachen';

  @override
  String get homeStartHere => 'Hier starten';

  @override
  String homeResume(String drill) {
    return 'Fortsetzen: $drill';
  }

  @override
  String get homeOpenings => 'Eröffnungen';

  @override
  String get homeOpeningExplorerDesc =>
      'Spiele Eröffnungen mit Stockfish-Tipps durch';

  @override
  String get sectionVision => 'Vision';

  @override
  String get sectionVisionDesc =>
      'Gewohnheiten beim Absuchen des Bretts, die kaum ein Spieler übt';

  @override
  String get sectionNotation => 'Notation';

  @override
  String get sectionNotationDesc =>
      'Felder und Züge lesen und finden, ohne nachzudenken';

  @override
  String sectionAllDrills(int count) {
    return 'Alle $count Übungen';
  }

  @override
  String get navHome => 'Start';

  @override
  String drillBest(String value) {
    return 'Rekord $value';
  }

  @override
  String get groupScan => 'Brett absuchen';

  @override
  String get groupGeometry => 'Geometrie';

  @override
  String get groupFinish => 'Abschluss';

  @override
  String get groupBoard => 'Das Brett';

  @override
  String get groupPieces => 'Figuren';

  @override
  String get drillFilesRanks => 'Linien & Reihen';

  @override
  String get drillReadMoves => 'Züge lesen';

  @override
  String get drillPieceLetters => 'Figurenbuchstaben';

  @override
  String get drillPieceValues => 'Figurenwerte';

  @override
  String get drillDescFindChecks => 'Jedes Schach in einer echten Stellung';

  @override
  String get drillDescFindCaptures => 'Finde jeden Schlagzug auf dem Brett';

  @override
  String get drillDescHanging => 'Erkenne jede ungedeckte Figur';

  @override
  String get drillDescForks => 'Felder für einen Doppelangriff';

  @override
  String get drillDescKnightSight => 'Jedes Feld, das ein Springer erreicht';

  @override
  String get drillDescKnightFlight => 'Mit möglichst wenigen Zügen ans Ziel';

  @override
  String get drillDescPawnAttack => 'Schlüpfe an einer Bauernmauer vorbei';

  @override
  String get drillDescMate => '400 Stellungen, ein Zug zum Matt';

  @override
  String get drillDescSquares => 'Finde schnell das Feld';

  @override
  String get drillDescFilesRanks => 'Benenne jede Linie und Reihe';

  @override
  String get drillDescReadMoves => 'Lies einen Zug und spiele ihn';

  @override
  String get drillDescLetters => 'K, Q, R, B, N auf einen Blick';

  @override
  String get drillDescValues => 'Welche Seite liegt vorn?';

  @override
  String get setupYourPiece => 'Deine Figur';

  @override
  String get setupForkTarget => 'Gabel auf König und …';

  @override
  String get setupMode => 'Modus';

  @override
  String get setupBoardSide => 'Brettseite';

  @override
  String get setupLines => 'Richtung';

  @override
  String get setupYourBest => 'Dein Rekord';

  @override
  String get setupNoBest => 'Noch kein Rekord';

  @override
  String get setupKnightPracticeOnly => 'Kein Timer. Lass dir Zeit.';

  @override
  String warmupStep(int current, int total) {
    return 'Aufwärmen · $current von $total';
  }

  @override
  String warmupNext(String drill) {
    return 'Als Nächstes: $drill';
  }

  @override
  String get warmupFinish => 'Aufwärmen abschließen';

  @override
  String get warmupEnd => 'Aufwärmen beenden';

  @override
  String get warmupDoneTitle => 'Aufwärmen abgeschlossen';

  @override
  String get warmupDoneBody =>
      'Fünf Übungen geschafft. Morgen zur gleichen Zeit?';

  @override
  String get resultsMissed => 'Verpasst';

  @override
  String get endDrill => 'Übung beenden';

  @override
  String get promptTitleChecks => 'Finde jedes Schach';

  @override
  String get promptTitleCaptures => 'Finde jeden Schlagzug';

  @override
  String get promptTitleHanging => 'Finde jede hängende Figur';

  @override
  String get promptTitleForks => 'Finde jede Gabel';

  @override
  String get promptTitleKnightSight => 'Jeder Springersprung';

  @override
  String get promptTitleKnightFlight => 'Erreiche den Ring';

  @override
  String get promptTitlePawnAttack => 'Schlage alle Bauern';

  @override
  String get promptTitleMate => 'Matt in einem Zug';
}
