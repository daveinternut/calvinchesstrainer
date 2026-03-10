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
      'Une application amusante et interactive qui enseigne les fondamentaux des échecs aux enfants. Apprends les colonnes, rangées, cases et mouvements de pièces grâce à des exercices, des quiz et des défis chronométrés — le tout avec un retour audio et un suivi des séries pour te motiver !';

  @override
  String get aboutTrainingModes => 'Modes d\'entraînement';

  @override
  String get aboutTrainingModesBody =>
      '• Explorer — apprends à ton rythme\n• Entraînement — teste-toi et construis des séries\n• Contre la Montre — 30 secondes, combien peux-tu en résoudre ?\n• Mode Difficile — cache les coordonnées pour un vrai défi';

  @override
  String get aboutCredits => 'Crédits et Remerciements';

  @override
  String get aboutCreditsBody =>
      '• Puzzles d\'échecs de la base de données Lichess (licence CC0)\n• Interface de l\'échiquier par Lichess chessground\n• Logique d\'échecs par Lichess dartchess\n• Clips vocaux par ElevenLabs\n• Développé avec Flutter et Dart';

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
  String get squareTrainer => 'Entraîneur de Cases';

  @override
  String get squareComingSoon => 'Entraîneur de cases bientôt disponible';

  @override
  String get moveTrainer => 'Entraîneur de Coups';

  @override
  String get moveComingSoon => 'Entraîneur de coups bientôt disponible';

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
