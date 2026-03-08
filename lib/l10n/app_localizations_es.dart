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
  String get calvinChessTrainer => 'Calvin Chess\nTrainer';

  @override
  String get masterTheFundamentals => '¡Domina los fundamentos!';

  @override
  String get chessNotation => 'Notación de Ajedrez';

  @override
  String get learnTheBoard => '¡Aprende el tablero!';

  @override
  String get chessVision => 'Visión de Ajedrez';

  @override
  String get seeTheBoard => '¡Ve el tablero!';

  @override
  String get comingSoon => 'PRÓXIMAMENTE';

  @override
  String get start => 'Comenzar';

  @override
  String get menu => 'Menú';

  @override
  String get playAgain => 'Jugar de nuevo';

  @override
  String get newRecord => '¡Nuevo récord!';

  @override
  String get whatToPractice => '¿Qué practicar?';

  @override
  String get chooseAMode => 'Elige un modo';

  @override
  String get files => 'Columnas';

  @override
  String get ranks => 'Filas';

  @override
  String get squares => 'Casillas';

  @override
  String get moves => 'Jugadas';

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
  String get hardMode => 'MODO DIFÍCIL';

  @override
  String get hardModeBlack => '¡El usuario juega con negras!';

  @override
  String get hardModeFlipped =>
      '¡Tablero invertido — perspectiva de las negras!';

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
  String get drillType => 'Tipo de ejercicio';

  @override
  String get forksAndSkewers => 'Horquillas y Enfiladas';

  @override
  String get pawnAttack => 'Ataque de Peón';

  @override
  String get knightSight => 'Visión del Caballo';

  @override
  String get knightFlight => 'Vuelo del Caballo';

  @override
  String get chooseYourPiece => 'Elige tu pieza';

  @override
  String get targetPiece => 'Pieza objetivo';

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
  String get concentricDrill => 'Ejercicio Concéntrico';

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
  String foundOfTotal(int found, int total) {
    return '$found de $total';
  }

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
  String titleForksAndSkewers(String piece, String mode) {
    return '$piece — $mode';
  }

  @override
  String titlePawnAttack(String piece, String mode) {
    return 'Ataque de Peón — $piece $mode';
  }

  @override
  String titleMovesGame(String mode) {
    return 'Jugadas - $mode';
  }

  @override
  String titleFileRankGame(String subject, String mode) {
    return '$subject - $mode';
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
      'Una app divertida e interactiva que enseña los fundamentos del ajedrez a los niños. Aprende columnas, filas, casillas y movimientos de piezas a través de ejercicios, cuestionarios y desafíos cronometrados — ¡todo con retroalimentación de audio y seguimiento de rachas para mantenerte motivado!';

  @override
  String get aboutTrainingModes => 'Modos de Entrenamiento';

  @override
  String get aboutTrainingModesBody =>
      '• Explorar — aprende a tu ritmo\n• Práctica — ponte a prueba y construye rachas\n• Ronda Rápida — 30 segundos, ¿cuántos puedes resolver?\n• Modo Difícil — oculta las coordenadas para un verdadero desafío';

  @override
  String get aboutCredits => 'Créditos y Agradecimientos';

  @override
  String get aboutCreditsBody =>
      '• Puzzles de ajedrez de la base de datos de Lichess (licencia CC0)\n• Interfaz del tablero por Lichess chessground\n• Lógica de ajedrez por Lichess dartchess\n• Clips de voz por ElevenLabs\n• Creado con Flutter y Dart';

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
  String get squareTrainer => 'Entrenador de Casillas';

  @override
  String get squareComingSoon => 'Entrenador de casillas próximamente';

  @override
  String get moveTrainer => 'Entrenador de Jugadas';

  @override
  String get moveComingSoon => 'Entrenador de jugadas próximamente';

  @override
  String get promptSquare => 'casilla';

  @override
  String get promptFile => 'columna';

  @override
  String get promptRank => 'fila';
}
