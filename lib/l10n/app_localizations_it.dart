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
  String get learnTheBoard => 'Impara la scacchiera!';

  @override
  String get comingSoon => 'PROSSIMAMENTE';

  @override
  String get start => 'Inizia';

  @override
  String get playAgain => 'Gioca ancora';

  @override
  String get newRecord => 'Nuovo record!';

  @override
  String get files => 'Colonne';

  @override
  String get ranks => 'Traverse';

  @override
  String get squares => 'Case';

  @override
  String get moves => 'Mosse';

  @override
  String get pieceValue => 'Valore pezzi';

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
  String get tapFileToSee => 'Tocca una colonna per vederne il nome';

  @override
  String get tapRankToSee => 'Tocca una traversa per vederne il nome';

  @override
  String get tapSquareToSee => 'Tocca una casa per vederne il nome';

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
  String get forksAndSkewers => 'Forchette e Infilate';

  @override
  String get pawnAttack => 'Attacco di Pedone';

  @override
  String get knightSight => 'Visione del Cavallo';

  @override
  String get knightFlight => 'Volo del Cavallo';

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
      'Un\'app divertente e interattiva che insegna ai bambini le basi degli scacchi. Visione Scacchistica ti allena a vedere al volo forchette, infilate, salti del cavallo, scacchi, catture e pezzi indifesi. Notazione Scacchistica ti insegna colonne, traverse, case, lettere dei pezzi, mosse e valore dei pezzi. Con l\'Esploratore di aperture provi le aperture con i consigli di un vero motore scacchistico. Audio, serie e record salvati ti tengono motivato!';

  @override
  String get aboutTrainingModes => 'Modalità di Allenamento';

  @override
  String get aboutTrainingModesBody =>
      '• Esplora — impara al tuo ritmo\n• Pratica — mettiti alla prova e costruisci serie\n• Sfida a Tempo — corri contro il tempo (30 o 60 secondi) e stabilisci un nuovo record\n• Modalità Difficile — gioca dal lato del nero';

  @override
  String get aboutCredits => 'Crediti e Ringraziamenti';

  @override
  String get aboutCreditsBody =>
      '• Consulente scacchistico: Dattasai Kilari\n• Puzzle di scacchi dal database Lichess (licenza CC0)\n• Interfaccia della scacchiera di Lichess chessground\n• Logica scacchistica di Lichess dartchess\n• Clip vocali di ElevenLabs\n• Sviluppato con Flutter e Dart';

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
  String get promptSquare => 'casa';

  @override
  String get promptFile => 'colonna';

  @override
  String get promptRank => 'traversa';

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
  String get tapTheSideWorthMore => 'Tocca il lato che vale di più';

  @override
  String get whichSideWinsPracticeDesc =>
      'Costruisci la tua serie — la difficoltà aumenta man mano!';

  @override
  String get letters => 'Lettere';

  @override
  String get king => 'Re';

  @override
  String get pawn => 'Pedone';

  @override
  String get tapPieceToLearnLetter =>
      'Tocca un pezzo per imparare la sua lettera!';

  @override
  String get whichPieceForLetter => 'Quale pezzo usa questa lettera?';

  @override
  String get whichLetterForPiece => 'Qual è la lettera di questo pezzo?';

  @override
  String get tapPieceNoLetter => 'Tocca il pezzo SENZA lettera!';

  @override
  String get noLetter => 'Senza lettera';

  @override
  String letterEquals(String letter, String piece) {
    return '$letter = $piece!';
  }

  @override
  String get pawnNoLetterFact => 'I pedoni non hanno bisogno di una lettera!';

  @override
  String get mnemonicKing => 'K come King — il Re in inglese!';

  @override
  String get mnemonicQueen => 'Q come Queen — la Donna in inglese!';

  @override
  String get mnemonicRook => 'R come Rook — la Torre in inglese!';

  @override
  String get mnemonicBishop => 'B come Bishop — l\'Alfiere in inglese!';

  @override
  String get mnemonicKnight => 'N come kNight — il Cavallo! La K è già del Re.';

  @override
  String get mnemonicPawn =>
      'I pedoni sono così coraggiosi che non hanno una lettera!';

  @override
  String get scanDrillChecks => 'Trova gli scacchi';

  @override
  String get scanDrillCaptures => 'Trova le catture';

  @override
  String get scanDrillHanging => 'Pezzi indifesi';

  @override
  String get scanDrillMate => 'Matto in 1';

  @override
  String get scanPromptChecks => 'Tocca ogni casa da cui puoi dare scacco!';

  @override
  String get scanPromptCaptures =>
      'Tocca ogni pezzo nemico che puoi catturare!';

  @override
  String get scanPromptHanging => 'Tocca ogni pezzo nemico che non è difeso!';

  @override
  String get scanPromptMate => 'Trova lo scacco matto in una mossa!';

  @override
  String get scanPracticeDesc => 'Senza timer — trovali tutti!';

  @override
  String get blitz => 'Blitz';

  @override
  String get scanBlitzDesc => '60 secondi — quanti matti riesci a trovare?';

  @override
  String get whiteToPlay => 'Muove il Bianco';

  @override
  String get blackToPlay => 'Muove il Nero';

  @override
  String get openingExplorer => 'Esploratore di aperture';

  @override
  String get startFromOpening => 'Inizia da un\'apertura';

  @override
  String get flipBoard => 'Gira la scacchiera';

  @override
  String get showScores => 'Mostra i punteggi';

  @override
  String get hideScores => 'Nascondi i punteggi';

  @override
  String get turnSoundOff => 'Disattiva l\'audio';

  @override
  String get turnSoundOn => 'Attiva l\'audio';

  @override
  String get searchOpenings => 'Cerca aperture…';

  @override
  String get noOpeningsFound => 'Nessuna apertura trovata';

  @override
  String get popularOpenings => 'Popolari';

  @override
  String get browseByCategory => 'Sfoglia per categoria';

  @override
  String get ecoFlankOpenings => 'Aperture di fianco';

  @override
  String get ecoSemiOpenGames => 'Aperture semiaperte';

  @override
  String get ecoOpenGames => 'Aperture aperte';

  @override
  String get ecoClosedGames => 'Chiuse e semichiuse';

  @override
  String get ecoIndianDefenses => 'Difese indiane';

  @override
  String get engineUnavailable => 'Il motore scacchistico non si è avviato.';

  @override
  String get visionPromptForks =>
      'Tocca ogni casa da cui il tuo pezzo attacca il re e l\'altro pezzo!';

  @override
  String get visionPromptKnightSight =>
      'Tocca ogni casa su cui può saltare il tuo cavallo!';

  @override
  String get visionPromptKnightFlight =>
      'Porta il tuo cavallo all\'anello con meno mosse possibile!';

  @override
  String get visionPromptPawnAttack =>
      'Cattura tutti i pedoni — non fermarti mai su una casa ombreggiata!';

  @override
  String get startOver => 'Ricomincia';

  @override
  String get loadFailed => 'Impossibile caricare gli esercizi.';

  @override
  String get checkmate => 'Scacco matto!';

  @override
  String get draw => 'Patta!';

  @override
  String get homeWarmupKicker => 'Riscaldamento quotidiano · 5 min';

  @override
  String get homeWarmupTitle => 'Allena ciò che i puzzle trascurano';

  @override
  String get homeWarmupBody =>
      'Cinque esercizi veloci: scacchi, pezzi indifesi, forchette, case dal lato del nero e un matto in una mossa.';

  @override
  String get homeWarmupStart => 'Inizia il riscaldamento';

  @override
  String get homeContinue => 'Continua';

  @override
  String get homeStartHere => 'Inizia qui';

  @override
  String homeResume(String drill) {
    return 'Riprendi: $drill';
  }

  @override
  String get homeOpenings => 'Aperture';

  @override
  String get homeOpeningExplorerDesc =>
      'Gioca le aperture con i suggerimenti di Stockfish';

  @override
  String get sectionVision => 'Visione';

  @override
  String get sectionVisionDesc =>
      'Le abitudini di scansione della scacchiera che quasi nessuno allena';

  @override
  String get sectionNotation => 'Notazione';

  @override
  String get sectionNotationDesc => 'Leggi e trova case e mosse senza pensarci';

  @override
  String sectionAllDrills(int count) {
    return 'Tutti i $count esercizi';
  }

  @override
  String get navHome => 'Home';

  @override
  String drillBest(String value) {
    return 'Record $value';
  }

  @override
  String get groupScan => 'Scansiona la scacchiera';

  @override
  String get groupGeometry => 'Geometria';

  @override
  String get groupFinish => 'Colpo finale';

  @override
  String get groupBoard => 'La scacchiera';

  @override
  String get groupPieces => 'Pezzi';

  @override
  String get drillFilesRanks => 'Colonne e traverse';

  @override
  String get drillReadMoves => 'Lettura delle mosse';

  @override
  String get drillPieceLetters => 'Lettere dei pezzi';

  @override
  String get drillPieceValues => 'Valore dei pezzi';

  @override
  String get drillDescFindChecks => 'Ogni scacco in una posizione reale';

  @override
  String get drillDescFindCaptures => 'Trova tutte le catture sulla scacchiera';

  @override
  String get drillDescHanging => 'Individua ogni pezzo indifeso';

  @override
  String get drillDescForks => 'Case di doppio attacco';

  @override
  String get drillDescKnightSight => 'Ogni casa raggiungibile dal cavallo';

  @override
  String get drillDescKnightFlight => 'Al bersaglio con meno mosse possibile';

  @override
  String get drillDescPawnAttack => 'Sguscia oltre un muro di pedoni';

  @override
  String get drillDescMate => '400 posizioni, una mossa per il matto';

  @override
  String get drillDescSquares => 'Trova la casa, in fretta';

  @override
  String get drillDescFilesRanks => 'Riconosci ogni colonna e traversa';

  @override
  String get drillDescReadMoves => 'Leggi una mossa, poi giocala';

  @override
  String get drillDescLetters => 'K, Q, R, B, N a colpo d\'occhio';

  @override
  String get drillDescValues => 'Quale lato è in vantaggio?';

  @override
  String get setupYourPiece => 'Il tuo pezzo';

  @override
  String get setupForkTarget => 'Forchetta a re e…';

  @override
  String get setupMode => 'Modalità';

  @override
  String get setupBoardSide => 'Lato della scacchiera';

  @override
  String get setupLines => 'Linee';

  @override
  String get setupYourBest => 'Il tuo record';

  @override
  String get setupNoBest => 'Ancora nessun record';

  @override
  String get setupKnightPracticeOnly => 'Senza timer. Fai con calma.';

  @override
  String warmupStep(int current, int total) {
    return 'Riscaldamento · $current di $total';
  }

  @override
  String warmupNext(String drill) {
    return 'Prossimo: $drill';
  }

  @override
  String get warmupFinish => 'Termina il riscaldamento';

  @override
  String get warmupEnd => 'Esci dal riscaldamento';

  @override
  String get warmupDoneTitle => 'Riscaldamento completato';

  @override
  String get warmupDoneBody => 'Cinque esercizi fatti. Domani alla stessa ora?';

  @override
  String get resultsMissed => 'Mancate';

  @override
  String get endDrill => 'Esci dall\'esercizio';

  @override
  String get promptTitleChecks => 'Trova tutti gli scacchi';

  @override
  String get promptTitleCaptures => 'Trova tutte le catture';

  @override
  String get promptTitleHanging => 'Trova ogni pezzo indifeso';

  @override
  String get promptTitleForks => 'Trova tutte le forchette';

  @override
  String get promptTitleKnightSight => 'Ogni salto del cavallo';

  @override
  String get promptTitleKnightFlight => 'Raggiungi l\'anello';

  @override
  String get promptTitlePawnAttack => 'Cattura tutti i pedoni';

  @override
  String get promptTitleMate => 'Scacco matto in una mossa';
}
