// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Calvin Chess Trainer';

  @override
  String get about => 'À propos';

  @override
  String get calvinChessTrainer => 'Calvin Chess\nTrainer';

  @override
  String get masterTheFundamentals => 'Maîtrise les fondamentaux !';

  @override
  String get chessNotation => 'Notation aux Échecs';

  @override
  String get learnTheBoard => 'Apprends l\'échiquier !';

  @override
  String get chessVision => 'Vision aux Échecs';

  @override
  String get seeTheBoard => 'Vois l\'échiquier !';

  @override
  String get startHere => 'COMMENCE ICI';

  @override
  String get comingSoon => 'BIENTÔT DISPONIBLE';

  @override
  String get start => 'Commencer';

  @override
  String get menu => 'Menu';

  @override
  String get playAgain => 'Rejouer';

  @override
  String get newRecord => 'Nouveau record !';

  @override
  String get whatToPractice => 'Que pratiquer ?';

  @override
  String get chooseAMode => 'Choisis un mode';

  @override
  String get files => 'Colonnes';

  @override
  String get ranks => 'Rangées';

  @override
  String get squares => 'Cases';

  @override
  String get moves => 'Coups';

  @override
  String get pieceValue => 'Valeur pièces';

  @override
  String get explore => 'Explorer';

  @override
  String get exploreDesc => 'Touche pour apprendre — sans pression, sans score';

  @override
  String get practice => 'Entraînement';

  @override
  String get practiceDesc => 'Teste-toi — construis ta série !';

  @override
  String get speedRound => 'Contre la Montre';

  @override
  String get speedRoundDesc => '30 secondes — combien peux-tu en résoudre ?';

  @override
  String get hardMode => 'MODE DIFFICILE';

  @override
  String get hardModeBlack => 'Le joueur contrôle les noirs !';

  @override
  String get hardModeFlipped => 'Échiquier inversé — perspective des noirs !';

  @override
  String get timesUp => 'Temps écoulé !';

  @override
  String get correct => 'Correct';

  @override
  String get accuracy => 'Précision';

  @override
  String get bestStreak => 'Meilleure série';

  @override
  String bestLabel(int value) {
    return 'Record : $value';
  }

  @override
  String get tapFileToHear => 'Touche une colonne pour entendre son nom';

  @override
  String get tapRankToHear => 'Touche une rangée pour entendre son nom';

  @override
  String get tapSquareToHear => 'Touche une case pour entendre son nom';

  @override
  String get tapFile => 'Touche la colonne';

  @override
  String get tapRank => 'Touche la rangée';

  @override
  String get tapSquare => 'Touche la case';

  @override
  String get milestoneNice => 'Bien !';

  @override
  String get milestoneAmazing => 'Incroyable !';

  @override
  String get milestoneIncredible => 'Phénoménal !';

  @override
  String get milestoneUnstoppable => 'Inarrêtable !';

  @override
  String get milestoneLegendary => 'Légendaire !';

  @override
  String get milestoneGreat => 'Super !';

  @override
  String streakMilestone(int count) {
    return '$count d\'affilée !';
  }

  @override
  String get hurry => 'Vite !';

  @override
  String get drillType => 'Type d\'exercice';

  @override
  String get forksAndSkewers => 'Fourchettes et Enfilades';

  @override
  String get pawnAttack => 'Attaque de Pion';

  @override
  String get knightSight => 'Vision du Cavalier';

  @override
  String get knightFlight => 'Vol du Cavalier';

  @override
  String get chooseYourPiece => 'Choisis ta pièce';

  @override
  String get targetPiece => 'Pièce cible';

  @override
  String get queen => 'Dame';

  @override
  String get rook => 'Tour';

  @override
  String get bishop => 'Fou';

  @override
  String get knight => 'Cavalier';

  @override
  String get findForksNoTimer =>
      'Trouve les fourchettes et enfilades — sans temps';

  @override
  String get speedRound60Desc => '60 secondes — résous-en un maximum !';

  @override
  String get concentricDrill => 'Exercice Concentrique';

  @override
  String get concentricDrillDesc =>
      'Complète toutes les positions — bats ton temps !';

  @override
  String get captureAllPawnsNoTimer => 'Capture tous les pions — sans temps';

  @override
  String get timed => 'Chronométré';

  @override
  String get timedPawnAttackDesc => 'Élimine 3 à 8 pions — bats ton temps !';

  @override
  String get concentric => 'Concentrique';

  @override
  String get retry => 'Réessayer';

  @override
  String get skip => 'Passer';

  @override
  String get none => 'Aucune';

  @override
  String minimumMoves(int count) {
    return 'Minimum : $count';
  }

  @override
  String yourMoves(int count) {
    return 'Tes coups : $count';
  }

  @override
  String pawnsRemaining(int count) {
    return 'Pions : $count';
  }

  @override
  String levelOfEight(int level) {
    return 'Niveau $level sur 8';
  }

  @override
  String movesCount(int count) {
    return 'Coups : $count';
  }

  @override
  String positionOfTotal(int current, int total) {
    return 'Position $current sur $total';
  }

  @override
  String get tapNoneHint => 'Touche Aucune s\'il n\'y a pas de solution';

  @override
  String get found => 'Trouvées';

  @override
  String foundOfTotal(int found, int total) {
    return '$found sur $total';
  }

  @override
  String get drillComplete => 'Exercice terminé !';

  @override
  String get allClear => 'Tout est résolu !';

  @override
  String get time => 'Temps';

  @override
  String get errors => 'Erreurs';

  @override
  String get rounds => 'Manches';

  @override
  String solvedCount(int count) {
    return '$count résolus';
  }

  @override
  String titleForksAndSkewers(String piece, String mode) {
    return '$piece — $mode';
  }

  @override
  String titlePawnAttack(String piece, String mode) {
    return 'Attaque de Pion — $piece $mode';
  }

  @override
  String titleMovesGame(String mode) {
    return 'Coups - $mode';
  }

  @override
  String titleFileRankGame(String subject, String mode) {
    return '$subject - $mode';
  }

  @override
  String get makeTheMove => 'Joue le coup';

  @override
  String get castleKingside => 'Petit roque';

  @override
  String get castleQueenside => 'Grand roque';

  @override
  String pieceTakesOn(String piece, String square) {
    return '$piece prend en $square';
  }

  @override
  String pieceToSquare(String piece, String square) {
    return '$piece en $square';
  }

  @override
  String get seePositionMakeMove => 'Vois une position, joue le coup !';

  @override
  String get aboutWhatIs => 'Qu\'est-ce que Calvin Chess Trainer ?';

  @override
  String get aboutWhatIsBody =>
      'Une application amusante et interactive qui apprend les bases des échecs aux enfants. Vision aux Échecs t\'entraîne à repérer d\'un coup d\'œil fourchettes, enfilades, sauts du cavalier, échecs, prises et pièces en prise. Notation aux Échecs t\'apprend les colonnes, les rangées, les cases, les lettres des pièces, les coups et la valeur des pièces. L\'Explorateur d\'ouvertures te fait essayer des ouvertures avec les conseils d\'un vrai moteur d\'échecs. Le son, les séries et tes records sauvegardés te gardent motivé !';

  @override
  String get aboutTrainingModes => 'Modes d\'entraînement';

  @override
  String get aboutTrainingModesBody =>
      '• Explorer — apprends à ton rythme\n• Entraînement — teste-toi et construis des séries\n• Contre la Montre — bats le chrono (30 ou 60 secondes) et établis un nouveau record\n• Mode Difficile — joue du côté des noirs';

  @override
  String get aboutCredits => 'Crédits et Remerciements';

  @override
  String get aboutCreditsBody =>
      '• Conseiller aux échecs : Dattasai Kilari\n• Puzzles d\'échecs de la base de données Lichess (licence CC0)\n• Interface de l\'échiquier par Lichess chessground\n• Logique d\'échecs par Lichess dartchess\n• Clips vocaux par ElevenLabs\n• Développé avec Flutter et Dart';

  @override
  String get aboutInspired => 'Inspiré par Rapid Chess Improvement';

  @override
  String get aboutInspiredBody =>
      'Cette application doit beaucoup au livre de Michael de la Maza Rapid Chess Improvement (Everyman Chess, 2002). Son concept de « vision échiquéenne » — la capacité de reconnaître instantanément les motifs tactiques et les relations entre les pièces — a transformé ma façon de penser l\'entraînement. Suivre ses idées m\'a aidé à améliorer considérablement mon propre jeu, et j\'ai créé Calvin Chess Trainer dans l\'espoir que son approche de la vision échiquéenne aide une nouvelle génération de joueurs à mieux voir l\'échiquier. Merci, Michael !';

  @override
  String get aboutInternut => 'À propos d\'Internut Education';

  @override
  String get aboutInternutBody =>
      'Internut Education crée des applications d\'apprentissage captivantes pour les enfants. Nous croyons que la meilleure façon d\'apprendre est par le jeu, la pratique et le renforcement positif.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutByInternut => 'par Internut Education';

  @override
  String get aboutFooter =>
      'Fait avec ❤️ pour les jeunes joueurs d\'échecs du monde entier';

  @override
  String get feedbackTitle => 'Envoyez-nous vos commentaires';

  @override
  String get feedbackBody =>
      'Nous cherchons toujours à améliorer cette app ! Que ce soit une idée, un bug ou quelque chose que vous adorez — nous aimerions vraiment avoir de vos nouvelles.';

  @override
  String get feedbackHint => 'Écrivez vos commentaires ici...';

  @override
  String get feedbackSend => 'Envoyer';

  @override
  String get feedbackSending => 'Envoi en cours...';

  @override
  String get feedbackThanks => 'Merci pour vos commentaires !';

  @override
  String get feedbackError => 'Impossible d\'envoyer. Veuillez réessayer.';

  @override
  String get feedbackEmpty => 'Veuillez écrire quelque chose avant d\'envoyer.';

  @override
  String get tacticsTrainer => 'Entraîneur de Tactique';

  @override
  String get tacticsComingSoon => 'Entraîneur de tactique bientôt disponible';

  @override
  String get promptSquare => 'case';

  @override
  String get promptFile => 'colonne';

  @override
  String get promptRank => 'rangée';

  @override
  String get openingFundamentals => 'Explorateur\nD\'Ouvertures';

  @override
  String get playTheOpening => 'Explorez les ouvertures !';

  @override
  String get openingPractice => 'Pratique d\'Ouverture';

  @override
  String get openingChallenge => 'Défi d\'Ouverture';

  @override
  String get playAs => 'Jouer en';

  @override
  String get playAsWhite => 'Blancs';

  @override
  String get playAsBlack => 'Noirs';

  @override
  String get difficulty => 'Difficulté';

  @override
  String get easy => 'Facile';

  @override
  String get medium => 'Moyen';

  @override
  String get hard => 'Difficile';

  @override
  String get challenge => 'Défi';

  @override
  String get practiceHintsDesc =>
      'Joue avec des indications — les 3 meilleurs coups affichés en flèches';

  @override
  String get challengeDesc =>
      'Teste tes compétences d\'ouverture — gagne des médailles !';

  @override
  String get engineThinking => 'Le moteur analyse...';

  @override
  String get yourTurn => 'À ton tour';

  @override
  String get gameOver => 'Partie terminée';

  @override
  String youSurvivedMoves(int count) {
    return 'Tu as survécu $count coup(s)';
  }

  @override
  String get reviewGame => 'Revoir la partie';

  @override
  String get openingTip => 'Conseil d\'ouverture';

  @override
  String get gotIt => 'Compris !';

  @override
  String get medalBronze => 'Bronze !';

  @override
  String get medalSilver => 'Argent !';

  @override
  String get medalGold => 'Or !';

  @override
  String get previousMove => 'Coup précédent';

  @override
  String get nextMove => 'Coup suivant';

  @override
  String get done => 'Terminé';

  @override
  String get thePieces => 'The Pieces';

  @override
  String get knowYourPieces => 'Know your pieces!';

  @override
  String get whichSideWins => 'Quel camp gagne ?';

  @override
  String get whichSideWinsDesc =>
      'Compare des groupes de pièces — touche le camp qui vaut le plus !';

  @override
  String get tapTheSideWorthMore => 'Touche le camp qui vaut le plus';

  @override
  String get whichSideWinsPracticeDesc =>
      'Construis ta série — la difficulté augmente au fur et à mesure !';

  @override
  String get letters => 'Lettres';

  @override
  String get king => 'Roi';

  @override
  String get pawn => 'Pion';

  @override
  String get hardModeBlackPieces => 'Pièces noires affichées !';

  @override
  String get tapPieceToLearnLetter =>
      'Touche une pièce pour apprendre sa lettre !';

  @override
  String get whichPieceForLetter => 'Quelle pièce utilise cette lettre ?';

  @override
  String get whichLetterForPiece => 'Quelle est la lettre de cette pièce ?';

  @override
  String get tapPieceNoLetter => 'Touche la pièce SANS lettre !';

  @override
  String get noLetter => 'Sans lettre';

  @override
  String letterEquals(String letter, String piece) {
    return '$letter = $piece !';
  }

  @override
  String get pawnNoLetterFact => 'Les pions n\'ont pas besoin de lettre !';

  @override
  String get mnemonicKing => 'K comme King — le Roi en anglais !';

  @override
  String get mnemonicQueen => 'Q comme Queen — la Dame en anglais !';

  @override
  String get mnemonicRook => 'R comme Rook — la Tour en anglais !';

  @override
  String get mnemonicBishop => 'B comme Bishop — le Fou en anglais !';

  @override
  String get mnemonicKnight =>
      'N comme kNight — le Cavalier ! Le K est déjà pris par le Roi.';

  @override
  String get mnemonicPawn =>
      'Les pions sont si courageux qu\'ils n\'ont pas de lettre !';

  @override
  String get scanDrillChecks => 'Trouve les échecs';

  @override
  String get scanDrillCaptures => 'Trouve les prises';

  @override
  String get scanDrillHanging => 'Pièces non défendues';

  @override
  String get scanDrillMate => 'Mat en 1';

  @override
  String get scanPromptChecks =>
      'Touche chaque case d\'où tu peux faire échec !';

  @override
  String get scanPromptCaptures =>
      'Touche chaque pièce ennemie que tu peux capturer !';

  @override
  String get scanPromptHanging =>
      'Touche chaque pièce ennemie qui n\'est pas défendue !';

  @override
  String get scanPromptMate => 'Trouve l\'échec et mat en un coup !';

  @override
  String get scanPracticeDesc => 'Sans chrono — trouve-les toutes !';

  @override
  String get blitz => 'Blitz';

  @override
  String get scanBlitzDesc => '60 secondes — combien de mats peux-tu trouver ?';

  @override
  String get whiteToPlay => 'Trait aux Blancs';

  @override
  String get blackToPlay => 'Trait aux Noirs';

  @override
  String get openingExplorer => 'Explorateur d\'ouvertures';

  @override
  String get startFromOpening => 'Partir d\'une ouverture';

  @override
  String get flipBoard => 'Retourner l\'échiquier';

  @override
  String get showScores => 'Afficher les scores';

  @override
  String get hideScores => 'Masquer les scores';

  @override
  String get searchOpenings => 'Rechercher une ouverture…';

  @override
  String get noOpeningsFound => 'Aucune ouverture trouvée';

  @override
  String get popularOpenings => 'Populaires';

  @override
  String get browseByCategory => 'Parcourir par catégorie';

  @override
  String get ecoFlankOpenings => 'Ouvertures de flanc';

  @override
  String get ecoSemiOpenGames => 'Parties semi-ouvertes';

  @override
  String get ecoOpenGames => 'Parties ouvertes';

  @override
  String get ecoClosedGames => 'Fermées et semi-fermées';

  @override
  String get ecoIndianDefenses => 'Défenses indiennes';

  @override
  String get engineUnavailable => 'Le moteur d\'échecs n\'a pas démarré.';

  @override
  String get visionPromptForks =>
      'Touche chaque case d\'où ta pièce attaque le roi et l\'autre pièce !';

  @override
  String get visionPromptKnightSight =>
      'Touche chaque case où ton cavalier peut sauter !';

  @override
  String get visionPromptKnightFlight =>
      'Amène ton cavalier jusqu\'à l\'anneau en un minimum de coups !';

  @override
  String get visionPromptPawnAttack =>
      'Prends tous les pions — ne t\'arrête jamais sur une case ombrée !';

  @override
  String get startOver => 'Recommencer';

  @override
  String get loadFailed => 'Impossible de charger les exercices.';

  @override
  String get checkmate => 'Échec et mat !';

  @override
  String get draw => 'Partie nulle !';
}
