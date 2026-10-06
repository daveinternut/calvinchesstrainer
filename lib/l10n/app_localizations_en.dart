// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Calvin Chess Trainer';

  @override
  String get about => 'About';

  @override
  String get learnTheBoard => 'Learn the board!';

  @override
  String get comingSoon => 'COMING SOON';

  @override
  String get start => 'Start';

  @override
  String get playAgain => 'Play Again';

  @override
  String get newRecord => 'New Record!';

  @override
  String get files => 'Files';

  @override
  String get ranks => 'Ranks';

  @override
  String get squares => 'Squares';

  @override
  String get moves => 'Moves';

  @override
  String get pieceValue => 'Piece Value';

  @override
  String get explore => 'Explore';

  @override
  String get exploreDesc => 'Tap to learn — no pressure, no scoring';

  @override
  String get practice => 'Practice';

  @override
  String get practiceDesc => 'Quiz yourself — build your streak!';

  @override
  String get speedRound => 'Speed Round';

  @override
  String get speedRoundDesc => '30 seconds — how many can you get?';

  @override
  String get timesUp => 'Time\'s Up!';

  @override
  String get correct => 'Correct';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String bestLabel(int value) {
    return 'Best: $value';
  }

  @override
  String get tapFileToHear => 'Tap any file to hear its name';

  @override
  String get tapRankToHear => 'Tap any rank to hear its name';

  @override
  String get tapSquareToHear => 'Tap any square to hear its name';

  @override
  String get tapFileToSee => 'Tap any file to see its name';

  @override
  String get tapRankToSee => 'Tap any rank to see its name';

  @override
  String get tapSquareToSee => 'Tap any square to see its name';

  @override
  String get tapFile => 'Tap file';

  @override
  String get tapRank => 'Tap rank';

  @override
  String get tapSquare => 'Tap square';

  @override
  String get milestoneNice => 'Nice!';

  @override
  String get milestoneAmazing => 'Amazing!';

  @override
  String get milestoneIncredible => 'Incredible!';

  @override
  String get milestoneUnstoppable => 'Unstoppable!';

  @override
  String get milestoneLegendary => 'Legendary!';

  @override
  String get milestoneGreat => 'Great!';

  @override
  String streakMilestone(int count) {
    return '$count in a row!';
  }

  @override
  String get hurry => 'Hurry!';

  @override
  String get forksAndSkewers => 'Forks & Skewers';

  @override
  String get pawnAttack => 'Pawn Attack';

  @override
  String get knightSight => 'Knight Sight';

  @override
  String get knightFlight => 'Knight Flight';

  @override
  String get queen => 'Queen';

  @override
  String get rook => 'Rook';

  @override
  String get bishop => 'Bishop';

  @override
  String get knight => 'Knight';

  @override
  String get findForksNoTimer => 'Find forks and skewers — no timer';

  @override
  String get speedRound60Desc => '60 seconds — solve as many as you can!';

  @override
  String get concentricDrillDesc => 'Complete all positions — beat your time!';

  @override
  String get captureAllPawnsNoTimer => 'Capture all pawns — no timer';

  @override
  String get timed => 'Timed';

  @override
  String get timedPawnAttackDesc => 'Clear 3 to 8 pawns — beat your time!';

  @override
  String get concentric => 'Concentric';

  @override
  String get retry => 'Retry';

  @override
  String get skip => 'Skip';

  @override
  String get none => 'None';

  @override
  String minimumMoves(int count) {
    return 'Minimum: $count';
  }

  @override
  String yourMoves(int count) {
    return 'Your moves: $count';
  }

  @override
  String pawnsRemaining(int count) {
    return 'Pawns: $count';
  }

  @override
  String levelOfEight(int level) {
    return 'Level $level of 8';
  }

  @override
  String movesCount(int count) {
    return 'Moves: $count';
  }

  @override
  String positionOfTotal(int current, int total) {
    return 'Position $current of $total';
  }

  @override
  String get tapNoneHint => 'Tap None if no solutions exist';

  @override
  String get found => 'Found';

  @override
  String get drillComplete => 'Drill Complete!';

  @override
  String get allClear => 'All Clear!';

  @override
  String get time => 'Time';

  @override
  String get errors => 'Errors';

  @override
  String get rounds => 'Rounds';

  @override
  String solvedCount(int count) {
    return '$count solved';
  }

  @override
  String get makeTheMove => 'Make the move';

  @override
  String get castleKingside => 'Castle kingside';

  @override
  String get castleQueenside => 'Castle queenside';

  @override
  String pieceTakesOn(String piece, String square) {
    return '$piece takes on $square';
  }

  @override
  String pieceToSquare(String piece, String square) {
    return '$piece to $square';
  }

  @override
  String get seePositionMakeMove => 'See a position, make the move!';

  @override
  String get aboutWhatIs => 'What is Calvin Chess Trainer?';

  @override
  String get aboutWhatIsBody =>
      'A fun, interactive app that teaches chess fundamentals to kids. Chess Vision trains you to spot forks, skewers, knight moves, checks, captures and hanging pieces at a glance. Chess Notation teaches files, ranks, squares, piece letters, moves and piece values. The Opening Explorer lets you try openings with hints from a real chess engine. Audio feedback, streaks and saved personal bests keep you motivated!';

  @override
  String get aboutTrainingModes => 'Training Modes';

  @override
  String get aboutTrainingModesBody =>
      '• Explore — learn at your own pace\n• Practice — quiz yourself and build streaks\n• Speed Round — race the clock (30 or 60 seconds) and set a new record\n• Hard Mode — play from Black\'s side of the board';

  @override
  String get aboutCredits => 'Credits & Acknowledgments';

  @override
  String get aboutCreditsBody =>
      '• Chess advisor: Dattasai Kilari\n• Chess puzzles from the Lichess database (CC0 license)\n• Board UI powered by Lichess chessground\n• Chess logic by Lichess dartchess\n• Voice clips by ElevenLabs\n• Built with Flutter & Dart';

  @override
  String get aboutInspired => 'Inspired by Rapid Chess Improvement';

  @override
  String get aboutInspiredBody =>
      'This app owes a great deal to Michael de la Maza\'s book Rapid Chess Improvement (Everyman Chess, 2002). His concept of \"chess vision\" — the ability to instantly recognize tactical patterns and piece relationships — transformed the way I thought about training. Following his ideas helped me improve my own game dramatically, and I built Calvin Chess Trainer in the hope that his approach to chess vision will help a new generation of players see the board more clearly. Thank you, Michael!';

  @override
  String get aboutInternut => 'About Internut Education';

  @override
  String get aboutInternutBody =>
      'Internut Education creates engaging learning apps for kids. We believe the best way to learn is through play, practice, and positive reinforcement.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutByInternut => 'by Internut Education';

  @override
  String get aboutFooter => 'Made with ❤️ for young chess players everywhere';

  @override
  String get feedbackTitle => 'Send Us Feedback';

  @override
  String get feedbackBody =>
      'We\'re always looking to make this app better! Whether it\'s a feature idea, a bug you found, or just something you love — we\'d really like to hear from you.';

  @override
  String get feedbackHint => 'Type your feedback here...';

  @override
  String get feedbackSend => 'Send Feedback';

  @override
  String get feedbackSending => 'Sending...';

  @override
  String get feedbackThanks => 'Thank you for your feedback!';

  @override
  String get feedbackError => 'Couldn\'t send feedback. Please try again.';

  @override
  String get feedbackEmpty => 'Please write something before sending.';

  @override
  String get tacticsTrainer => 'Tactics Trainer';

  @override
  String get tacticsComingSoon => 'Tactics trainer coming soon';

  @override
  String get promptSquare => 'square';

  @override
  String get promptFile => 'file';

  @override
  String get promptRank => 'rank';

  @override
  String get playTheOpening => 'Explore openings!';

  @override
  String get openingPractice => 'Opening Practice';

  @override
  String get openingChallenge => 'Opening Challenge';

  @override
  String get playAs => 'Play as';

  @override
  String get playAsWhite => 'White';

  @override
  String get playAsBlack => 'Black';

  @override
  String get difficulty => 'Difficulty';

  @override
  String get easy => 'Easy';

  @override
  String get medium => 'Medium';

  @override
  String get hard => 'Hard';

  @override
  String get challenge => 'Challenge';

  @override
  String get practiceHintsDesc =>
      'Play with hints — top 3 moves shown as arrows';

  @override
  String get challengeDesc => 'Test your opening skills — earn medals!';

  @override
  String get engineThinking => 'Engine thinking...';

  @override
  String get yourTurn => 'Your turn';

  @override
  String get gameOver => 'Game Over';

  @override
  String youSurvivedMoves(int count) {
    return 'You survived $count move(s)';
  }

  @override
  String get reviewGame => 'Review Game';

  @override
  String get openingTip => 'Opening Tip';

  @override
  String get gotIt => 'Got it!';

  @override
  String get medalBronze => 'Bronze!';

  @override
  String get medalSilver => 'Silver!';

  @override
  String get medalGold => 'Gold!';

  @override
  String get previousMove => 'Previous move';

  @override
  String get nextMove => 'Next move';

  @override
  String get done => 'Done';

  @override
  String get thePieces => 'The Pieces';

  @override
  String get knowYourPieces => 'Know your pieces!';

  @override
  String get tapTheSideWorthMore => 'Tap the side worth more';

  @override
  String get whichSideWinsPracticeDesc =>
      'Build your streak — difficulty increases as you go!';

  @override
  String get letters => 'Letters';

  @override
  String get king => 'King';

  @override
  String get pawn => 'Pawn';

  @override
  String get tapPieceToLearnLetter => 'Tap a piece to learn its letter!';

  @override
  String get whichPieceForLetter => 'Which piece uses this letter?';

  @override
  String get whichLetterForPiece => 'Which letter is this piece?';

  @override
  String get tapPieceNoLetter => 'Tap the piece with NO letter!';

  @override
  String get noLetter => 'No letter';

  @override
  String letterEquals(String letter, String piece) {
    return '$letter = $piece!';
  }

  @override
  String get pawnNoLetterFact => 'Pawns don\'t need a letter!';

  @override
  String get mnemonicKing => 'K is for King — the boss of the board!';

  @override
  String get mnemonicQueen => 'Q is for Queen — the most powerful piece!';

  @override
  String get mnemonicRook => 'R is for Rook — the castle tower!';

  @override
  String get mnemonicBishop => 'B is for Bishop — the diagonal expert!';

  @override
  String get mnemonicKnight => 'N is for kNight — the King already took K!';

  @override
  String get mnemonicPawn => 'Pawns are so brave they don\'t need a letter!';

  @override
  String get scanDrillChecks => 'Find Checks';

  @override
  String get scanDrillCaptures => 'Find Captures';

  @override
  String get scanDrillHanging => 'Hanging Pieces';

  @override
  String get scanDrillMate => 'Mate in 1';

  @override
  String get scanPromptChecks => 'Tap every square where you can give check!';

  @override
  String get scanPromptCaptures => 'Tap every enemy piece you can capture!';

  @override
  String get scanPromptHanging => 'Tap every enemy piece that has no defender!';

  @override
  String get scanPromptMate => 'Find the checkmate in one move!';

  @override
  String get scanPracticeDesc => 'No timer — find them all!';

  @override
  String get blitz => 'Blitz';

  @override
  String get scanBlitzDesc => '60 seconds — how many mates can you find?';

  @override
  String get whiteToPlay => 'White to play';

  @override
  String get blackToPlay => 'Black to play';

  @override
  String get openingExplorer => 'Opening Explorer';

  @override
  String get startFromOpening => 'Start from an opening';

  @override
  String get flipBoard => 'Flip board';

  @override
  String get showScores => 'Show scores';

  @override
  String get hideScores => 'Hide scores';

  @override
  String get turnSoundOff => 'Turn sound off';

  @override
  String get turnSoundOn => 'Turn sound on';

  @override
  String get searchOpenings => 'Search openings…';

  @override
  String get noOpeningsFound => 'No openings found';

  @override
  String get popularOpenings => 'Popular';

  @override
  String get browseByCategory => 'Browse by category';

  @override
  String get ecoFlankOpenings => 'Flank Openings';

  @override
  String get ecoSemiOpenGames => 'Semi-Open Games';

  @override
  String get ecoOpenGames => 'Open Games';

  @override
  String get ecoClosedGames => 'Closed & Semi-Closed';

  @override
  String get ecoIndianDefenses => 'Indian Defenses';

  @override
  String get engineUnavailable => 'The chess engine didn\'t start.';

  @override
  String get visionPromptForks =>
      'Tap every square where your piece attacks the king and the other piece!';

  @override
  String get visionPromptKnightSight =>
      'Tap every square your knight can jump to!';

  @override
  String get visionPromptKnightFlight =>
      'Jump your knight to the ring in as few moves as you can!';

  @override
  String get visionPromptPawnAttack =>
      'Capture every pawn — never stop on a shaded square!';

  @override
  String get startOver => 'Start over';

  @override
  String get loadFailed => 'Couldn\'t load the puzzles.';

  @override
  String get checkmate => 'Checkmate!';

  @override
  String get draw => 'Draw!';

  @override
  String get homeWarmupKicker => 'Daily warm-up · 5 min';

  @override
  String get homeWarmupTitle => 'Train what puzzles skip';

  @override
  String get homeWarmupBody =>
      'Five quick drills: checks, loose pieces, forks, squares from Black\'s side and a mate in one.';

  @override
  String get homeWarmupStart => 'Start warm-up';

  @override
  String get homeContinue => 'Continue';

  @override
  String get homeStartHere => 'Start here';

  @override
  String homeResume(String drill) {
    return 'Resume $drill';
  }

  @override
  String get homeOpenings => 'Openings';

  @override
  String get homeOpeningExplorerDesc =>
      'Play through openings with Stockfish hints';

  @override
  String get sectionVision => 'Vision';

  @override
  String get sectionVisionDesc =>
      'The board-scanning habits most players never drill';

  @override
  String get sectionNotation => 'Notation';

  @override
  String get sectionNotationDesc =>
      'Read and find squares and moves without thinking';

  @override
  String sectionAllDrills(int count) {
    return 'All $count drills';
  }

  @override
  String get navHome => 'Home';

  @override
  String drillBest(String value) {
    return 'Best $value';
  }

  @override
  String get groupScan => 'Scan the board';

  @override
  String get groupGeometry => 'Geometry';

  @override
  String get groupFinish => 'Finish';

  @override
  String get groupBoard => 'The board';

  @override
  String get groupPieces => 'Pieces';

  @override
  String get drillFilesRanks => 'Files & Ranks';

  @override
  String get drillReadMoves => 'Read Moves';

  @override
  String get drillPieceLetters => 'Piece Letters';

  @override
  String get drillPieceValues => 'Piece Values';

  @override
  String get drillDescFindChecks => 'Every check in a real position';

  @override
  String get drillDescFindCaptures => 'Find every capture on the board';

  @override
  String get drillDescHanging => 'Spot every undefended piece';

  @override
  String get drillDescForks => 'Squares that hit two targets';

  @override
  String get drillDescKnightSight => 'Every square a knight reaches';

  @override
  String get drillDescKnightFlight => 'Fewest moves to the target';

  @override
  String get drillDescPawnAttack => 'Slip past a wall of pawns';

  @override
  String get drillDescMate => '400 positions, one move to mate';

  @override
  String get drillDescSquares => 'Find the square, fast';

  @override
  String get drillDescFilesRanks => 'Name every file and rank';

  @override
  String get drillDescReadMoves => 'Read a move, then play it';

  @override
  String get drillDescLetters => 'K, Q, R, B, N at a glance';

  @override
  String get drillDescValues => 'Which side comes out ahead?';

  @override
  String get setupYourPiece => 'Your piece';

  @override
  String get setupForkTarget => 'Fork the king and a…';

  @override
  String get setupMode => 'Mode';

  @override
  String get setupBoardSide => 'Board side';

  @override
  String get setupLines => 'Lines';

  @override
  String get setupYourBest => 'Your best';

  @override
  String get setupNoBest => 'No best yet';

  @override
  String get setupKnightPracticeOnly => 'No timer. Take your time.';

  @override
  String warmupStep(int current, int total) {
    return 'Warm-up · $current of $total';
  }

  @override
  String warmupNext(String drill) {
    return 'Next: $drill';
  }

  @override
  String get warmupFinish => 'Finish warm-up';

  @override
  String get warmupEnd => 'End warm-up';

  @override
  String get warmupDoneTitle => 'Warm-up complete';

  @override
  String get warmupDoneBody => 'Five drills done. Same time tomorrow?';

  @override
  String get resultsMissed => 'Missed';

  @override
  String get endDrill => 'End drill';

  @override
  String get promptTitleChecks => 'Find every check';

  @override
  String get promptTitleCaptures => 'Find every capture';

  @override
  String get promptTitleHanging => 'Find every loose piece';

  @override
  String get promptTitleForks => 'Find every fork';

  @override
  String get promptTitleKnightSight => 'Every knight jump';

  @override
  String get promptTitleKnightFlight => 'Reach the ring';

  @override
  String get promptTitlePawnAttack => 'Capture every pawn';

  @override
  String get promptTitleMate => 'Checkmate in one';
}
