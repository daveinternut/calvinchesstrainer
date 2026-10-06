// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Calvin Chess Trainer';

  @override
  String get about => '소개';

  @override
  String get learnTheBoard => '체스판을 배우세요!';

  @override
  String get comingSoon => '출시 예정';

  @override
  String get start => '시작';

  @override
  String get playAgain => '다시 플레이';

  @override
  String get newRecord => '새 기록!';

  @override
  String get files => '파일';

  @override
  String get ranks => '랭크';

  @override
  String get squares => '칸';

  @override
  String get moves => '수';

  @override
  String get pieceValue => '기물 가치';

  @override
  String get explore => '탐색';

  @override
  String get exploreDesc => '탭하여 배우기 — 부담 없이, 점수 없이';

  @override
  String get practice => '연습';

  @override
  String get practiceDesc => '스스로를 테스트하세요 — 연승 기록을 세우세요!';

  @override
  String get speedRound => '스피드 라운드';

  @override
  String get speedRoundDesc => '30초 — 몇 개나 맞출 수 있을까요?';

  @override
  String get timesUp => '시간 종료!';

  @override
  String get correct => '정답';

  @override
  String get accuracy => '정확도';

  @override
  String get bestStreak => '최고 연승';

  @override
  String bestLabel(int value) {
    return '최고: $value';
  }

  @override
  String get tapFileToHear => '파일을 탭하여 이름을 들으세요';

  @override
  String get tapRankToHear => '랭크를 탭하여 이름을 들으세요';

  @override
  String get tapSquareToHear => '칸을 탭하여 이름을 들으세요';

  @override
  String get tapFileToSee => '파일을 탭하여 이름을 확인하세요';

  @override
  String get tapRankToSee => '랭크를 탭하여 이름을 확인하세요';

  @override
  String get tapSquareToSee => '칸을 탭하여 이름을 확인하세요';

  @override
  String get tapFile => '파일 탭';

  @override
  String get tapRank => '랭크 탭';

  @override
  String get tapSquare => '칸 탭';

  @override
  String get milestoneNice => '좋아요!';

  @override
  String get milestoneAmazing => '놀라워요!';

  @override
  String get milestoneIncredible => '믿을 수 없어요!';

  @override
  String get milestoneUnstoppable => '막을 수 없어요!';

  @override
  String get milestoneLegendary => '전설이에요!';

  @override
  String get milestoneGreat => '대단해요!';

  @override
  String streakMilestone(int count) {
    return '$count연속!';
  }

  @override
  String get hurry => '서두르세요!';

  @override
  String get forksAndSkewers => '포크와 스큐어';

  @override
  String get pawnAttack => '폰 공격';

  @override
  String get knightSight => '나이트 시야';

  @override
  String get knightFlight => '나이트 비행';

  @override
  String get queen => '퀸';

  @override
  String get rook => '룩';

  @override
  String get bishop => '비숍';

  @override
  String get knight => '나이트';

  @override
  String get findForksNoTimer => '포크와 스큐어를 찾으세요 — 시간 제한 없음';

  @override
  String get speedRound60Desc => '60초 — 최대한 많이 풀어보세요!';

  @override
  String get concentricDrillDesc => '모든 위치를 완성하세요 — 기록을 갱신하세요!';

  @override
  String get captureAllPawnsNoTimer => '모든 폰을 잡으세요 — 시간 제한 없음';

  @override
  String get timed => '시간 제한';

  @override
  String get timedPawnAttackDesc => '3~8개의 폰을 제거하세요 — 기록을 갱신하세요!';

  @override
  String get concentric => '동심원';

  @override
  String get retry => '다시 시도';

  @override
  String get skip => '건너뛰기';

  @override
  String get none => '없음';

  @override
  String minimumMoves(int count) {
    return '최소: $count';
  }

  @override
  String yourMoves(int count) {
    return '당신의 수: $count';
  }

  @override
  String pawnsRemaining(int count) {
    return '폰: $count';
  }

  @override
  String levelOfEight(int level) {
    return '레벨 $level/8';
  }

  @override
  String movesCount(int count) {
    return '수: $count';
  }

  @override
  String positionOfTotal(int current, int total) {
    return '위치 $current/$total';
  }

  @override
  String get tapNoneHint => '해답이 없으면 없음을 탭하세요';

  @override
  String get found => '발견';

  @override
  String get drillComplete => '훈련 완료!';

  @override
  String get allClear => '모두 해결!';

  @override
  String get time => '시간';

  @override
  String get errors => '오류';

  @override
  String get rounds => '라운드';

  @override
  String solvedCount(int count) {
    return '$count개 해결';
  }

  @override
  String get makeTheMove => '수를 두세요';

  @override
  String get castleKingside => '킹사이드 캐슬링';

  @override
  String get castleQueenside => '퀸사이드 캐슬링';

  @override
  String pieceTakesOn(String piece, String square) {
    return '$piece이(가) $square에서 잡음';
  }

  @override
  String pieceToSquare(String piece, String square) {
    return '$piece을(를) $square(으)로';
  }

  @override
  String get seePositionMakeMove => '포지션을 보고, 수를 두세요!';

  @override
  String get aboutWhatIs => 'Calvin Chess Trainer란?';

  @override
  String get aboutWhatIsBody =>
      '아이들에게 체스의 기초를 가르쳐 주는 재미있는 인터랙티브 앱이에요. 체스 비전은 포크, 스큐어, 나이트의 움직임, 체크, 잡기, 지켜지지 않는 기물을 한눈에 찾는 눈을 길러 줘요. 체스 기보법에서는 파일, 랭크, 칸, 기물 기호, 수, 기물의 가치를 배워요. 오프닝 탐색기에서는 진짜 체스 엔진의 힌트를 보며 오프닝을 연습할 수 있어요. 소리 피드백, 연속 기록, 저장되는 최고 기록이 계속 의욕을 북돋아 줘요!';

  @override
  String get aboutTrainingModes => '훈련 모드';

  @override
  String get aboutTrainingModesBody =>
      '• 탐색 — 자신의 속도로 배우기\n• 연습 — 스스로를 테스트하고 연속 기록 세우기\n• 스피드 라운드 — 시간과 겨뤄(30초 또는 60초) 새 기록에 도전하기\n• 하드 모드 — 흑의 쪽에서 보드 보기';

  @override
  String get aboutCredits => '크레딧 및 감사의 말';

  @override
  String get aboutCreditsBody =>
      '• 체스 자문: Dattasai Kilari\n• Lichess 데이터베이스의 체스 퍼즐 (CC0 라이선스)\n• Lichess chessground 보드 UI\n• Lichess dartchess 체스 로직\n• ElevenLabs 음성 클립\n• Flutter와 Dart로 개발';

  @override
  String get aboutInspired => 'Rapid Chess Improvement에서 영감을 받아';

  @override
  String get aboutInspiredBody =>
      '이 앱은 Michael de la Maza의 책 Rapid Chess Improvement (Everyman Chess, 2002)에 큰 영감을 받았습니다. 그의 \"체스 비전\" 개념 — 전술 패턴과 기물 관계를 즉각 인식하는 능력 — 은 훈련에 대한 저의 사고방식을 변화시켰습니다. 그의 아이디어를 따르면서 저의 실력이 크게 향상되었고, 그의 체스 비전 접근 방식이 새로운 세대의 선수들이 보드를 더 명확하게 볼 수 있도록 도움이 되길 바라며 Calvin Chess Trainer를 만들었습니다. 감사합니다, Michael!';

  @override
  String get aboutInternut => 'Internut Education 소개';

  @override
  String get aboutInternutBody =>
      'Internut Education은 아이들을 위한 매력적인 학습 앱을 만듭니다. 놀이, 연습, 긍정적 강화를 통해 배우는 것이 최선이라고 믿습니다.';

  @override
  String aboutVersion(String version) {
    return '버전 $version';
  }

  @override
  String get aboutByInternut => 'Internut Education 제작';

  @override
  String get aboutFooter => '전 세계 어린 체스 선수들을 위해 ❤️를 담아';

  @override
  String get feedbackTitle => '피드백 보내기';

  @override
  String get feedbackBody =>
      '이 앱을 더 좋게 만들고 싶습니다! 아이디어, 버그, 좋아하는 점 — 무엇이든 알려주세요.';

  @override
  String get feedbackHint => '피드백을 여기에 입력하세요...';

  @override
  String get feedbackSend => '피드백 보내기';

  @override
  String get feedbackSending => '전송 중...';

  @override
  String get feedbackThanks => '피드백 감사합니다!';

  @override
  String get feedbackError => '전송할 수 없습니다. 다시 시도해주세요.';

  @override
  String get feedbackEmpty => '보내기 전에 내용을 작성해주세요.';

  @override
  String get tacticsTrainer => '전술 트레이너';

  @override
  String get tacticsComingSoon => '전술 트레이너 출시 예정';

  @override
  String get promptSquare => '칸';

  @override
  String get promptFile => '파일';

  @override
  String get promptRank => '랭크';

  @override
  String get playTheOpening => '오프닝을 탐색하세요!';

  @override
  String get openingPractice => '오프닝 연습';

  @override
  String get openingChallenge => '오프닝 챌린지';

  @override
  String get playAs => '플레이';

  @override
  String get playAsWhite => '백';

  @override
  String get playAsBlack => '흑';

  @override
  String get difficulty => '난이도';

  @override
  String get easy => '쉬움';

  @override
  String get medium => '보통';

  @override
  String get hard => '어려움';

  @override
  String get challenge => '챌린지';

  @override
  String get practiceHintsDesc => '힌트와 함께 플레이 — 상위 3수 화살표로 표시';

  @override
  String get challengeDesc => '오프닝 실력을 테스트하세요 — 메달을 획득하세요!';

  @override
  String get engineThinking => '엔진 분석 중...';

  @override
  String get yourTurn => '당신 차례';

  @override
  String get gameOver => '게임 오버';

  @override
  String youSurvivedMoves(int count) {
    return '$count수 생존했습니다';
  }

  @override
  String get reviewGame => '게임 복기';

  @override
  String get openingTip => '오프닝 팁';

  @override
  String get gotIt => '알겠습니다!';

  @override
  String get medalBronze => '동메달!';

  @override
  String get medalSilver => '은메달!';

  @override
  String get medalGold => '금메달!';

  @override
  String get previousMove => '이전 수';

  @override
  String get nextMove => '다음 수';

  @override
  String get done => '완료';

  @override
  String get thePieces => 'The Pieces';

  @override
  String get knowYourPieces => 'Know your pieces!';

  @override
  String get tapTheSideWorthMore => '더 가치 있는 쪽을 탭하세요';

  @override
  String get whichSideWinsPracticeDesc => '연속 기록을 쌓으세요 — 갈수록 어려워져요!';

  @override
  String get letters => '글자';

  @override
  String get king => '킹';

  @override
  String get pawn => '폰';

  @override
  String get tapPieceToLearnLetter => '기물을 탭하여 글자를 배우세요!';

  @override
  String get whichPieceForLetter => '이 글자는 어떤 기물일까요?';

  @override
  String get whichLetterForPiece => '이 기물의 글자는 무엇일까요?';

  @override
  String get tapPieceNoLetter => '글자가 없는 기물을 탭하세요!';

  @override
  String get noLetter => '글자 없음';

  @override
  String letterEquals(String letter, String piece) {
    return '$letter = $piece!';
  }

  @override
  String get pawnNoLetterFact => '폰은 글자가 필요 없어요!';

  @override
  String get mnemonicKing => 'K는 King — 킹의 첫 글자!';

  @override
  String get mnemonicQueen => 'Q는 Queen — 퀸의 첫 글자!';

  @override
  String get mnemonicRook => 'R은 Rook — 룩의 첫 글자!';

  @override
  String get mnemonicBishop => 'B는 Bishop — 비숍의 첫 글자!';

  @override
  String get mnemonicKnight => 'N은 kNight의 N — K는 킹이 쓰니까요!';

  @override
  String get mnemonicPawn => '폰은 글자가 없어도 용감해요!';

  @override
  String get scanDrillChecks => '체크 찾기';

  @override
  String get scanDrillCaptures => '캡처 찾기';

  @override
  String get scanDrillHanging => '무방비 기물';

  @override
  String get scanDrillMate => '1수 메이트';

  @override
  String get scanPromptChecks => '체크할 수 있는 칸을 모두 탭하세요!';

  @override
  String get scanPromptCaptures => '잡을 수 있는 상대 기물을 모두 탭하세요!';

  @override
  String get scanPromptHanging => '지켜지지 않는 상대 기물을 모두 탭하세요!';

  @override
  String get scanPromptMate => '한 수 만에 체크메이트를 찾으세요!';

  @override
  String get scanPracticeDesc => '타이머 없음 — 모두 찾아보세요!';

  @override
  String get blitz => '블리츠';

  @override
  String get scanBlitzDesc => '60초 — 메이트를 몇 개나 찾을 수 있나요?';

  @override
  String get whiteToPlay => '백 차례';

  @override
  String get blackToPlay => '흑 차례';

  @override
  String get openingExplorer => '오프닝 탐색기';

  @override
  String get startFromOpening => '오프닝에서 시작하기';

  @override
  String get flipBoard => '보드 뒤집기';

  @override
  String get showScores => '점수 보기';

  @override
  String get hideScores => '점수 숨기기';

  @override
  String get turnSoundOff => '소리 끄기';

  @override
  String get turnSoundOn => '소리 켜기';

  @override
  String get searchOpenings => '오프닝 검색…';

  @override
  String get noOpeningsFound => '오프닝을 찾을 수 없어요';

  @override
  String get popularOpenings => '인기';

  @override
  String get browseByCategory => '분류별로 보기';

  @override
  String get ecoFlankOpenings => '측면 오프닝';

  @override
  String get ecoSemiOpenGames => '세미 오픈 게임';

  @override
  String get ecoOpenGames => '오픈 게임';

  @override
  String get ecoClosedGames => '클로즈드 & 세미 클로즈드';

  @override
  String get ecoIndianDefenses => '인디언 디펜스';

  @override
  String get engineUnavailable => '체스 엔진을 시작하지 못했어요.';

  @override
  String get visionPromptForks => '내 기물이 킹과 다른 기물을 동시에 공격하는 칸을 모두 탭하세요!';

  @override
  String get visionPromptKnightSight => '나이트가 뛸 수 있는 칸을 모두 탭하세요!';

  @override
  String get visionPromptKnightFlight => '최대한 적은 수로 나이트를 링까지 옮기세요!';

  @override
  String get visionPromptPawnAttack => '폰을 모두 잡으세요 — 색칠된 칸에는 멈추지 마세요!';

  @override
  String get startOver => '처음부터';

  @override
  String get loadFailed => '문제를 불러오지 못했어요.';

  @override
  String get checkmate => '체크메이트!';

  @override
  String get draw => '무승부!';

  @override
  String get homeWarmupKicker => '매일 워밍업 · 5분';

  @override
  String get homeWarmupTitle => '퍼즐이 놓치는 것을 훈련하세요';

  @override
  String get homeWarmupBody =>
      '빠른 훈련 5가지: 체크, 무방비 기물, 포크, 흑의 시점에서 본 칸, 그리고 1수 메이트.';

  @override
  String get homeWarmupStart => '워밍업 시작';

  @override
  String get homeContinue => '이어서 하기';

  @override
  String get homeStartHere => '여기서 시작';

  @override
  String homeResume(String drill) {
    return '$drill 이어하기';
  }

  @override
  String get homeOpenings => '오프닝';

  @override
  String get homeOpeningExplorerDesc => 'Stockfish 힌트로 오프닝을 둬 보세요';

  @override
  String get sectionVision => '체스 비전';

  @override
  String get sectionVisionDesc => '대부분이 훈련하지 않는 체스판 훑어보기 습관';

  @override
  String get sectionNotation => '기보법';

  @override
  String get sectionNotationDesc => '생각하지 않고도 칸과 수를 읽고 찾기';

  @override
  String sectionAllDrills(int count) {
    return '전체 훈련 $count개';
  }

  @override
  String get navHome => '홈';

  @override
  String drillBest(String value) {
    return '최고 $value';
  }

  @override
  String get groupScan => '체스판 훑어보기';

  @override
  String get groupGeometry => '기하학';

  @override
  String get groupFinish => '마무리';

  @override
  String get groupBoard => '체스판';

  @override
  String get groupPieces => '기물';

  @override
  String get drillFilesRanks => '파일과 랭크';

  @override
  String get drillReadMoves => '기보 읽기';

  @override
  String get drillPieceLetters => '기물 글자';

  @override
  String get drillPieceValues => '기물 가치';

  @override
  String get drillDescFindChecks => '실전 포지션의 모든 체크';

  @override
  String get drillDescFindCaptures => '체스판 위의 모든 캡처 찾기';

  @override
  String get drillDescHanging => '지켜지지 않는 기물 모두 찾기';

  @override
  String get drillDescForks => '두 기물을 동시에 노리는 칸';

  @override
  String get drillDescKnightSight => '나이트가 갈 수 있는 모든 칸';

  @override
  String get drillDescKnightFlight => '최소한의 수로 목표까지';

  @override
  String get drillDescPawnAttack => '폰의 벽을 빠져나가기';

  @override
  String get drillDescMate => '400개 포지션, 한 수로 메이트';

  @override
  String get drillDescSquares => '칸을 빠르게 찾기';

  @override
  String get drillDescFilesRanks => '모든 파일과 랭크 이름 맞히기';

  @override
  String get drillDescReadMoves => '기보를 읽고 그 수를 두기';

  @override
  String get drillDescLetters => 'K, Q, R, B, N을 한눈에';

  @override
  String get drillDescValues => '어느 쪽이 유리할까?';

  @override
  String get setupYourPiece => '내 기물';

  @override
  String get setupForkTarget => '포크: 킹과…';

  @override
  String get setupMode => '모드';

  @override
  String get setupBoardSide => '보드 방향';

  @override
  String get setupLines => '라인';

  @override
  String get setupYourBest => '내 최고 기록';

  @override
  String get setupNoBest => '아직 기록 없음';

  @override
  String get setupKnightPracticeOnly => '타이머 없음. 천천히 하세요.';

  @override
  String warmupStep(int current, int total) {
    return '워밍업 · $current/$total';
  }

  @override
  String warmupNext(String drill) {
    return '다음: $drill';
  }

  @override
  String get warmupFinish => '워밍업 마치기';

  @override
  String get warmupEnd => '워밍업 종료';

  @override
  String get warmupDoneTitle => '워밍업 완료';

  @override
  String get warmupDoneBody => '훈련 5개 완료. 내일 같은 시간에 할까요?';

  @override
  String get resultsMissed => '놓침';

  @override
  String get endDrill => '훈련 종료';

  @override
  String get promptTitleChecks => '모든 체크를 찾으세요';

  @override
  String get promptTitleCaptures => '모든 캡처를 찾으세요';

  @override
  String get promptTitleHanging => '무방비 기물을 모두 찾으세요';

  @override
  String get promptTitleForks => '모든 포크를 찾으세요';

  @override
  String get promptTitleKnightSight => '나이트의 모든 점프';

  @override
  String get promptTitleKnightFlight => '링에 도착하세요';

  @override
  String get promptTitlePawnAttack => '폰을 모두 잡으세요';

  @override
  String get promptTitleMate => '한 수 만에 체크메이트';
}
