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
  String get calvinChessTrainer => 'Calvin Chess\nTrainer';

  @override
  String get masterTheFundamentals => 'Master the fundamentals!';

  @override
  String get chessNotation => 'Chess Notation';

  @override
  String get learnTheBoard => 'Learn the board!';

  @override
  String get chessVision => 'Chess Vision';

  @override
  String get seeTheBoard => 'See the board!';

  @override
  String get comingSoon => 'COMING SOON';

  @override
  String get start => 'Start';

  @override
  String get menu => 'Menu';

  @override
  String get playAgain => 'Play Again';

  @override
  String get newRecord => 'New Record!';

  @override
  String get whatToPractice => 'What to practice?';

  @override
  String get chooseAMode => 'Choose a mode';

  @override
  String get files => 'Files';

  @override
  String get ranks => 'Ranks';

  @override
  String get squares => 'Squares';

  @override
  String get moves => 'Moves';

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
  String get hardMode => 'HARD MODE';

  @override
  String get hardModeBlack => 'User controls black!';

  @override
  String get hardModeFlipped => 'Board flipped — black\'s perspective!';

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
  String get drillType => 'Drill type';

  @override
  String get forksAndSkewers => 'Forks & Skewers';

  @override
  String get pawnAttack => 'Pawn Attack';

  @override
  String get knightSight => 'Knight Sight';

  @override
  String get knightFlight => 'Knight Flight';

  @override
  String get chooseYourPiece => 'Choose your piece';

  @override
  String get targetPiece => 'Target piece';

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
  String get concentricDrill => 'Concentric Drill';

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
  String foundOfTotal(int found, int total) {
    return '$found of $total';
  }

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
  String titleForksAndSkewers(String piece, String mode) {
    return '$piece — $mode';
  }

  @override
  String titlePawnAttack(String piece, String mode) {
    return 'Pawn Attack — $piece $mode';
  }

  @override
  String titleMovesGame(String mode) {
    return 'Moves - $mode';
  }

  @override
  String titleFileRankGame(String subject, String mode) {
    return '$subject - $mode';
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
      'A fun, interactive app that teaches chess fundamentals to kids. Learn files, ranks, squares, and piece moves through drills, quizzes, and timed challenges — all with audio feedback and streak tracking to keep you motivated!';

  @override
  String get aboutTrainingModes => 'Training Modes';

  @override
  String get aboutTrainingModesBody =>
      '• Explore — learn at your own pace\n• Practice — quiz yourself and build streaks\n• Speed Round — 30 seconds, how many can you get?\n• Hard Mode — hide coordinates for a real challenge';

  @override
  String get aboutCredits => 'Credits & Acknowledgments';

  @override
  String get aboutCreditsBody =>
      '• Chess puzzles from the Lichess database (CC0 license)\n• Board UI powered by Lichess chessground\n• Chess logic by Lichess dartchess\n• Voice clips by ElevenLabs\n• Built with Flutter & Dart';

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
  String get squareTrainer => 'Square Trainer';

  @override
  String get squareComingSoon => 'Square trainer coming soon';

  @override
  String get moveTrainer => 'Move Trainer';

  @override
  String get moveComingSoon => 'Move trainer coming soon';

  @override
  String get promptSquare => 'square';

  @override
  String get promptFile => 'file';

  @override
  String get promptRank => 'rank';

  @override
  String get openingFundamentals => 'Opening\nExplorer';

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
  String get whichSideWins => 'Which Side Wins?';

  @override
  String get whichSideWinsDesc =>
      'Compare groups of pieces — tap the side worth more!';

  @override
  String get tapTheSideWorthMore => 'Tap the side worth more';

  @override
  String get whichSideWinsPracticeDesc =>
      'Build your streak — difficulty increases as you go!';

  @override
  String get piecesEasyDesc => 'Single pieces';

  @override
  String get piecesMediumDesc => 'Small groups';

  @override
  String get piecesHardDesc => 'Tricky trades';
}
