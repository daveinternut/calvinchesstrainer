// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Calvin Chess Trainer';

  @override
  String get about => 'Acerca de';

  @override
  String get learnTheBoard => '¡Aprende el tablero!';

  @override
  String get comingSoon => 'PRÓXIMAMENTE';

  @override
  String get start => 'Comenzar';

  @override
  String get playAgain => 'Jugar de nuevo';

  @override
  String get newRecord => '¡Nuevo récord!';

  @override
  String get files => 'Columnas';

  @override
  String get ranks => 'Filas';

  @override
  String get squares => 'Casillas';

  @override
  String get moves => 'Jugadas';

  @override
  String get pieceValue => 'Valor de piezas';

  @override
  String get explore => 'Explorar';

  @override
  String get exploreDesc => 'Toca para aprender — sin presión, sin puntuación';

  @override
  String get practice => 'Práctica';

  @override
  String get practiceDesc => '¡Ponte a prueba — construye tu racha!';

  @override
  String get speedRound => 'Ronda Rápida';

  @override
  String get speedRoundDesc => '30 segundos — ¿cuántos puedes resolver?';

  @override
  String get timesUp => '¡Se acabó el tiempo!';

  @override
  String get correct => 'Correctas';

  @override
  String get accuracy => 'Precisión';

  @override
  String get bestStreak => 'Mejor racha';

  @override
  String bestLabel(int value) {
    return 'Mejor: $value';
  }

  @override
  String get tapFileToHear => 'Toca cualquier columna para oír su nombre';

  @override
  String get tapRankToHear => 'Toca cualquier fila para oír su nombre';

  @override
  String get tapSquareToHear => 'Toca cualquier casilla para oír su nombre';

  @override
  String get tapFile => 'Toca la columna';

  @override
  String get tapRank => 'Toca la fila';

  @override
  String get tapSquare => 'Toca la casilla';

  @override
  String get milestoneNice => '¡Bien!';

  @override
  String get milestoneAmazing => '¡Increíble!';

  @override
  String get milestoneIncredible => '¡Fenomenal!';

  @override
  String get milestoneUnstoppable => '¡Imparable!';

  @override
  String get milestoneLegendary => '¡Legendario!';

  @override
  String get milestoneGreat => '¡Genial!';

  @override
  String streakMilestone(int count) {
    return '¡$count seguidos!';
  }

  @override
  String get hurry => '¡Rápido!';

  @override
  String get forksAndSkewers => 'Horquillas y Enfiladas';

  @override
  String get pawnAttack => 'Ataque de Peón';

  @override
  String get knightSight => 'Visión del Caballo';

  @override
  String get knightFlight => 'Vuelo del Caballo';

  @override
  String get queen => 'Dama';

  @override
  String get rook => 'Torre';

  @override
  String get bishop => 'Alfil';

  @override
  String get knight => 'Caballo';

  @override
  String get findForksNoTimer =>
      'Encuentra horquillas y enfiladas — sin tiempo';

  @override
  String get speedRound60Desc =>
      '60 segundos — ¡resuelve todos los que puedas!';

  @override
  String get concentricDrillDesc =>
      '¡Completa todas las posiciones — supera tu tiempo!';

  @override
  String get captureAllPawnsNoTimer => 'Captura todos los peones — sin tiempo';

  @override
  String get timed => 'Cronometrado';

  @override
  String get timedPawnAttackDesc =>
      '¡Elimina de 3 a 8 peones — supera tu tiempo!';

  @override
  String get concentric => 'Concéntrico';

  @override
  String get retry => 'Reintentar';

  @override
  String get skip => 'Omitir';

  @override
  String get none => 'Ninguna';

  @override
  String minimumMoves(int count) {
    return 'Mínimo: $count';
  }

  @override
  String yourMoves(int count) {
    return 'Tus jugadas: $count';
  }

  @override
  String pawnsRemaining(int count) {
    return 'Peones: $count';
  }

  @override
  String levelOfEight(int level) {
    return 'Nivel $level de 8';
  }

  @override
  String movesCount(int count) {
    return 'Jugadas: $count';
  }

  @override
  String positionOfTotal(int current, int total) {
    return 'Posición $current de $total';
  }

  @override
  String get tapNoneHint => 'Toca Ninguna si no hay soluciones';

  @override
  String get found => 'Encontradas';

  @override
  String get drillComplete => '¡Ejercicio completo!';

  @override
  String get allClear => '¡Todo limpio!';

  @override
  String get time => 'Tiempo';

  @override
  String get errors => 'Errores';

  @override
  String get rounds => 'Rondas';

  @override
  String solvedCount(int count) {
    return '$count resueltos';
  }

  @override
  String get makeTheMove => 'Haz la jugada';

  @override
  String get castleKingside => 'Enroque corto';

  @override
  String get castleQueenside => 'Enroque largo';

  @override
  String pieceTakesOn(String piece, String square) {
    return '$piece captura en $square';
  }

  @override
  String pieceToSquare(String piece, String square) {
    return '$piece a $square';
  }

  @override
  String get seePositionMakeMove => '¡Ve una posición, haz la jugada!';

  @override
  String get aboutWhatIs => '¿Qué es Calvin Chess Trainer?';

  @override
  String get aboutWhatIsBody =>
      'Una app divertida e interactiva que enseña a los niños los fundamentos del ajedrez. Visión de Ajedrez te entrena para ver de un vistazo horquillas, enfiladas, saltos del caballo, jaques, capturas y piezas colgadas. Notación de Ajedrez te enseña columnas, filas, casillas, letras de las piezas, jugadas y el valor de las piezas. Con el Explorador de Aperturas pruebas aperturas con pistas de un motor de ajedrez de verdad. ¡El audio, las rachas y tus récords guardados te mantienen motivado!';

  @override
  String get aboutTrainingModes => 'Modos de Entrenamiento';

  @override
  String get aboutTrainingModesBody =>
      '• Explorar — aprende a tu ritmo\n• Práctica — ponte a prueba y construye rachas\n• Ronda Rápida — corre contra el reloj (30 o 60 segundos) y bate tu récord\n• Modo Difícil — juega desde el lado de las negras';

  @override
  String get aboutCredits => 'Créditos y Agradecimientos';

  @override
  String get aboutCreditsBody =>
      '• Asesor de ajedrez: Dattasai Kilari\n• Puzzles de ajedrez de la base de datos de Lichess (licencia CC0)\n• Interfaz del tablero por Lichess chessground\n• Lógica de ajedrez por Lichess dartchess\n• Clips de voz por ElevenLabs\n• Creado con Flutter y Dart';

  @override
  String get aboutInspired => 'Inspirado en Rapid Chess Improvement';

  @override
  String get aboutInspiredBody =>
      'Esta app debe mucho al libro de Michael de la Maza Rapid Chess Improvement (Everyman Chess, 2002). Su concepto de \"visión ajedrecística\" — la capacidad de reconocer instantáneamente patrones tácticos y relaciones entre piezas — transformó mi forma de pensar sobre el entrenamiento. Seguir sus ideas me ayudó a mejorar mi propio juego drásticamente, y construí Calvin Chess Trainer con la esperanza de que su enfoque de la visión ajedrecística ayude a una nueva generación de jugadores a ver el tablero con más claridad. ¡Gracias, Michael!';

  @override
  String get aboutInternut => 'Acerca de Internut Education';

  @override
  String get aboutInternutBody =>
      'Internut Education crea apps de aprendizaje atractivas para niños. Creemos que la mejor manera de aprender es a través del juego, la práctica y el refuerzo positivo.';

  @override
  String aboutVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get aboutByInternut => 'por Internut Education';

  @override
  String get aboutFooter =>
      'Hecho con ❤️ para jóvenes ajedrecistas de todo el mundo';

  @override
  String get feedbackTitle => 'Envíanos tu opinión';

  @override
  String get feedbackBody =>
      '¡Siempre buscamos mejorar esta app! Ya sea una idea, un error que encontraste o algo que te encanta — nos encantaría saber de ti.';

  @override
  String get feedbackHint => 'Escribe tu opinión aquí...';

  @override
  String get feedbackSend => 'Enviar opinión';

  @override
  String get feedbackSending => 'Enviando...';

  @override
  String get feedbackThanks => '¡Gracias por tu opinión!';

  @override
  String get feedbackError => 'No se pudo enviar. Inténtalo de nuevo.';

  @override
  String get feedbackEmpty => 'Escribe algo antes de enviar.';

  @override
  String get tacticsTrainer => 'Entrenador de Táctica';

  @override
  String get tacticsComingSoon => 'Entrenador de táctica próximamente';

  @override
  String get promptSquare => 'casilla';

  @override
  String get promptFile => 'columna';

  @override
  String get promptRank => 'fila';

  @override
  String get playTheOpening => '¡Explora aperturas!';

  @override
  String get openingPractice => 'Práctica de Apertura';

  @override
  String get openingChallenge => 'Desafío de Apertura';

  @override
  String get playAs => 'Jugar como';

  @override
  String get playAsWhite => 'Blancas';

  @override
  String get playAsBlack => 'Negras';

  @override
  String get difficulty => 'Dificultad';

  @override
  String get easy => 'Fácil';

  @override
  String get medium => 'Medio';

  @override
  String get hard => 'Difícil';

  @override
  String get challenge => 'Desafío';

  @override
  String get practiceHintsDesc =>
      'Juega con pistas — las 3 mejores jugadas mostradas como flechas';

  @override
  String get challengeDesc =>
      '¡Prueba tus habilidades de apertura — gana medallas!';

  @override
  String get engineThinking => 'El motor está pensando...';

  @override
  String get yourTurn => 'Tu turno';

  @override
  String get gameOver => 'Fin del juego';

  @override
  String youSurvivedMoves(int count) {
    return 'Sobreviviste $count jugada(s)';
  }

  @override
  String get reviewGame => 'Revisar partida';

  @override
  String get openingTip => 'Consejo de apertura';

  @override
  String get gotIt => '¡Entendido!';

  @override
  String get medalBronze => '¡Bronce!';

  @override
  String get medalSilver => '¡Plata!';

  @override
  String get medalGold => '¡Oro!';

  @override
  String get previousMove => 'Jugada anterior';

  @override
  String get nextMove => 'Siguiente jugada';

  @override
  String get done => 'Listo';

  @override
  String get thePieces => 'The Pieces';

  @override
  String get knowYourPieces => 'Know your pieces!';

  @override
  String get tapTheSideWorthMore => 'Toca el lado que vale más';

  @override
  String get whichSideWinsPracticeDesc =>
      'Construye tu racha — ¡la dificultad aumenta sobre la marcha!';

  @override
  String get letters => 'Letras';

  @override
  String get king => 'Rey';

  @override
  String get pawn => 'Peón';

  @override
  String get tapPieceToLearnLetter => '¡Toca una pieza para aprender su letra!';

  @override
  String get whichPieceForLetter => '¿Qué pieza usa esta letra?';

  @override
  String get whichLetterForPiece => '¿Cuál es la letra de esta pieza?';

  @override
  String get tapPieceNoLetter => '¡Toca la pieza SIN letra!';

  @override
  String get noLetter => 'Sin letra';

  @override
  String letterEquals(String letter, String piece) {
    return '¡$letter = $piece!';
  }

  @override
  String get pawnNoLetterFact => '¡Los peones no necesitan letra!';

  @override
  String get mnemonicKing => 'K de King — ¡el Rey en inglés!';

  @override
  String get mnemonicQueen => 'Q de Queen — ¡la Dama en inglés!';

  @override
  String get mnemonicRook => 'R de Rook — ¡la Torre en inglés!';

  @override
  String get mnemonicBishop => 'B de Bishop — ¡el Alfil en inglés!';

  @override
  String get mnemonicKnight => 'N de kNight — ¡el Caballo! La K ya es del Rey.';

  @override
  String get mnemonicPawn =>
      '¡Los peones son tan valientes que no llevan letra!';

  @override
  String get scanDrillChecks => 'Encuentra los jaques';

  @override
  String get scanDrillCaptures => 'Encuentra las capturas';

  @override
  String get scanDrillHanging => 'Piezas colgadas';

  @override
  String get scanDrillMate => 'Mate en 1';

  @override
  String get scanPromptChecks =>
      '¡Toca cada casilla desde la que puedas dar jaque!';

  @override
  String get scanPromptCaptures =>
      '¡Toca cada pieza enemiga que puedas capturar!';

  @override
  String get scanPromptHanging =>
      '¡Toca cada pieza enemiga que no esté defendida!';

  @override
  String get scanPromptMate => '¡Encuentra el jaque mate en una jugada!';

  @override
  String get scanPracticeDesc => 'Sin temporizador: ¡encuéntralas todas!';

  @override
  String get blitz => 'Blitz';

  @override
  String get scanBlitzDesc => '60 segundos: ¿cuántos mates puedes encontrar?';

  @override
  String get whiteToPlay => 'Juegan blancas';

  @override
  String get blackToPlay => 'Juegan negras';

  @override
  String get openingExplorer => 'Explorador de Aperturas';

  @override
  String get startFromOpening => 'Empezar desde una apertura';

  @override
  String get flipBoard => 'Girar tablero';

  @override
  String get showScores => 'Mostrar puntuaciones';

  @override
  String get hideScores => 'Ocultar puntuaciones';

  @override
  String get searchOpenings => 'Buscar aperturas…';

  @override
  String get noOpeningsFound => 'No se encontraron aperturas';

  @override
  String get popularOpenings => 'Populares';

  @override
  String get browseByCategory => 'Explorar por categoría';

  @override
  String get ecoFlankOpenings => 'Aperturas de flanco';

  @override
  String get ecoSemiOpenGames => 'Aperturas semiabiertas';

  @override
  String get ecoOpenGames => 'Aperturas abiertas';

  @override
  String get ecoClosedGames => 'Cerradas y semicerradas';

  @override
  String get ecoIndianDefenses => 'Defensas indias';

  @override
  String get engineUnavailable => 'El motor de ajedrez no se inició.';

  @override
  String get visionPromptForks =>
      '¡Toca cada casilla desde la que tu pieza ataca al rey y a la otra pieza!';

  @override
  String get visionPromptKnightSight =>
      '¡Toca cada casilla a la que puede saltar tu caballo!';

  @override
  String get visionPromptKnightFlight =>
      '¡Lleva tu caballo al anillo en el menor número de saltos posible!';

  @override
  String get visionPromptPawnAttack =>
      '¡Captura todos los peones — nunca te detengas en una casilla sombreada!';

  @override
  String get startOver => 'Empezar de nuevo';

  @override
  String get loadFailed => 'No se pudieron cargar los ejercicios.';

  @override
  String get checkmate => '¡Jaque mate!';

  @override
  String get draw => '¡Tablas!';

  @override
  String get homeWarmupKicker => 'Calentamiento diario · 5 min';

  @override
  String get homeWarmupTitle => 'Entrena lo que los puzzles se saltan';

  @override
  String get homeWarmupBody =>
      'Cinco ejercicios rápidos: jaques, piezas colgadas, horquillas, casillas desde el lado de las negras y un mate en una jugada.';

  @override
  String get homeWarmupStart => 'Comenzar calentamiento';

  @override
  String get homeContinue => 'Continuar';

  @override
  String get homeStartHere => 'Empieza aquí';

  @override
  String homeResume(String drill) {
    return 'Reanudar: $drill';
  }

  @override
  String get homeOpenings => 'Aperturas';

  @override
  String get homeOpeningExplorerDesc =>
      'Recorre aperturas con pistas de Stockfish';

  @override
  String get sectionVision => 'Visión';

  @override
  String get sectionVisionDesc =>
      'Los hábitos de revisar el tablero que casi nadie entrena';

  @override
  String get sectionNotation => 'Notación';

  @override
  String get sectionNotationDesc =>
      'Lee y encuentra casillas y jugadas sin pensar';

  @override
  String sectionAllDrills(int count) {
    return 'Los $count ejercicios';
  }

  @override
  String get navHome => 'Inicio';

  @override
  String drillBest(String value) {
    return 'Mejor $value';
  }

  @override
  String get groupScan => 'Revisa el tablero';

  @override
  String get groupGeometry => 'Geometría';

  @override
  String get groupFinish => 'Remate';

  @override
  String get groupBoard => 'El tablero';

  @override
  String get groupPieces => 'Piezas';

  @override
  String get drillFilesRanks => 'Columnas y filas';

  @override
  String get drillReadMoves => 'Lectura de jugadas';

  @override
  String get drillPieceLetters => 'Letras de las piezas';

  @override
  String get drillPieceValues => 'Valor de las piezas';

  @override
  String get drillDescFindChecks => 'Todos los jaques en una posición real';

  @override
  String get drillDescFindCaptures =>
      'Encuentra todas las capturas del tablero';

  @override
  String get drillDescHanging => 'Detecta todas las piezas sin defensa';

  @override
  String get drillDescForks => 'Casillas con doble ataque';

  @override
  String get drillDescKnightSight => 'Cada casilla que alcanza el caballo';

  @override
  String get drillDescKnightFlight => 'Al objetivo en el mínimo de jugadas';

  @override
  String get drillDescPawnAttack => 'Esquiva una muralla de peones';

  @override
  String get drillDescMate => '400 posiciones, una jugada para el mate';

  @override
  String get drillDescSquares => 'Encuentra la casilla, rápido';

  @override
  String get drillDescFilesRanks => 'Nombra cada columna y fila';

  @override
  String get drillDescReadMoves => 'Lee una jugada y juégala';

  @override
  String get drillDescLetters => 'K, Q, R, B, N de un vistazo';

  @override
  String get drillDescValues => '¿Qué lado sale ganando?';

  @override
  String get setupYourPiece => 'Tu pieza';

  @override
  String get setupForkTarget => 'Horquilla de rey y…';

  @override
  String get setupMode => 'Modo';

  @override
  String get setupBoardSide => 'Lado del tablero';

  @override
  String get setupLines => 'Líneas';

  @override
  String get setupYourBest => 'Tu récord';

  @override
  String get setupNoBest => 'Aún sin récord';

  @override
  String get setupKnightPracticeOnly => 'Sin temporizador. Tómate tu tiempo.';

  @override
  String warmupStep(int current, int total) {
    return 'Calentamiento · $current de $total';
  }

  @override
  String warmupNext(String drill) {
    return 'Siguiente: $drill';
  }

  @override
  String get warmupFinish => 'Finalizar calentamiento';

  @override
  String get warmupEnd => 'Salir del calentamiento';

  @override
  String get warmupDoneTitle => 'Calentamiento completado';

  @override
  String get warmupDoneBody =>
      'Cinco ejercicios hechos. ¿Mañana a la misma hora?';

  @override
  String get resultsMissed => 'Falladas';

  @override
  String get endDrill => 'Salir del ejercicio';

  @override
  String get promptTitleChecks => 'Encuentra todos los jaques';

  @override
  String get promptTitleCaptures => 'Encuentra todas las capturas';

  @override
  String get promptTitleHanging => 'Encuentra todas las piezas colgadas';

  @override
  String get promptTitleForks => 'Encuentra todas las horquillas';

  @override
  String get promptTitleKnightSight => 'Todos los saltos del caballo';

  @override
  String get promptTitleKnightFlight => 'Llega al anillo';

  @override
  String get promptTitlePawnAttack => 'Captura todos los peones';

  @override
  String get promptTitleMate => 'Jaque mate en una jugada';
}
