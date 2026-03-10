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
    Locale('de'),
    Locale('en'),
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

  /// No description provided for @calvinChessTrainer.
  ///
  /// In en, this message translates to:
  /// **'Calvin Chess\nTrainer'**
  String get calvinChessTrainer;

  /// No description provided for @masterTheFundamentals.
  ///
  /// In en, this message translates to:
  /// **'Master the fundamentals!'**
  String get masterTheFundamentals;

  /// No description provided for @chessNotation.
  ///
  /// In en, this message translates to:
  /// **'Chess Notation'**
  String get chessNotation;

  /// No description provided for @learnTheBoard.
  ///
  /// In en, this message translates to:
  /// **'Learn the board!'**
  String get learnTheBoard;

  /// No description provided for @chessVision.
  ///
  /// In en, this message translates to:
  /// **'Chess Vision'**
  String get chessVision;

  /// No description provided for @seeTheBoard.
  ///
  /// In en, this message translates to:
  /// **'See the board!'**
  String get seeTheBoard;

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

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

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

  /// No description provided for @whatToPractice.
  ///
  /// In en, this message translates to:
  /// **'What to practice?'**
  String get whatToPractice;

  /// No description provided for @chooseAMode.
  ///
  /// In en, this message translates to:
  /// **'Choose a mode'**
  String get chooseAMode;

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

  /// No description provided for @hardMode.
  ///
  /// In en, this message translates to:
  /// **'HARD MODE'**
  String get hardMode;

  /// No description provided for @hardModeBlack.
  ///
  /// In en, this message translates to:
  /// **'User controls black!'**
  String get hardModeBlack;

  /// No description provided for @hardModeFlipped.
  ///
  /// In en, this message translates to:
  /// **'Board flipped — black\'s perspective!'**
  String get hardModeFlipped;

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

  /// No description provided for @drillType.
  ///
  /// In en, this message translates to:
  /// **'Drill type'**
  String get drillType;

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

  /// No description provided for @chooseYourPiece.
  ///
  /// In en, this message translates to:
  /// **'Choose your piece'**
  String get chooseYourPiece;

  /// No description provided for @targetPiece.
  ///
  /// In en, this message translates to:
  /// **'Target piece'**
  String get targetPiece;

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

  /// No description provided for @concentricDrill.
  ///
  /// In en, this message translates to:
  /// **'Concentric Drill'**
  String get concentricDrill;

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

  /// No description provided for @foundOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{found} of {total}'**
  String foundOfTotal(int found, int total);

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

  /// No description provided for @titleForksAndSkewers.
  ///
  /// In en, this message translates to:
  /// **'{piece} — {mode}'**
  String titleForksAndSkewers(String piece, String mode);

  /// No description provided for @titlePawnAttack.
  ///
  /// In en, this message translates to:
  /// **'Pawn Attack — {piece} {mode}'**
  String titlePawnAttack(String piece, String mode);

  /// No description provided for @titleMovesGame.
  ///
  /// In en, this message translates to:
  /// **'Moves - {mode}'**
  String titleMovesGame(String mode);

  /// No description provided for @titleFileRankGame.
  ///
  /// In en, this message translates to:
  /// **'{subject} - {mode}'**
  String titleFileRankGame(String subject, String mode);

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
  /// **'A fun, interactive app that teaches chess fundamentals to kids. Learn files, ranks, squares, and piece moves through drills, quizzes, and timed challenges — all with audio feedback and streak tracking to keep you motivated!'**
  String get aboutWhatIsBody;

  /// No description provided for @aboutTrainingModes.
  ///
  /// In en, this message translates to:
  /// **'Training Modes'**
  String get aboutTrainingModes;

  /// No description provided for @aboutTrainingModesBody.
  ///
  /// In en, this message translates to:
  /// **'• Explore — learn at your own pace\n• Practice — quiz yourself and build streaks\n• Speed Round — 30 seconds, how many can you get?\n• Hard Mode — hide coordinates for a real challenge'**
  String get aboutTrainingModesBody;

  /// No description provided for @aboutCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits & Acknowledgments'**
  String get aboutCredits;

  /// No description provided for @aboutCreditsBody.
  ///
  /// In en, this message translates to:
  /// **'• Chess puzzles from the Lichess database (CC0 license)\n• Board UI powered by Lichess chessground\n• Chess logic by Lichess dartchess\n• Voice clips by ElevenLabs\n• Built with Flutter & Dart'**
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

  /// No description provided for @squareTrainer.
  ///
  /// In en, this message translates to:
  /// **'Square Trainer'**
  String get squareTrainer;

  /// No description provided for @squareComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Square trainer coming soon'**
  String get squareComingSoon;

  /// No description provided for @moveTrainer.
  ///
  /// In en, this message translates to:
  /// **'Move Trainer'**
  String get moveTrainer;

  /// No description provided for @moveComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Move trainer coming soon'**
  String get moveComingSoon;

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

  /// No description provided for @openingFundamentals.
  ///
  /// In en, this message translates to:
  /// **'Opening\nExplorer'**
  String get openingFundamentals;

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

  /// No description provided for @whichSideWins.
  ///
  /// In en, this message translates to:
  /// **'Which Side Wins?'**
  String get whichSideWins;

  /// No description provided for @whichSideWinsDesc.
  ///
  /// In en, this message translates to:
  /// **'Compare groups of pieces — tap the side worth more!'**
  String get whichSideWinsDesc;

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
