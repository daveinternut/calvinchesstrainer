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
  String get calvinChessTrainer => 'Calvin Chess\nTrainer';

  @override
  String get masterTheFundamentals => 'Domine os fundamentos!';

  @override
  String get chessNotation => 'Notação de Xadrez';

  @override
  String get learnTheBoard => 'Aprenda o tabuleiro!';

  @override
  String get chessVision => 'Visão de Xadrez';

  @override
  String get seeTheBoard => 'Veja o tabuleiro!';

  @override
  String get comingSoon => 'EM BREVE';

  @override
  String get start => 'Começar';

  @override
  String get menu => 'Menu';

  @override
  String get playAgain => 'Jogar novamente';

  @override
  String get newRecord => 'Novo recorde!';

  @override
  String get whatToPractice => 'O que praticar?';

  @override
  String get chooseAMode => 'Escolha um modo';

  @override
  String get files => 'Colunas';

  @override
  String get ranks => 'Fileiras';

  @override
  String get squares => 'Casas';

  @override
  String get moves => 'Lances';

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
  String get hardMode => 'MODO DIFÍCIL';

  @override
  String get hardModeBlack => 'Jogador controla as pretas!';

  @override
  String get hardModeFlipped => 'Tabuleiro invertido — perspectiva das pretas!';

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
  String get drillType => 'Tipo de exercício';

  @override
  String get forksAndSkewers => 'Garfos e Espetos';

  @override
  String get pawnAttack => 'Ataque de Peão';

  @override
  String get knightSight => 'Visão do Cavalo';

  @override
  String get knightFlight => 'Voo do Cavalo';

  @override
  String get chooseYourPiece => 'Escolha sua peça';

  @override
  String get targetPiece => 'Peça alvo';

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
  String get concentricDrill => 'Exercício Concêntrico';

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
  String foundOfTotal(int found, int total) {
    return '$found de $total';
  }

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
  String titleForksAndSkewers(String piece, String mode) {
    return '$piece — $mode';
  }

  @override
  String titlePawnAttack(String piece, String mode) {
    return 'Ataque de Peão — $piece $mode';
  }

  @override
  String titleMovesGame(String mode) {
    return 'Lances - $mode';
  }

  @override
  String titleFileRankGame(String subject, String mode) {
    return '$subject - $mode';
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
      'Um aplicativo divertido e interativo que ensina os fundamentos do xadrez para crianças. Aprenda colunas, fileiras, casas e movimentos de peças através de exercícios, quizzes e desafios cronometrados — tudo com feedback de áudio e acompanhamento de sequências para te manter motivado!';

  @override
  String get aboutTrainingModes => 'Modos de Treinamento';

  @override
  String get aboutTrainingModesBody =>
      '• Explorar — aprenda no seu ritmo\n• Prática — teste-se e construa sequências\n• Rodada Rápida — 30 segundos, quantos você consegue?\n• Modo Difícil — esconda as coordenadas para um verdadeiro desafio';

  @override
  String get aboutCredits => 'Créditos e Agradecimentos';

  @override
  String get aboutCreditsBody =>
      '• Puzzles de xadrez do banco de dados Lichess (licença CC0)\n• Interface do tabuleiro por Lichess chessground\n• Lógica de xadrez por Lichess dartchess\n• Clipes de voz por ElevenLabs\n• Desenvolvido com Flutter e Dart';

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
  String get squareTrainer => 'Treinador de Casas';

  @override
  String get squareComingSoon => 'Treinador de casas em breve';

  @override
  String get moveTrainer => 'Treinador de Lances';

  @override
  String get moveComingSoon => 'Treinador de lances em breve';

  @override
  String get promptSquare => 'casa';

  @override
  String get promptFile => 'coluna';

  @override
  String get promptRank => 'fileira';
}
