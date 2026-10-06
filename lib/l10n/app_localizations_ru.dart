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
  String get learnTheBoard => 'Изучи доску!';

  @override
  String get comingSoon => 'СКОРО';

  @override
  String get start => 'Начать';

  @override
  String get playAgain => 'Играть снова';

  @override
  String get newRecord => 'Новый рекорд!';

  @override
  String get files => 'Вертикали';

  @override
  String get ranks => 'Горизонтали';

  @override
  String get squares => 'Поля';

  @override
  String get moves => 'Ходы';

  @override
  String get pieceValue => 'Ценность фигур';

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
  String get tapFileToSee => 'Нажми на вертикаль, чтобы увидеть её название';

  @override
  String get tapRankToSee => 'Нажми на горизонталь, чтобы увидеть её название';

  @override
  String get tapSquareToSee => 'Нажми на поле, чтобы увидеть его название';

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
  String get forksAndSkewers => 'Вилки и линейные удары';

  @override
  String get pawnAttack => 'Атака пешкой';

  @override
  String get knightSight => 'Зрение коня';

  @override
  String get knightFlight => 'Полёт коня';

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
      'Весёлое интерактивное приложение, которое учит детей основам шахмат. «Шахматное зрение» тренирует замечать с первого взгляда вилки, линейные удары, ходы коня, шахи, взятия и незащищённые фигуры. «Шахматная нотация» учит вертикали, горизонтали, поля, буквы фигур, ходы и ценность фигур. В «Обозревателе дебютов» можно пробовать дебюты с подсказками настоящего шахматного движка. Звуки, серии и сохранённые рекорды помогают не терять интерес!';

  @override
  String get aboutTrainingModes => 'Режимы тренировки';

  @override
  String get aboutTrainingModesBody =>
      '• Изучение — учись в своём темпе\n• Практика — проверяй себя и набирай серии\n• Блиц-раунд — соревнуйся с часами (30 или 60 секунд) и ставь новый рекорд\n• Сложный режим — играй со стороны чёрных';

  @override
  String get aboutCredits => 'Благодарности';

  @override
  String get aboutCreditsBody =>
      '• Шахматный консультант: Dattasai Kilari\n• Шахматные задачи из базы Lichess (лицензия CC0)\n• Интерфейс доски: Lichess chessground\n• Шахматная логика: Lichess dartchess\n• Голосовые клипы: ElevenLabs\n• Разработано на Flutter и Dart';

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
  String get promptSquare => 'поле';

  @override
  String get promptFile => 'вертикаль';

  @override
  String get promptRank => 'горизонталь';

  @override
  String get playTheOpening => 'Исследуйте дебюты!';

  @override
  String get openingPractice => 'Практика дебюта';

  @override
  String get openingChallenge => 'Испытание дебюта';

  @override
  String get playAs => 'Играть за';

  @override
  String get playAsWhite => 'Белые';

  @override
  String get playAsBlack => 'Чёрные';

  @override
  String get difficulty => 'Сложность';

  @override
  String get easy => 'Лёгкий';

  @override
  String get medium => 'Средний';

  @override
  String get hard => 'Сложный';

  @override
  String get challenge => 'Испытание';

  @override
  String get practiceHintsDesc =>
      'Играй с подсказками — 3 лучших хода показаны стрелками';

  @override
  String get challengeDesc =>
      'Проверь свои навыки дебюта — зарабатывай медали!';

  @override
  String get engineThinking => 'Движок анализирует...';

  @override
  String get yourTurn => 'Твой ход';

  @override
  String get gameOver => 'Игра окончена';

  @override
  String youSurvivedMoves(int count) {
    return 'Ты продержался $count ход(ов)';
  }

  @override
  String get reviewGame => 'Разбор партии';

  @override
  String get openingTip => 'Совет по дебюту';

  @override
  String get gotIt => 'Понятно!';

  @override
  String get medalBronze => 'Бронза!';

  @override
  String get medalSilver => 'Серебро!';

  @override
  String get medalGold => 'Золото!';

  @override
  String get previousMove => 'Предыдущий ход';

  @override
  String get nextMove => 'Следующий ход';

  @override
  String get done => 'Готово';

  @override
  String get thePieces => 'The Pieces';

  @override
  String get knowYourPieces => 'Know your pieces!';

  @override
  String get tapTheSideWorthMore => 'Нажми на более ценную сторону';

  @override
  String get whichSideWinsPracticeDesc =>
      'Наращивай серию — сложность растёт по ходу!';

  @override
  String get letters => 'Буквы';

  @override
  String get king => 'Король';

  @override
  String get pawn => 'Пешка';

  @override
  String get tapPieceToLearnLetter => 'Нажми на фигуру, чтобы узнать её букву!';

  @override
  String get whichPieceForLetter => 'Какая фигура обозначается этой буквой?';

  @override
  String get whichLetterForPiece => 'Какой буквой обозначается эта фигура?';

  @override
  String get tapPieceNoLetter => 'Нажми на фигуру БЕЗ буквы!';

  @override
  String get noLetter => 'Без буквы';

  @override
  String letterEquals(String letter, String piece) {
    return '$letter = $piece!';
  }

  @override
  String get pawnNoLetterFact => 'Пешкам буква не нужна!';

  @override
  String get mnemonicKing => 'K — King, король по-английски!';

  @override
  String get mnemonicQueen => 'Q — Queen, ферзь по-английски!';

  @override
  String get mnemonicRook => 'R — Rook, ладья по-английски!';

  @override
  String get mnemonicBishop => 'B — Bishop, слон по-английски!';

  @override
  String get mnemonicKnight => 'N — kNight, конь! Буква K уже занята королём.';

  @override
  String get mnemonicPawn => 'Пешки такие храбрые, что им и буква не нужна!';

  @override
  String get scanDrillChecks => 'Найди шахи';

  @override
  String get scanDrillCaptures => 'Найди взятия';

  @override
  String get scanDrillHanging => 'Висячие фигуры';

  @override
  String get scanDrillMate => 'Мат в 1 ход';

  @override
  String get scanPromptChecks =>
      'Нажми на каждое поле, с которого можно дать шах!';

  @override
  String get scanPromptCaptures =>
      'Нажми на каждую фигуру соперника, которую можно взять!';

  @override
  String get scanPromptHanging =>
      'Нажми на каждую незащищённую фигуру соперника!';

  @override
  String get scanPromptMate => 'Найди мат в один ход!';

  @override
  String get scanPracticeDesc => 'Без таймера — найди их все!';

  @override
  String get blitz => 'Блиц';

  @override
  String get scanBlitzDesc => '60 секунд — сколько матов ты найдёшь?';

  @override
  String get whiteToPlay => 'Ход белых';

  @override
  String get blackToPlay => 'Ход чёрных';

  @override
  String get openingExplorer => 'Обозреватель дебютов';

  @override
  String get startFromOpening => 'Начать с дебюта';

  @override
  String get flipBoard => 'Перевернуть доску';

  @override
  String get showScores => 'Показать оценки';

  @override
  String get hideScores => 'Скрыть оценки';

  @override
  String get turnSoundOff => 'Выключить звук';

  @override
  String get turnSoundOn => 'Включить звук';

  @override
  String get searchOpenings => 'Поиск дебютов…';

  @override
  String get noOpeningsFound => 'Дебюты не найдены';

  @override
  String get popularOpenings => 'Популярные';

  @override
  String get browseByCategory => 'По категориям';

  @override
  String get ecoFlankOpenings => 'Фланговые дебюты';

  @override
  String get ecoSemiOpenGames => 'Полуоткрытые дебюты';

  @override
  String get ecoOpenGames => 'Открытые дебюты';

  @override
  String get ecoClosedGames => 'Закрытые и полузакрытые';

  @override
  String get ecoIndianDefenses => 'Индийские защиты';

  @override
  String get engineUnavailable => 'Шахматный движок не запустился.';

  @override
  String get visionPromptForks =>
      'Нажми на каждое поле, с которого твоя фигура атакует короля и другую фигуру!';

  @override
  String get visionPromptKnightSight =>
      'Нажми на каждое поле, куда может прыгнуть твой конь!';

  @override
  String get visionPromptKnightFlight =>
      'Доведи коня до кольца за как можно меньшее число ходов!';

  @override
  String get visionPromptPawnAttack =>
      'Забери все пешки — никогда не останавливайся на затенённом поле!';

  @override
  String get startOver => 'Начать заново';

  @override
  String get loadFailed => 'Не удалось загрузить задачи.';

  @override
  String get checkmate => 'Мат!';

  @override
  String get draw => 'Ничья!';

  @override
  String get homeWarmupKicker => 'Ежедневная разминка · 5 мин';

  @override
  String get homeWarmupTitle => 'Тренируй то, чего нет в задачах';

  @override
  String get homeWarmupBody =>
      'Пять коротких упражнений: шахи, незащищённые фигуры, вилки, поля со стороны чёрных и мат в один ход.';

  @override
  String get homeWarmupStart => 'Начать разминку';

  @override
  String get homeContinue => 'Продолжить';

  @override
  String get homeStartHere => 'Начни здесь';

  @override
  String homeResume(String drill) {
    return 'Продолжить: $drill';
  }

  @override
  String get homeOpenings => 'Дебюты';

  @override
  String get homeOpeningExplorerDesc =>
      'Разыгрывай дебюты с подсказками Stockfish';

  @override
  String get sectionVision => 'Шахматное зрение';

  @override
  String get sectionVisionDesc =>
      'Привычки осмотра доски, которые почти никто не тренирует';

  @override
  String get sectionNotation => 'Нотация';

  @override
  String get sectionNotationDesc => 'Читай и находи поля и ходы не задумываясь';

  @override
  String sectionAllDrills(int count) {
    return 'Все упражнения ($count)';
  }

  @override
  String get navHome => 'Главная';

  @override
  String drillBest(String value) {
    return 'Рекорд $value';
  }

  @override
  String get groupScan => 'Осмотри доску';

  @override
  String get groupGeometry => 'Геометрия';

  @override
  String get groupFinish => 'Решающий удар';

  @override
  String get groupBoard => 'Доска';

  @override
  String get groupPieces => 'Фигуры';

  @override
  String get drillFilesRanks => 'Вертикали и горизонтали';

  @override
  String get drillReadMoves => 'Чтение ходов';

  @override
  String get drillPieceLetters => 'Буквы фигур';

  @override
  String get drillPieceValues => 'Ценность фигур';

  @override
  String get drillDescFindChecks => 'Все шахи в реальной позиции';

  @override
  String get drillDescFindCaptures => 'Найди все взятия на доске';

  @override
  String get drillDescHanging => 'Замечай все незащищённые фигуры';

  @override
  String get drillDescForks => 'Поля для двойного удара';

  @override
  String get drillDescKnightSight => 'Все поля, куда может прыгнуть конь';

  @override
  String get drillDescKnightFlight => 'До цели за минимум ходов';

  @override
  String get drillDescPawnAttack => 'Проберись сквозь стену пешек';

  @override
  String get drillDescMate => '400 позиций, мат в один ход';

  @override
  String get drillDescSquares => 'Быстро найди поле';

  @override
  String get drillDescFilesRanks => 'Называй все вертикали и горизонтали';

  @override
  String get drillDescReadMoves => 'Прочитай ход, затем сделай его';

  @override
  String get drillDescLetters => 'K, Q, R, B, N с первого взгляда';

  @override
  String get drillDescValues => 'Какая сторона в выигрыше?';

  @override
  String get setupYourPiece => 'Твоя фигура';

  @override
  String get setupForkTarget => 'Вилка: король и…';

  @override
  String get setupMode => 'Режим';

  @override
  String get setupBoardSide => 'Сторона доски';

  @override
  String get setupLines => 'Линии';

  @override
  String get setupYourBest => 'Твой рекорд';

  @override
  String get setupNoBest => 'Рекорда пока нет';

  @override
  String get setupKnightPracticeOnly => 'Без таймера. Не торопись.';

  @override
  String warmupStep(int current, int total) {
    return 'Разминка · $current из $total';
  }

  @override
  String warmupNext(String drill) {
    return 'Далее: $drill';
  }

  @override
  String get warmupFinish => 'Завершить разминку';

  @override
  String get warmupEnd => 'Выйти из разминки';

  @override
  String get warmupDoneTitle => 'Разминка завершена';

  @override
  String get warmupDoneBody =>
      'Пять упражнений выполнено. Завтра в то же время?';

  @override
  String get resultsMissed => 'Пропущено';

  @override
  String get endDrill => 'Выйти из упражнения';

  @override
  String get promptTitleChecks => 'Найди все шахи';

  @override
  String get promptTitleCaptures => 'Найди все взятия';

  @override
  String get promptTitleHanging => 'Найди все висячие фигуры';

  @override
  String get promptTitleForks => 'Найди все вилки';

  @override
  String get promptTitleKnightSight => 'Все прыжки коня';

  @override
  String get promptTitleKnightFlight => 'Доберись до кольца';

  @override
  String get promptTitlePawnAttack => 'Забери все пешки';

  @override
  String get promptTitleMate => 'Мат в один ход';
}
