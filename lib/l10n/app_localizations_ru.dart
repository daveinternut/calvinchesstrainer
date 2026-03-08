// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Calvin Chess Trainer';

  @override
  String get about => 'О приложении';

  @override
  String get calvinChessTrainer => 'Calvin Chess\nTrainer';

  @override
  String get masterTheFundamentals => 'Освой основы!';

  @override
  String get chessNotation => 'Шахматная нотация';

  @override
  String get learnTheBoard => 'Изучи доску!';

  @override
  String get chessVision => 'Шахматное зрение';

  @override
  String get seeTheBoard => 'Смотри на доску!';

  @override
  String get comingSoon => 'СКОРО';

  @override
  String get start => 'Начать';

  @override
  String get menu => 'Меню';

  @override
  String get playAgain => 'Играть снова';

  @override
  String get newRecord => 'Новый рекорд!';

  @override
  String get whatToPractice => 'Что тренировать?';

  @override
  String get chooseAMode => 'Выбери режим';

  @override
  String get files => 'Вертикали';

  @override
  String get ranks => 'Горизонтали';

  @override
  String get squares => 'Поля';

  @override
  String get moves => 'Ходы';

  @override
  String get explore => 'Изучение';

  @override
  String get exploreDesc => 'Нажимай для изучения — без давления, без очков';

  @override
  String get practice => 'Практика';

  @override
  String get practiceDesc => 'Проверь себя — набирай серию!';

  @override
  String get speedRound => 'Блиц-раунд';

  @override
  String get speedRoundDesc => '30 секунд — сколько решишь?';

  @override
  String get hardMode => 'СЛОЖНЫЙ РЕЖИМ';

  @override
  String get hardModeBlack => 'Игрок за чёрных!';

  @override
  String get hardModeFlipped => 'Доска перевёрнута — вид со стороны чёрных!';

  @override
  String get timesUp => 'Время вышло!';

  @override
  String get correct => 'Правильно';

  @override
  String get accuracy => 'Точность';

  @override
  String get bestStreak => 'Лучшая серия';

  @override
  String bestLabel(int value) {
    return 'Лучшая: $value';
  }

  @override
  String get tapFileToHear => 'Нажми на вертикаль, чтобы услышать её название';

  @override
  String get tapRankToHear =>
      'Нажми на горизонталь, чтобы услышать её название';

  @override
  String get tapSquareToHear => 'Нажми на поле, чтобы услышать его название';

  @override
  String get tapFile => 'Нажми вертикаль';

  @override
  String get tapRank => 'Нажми горизонталь';

  @override
  String get tapSquare => 'Нажми поле';

  @override
  String get milestoneNice => 'Отлично!';

  @override
  String get milestoneAmazing => 'Потрясающе!';

  @override
  String get milestoneIncredible => 'Невероятно!';

  @override
  String get milestoneUnstoppable => 'Не остановить!';

  @override
  String get milestoneLegendary => 'Легендарно!';

  @override
  String get milestoneGreat => 'Здорово!';

  @override
  String streakMilestone(int count) {
    return '$count подряд!';
  }

  @override
  String get hurry => 'Быстрее!';

  @override
  String get drillType => 'Тип упражнения';

  @override
  String get forksAndSkewers => 'Вилки и линейные удары';

  @override
  String get pawnAttack => 'Атака пешкой';

  @override
  String get knightSight => 'Зрение коня';

  @override
  String get knightFlight => 'Полёт коня';

  @override
  String get chooseYourPiece => 'Выбери фигуру';

  @override
  String get targetPiece => 'Целевая фигура';

  @override
  String get queen => 'Ферзь';

  @override
  String get rook => 'Ладья';

  @override
  String get bishop => 'Слон';

  @override
  String get knight => 'Конь';

  @override
  String get findForksNoTimer =>
      'Найди вилки и линейные удары — без ограничения времени';

  @override
  String get speedRound60Desc => '60 секунд — реши как можно больше!';

  @override
  String get concentricDrill => 'Концентрическое упражнение';

  @override
  String get concentricDrillDesc => 'Пройди все позиции — побей своё время!';

  @override
  String get captureAllPawnsNoTimer =>
      'Забери все пешки — без ограничения времени';

  @override
  String get timed => 'На время';

  @override
  String get timedPawnAttackDesc => 'Убери от 3 до 8 пешек — побей своё время!';

  @override
  String get concentric => 'Концентрическое';

  @override
  String get retry => 'Повтор';

  @override
  String get skip => 'Пропустить';

  @override
  String get none => 'Нет';

  @override
  String minimumMoves(int count) {
    return 'Минимум: $count';
  }

  @override
  String yourMoves(int count) {
    return 'Твои ходы: $count';
  }

  @override
  String pawnsRemaining(int count) {
    return 'Пешки: $count';
  }

  @override
  String levelOfEight(int level) {
    return 'Уровень $level из 8';
  }

  @override
  String movesCount(int count) {
    return 'Ходы: $count';
  }

  @override
  String positionOfTotal(int current, int total) {
    return 'Позиция $current из $total';
  }

  @override
  String get tapNoneHint => 'Нажми «Нет», если решений нет';

  @override
  String get found => 'Найдено';

  @override
  String foundOfTotal(int found, int total) {
    return '$found из $total';
  }

  @override
  String get drillComplete => 'Упражнение завершено!';

  @override
  String get allClear => 'Всё решено!';

  @override
  String get time => 'Время';

  @override
  String get errors => 'Ошибки';

  @override
  String get rounds => 'Раунды';

  @override
  String solvedCount(int count) {
    return '$count решено';
  }

  @override
  String titleForksAndSkewers(String piece, String mode) {
    return '$piece — $mode';
  }

  @override
  String titlePawnAttack(String piece, String mode) {
    return 'Атака пешкой — $piece $mode';
  }

  @override
  String titleMovesGame(String mode) {
    return 'Ходы - $mode';
  }

  @override
  String titleFileRankGame(String subject, String mode) {
    return '$subject - $mode';
  }

  @override
  String get makeTheMove => 'Сделай ход';

  @override
  String get castleKingside => 'Короткая рокировка';

  @override
  String get castleQueenside => 'Длинная рокировка';

  @override
  String pieceTakesOn(String piece, String square) {
    return '$piece берёт на $square';
  }

  @override
  String pieceToSquare(String piece, String square) {
    return '$piece на $square';
  }

  @override
  String get seePositionMakeMove => 'Смотри позицию, делай ход!';

  @override
  String get aboutWhatIs => 'Что такое Calvin Chess Trainer?';

  @override
  String get aboutWhatIsBody =>
      'Весёлое интерактивное приложение для обучения детей основам шахмат. Изучай вертикали, горизонтали, поля и ходы фигур через упражнения, тесты и задания на время — всё с аудио-подсказками и подсчётом серий для мотивации!';

  @override
  String get aboutTrainingModes => 'Режимы тренировки';

  @override
  String get aboutTrainingModesBody =>
      '• Изучение — учись в своём темпе\n• Практика — проверяй себя и набирай серии\n• Блиц-раунд — 30 секунд, сколько решишь?\n• Сложный режим — скрой координаты для настоящего вызова';

  @override
  String get aboutCredits => 'Благодарности';

  @override
  String get aboutCreditsBody =>
      '• Шахматные задачи из базы Lichess (лицензия CC0)\n• Интерфейс доски: Lichess chessground\n• Шахматная логика: Lichess dartchess\n• Голосовые клипы: ElevenLabs\n• Разработано на Flutter и Dart';

  @override
  String get aboutInspired => 'Вдохновлено книгой Rapid Chess Improvement';

  @override
  String get aboutInspiredBody =>
      'Это приложение многим обязано книге Майкла де ла Маза Rapid Chess Improvement (Everyman Chess, 2002). Его концепция «шахматного зрения» — способности мгновенно распознавать тактические паттерны и связи между фигурами — изменила мой подход к тренировкам. Следуя его идеям, я кардинально улучшил свою игру, и создал Calvin Chess Trainer в надежде, что его подход к шахматному зрению поможет новому поколению игроков яснее видеть доску. Спасибо, Майкл!';

  @override
  String get aboutInternut => 'Об Internut Education';

  @override
  String get aboutInternutBody =>
      'Internut Education создаёт увлекательные обучающие приложения для детей. Мы верим, что лучший способ учиться — через игру, практику и позитивное подкрепление.';

  @override
  String aboutVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get aboutByInternut => 'от Internut Education';

  @override
  String get aboutFooter => 'Сделано с ❤️ для юных шахматистов всего мира';

  @override
  String get feedbackTitle => 'Отправьте нам отзыв';

  @override
  String get feedbackBody =>
      'Мы всегда стремимся улучшить это приложение! Будь то идея, найденная ошибка или то, что вам нравится — мы будем рады вашему мнению.';

  @override
  String get feedbackHint => 'Напишите ваш отзыв здесь...';

  @override
  String get feedbackSend => 'Отправить отзыв';

  @override
  String get feedbackSending => 'Отправка...';

  @override
  String get feedbackThanks => 'Спасибо за ваш отзыв!';

  @override
  String get feedbackError => 'Не удалось отправить. Попробуйте ещё раз.';

  @override
  String get feedbackEmpty => 'Напишите что-нибудь перед отправкой.';

  @override
  String get tacticsTrainer => 'Тренажёр тактики';

  @override
  String get tacticsComingSoon => 'Тренажёр тактики скоро появится';

  @override
  String get squareTrainer => 'Тренажёр полей';

  @override
  String get squareComingSoon => 'Тренажёр полей скоро появится';

  @override
  String get moveTrainer => 'Тренажёр ходов';

  @override
  String get moveComingSoon => 'Тренажёр ходов скоро появится';

  @override
  String get promptSquare => 'поле';

  @override
  String get promptFile => 'вертикаль';

  @override
  String get promptRank => 'горизонталь';
}
