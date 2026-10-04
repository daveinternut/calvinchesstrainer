// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Calvin Chess Trainer';

  @override
  String get about => 'Sobre';

  @override
  String get learnTheBoard => 'Aprenda o tabuleiro!';

  @override
  String get comingSoon => 'EM BREVE';

  @override
  String get start => 'Começar';

  @override
  String get playAgain => 'Jogar novamente';

  @override
  String get newRecord => 'Novo recorde!';

  @override
  String get files => 'Colunas';

  @override
  String get ranks => 'Fileiras';

  @override
  String get squares => 'Casas';

  @override
  String get moves => 'Lances';

  @override
  String get pieceValue => 'Valor das peças';

  @override
  String get explore => 'Explorar';

  @override
  String get exploreDesc => 'Toque para aprender — sem pressão, sem pontuação';

  @override
  String get practice => 'Prática';

  @override
  String get practiceDesc => 'Teste-se — construa sua sequência!';

  @override
  String get speedRound => 'Rodada Rápida';

  @override
  String get speedRoundDesc => '30 segundos — quantos você consegue?';

  @override
  String get timesUp => 'Tempo esgotado!';

  @override
  String get correct => 'Corretas';

  @override
  String get accuracy => 'Precisão';

  @override
  String get bestStreak => 'Melhor sequência';

  @override
  String bestLabel(int value) {
    return 'Melhor: $value';
  }

  @override
  String get tapFileToHear => 'Toque em qualquer coluna para ouvir seu nome';

  @override
  String get tapRankToHear => 'Toque em qualquer fileira para ouvir seu nome';

  @override
  String get tapSquareToHear => 'Toque em qualquer casa para ouvir seu nome';

  @override
  String get tapFile => 'Toque na coluna';

  @override
  String get tapRank => 'Toque na fileira';

  @override
  String get tapSquare => 'Toque na casa';

  @override
  String get milestoneNice => 'Legal!';

  @override
  String get milestoneAmazing => 'Incrível!';

  @override
  String get milestoneIncredible => 'Fenomenal!';

  @override
  String get milestoneUnstoppable => 'Imparável!';

  @override
  String get milestoneLegendary => 'Lendário!';

  @override
  String get milestoneGreat => 'Ótimo!';

  @override
  String streakMilestone(int count) {
    return '$count seguidos!';
  }

  @override
  String get hurry => 'Rápido!';

  @override
  String get forksAndSkewers => 'Garfos e Espetos';

  @override
  String get pawnAttack => 'Ataque de Peão';

  @override
  String get knightSight => 'Visão do Cavalo';

  @override
  String get knightFlight => 'Voo do Cavalo';

  @override
  String get queen => 'Dama';

  @override
  String get rook => 'Torre';

  @override
  String get bishop => 'Bispo';

  @override
  String get knight => 'Cavalo';

  @override
  String get findForksNoTimer => 'Encontre garfos e espetos — sem tempo';

  @override
  String get speedRound60Desc => '60 segundos — resolva o máximo que puder!';

  @override
  String get concentricDrillDesc =>
      'Complete todas as posições — supere seu tempo!';

  @override
  String get captureAllPawnsNoTimer => 'Capture todos os peões — sem tempo';

  @override
  String get timed => 'Cronometrado';

  @override
  String get timedPawnAttackDesc => 'Elimine 3 a 8 peões — supere seu tempo!';

  @override
  String get concentric => 'Concêntrico';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get skip => 'Pular';

  @override
  String get none => 'Nenhuma';

  @override
  String minimumMoves(int count) {
    return 'Mínimo: $count';
  }

  @override
  String yourMoves(int count) {
    return 'Seus lances: $count';
  }

  @override
  String pawnsRemaining(int count) {
    return 'Peões: $count';
  }

  @override
  String levelOfEight(int level) {
    return 'Nível $level de 8';
  }

  @override
  String movesCount(int count) {
    return 'Lances: $count';
  }

  @override
  String positionOfTotal(int current, int total) {
    return 'Posição $current de $total';
  }

  @override
  String get tapNoneHint => 'Toque em Nenhuma se não houver soluções';

  @override
  String get found => 'Encontradas';

  @override
  String get drillComplete => 'Exercício completo!';

  @override
  String get allClear => 'Tudo resolvido!';

  @override
  String get time => 'Tempo';

  @override
  String get errors => 'Erros';

  @override
  String get rounds => 'Rodadas';

  @override
  String solvedCount(int count) {
    return '$count resolvidos';
  }

  @override
  String get makeTheMove => 'Faça o lance';

  @override
  String get castleKingside => 'Roque menor';

  @override
  String get castleQueenside => 'Roque maior';

  @override
  String pieceTakesOn(String piece, String square) {
    return '$piece captura em $square';
  }

  @override
  String pieceToSquare(String piece, String square) {
    return '$piece para $square';
  }

  @override
  String get seePositionMakeMove => 'Veja uma posição, faça o lance!';

  @override
  String get aboutWhatIs => 'O que é Calvin Chess Trainer?';

  @override
  String get aboutWhatIsBody =>
      'Um app divertido e interativo que ensina às crianças os fundamentos do xadrez. A Visão de Xadrez treina você a enxergar num relance garfos, espetos, saltos do cavalo, xeques, capturas e peças desprotegidas. A Notação de Xadrez ensina colunas, fileiras, casas, letras das peças, lances e o valor das peças. No Explorador de Aberturas você experimenta aberturas com dicas de um motor de xadrez de verdade. Som, sequências e recordes salvos mantêm você motivado!';

  @override
  String get aboutTrainingModes => 'Modos de Treinamento';

  @override
  String get aboutTrainingModesBody =>
      '• Explorar — aprenda no seu ritmo\n• Prática — teste-se e construa sequências\n• Rodada Rápida — corra contra o relógio (30 ou 60 segundos) e bata seu recorde\n• Modo Difícil — jogue do lado das pretas';

  @override
  String get aboutCredits => 'Créditos e Agradecimentos';

  @override
  String get aboutCreditsBody =>
      '• Consultor de xadrez: Dattasai Kilari\n• Puzzles de xadrez do banco de dados Lichess (licença CC0)\n• Interface do tabuleiro por Lichess chessground\n• Lógica de xadrez por Lichess dartchess\n• Clipes de voz por ElevenLabs\n• Desenvolvido com Flutter e Dart';

  @override
  String get aboutInspired => 'Inspirado em Rapid Chess Improvement';

  @override
  String get aboutInspiredBody =>
      'Este aplicativo deve muito ao livro de Michael de la Maza Rapid Chess Improvement (Everyman Chess, 2002). Seu conceito de \"visão enxadrística\" — a capacidade de reconhecer instantaneamente padrões táticos e relações entre peças — transformou minha forma de pensar sobre treinamento. Seguir suas ideias me ajudou a melhorar meu próprio jogo dramaticamente, e criei o Calvin Chess Trainer na esperança de que sua abordagem de visão enxadrística ajude uma nova geração de jogadores a ver o tabuleiro com mais clareza. Obrigado, Michael!';

  @override
  String get aboutInternut => 'Sobre a Internut Education';

  @override
  String get aboutInternutBody =>
      'A Internut Education cria aplicativos de aprendizagem envolventes para crianças. Acreditamos que a melhor forma de aprender é através do jogo, da prática e do reforço positivo.';

  @override
  String aboutVersion(String version) {
    return 'Versão $version';
  }

  @override
  String get aboutByInternut => 'por Internut Education';

  @override
  String get aboutFooter =>
      'Feito com ❤️ para jovens enxadristas de todo o mundo';

  @override
  String get feedbackTitle => 'Envie-nos seu feedback';

  @override
  String get feedbackBody =>
      'Estamos sempre buscando melhorar este app! Seja uma ideia, um bug ou algo que você adora — adoraríamos ouvir de você.';

  @override
  String get feedbackHint => 'Escreva seu feedback aqui...';

  @override
  String get feedbackSend => 'Enviar feedback';

  @override
  String get feedbackSending => 'Enviando...';

  @override
  String get feedbackThanks => 'Obrigado pelo seu feedback!';

  @override
  String get feedbackError => 'Não foi possível enviar. Tente novamente.';

  @override
  String get feedbackEmpty => 'Escreva algo antes de enviar.';

  @override
  String get tacticsTrainer => 'Treinador de Tática';

  @override
  String get tacticsComingSoon => 'Treinador de tática em breve';

  @override
  String get promptSquare => 'casa';

  @override
  String get promptFile => 'coluna';

  @override
  String get promptRank => 'fileira';

  @override
  String get playTheOpening => 'Explore aberturas!';

  @override
  String get openingPractice => 'Prática de Abertura';

  @override
  String get openingChallenge => 'Desafio de Abertura';

  @override
  String get playAs => 'Jogar como';

  @override
  String get playAsWhite => 'Brancas';

  @override
  String get playAsBlack => 'Pretas';

  @override
  String get difficulty => 'Dificuldade';

  @override
  String get easy => 'Fácil';

  @override
  String get medium => 'Médio';

  @override
  String get hard => 'Difícil';

  @override
  String get challenge => 'Desafio';

  @override
  String get practiceHintsDesc =>
      'Jogue com dicas — as 3 melhores jogadas mostradas como setas';

  @override
  String get challengeDesc =>
      'Teste suas habilidades de abertura — ganhe medalhas!';

  @override
  String get engineThinking => 'Motor analisando...';

  @override
  String get yourTurn => 'Sua vez';

  @override
  String get gameOver => 'Fim de jogo';

  @override
  String youSurvivedMoves(int count) {
    return 'Você sobreviveu $count lance(s)';
  }

  @override
  String get reviewGame => 'Revisar partida';

  @override
  String get openingTip => 'Dica de abertura';

  @override
  String get gotIt => 'Entendi!';

  @override
  String get medalBronze => 'Bronze!';

  @override
  String get medalSilver => 'Prata!';

  @override
  String get medalGold => 'Ouro!';

  @override
  String get previousMove => 'Lance anterior';

  @override
  String get nextMove => 'Próximo lance';

  @override
  String get done => 'Concluído';

  @override
  String get thePieces => 'The Pieces';

  @override
  String get knowYourPieces => 'Know your pieces!';

  @override
  String get tapTheSideWorthMore => 'Toque no lado que vale mais';

  @override
  String get whichSideWinsPracticeDesc =>
      'Construa sua sequência — a dificuldade aumenta conforme você avança!';

  @override
  String get letters => 'Letras';

  @override
  String get king => 'Rei';

  @override
  String get pawn => 'Peão';

  @override
  String get tapPieceToLearnLetter =>
      'Toque em uma peça para aprender sua letra!';

  @override
  String get whichPieceForLetter => 'Qual peça usa esta letra?';

  @override
  String get whichLetterForPiece => 'Qual é a letra desta peça?';

  @override
  String get tapPieceNoLetter => 'Toque na peça SEM letra!';

  @override
  String get noLetter => 'Sem letra';

  @override
  String letterEquals(String letter, String piece) {
    return '$letter = $piece!';
  }

  @override
  String get pawnNoLetterFact => 'Os peões não precisam de letra!';

  @override
  String get mnemonicKing => 'K de King — o Rei em inglês!';

  @override
  String get mnemonicQueen => 'Q de Queen — a Dama em inglês!';

  @override
  String get mnemonicRook => 'R de Rook — a Torre em inglês!';

  @override
  String get mnemonicBishop => 'B de Bishop — o Bispo em inglês!';

  @override
  String get mnemonicKnight => 'N de kNight — o Cavalo! O K já é do Rei.';

  @override
  String get mnemonicPawn =>
      'Os peões são tão corajosos que não precisam de letra!';

  @override
  String get scanDrillChecks => 'Encontre os xeques';

  @override
  String get scanDrillCaptures => 'Encontre as capturas';

  @override
  String get scanDrillHanging => 'Peças penduradas';

  @override
  String get scanDrillMate => 'Mate em 1';

  @override
  String get scanPromptChecks =>
      'Toque em cada casa de onde você pode dar xeque!';

  @override
  String get scanPromptCaptures =>
      'Toque em cada peça inimiga que você pode capturar!';

  @override
  String get scanPromptHanging =>
      'Toque em cada peça inimiga que não está defendida!';

  @override
  String get scanPromptMate => 'Encontre o xeque-mate em um lance!';

  @override
  String get scanPracticeDesc => 'Sem cronômetro — encontre todas!';

  @override
  String get blitz => 'Blitz';

  @override
  String get scanBlitzDesc =>
      '60 segundos — quantos mates você consegue encontrar?';

  @override
  String get whiteToPlay => 'Brancas jogam';

  @override
  String get blackToPlay => 'Pretas jogam';

  @override
  String get openingExplorer => 'Explorador de Aberturas';

  @override
  String get startFromOpening => 'Começar de uma abertura';

  @override
  String get flipBoard => 'Girar tabuleiro';

  @override
  String get showScores => 'Mostrar pontuações';

  @override
  String get hideScores => 'Ocultar pontuações';

  @override
  String get searchOpenings => 'Buscar aberturas…';

  @override
  String get noOpeningsFound => 'Nenhuma abertura encontrada';

  @override
  String get popularOpenings => 'Populares';

  @override
  String get browseByCategory => 'Navegar por categoria';

  @override
  String get ecoFlankOpenings => 'Aberturas de flanco';

  @override
  String get ecoSemiOpenGames => 'Aberturas semiabertas';

  @override
  String get ecoOpenGames => 'Aberturas abertas';

  @override
  String get ecoClosedGames => 'Fechadas e semifechadas';

  @override
  String get ecoIndianDefenses => 'Defesas índias';

  @override
  String get engineUnavailable => 'O motor de xadrez não iniciou.';

  @override
  String get visionPromptForks =>
      'Toque em cada casa de onde sua peça ataca o rei e a outra peça!';

  @override
  String get visionPromptKnightSight =>
      'Toque em cada casa para onde seu cavalo pode pular!';

  @override
  String get visionPromptKnightFlight =>
      'Leve seu cavalo até o anel com o menor número de lances possível!';

  @override
  String get visionPromptPawnAttack =>
      'Capture todos os peões — nunca pare numa casa sombreada!';

  @override
  String get startOver => 'Recomeçar';

  @override
  String get loadFailed => 'Não foi possível carregar os exercícios.';

  @override
  String get checkmate => 'Xeque-mate!';

  @override
  String get draw => 'Empate!';

  @override
  String get homeWarmupKicker => 'Aquecimento diário · 5 min';

  @override
  String get homeWarmupTitle => 'Treine o que os puzzles deixam de fora';

  @override
  String get homeWarmupBody =>
      'Cinco exercícios rápidos: xeques, peças soltas, garfos, casas do lado das pretas e um mate em um lance.';

  @override
  String get homeWarmupStart => 'Começar aquecimento';

  @override
  String get homeContinue => 'Continuar';

  @override
  String get homeStartHere => 'Comece aqui';

  @override
  String homeResume(String drill) {
    return 'Retomar: $drill';
  }

  @override
  String get homeOpenings => 'Aberturas';

  @override
  String get homeOpeningExplorerDesc =>
      'Jogue aberturas com dicas do Stockfish';

  @override
  String get sectionVision => 'Visão';

  @override
  String get sectionVisionDesc =>
      'Os hábitos de examinar o tabuleiro que quase ninguém treina';

  @override
  String get sectionNotation => 'Notação';

  @override
  String get sectionNotationDesc => 'Leia e encontre casas e lances sem pensar';

  @override
  String sectionAllDrills(int count) {
    return 'Todos os $count exercícios';
  }

  @override
  String get navHome => 'Início';

  @override
  String drillBest(String value) {
    return 'Melhor $value';
  }

  @override
  String get groupScan => 'Examine o tabuleiro';

  @override
  String get groupGeometry => 'Geometria';

  @override
  String get groupFinish => 'Finalização';

  @override
  String get groupBoard => 'O tabuleiro';

  @override
  String get groupPieces => 'Peças';

  @override
  String get drillFilesRanks => 'Colunas e fileiras';

  @override
  String get drillReadMoves => 'Leitura de lances';

  @override
  String get drillPieceLetters => 'Letras das peças';

  @override
  String get drillPieceValues => 'Valor das peças';

  @override
  String get drillDescFindChecks => 'Todos os xeques numa posição real';

  @override
  String get drillDescFindCaptures => 'Encontre todas as capturas no tabuleiro';

  @override
  String get drillDescHanging => 'Identifique cada peça sem defesa';

  @override
  String get drillDescForks => 'Casas de ataque duplo';

  @override
  String get drillDescKnightSight => 'Cada casa que o cavalo alcança';

  @override
  String get drillDescKnightFlight => 'O mínimo de lances até o alvo';

  @override
  String get drillDescPawnAttack => 'Atravesse uma muralha de peões';

  @override
  String get drillDescMate => '400 posições, um lance para o mate';

  @override
  String get drillDescSquares => 'Encontre a casa, rápido';

  @override
  String get drillDescFilesRanks => 'Nomeie cada coluna e fileira';

  @override
  String get drillDescReadMoves => 'Leia um lance e depois jogue-o';

  @override
  String get drillDescLetters => 'K, Q, R, B, N num relance';

  @override
  String get drillDescValues => 'Qual lado sai na frente?';

  @override
  String get setupYourPiece => 'Sua peça';

  @override
  String get setupForkTarget => 'Garfo no rei e…';

  @override
  String get setupMode => 'Modo';

  @override
  String get setupBoardSide => 'Lado do tabuleiro';

  @override
  String get setupLines => 'Linhas';

  @override
  String get setupYourBest => 'Seu recorde';

  @override
  String get setupNoBest => 'Ainda sem recorde';

  @override
  String get setupKnightPracticeOnly => 'Sem cronômetro. Sem pressa.';

  @override
  String warmupStep(int current, int total) {
    return 'Aquecimento · $current de $total';
  }

  @override
  String warmupNext(String drill) {
    return 'Próximo: $drill';
  }

  @override
  String get warmupFinish => 'Concluir aquecimento';

  @override
  String get warmupEnd => 'Sair do aquecimento';

  @override
  String get warmupDoneTitle => 'Aquecimento concluído';

  @override
  String get warmupDoneBody =>
      'Cinco exercícios feitos. Amanhã no mesmo horário?';

  @override
  String get resultsMissed => 'Perdidas';

  @override
  String get endDrill => 'Sair do exercício';

  @override
  String get promptTitleChecks => 'Encontre todos os xeques';

  @override
  String get promptTitleCaptures => 'Encontre todas as capturas';

  @override
  String get promptTitleHanging => 'Encontre todas as peças soltas';

  @override
  String get promptTitleForks => 'Encontre todos os garfos';

  @override
  String get promptTitleKnightSight => 'Todos os saltos do cavalo';

  @override
  String get promptTitleKnightFlight => 'Chegue ao anel';

  @override
  String get promptTitlePawnAttack => 'Capture todos os peões';

  @override
  String get promptTitleMate => 'Xeque-mate em um lance';
}
