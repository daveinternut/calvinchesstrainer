// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Calvin Chess Trainer';

  @override
  String get about => 'Info';

  @override
  String get calvinChessTrainer => 'Calvin Chess\nTrainer';

  @override
  String get masterTheFundamentals => 'Padroneggia i fondamentali!';

  @override
  String get chessNotation => 'Notazione Scacchistica';

  @override
  String get learnTheBoard => 'Impara la scacchiera!';

  @override
  String get chessVision => 'Visione Scacchistica';

  @override
  String get seeTheBoard => 'Vedi la scacchiera!';

  @override
  String get comingSoon => 'PROSSIMAMENTE';

  @override
  String get start => 'Inizia';

  @override
  String get menu => 'Menu';

  @override
  String get playAgain => 'Gioca ancora';

  @override
  String get newRecord => 'Nuovo record!';

  @override
  String get whatToPractice => 'Cosa praticare?';

  @override
  String get chooseAMode => 'Scegli una modalità';

  @override
  String get files => 'Colonne';

  @override
  String get ranks => 'Traverse';

  @override
  String get squares => 'Case';

  @override
  String get moves => 'Mosse';

  @override
  String get explore => 'Esplora';

  @override
  String get exploreDesc =>
      'Tocca per imparare — nessuna pressione, nessun punteggio';

  @override
  String get practice => 'Pratica';

  @override
  String get practiceDesc => 'Mettiti alla prova — costruisci la tua serie!';

  @override
  String get speedRound => 'Sfida a Tempo';

  @override
  String get speedRoundDesc => '30 secondi — quanti riesci a risolverne?';

  @override
  String get hardMode => 'MODALITÀ DIFFICILE';

  @override
  String get hardModeBlack => 'Il giocatore controlla il nero!';

  @override
  String get hardModeFlipped => 'Scacchiera capovolta — prospettiva del nero!';

  @override
  String get timesUp => 'Tempo scaduto!';

  @override
  String get correct => 'Corrette';

  @override
  String get accuracy => 'Precisione';

  @override
  String get bestStreak => 'Migliore serie';

  @override
  String bestLabel(int value) {
    return 'Record: $value';
  }

  @override
  String get tapFileToHear => 'Tocca una colonna per sentirne il nome';

  @override
  String get tapRankToHear => 'Tocca una traversa per sentirne il nome';

  @override
  String get tapSquareToHear => 'Tocca una casa per sentirne il nome';

  @override
  String get tapFile => 'Tocca la colonna';

  @override
  String get tapRank => 'Tocca la traversa';

  @override
  String get tapSquare => 'Tocca la casa';

  @override
  String get milestoneNice => 'Bene!';

  @override
  String get milestoneAmazing => 'Fantastico!';

  @override
  String get milestoneIncredible => 'Incredibile!';

  @override
  String get milestoneUnstoppable => 'Inarrestabile!';

  @override
  String get milestoneLegendary => 'Leggendario!';

  @override
  String get milestoneGreat => 'Ottimo!';

  @override
  String streakMilestone(int count) {
    return '$count di fila!';
  }

  @override
  String get hurry => 'Sbrigati!';

  @override
  String get drillType => 'Tipo di esercizio';

  @override
  String get forksAndSkewers => 'Forchette e Infilate';

  @override
  String get pawnAttack => 'Attacco di Pedone';

  @override
  String get knightSight => 'Visione del Cavallo';

  @override
  String get knightFlight => 'Volo del Cavallo';

  @override
  String get chooseYourPiece => 'Scegli il tuo pezzo';

  @override
  String get targetPiece => 'Pezzo bersaglio';

  @override
  String get queen => 'Donna';

  @override
  String get rook => 'Torre';

  @override
  String get bishop => 'Alfiere';

  @override
  String get knight => 'Cavallo';

  @override
  String get findForksNoTimer => 'Trova forchette e infilate — senza tempo';

  @override
  String get speedRound60Desc => '60 secondi — risolvine il più possibile!';

  @override
  String get concentricDrill => 'Esercizio Concentrico';

  @override
  String get concentricDrillDesc =>
      'Completa tutte le posizioni — batti il tuo tempo!';

  @override
  String get captureAllPawnsNoTimer => 'Cattura tutti i pedoni — senza tempo';

  @override
  String get timed => 'A tempo';

  @override
  String get timedPawnAttackDesc =>
      'Elimina da 3 a 8 pedoni — batti il tuo tempo!';

  @override
  String get concentric => 'Concentrico';

  @override
  String get retry => 'Riprova';

  @override
  String get skip => 'Salta';

  @override
  String get none => 'Nessuna';

  @override
  String minimumMoves(int count) {
    return 'Minimo: $count';
  }

  @override
  String yourMoves(int count) {
    return 'Le tue mosse: $count';
  }

  @override
  String pawnsRemaining(int count) {
    return 'Pedoni: $count';
  }

  @override
  String levelOfEight(int level) {
    return 'Livello $level di 8';
  }

  @override
  String movesCount(int count) {
    return 'Mosse: $count';
  }

  @override
  String positionOfTotal(int current, int total) {
    return 'Posizione $current di $total';
  }

  @override
  String get tapNoneHint => 'Tocca Nessuna se non ci sono soluzioni';

  @override
  String get found => 'Trovate';

  @override
  String foundOfTotal(int found, int total) {
    return '$found di $total';
  }

  @override
  String get drillComplete => 'Esercizio completato!';

  @override
  String get allClear => 'Tutto risolto!';

  @override
  String get time => 'Tempo';

  @override
  String get errors => 'Errori';

  @override
  String get rounds => 'Round';

  @override
  String solvedCount(int count) {
    return '$count risolti';
  }

  @override
  String titleForksAndSkewers(String piece, String mode) {
    return '$piece — $mode';
  }

  @override
  String titlePawnAttack(String piece, String mode) {
    return 'Attacco di Pedone — $piece $mode';
  }

  @override
  String titleMovesGame(String mode) {
    return 'Mosse - $mode';
  }

  @override
  String titleFileRankGame(String subject, String mode) {
    return '$subject - $mode';
  }

  @override
  String get makeTheMove => 'Fai la mossa';

  @override
  String get castleKingside => 'Arrocco corto';

  @override
  String get castleQueenside => 'Arrocco lungo';

  @override
  String pieceTakesOn(String piece, String square) {
    return '$piece cattura in $square';
  }

  @override
  String pieceToSquare(String piece, String square) {
    return '$piece in $square';
  }

  @override
  String get seePositionMakeMove => 'Vedi una posizione, fai la mossa!';

  @override
  String get aboutWhatIs => 'Cos\'è Calvin Chess Trainer?';

  @override
  String get aboutWhatIsBody =>
      'Un\'app divertente e interattiva che insegna i fondamentali degli scacchi ai bambini. Impara colonne, traverse, case e mosse dei pezzi attraverso esercizi, quiz e sfide a tempo — il tutto con feedback audio e tracciamento delle serie per tenerti motivato!';

  @override
  String get aboutTrainingModes => 'Modalità di Allenamento';

  @override
  String get aboutTrainingModesBody =>
      '• Esplora — impara al tuo ritmo\n• Pratica — mettiti alla prova e costruisci serie\n• Sfida a Tempo — 30 secondi, quanti riesci a risolverne?\n• Modalità Difficile — nascondi le coordinate per una vera sfida';

  @override
  String get aboutCredits => 'Crediti e Ringraziamenti';

  @override
  String get aboutCreditsBody =>
      '• Puzzle di scacchi dal database Lichess (licenza CC0)\n• Interfaccia della scacchiera di Lichess chessground\n• Logica scacchistica di Lichess dartchess\n• Clip vocali di ElevenLabs\n• Sviluppato con Flutter e Dart';

  @override
  String get aboutInspired => 'Ispirato a Rapid Chess Improvement';

  @override
  String get aboutInspiredBody =>
      'Questa app deve molto al libro di Michael de la Maza Rapid Chess Improvement (Everyman Chess, 2002). Il suo concetto di \"visione scacchistica\" — la capacità di riconoscere istantaneamente schemi tattici e relazioni tra pezzi — ha trasformato il mio modo di pensare all\'allenamento. Seguire le sue idee mi ha aiutato a migliorare drasticamente il mio gioco, e ho creato Calvin Chess Trainer nella speranza che il suo approccio alla visione scacchistica aiuti una nuova generazione di giocatori a vedere la scacchiera più chiaramente. Grazie, Michael!';

  @override
  String get aboutInternut => 'Informazioni su Internut Education';

  @override
  String get aboutInternutBody =>
      'Internut Education crea app di apprendimento coinvolgenti per bambini. Crediamo che il modo migliore per imparare sia attraverso il gioco, la pratica e il rinforzo positivo.';

  @override
  String aboutVersion(String version) {
    return 'Versione $version';
  }

  @override
  String get aboutByInternut => 'di Internut Education';

  @override
  String get aboutFooter =>
      'Fatto con ❤️ per giovani scacchisti di tutto il mondo';

  @override
  String get feedbackTitle => 'Inviaci il tuo feedback';

  @override
  String get feedbackBody =>
      'Cerchiamo sempre di migliorare questa app! Che sia un\'idea, un bug o qualcosa che adori — ci piacerebbe sentire la tua opinione.';

  @override
  String get feedbackHint => 'Scrivi il tuo feedback qui...';

  @override
  String get feedbackSend => 'Invia feedback';

  @override
  String get feedbackSending => 'Invio in corso...';

  @override
  String get feedbackThanks => 'Grazie per il tuo feedback!';

  @override
  String get feedbackError => 'Invio non riuscito. Riprova.';

  @override
  String get feedbackEmpty => 'Scrivi qualcosa prima di inviare.';

  @override
  String get tacticsTrainer => 'Allenatore di Tattica';

  @override
  String get tacticsComingSoon => 'Allenatore di tattica prossimamente';

  @override
  String get squareTrainer => 'Allenatore di Case';

  @override
  String get squareComingSoon => 'Allenatore di case prossimamente';

  @override
  String get moveTrainer => 'Allenatore di Mosse';

  @override
  String get moveComingSoon => 'Allenatore di mosse prossimamente';

  @override
  String get promptSquare => 'casa';

  @override
  String get promptFile => 'colonna';

  @override
  String get promptRank => 'traversa';

  @override
  String get openingFundamentals => 'Esploratore\nDi Aperture';

  @override
  String get playTheOpening => 'Esplora le aperture!';

  @override
  String get openingPractice => 'Pratica di Apertura';

  @override
  String get openingChallenge => 'Sfida di Apertura';

  @override
  String get playAs => 'Gioca come';

  @override
  String get playAsWhite => 'Bianco';

  @override
  String get playAsBlack => 'Nero';

  @override
  String get difficulty => 'Difficoltà';

  @override
  String get easy => 'Facile';

  @override
  String get medium => 'Medio';

  @override
  String get hard => 'Difficile';

  @override
  String get challenge => 'Sfida';

  @override
  String get practiceHintsDesc =>
      'Gioca con suggerimenti — le 3 migliori mosse mostrate come frecce';

  @override
  String get challengeDesc =>
      'Metti alla prova le tue capacità di apertura — guadagna medaglie!';

  @override
  String get engineThinking => 'Motore in analisi...';

  @override
  String get yourTurn => 'Il tuo turno';

  @override
  String get gameOver => 'Fine partita';

  @override
  String youSurvivedMoves(int count) {
    return 'Sei sopravvissuto $count mossa/e';
  }

  @override
  String get reviewGame => 'Rivedi partita';

  @override
  String get openingTip => 'Consiglio di apertura';

  @override
  String get gotIt => 'Capito!';

  @override
  String get medalBronze => 'Bronzo!';

  @override
  String get medalSilver => 'Argento!';

  @override
  String get medalGold => 'Oro!';

  @override
  String get previousMove => 'Mossa precedente';

  @override
  String get nextMove => 'Prossima mossa';

  @override
  String get done => 'Fatto';

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
