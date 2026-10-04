import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Calvin Chess Trainer'**
  String get appTitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @learnTheBoard.
  ///
  /// In en, this message translates to:
  /// **'Learn the board!'**
  String get learnTheBoard;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'COMING SOON'**
  String get comingSoon;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @newRecord.
  ///
  /// In en, this message translates to:
  /// **'New Record!'**
  String get newRecord;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @ranks.
  ///
  /// In en, this message translates to:
  /// **'Ranks'**
  String get ranks;

  /// No description provided for @squares.
  ///
  /// In en, this message translates to:
  /// **'Squares'**
  String get squares;

  /// No description provided for @moves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get moves;

  /// No description provided for @pieceValue.
  ///
  /// In en, this message translates to:
  /// **'Piece Value'**
  String get pieceValue;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @exploreDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap to learn — no pressure, no scoring'**
  String get exploreDesc;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @practiceDesc.
  ///
  /// In en, this message translates to:
  /// **'Quiz yourself — build your streak!'**
  String get practiceDesc;

  /// No description provided for @speedRound.
  ///
  /// In en, this message translates to:
  /// **'Speed Round'**
  String get speedRound;

  /// No description provided for @speedRoundDesc.
  ///
  /// In en, this message translates to:
  /// **'30 seconds — how many can you get?'**
  String get speedRoundDesc;

  /// No description provided for @timesUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up!'**
  String get timesUp;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @bestLabel.
  ///
  /// In en, this message translates to:
  /// **'Best: {value}'**
  String bestLabel(int value);

  /// No description provided for @tapFileToHear.
  ///
  /// In en, this message translates to:
  /// **'Tap any file to hear its name'**
  String get tapFileToHear;

  /// No description provided for @tapRankToHear.
  ///
  /// In en, this message translates to:
  /// **'Tap any rank to hear its name'**
  String get tapRankToHear;

  /// No description provided for @tapSquareToHear.
  ///
  /// In en, this message translates to:
  /// **'Tap any square to hear its name'**
  String get tapSquareToHear;

  /// No description provided for @tapFile.
  ///
  /// In en, this message translates to:
  /// **'Tap file'**
  String get tapFile;

  /// No description provided for @tapRank.
  ///
  /// In en, this message translates to:
  /// **'Tap rank'**
  String get tapRank;

  /// No description provided for @tapSquare.
  ///
  /// In en, this message translates to:
  /// **'Tap square'**
  String get tapSquare;

  /// No description provided for @milestoneNice.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get milestoneNice;

  /// No description provided for @milestoneAmazing.
  ///
  /// In en, this message translates to:
  /// **'Amazing!'**
  String get milestoneAmazing;

  /// No description provided for @milestoneIncredible.
  ///
  /// In en, this message translates to:
  /// **'Incredible!'**
  String get milestoneIncredible;

  /// No description provided for @milestoneUnstoppable.
  ///
  /// In en, this message translates to:
  /// **'Unstoppable!'**
  String get milestoneUnstoppable;

  /// No description provided for @milestoneLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary!'**
  String get milestoneLegendary;

  /// No description provided for @milestoneGreat.
  ///
  /// In en, this message translates to:
  /// **'Great!'**
  String get milestoneGreat;

  /// No description provided for @streakMilestone.
  ///
  /// In en, this message translates to:
  /// **'{count} in a row!'**
  String streakMilestone(int count);

  /// No description provided for @hurry.
  ///
  /// In en, this message translates to:
  /// **'Hurry!'**
  String get hurry;

  /// No description provided for @forksAndSkewers.
  ///
  /// In en, this message translates to:
  /// **'Forks & Skewers'**
  String get forksAndSkewers;

  /// No description provided for @pawnAttack.
  ///
  /// In en, this message translates to:
  /// **'Pawn Attack'**
  String get pawnAttack;

  /// No description provided for @knightSight.
  ///
  /// In en, this message translates to:
  /// **'Knight Sight'**
  String get knightSight;

  /// No description provided for @knightFlight.
  ///
  /// In en, this message translates to:
  /// **'Knight Flight'**
  String get knightFlight;

  /// No description provided for @queen.
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get queen;

  /// No description provided for @rook.
  ///
  /// In en, this message translates to:
  /// **'Rook'**
  String get rook;

  /// No description provided for @bishop.
  ///
  /// In en, this message translates to:
  /// **'Bishop'**
  String get bishop;

  /// No description provided for @knight.
  ///
  /// In en, this message translates to:
  /// **'Knight'**
  String get knight;

  /// No description provided for @findForksNoTimer.
  ///
  /// In en, this message translates to:
  /// **'Find forks and skewers — no timer'**
  String get findForksNoTimer;

  /// No description provided for @speedRound60Desc.
  ///
  /// In en, this message translates to:
  /// **'60 seconds — solve as many as you can!'**
  String get speedRound60Desc;

  /// No description provided for @concentricDrillDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete all positions — beat your time!'**
  String get concentricDrillDesc;

  /// No description provided for @captureAllPawnsNoTimer.
  ///
  /// In en, this message translates to:
  /// **'Capture all pawns — no timer'**
  String get captureAllPawnsNoTimer;

  /// No description provided for @timed.
  ///
  /// In en, this message translates to:
  /// **'Timed'**
  String get timed;

  /// No description provided for @timedPawnAttackDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear 3 to 8 pawns — beat your time!'**
  String get timedPawnAttackDesc;

  /// No description provided for @concentric.
  ///
  /// In en, this message translates to:
  /// **'Concentric'**
  String get concentric;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @minimumMoves.
  ///
  /// In en, this message translates to:
  /// **'Minimum: {count}'**
  String minimumMoves(int count);

  /// No description provided for @yourMoves.
  ///
  /// In en, this message translates to:
  /// **'Your moves: {count}'**
  String yourMoves(int count);

  /// No description provided for @pawnsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Pawns: {count}'**
  String pawnsRemaining(int count);

  /// No description provided for @levelOfEight.
  ///
  /// In en, this message translates to:
  /// **'Level {level} of 8'**
  String levelOfEight(int level);

  /// No description provided for @movesCount.
  ///
  /// In en, this message translates to:
  /// **'Moves: {count}'**
  String movesCount(int count);

  /// No description provided for @positionOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Position {current} of {total}'**
  String positionOfTotal(int current, int total);

  /// No description provided for @tapNoneHint.
  ///
  /// In en, this message translates to:
  /// **'Tap None if no solutions exist'**
  String get tapNoneHint;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get found;

  /// No description provided for @drillComplete.
  ///
  /// In en, this message translates to:
  /// **'Drill Complete!'**
  String get drillComplete;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All Clear!'**
  String get allClear;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @rounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get rounds;

  /// No description provided for @solvedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} solved'**
  String solvedCount(int count);

  /// No description provided for @makeTheMove.
  ///
  /// In en, this message translates to:
  /// **'Make the move'**
  String get makeTheMove;

  /// No description provided for @castleKingside.
  ///
  /// In en, this message translates to:
  /// **'Castle kingside'**
  String get castleKingside;

  /// No description provided for @castleQueenside.
  ///
  /// In en, this message translates to:
  /// **'Castle queenside'**
  String get castleQueenside;

  /// No description provided for @pieceTakesOn.
  ///
  /// In en, this message translates to:
  /// **'{piece} takes on {square}'**
  String pieceTakesOn(String piece, String square);

  /// No description provided for @pieceToSquare.
  ///
  /// In en, this message translates to:
  /// **'{piece} to {square}'**
  String pieceToSquare(String piece, String square);

  /// No description provided for @seePositionMakeMove.
  ///
  /// In en, this message translates to:
  /// **'See a position, make the move!'**
  String get seePositionMakeMove;

  /// No description provided for @aboutWhatIs.
  ///
  /// In en, this message translates to:
  /// **'What is Calvin Chess Trainer?'**
  String get aboutWhatIs;

  /// No description provided for @aboutWhatIsBody.
  ///
  /// In en, this message translates to:
  /// **'A fun, interactive app that teaches chess fundamentals to kids. Chess Vision trains you to spot forks, skewers, knight moves, checks, captures and hanging pieces at a glance. Chess Notation teaches files, ranks, squares, piece letters, moves and piece values. The Opening Explorer lets you try openings with hints from a real chess engine. Audio feedback, streaks and saved personal bests keep you motivated!'**
  String get aboutWhatIsBody;

  /// No description provided for @aboutTrainingModes.
  ///
  /// In en, this message translates to:
  /// **'Training Modes'**
  String get aboutTrainingModes;

  /// No description provided for @aboutTrainingModesBody.
  ///
  /// In en, this message translates to:
  /// **'• Explore — learn at your own pace\n• Practice — quiz yourself and build streaks\n• Speed Round — race the clock (30 or 60 seconds) and set a new record\n• Hard Mode — play from Black\'s side of the board'**
  String get aboutTrainingModesBody;

  /// No description provided for @aboutCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits & Acknowledgments'**
  String get aboutCredits;

  /// No description provided for @aboutCreditsBody.
  ///
  /// In en, this message translates to:
  /// **'• Chess advisor: Dattasai Kilari\n• Chess puzzles from the Lichess database (CC0 license)\n• Board UI powered by Lichess chessground\n• Chess logic by Lichess dartchess\n• Voice clips by ElevenLabs\n• Built with Flutter & Dart'**
  String get aboutCreditsBody;

  /// No description provided for @aboutInspired.
  ///
  /// In en, this message translates to:
  /// **'Inspired by Rapid Chess Improvement'**
  String get aboutInspired;

  /// No description provided for @aboutInspiredBody.
  ///
  /// In en, this message translates to:
  /// **'This app owes a great deal to Michael de la Maza\'s book Rapid Chess Improvement (Everyman Chess, 2002). His concept of \"chess vision\" — the ability to instantly recognize tactical patterns and piece relationships — transformed the way I thought about training. Following his ideas helped me improve my own game dramatically, and I built Calvin Chess Trainer in the hope that his approach to chess vision will help a new generation of players see the board more clearly. Thank you, Michael!'**
  String get aboutInspiredBody;

  /// No description provided for @aboutInternut.
  ///
  /// In en, this message translates to:
  /// **'About Internut Education'**
  String get aboutInternut;

  /// No description provided for @aboutInternutBody.
  ///
  /// In en, this message translates to:
  /// **'Internut Education creates engaging learning apps for kids. We believe the best way to learn is through play, practice, and positive reinforcement.'**
  String get aboutInternutBody;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutByInternut.
  ///
  /// In en, this message translates to:
  /// **'by Internut Education'**
  String get aboutByInternut;

  /// No description provided for @aboutFooter.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ for young chess players everywhere'**
  String get aboutFooter;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Us Feedback'**
  String get feedbackTitle;

  /// No description provided for @feedbackBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re always looking to make this app better! Whether it\'s a feature idea, a bug you found, or just something you love — we\'d really like to hear from you.'**
  String get feedbackBody;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Type your feedback here...'**
  String get feedbackHint;

  /// No description provided for @feedbackSend.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get feedbackSend;

  /// No description provided for @feedbackSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get feedbackSending;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedbackThanks;

  /// No description provided for @feedbackError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send feedback. Please try again.'**
  String get feedbackError;

  /// No description provided for @feedbackEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please write something before sending.'**
  String get feedbackEmpty;

  /// No description provided for @tacticsTrainer.
  ///
  /// In en, this message translates to:
  /// **'Tactics Trainer'**
  String get tacticsTrainer;

  /// No description provided for @tacticsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Tactics trainer coming soon'**
  String get tacticsComingSoon;

  /// No description provided for @promptSquare.
  ///
  /// In en, this message translates to:
  /// **'square'**
  String get promptSquare;

  /// No description provided for @promptFile.
  ///
  /// In en, this message translates to:
  /// **'file'**
  String get promptFile;

  /// No description provided for @promptRank.
  ///
  /// In en, this message translates to:
  /// **'rank'**
  String get promptRank;

  /// No description provided for @playTheOpening.
  ///
  /// In en, this message translates to:
  /// **'Explore openings!'**
  String get playTheOpening;

  /// No description provided for @openingPractice.
  ///
  /// In en, this message translates to:
  /// **'Opening Practice'**
  String get openingPractice;

  /// No description provided for @openingChallenge.
  ///
  /// In en, this message translates to:
  /// **'Opening Challenge'**
  String get openingChallenge;

  /// No description provided for @playAs.
  ///
  /// In en, this message translates to:
  /// **'Play as'**
  String get playAs;

  /// No description provided for @playAsWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get playAsWhite;

  /// No description provided for @playAsBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get playAsBlack;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @easy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get easy;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @hard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get hard;

  /// No description provided for @challenge.
  ///
  /// In en, this message translates to:
  /// **'Challenge'**
  String get challenge;

  /// No description provided for @practiceHintsDesc.
  ///
  /// In en, this message translates to:
  /// **'Play with hints — top 3 moves shown as arrows'**
  String get practiceHintsDesc;

  /// No description provided for @challengeDesc.
  ///
  /// In en, this message translates to:
  /// **'Test your opening skills — earn medals!'**
  String get challengeDesc;

  /// No description provided for @engineThinking.
  ///
  /// In en, this message translates to:
  /// **'Engine thinking...'**
  String get engineThinking;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get gameOver;

  /// No description provided for @youSurvivedMoves.
  ///
  /// In en, this message translates to:
  /// **'You survived {count} move(s)'**
  String youSurvivedMoves(int count);

  /// No description provided for @reviewGame.
  ///
  /// In en, this message translates to:
  /// **'Review Game'**
  String get reviewGame;

  /// No description provided for @openingTip.
  ///
  /// In en, this message translates to:
  /// **'Opening Tip'**
  String get openingTip;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @medalBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze!'**
  String get medalBronze;

  /// No description provided for @medalSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver!'**
  String get medalSilver;

  /// No description provided for @medalGold.
  ///
  /// In en, this message translates to:
  /// **'Gold!'**
  String get medalGold;

  /// No description provided for @previousMove.
  ///
  /// In en, this message translates to:
  /// **'Previous move'**
  String get previousMove;

  /// No description provided for @nextMove.
  ///
  /// In en, this message translates to:
  /// **'Next move'**
  String get nextMove;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @thePieces.
  ///
  /// In en, this message translates to:
  /// **'The Pieces'**
  String get thePieces;

  /// No description provided for @knowYourPieces.
  ///
  /// In en, this message translates to:
  /// **'Know your pieces!'**
  String get knowYourPieces;

  /// No description provided for @tapTheSideWorthMore.
  ///
  /// In en, this message translates to:
  /// **'Tap the side worth more'**
  String get tapTheSideWorthMore;

  /// No description provided for @whichSideWinsPracticeDesc.
  ///
  /// In en, this message translates to:
  /// **'Build your streak — difficulty increases as you go!'**
  String get whichSideWinsPracticeDesc;

  /// No description provided for @letters.
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get letters;

  /// No description provided for @king.
  ///
  /// In en, this message translates to:
  /// **'King'**
  String get king;

  /// No description provided for @pawn.
  ///
  /// In en, this message translates to:
  /// **'Pawn'**
  String get pawn;

  /// No description provided for @tapPieceToLearnLetter.
  ///
  /// In en, this message translates to:
  /// **'Tap a piece to learn its letter!'**
  String get tapPieceToLearnLetter;

  /// No description provided for @whichPieceForLetter.
  ///
  /// In en, this message translates to:
  /// **'Which piece uses this letter?'**
  String get whichPieceForLetter;

  /// No description provided for @whichLetterForPiece.
  ///
  /// In en, this message translates to:
  /// **'Which letter is this piece?'**
  String get whichLetterForPiece;

  /// No description provided for @tapPieceNoLetter.
  ///
  /// In en, this message translates to:
  /// **'Tap the piece with NO letter!'**
  String get tapPieceNoLetter;

  /// No description provided for @noLetter.
  ///
  /// In en, this message translates to:
  /// **'No letter'**
  String get noLetter;

  /// No description provided for @letterEquals.
  ///
  /// In en, this message translates to:
  /// **'{letter} = {piece}!'**
  String letterEquals(String letter, String piece);

  /// No description provided for @pawnNoLetterFact.
  ///
  /// In en, this message translates to:
  /// **'Pawns don\'t need a letter!'**
  String get pawnNoLetterFact;

  /// No description provided for @mnemonicKing.
  ///
  /// In en, this message translates to:
  /// **'K is for King — the boss of the board!'**
  String get mnemonicKing;

  /// No description provided for @mnemonicQueen.
  ///
  /// In en, this message translates to:
  /// **'Q is for Queen — the most powerful piece!'**
  String get mnemonicQueen;

  /// No description provided for @mnemonicRook.
  ///
  /// In en, this message translates to:
  /// **'R is for Rook — the castle tower!'**
  String get mnemonicRook;

  /// No description provided for @mnemonicBishop.
  ///
  /// In en, this message translates to:
  /// **'B is for Bishop — the diagonal expert!'**
  String get mnemonicBishop;

  /// No description provided for @mnemonicKnight.
  ///
  /// In en, this message translates to:
  /// **'N is for kNight — the King already took K!'**
  String get mnemonicKnight;

  /// No description provided for @mnemonicPawn.
  ///
  /// In en, this message translates to:
  /// **'Pawns are so brave they don\'t need a letter!'**
  String get mnemonicPawn;

  /// No description provided for @scanDrillChecks.
  ///
  /// In en, this message translates to:
  /// **'Find Checks'**
  String get scanDrillChecks;

  /// No description provided for @scanDrillCaptures.
  ///
  /// In en, this message translates to:
  /// **'Find Captures'**
  String get scanDrillCaptures;

  /// No description provided for @scanDrillHanging.
  ///
  /// In en, this message translates to:
  /// **'Hanging Pieces'**
  String get scanDrillHanging;

  /// No description provided for @scanDrillMate.
  ///
  /// In en, this message translates to:
  /// **'Mate in 1'**
  String get scanDrillMate;

  /// No description provided for @scanPromptChecks.
  ///
  /// In en, this message translates to:
  /// **'Tap every square where you can give check!'**
  String get scanPromptChecks;

  /// No description provided for @scanPromptCaptures.
  ///
  /// In en, this message translates to:
  /// **'Tap every enemy piece you can capture!'**
  String get scanPromptCaptures;

  /// No description provided for @scanPromptHanging.
  ///
  /// In en, this message translates to:
  /// **'Tap every enemy piece that has no defender!'**
  String get scanPromptHanging;

  /// No description provided for @scanPromptMate.
  ///
  /// In en, this message translates to:
  /// **'Find the checkmate in one move!'**
  String get scanPromptMate;

  /// No description provided for @scanPracticeDesc.
  ///
  /// In en, this message translates to:
  /// **'No timer — find them all!'**
  String get scanPracticeDesc;

  /// No description provided for @blitz.
  ///
  /// In en, this message translates to:
  /// **'Blitz'**
  String get blitz;

  /// No description provided for @scanBlitzDesc.
  ///
  /// In en, this message translates to:
  /// **'60 seconds — how many mates can you find?'**
  String get scanBlitzDesc;

  /// No description provided for @whiteToPlay.
  ///
  /// In en, this message translates to:
  /// **'White to play'**
  String get whiteToPlay;

  /// No description provided for @blackToPlay.
  ///
  /// In en, this message translates to:
  /// **'Black to play'**
  String get blackToPlay;

  /// Opening trainer screen title
  ///
  /// In en, this message translates to:
  /// **'Opening Explorer'**
  String get openingExplorer;

  /// Opening picker sheet title and its toolbar tooltip
  ///
  /// In en, this message translates to:
  /// **'Start from an opening'**
  String get startFromOpening;

  /// Toolbar tooltip: flip the board
  ///
  /// In en, this message translates to:
  /// **'Flip board'**
  String get flipBoard;

  /// Toolbar tooltip: show move scores
  ///
  /// In en, this message translates to:
  /// **'Show scores'**
  String get showScores;

  /// Toolbar tooltip: hide move scores
  ///
  /// In en, this message translates to:
  /// **'Hide scores'**
  String get hideScores;

  /// Opening picker search field hint
  ///
  /// In en, this message translates to:
  /// **'Search openings…'**
  String get searchOpenings;

  /// Opening picker: search found nothing
  ///
  /// In en, this message translates to:
  /// **'No openings found'**
  String get noOpeningsFound;

  /// Opening picker section heading
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popularOpenings;

  /// Opening picker section heading
  ///
  /// In en, this message translates to:
  /// **'Browse by category'**
  String get browseByCategory;

  /// ECO category A
  ///
  /// In en, this message translates to:
  /// **'Flank Openings'**
  String get ecoFlankOpenings;

  /// ECO category B
  ///
  /// In en, this message translates to:
  /// **'Semi-Open Games'**
  String get ecoSemiOpenGames;

  /// ECO category C
  ///
  /// In en, this message translates to:
  /// **'Open Games'**
  String get ecoOpenGames;

  /// ECO category D
  ///
  /// In en, this message translates to:
  /// **'Closed & Semi-Closed'**
  String get ecoClosedGames;

  /// ECO category E
  ///
  /// In en, this message translates to:
  /// **'Indian Defenses'**
  String get ecoIndianDefenses;

  /// Shown when Stockfish fails to start; paired with the Retry button
  ///
  /// In en, this message translates to:
  /// **'The chess engine didn\'t start.'**
  String get engineUnavailable;

  /// Forks & Skewers in-drill instruction
  ///
  /// In en, this message translates to:
  /// **'Tap every square where your piece attacks the king and the other piece!'**
  String get visionPromptForks;

  /// Knight Sight in-drill instruction
  ///
  /// In en, this message translates to:
  /// **'Tap every square your knight can jump to!'**
  String get visionPromptKnightSight;

  /// Knight Flight in-drill instruction
  ///
  /// In en, this message translates to:
  /// **'Jump your knight to the ring in as few moves as you can!'**
  String get visionPromptKnightFlight;

  /// Pawn Attack in-drill instruction (shaded squares are the ones pawns attack)
  ///
  /// In en, this message translates to:
  /// **'Capture every pawn — never stop on a shaded square!'**
  String get visionPromptPawnAttack;

  /// Button: reset the current board to its starting position
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// Shown when a drill could not load its puzzle file; paired with the Retry button
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the puzzles.'**
  String get loadFailed;

  /// Opening Explorer: the game ended in checkmate
  ///
  /// In en, this message translates to:
  /// **'Checkmate!'**
  String get checkmate;

  /// Opening Explorer: the game ended in a draw (stalemate, repetition, etc.)
  ///
  /// In en, this message translates to:
  /// **'Draw!'**
  String get draw;

  /// No description provided for @homeWarmupKicker.
  ///
  /// In en, this message translates to:
  /// **'Daily warm-up · 5 min'**
  String get homeWarmupKicker;

  /// No description provided for @homeWarmupTitle.
  ///
  /// In en, this message translates to:
  /// **'Train what puzzles skip'**
  String get homeWarmupTitle;

  /// No description provided for @homeWarmupBody.
  ///
  /// In en, this message translates to:
  /// **'Five quick drills: checks, loose pieces, forks, squares from Black\'s side and a mate in one.'**
  String get homeWarmupBody;

  /// No description provided for @homeWarmupStart.
  ///
  /// In en, this message translates to:
  /// **'Start warm-up'**
  String get homeWarmupStart;

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinue;

  /// No description provided for @homeStartHere.
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get homeStartHere;

  /// No description provided for @homeResume.
  ///
  /// In en, this message translates to:
  /// **'Resume {drill}'**
  String homeResume(String drill);

  /// No description provided for @homeOpenings.
  ///
  /// In en, this message translates to:
  /// **'Openings'**
  String get homeOpenings;

  /// No description provided for @homeOpeningExplorerDesc.
  ///
  /// In en, this message translates to:
  /// **'Play through openings with Stockfish hints'**
  String get homeOpeningExplorerDesc;

  /// No description provided for @sectionVision.
  ///
  /// In en, this message translates to:
  /// **'Vision'**
  String get sectionVision;

  /// No description provided for @sectionVisionDesc.
  ///
  /// In en, this message translates to:
  /// **'The board-scanning habits most players never drill'**
  String get sectionVisionDesc;

  /// No description provided for @sectionNotation.
  ///
  /// In en, this message translates to:
  /// **'Notation'**
  String get sectionNotation;

  /// No description provided for @sectionNotationDesc.
  ///
  /// In en, this message translates to:
  /// **'Read and find squares and moves without thinking'**
  String get sectionNotationDesc;

  /// No description provided for @sectionAllDrills.
  ///
  /// In en, this message translates to:
  /// **'All {count} drills'**
  String sectionAllDrills(int count);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @drillBest.
  ///
  /// In en, this message translates to:
  /// **'Best {value}'**
  String drillBest(String value);

  /// No description provided for @groupScan.
  ///
  /// In en, this message translates to:
  /// **'Scan the board'**
  String get groupScan;

  /// No description provided for @groupGeometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry'**
  String get groupGeometry;

  /// No description provided for @groupFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get groupFinish;

  /// No description provided for @groupBoard.
  ///
  /// In en, this message translates to:
  /// **'The board'**
  String get groupBoard;

  /// No description provided for @groupPieces.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get groupPieces;

  /// No description provided for @drillFilesRanks.
  ///
  /// In en, this message translates to:
  /// **'Files & Ranks'**
  String get drillFilesRanks;

  /// No description provided for @drillReadMoves.
  ///
  /// In en, this message translates to:
  /// **'Read Moves'**
  String get drillReadMoves;

  /// No description provided for @drillPieceLetters.
  ///
  /// In en, this message translates to:
  /// **'Piece Letters'**
  String get drillPieceLetters;

  /// No description provided for @drillPieceValues.
  ///
  /// In en, this message translates to:
  /// **'Piece Values'**
  String get drillPieceValues;

  /// No description provided for @drillDescFindChecks.
  ///
  /// In en, this message translates to:
  /// **'Every check in a real position'**
  String get drillDescFindChecks;

  /// No description provided for @drillDescFindCaptures.
  ///
  /// In en, this message translates to:
  /// **'Find every capture on the board'**
  String get drillDescFindCaptures;

  /// No description provided for @drillDescHanging.
  ///
  /// In en, this message translates to:
  /// **'Spot every undefended piece'**
  String get drillDescHanging;

  /// No description provided for @drillDescForks.
  ///
  /// In en, this message translates to:
  /// **'Squares that hit two targets'**
  String get drillDescForks;

  /// No description provided for @drillDescKnightSight.
  ///
  /// In en, this message translates to:
  /// **'Every square a knight reaches'**
  String get drillDescKnightSight;

  /// No description provided for @drillDescKnightFlight.
  ///
  /// In en, this message translates to:
  /// **'Fewest moves to the target'**
  String get drillDescKnightFlight;

  /// No description provided for @drillDescPawnAttack.
  ///
  /// In en, this message translates to:
  /// **'Slip past a wall of pawns'**
  String get drillDescPawnAttack;

  /// No description provided for @drillDescMate.
  ///
  /// In en, this message translates to:
  /// **'400 positions, one move to mate'**
  String get drillDescMate;

  /// No description provided for @drillDescSquares.
  ///
  /// In en, this message translates to:
  /// **'Find the square, fast'**
  String get drillDescSquares;

  /// No description provided for @drillDescFilesRanks.
  ///
  /// In en, this message translates to:
  /// **'Name every file and rank'**
  String get drillDescFilesRanks;

  /// No description provided for @drillDescReadMoves.
  ///
  /// In en, this message translates to:
  /// **'Read a move, then play it'**
  String get drillDescReadMoves;

  /// No description provided for @drillDescLetters.
  ///
  /// In en, this message translates to:
  /// **'K, Q, R, B, N at a glance'**
  String get drillDescLetters;

  /// No description provided for @drillDescValues.
  ///
  /// In en, this message translates to:
  /// **'Which side comes out ahead?'**
  String get drillDescValues;

  /// No description provided for @setupYourPiece.
  ///
  /// In en, this message translates to:
  /// **'Your piece'**
  String get setupYourPiece;

  /// No description provided for @setupForkTarget.
  ///
  /// In en, this message translates to:
  /// **'Fork the king and a…'**
  String get setupForkTarget;

  /// No description provided for @setupMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get setupMode;

  /// No description provided for @setupBoardSide.
  ///
  /// In en, this message translates to:
  /// **'Board side'**
  String get setupBoardSide;

  /// No description provided for @setupLines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get setupLines;

  /// No description provided for @setupYourBest.
  ///
  /// In en, this message translates to:
  /// **'Your best'**
  String get setupYourBest;

  /// No description provided for @setupNoBest.
  ///
  /// In en, this message translates to:
  /// **'No best yet'**
  String get setupNoBest;

  /// No description provided for @setupKnightPracticeOnly.
  ///
  /// In en, this message translates to:
  /// **'No timer. Take your time.'**
  String get setupKnightPracticeOnly;

  /// No description provided for @warmupStep.
  ///
  /// In en, this message translates to:
  /// **'Warm-up · {current} of {total}'**
  String warmupStep(int current, int total);

  /// No description provided for @warmupNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {drill}'**
  String warmupNext(String drill);

  /// No description provided for @warmupFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish warm-up'**
  String get warmupFinish;

  /// No description provided for @warmupEnd.
  ///
  /// In en, this message translates to:
  /// **'End warm-up'**
  String get warmupEnd;

  /// No description provided for @warmupDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Warm-up complete'**
  String get warmupDoneTitle;

  /// No description provided for @warmupDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Five drills done. Same time tomorrow?'**
  String get warmupDoneBody;

  /// No description provided for @resultsMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get resultsMissed;

  /// No description provided for @endDrill.
  ///
  /// In en, this message translates to:
  /// **'End drill'**
  String get endDrill;

  /// No description provided for @promptTitleChecks.
  ///
  /// In en, this message translates to:
  /// **'Find every check'**
  String get promptTitleChecks;

  /// No description provided for @promptTitleCaptures.
  ///
  /// In en, this message translates to:
  /// **'Find every capture'**
  String get promptTitleCaptures;

  /// No description provided for @promptTitleHanging.
  ///
  /// In en, this message translates to:
  /// **'Find every loose piece'**
  String get promptTitleHanging;

  /// No description provided for @promptTitleForks.
  ///
  /// In en, this message translates to:
  /// **'Find every fork'**
  String get promptTitleForks;

  /// No description provided for @promptTitleKnightSight.
  ///
  /// In en, this message translates to:
  /// **'Every knight jump'**
  String get promptTitleKnightSight;

  /// No description provided for @promptTitleKnightFlight.
  ///
  /// In en, this message translates to:
  /// **'Reach the ring'**
  String get promptTitleKnightFlight;

  /// No description provided for @promptTitlePawnAttack.
  ///
  /// In en, this message translates to:
  /// **'Capture every pawn'**
  String get promptTitlePawnAttack;

  /// No description provided for @promptTitleMate.
  ///
  /// In en, this message translates to:
  /// **'Checkmate in one'**
  String get promptTitleMate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'ja',
    'ko',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
