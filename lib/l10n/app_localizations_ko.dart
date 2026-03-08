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
  String get calvinChessTrainer => 'Calvin Chess\nTrainer';

  @override
  String get masterTheFundamentals => '기본기를 마스터하세요!';

  @override
  String get chessNotation => '체스 기보법';

  @override
  String get learnTheBoard => '체스판을 배우세요!';

  @override
  String get chessVision => '체스 비전';

  @override
  String get seeTheBoard => '체스판을 보세요!';

  @override
  String get comingSoon => '출시 예정';

  @override
  String get start => '시작';

  @override
  String get menu => '메뉴';

  @override
  String get playAgain => '다시 플레이';

  @override
  String get newRecord => '새 기록!';

  @override
  String get whatToPractice => '무엇을 연습할까요?';

  @override
  String get chooseAMode => '모드 선택';

  @override
  String get files => '파일';

  @override
  String get ranks => '랭크';

  @override
  String get squares => '칸';

  @override
  String get moves => '수';

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
  String get hardMode => '하드 모드';

  @override
  String get hardModeBlack => '플레이어가 흑을 조작합니다!';

  @override
  String get hardModeFlipped => '보드 뒤집기 — 흑의 관점!';

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
  String get drillType => '훈련 유형';

  @override
  String get forksAndSkewers => '포크와 스큐어';

  @override
  String get pawnAttack => '폰 공격';

  @override
  String get knightSight => '나이트 시야';

  @override
  String get knightFlight => '나이트 비행';

  @override
  String get chooseYourPiece => '기물 선택';

  @override
  String get targetPiece => '대상 기물';

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
  String get concentricDrill => '동심원 훈련';

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
  String foundOfTotal(int found, int total) {
    return '$found/$total';
  }

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
  String titleForksAndSkewers(String piece, String mode) {
    return '$piece — $mode';
  }

  @override
  String titlePawnAttack(String piece, String mode) {
    return '폰 공격 — $piece $mode';
  }

  @override
  String titleMovesGame(String mode) {
    return '수 - $mode';
  }

  @override
  String titleFileRankGame(String subject, String mode) {
    return '$subject - $mode';
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
      '아이들에게 체스 기초를 가르치는 재미있고 상호작용적인 앱입니다. 훈련, 퀴즈, 시간 제한 도전을 통해 파일, 랭크, 칸, 기물 이동을 배우세요 — 오디오 피드백과 연승 추적으로 동기를 유지하세요!';

  @override
  String get aboutTrainingModes => '훈련 모드';

  @override
  String get aboutTrainingModesBody =>
      '• 탐색 — 자신의 속도로 배우기\n• 연습 — 스스로를 테스트하고 연승 기록 세우기\n• 스피드 라운드 — 30초, 몇 개나 맞출 수 있을까요?\n• 하드 모드 — 좌표를 숨겨 진정한 도전';

  @override
  String get aboutCredits => '크레딧 및 감사의 말';

  @override
  String get aboutCreditsBody =>
      '• Lichess 데이터베이스의 체스 퍼즐 (CC0 라이선스)\n• Lichess chessground 보드 UI\n• Lichess dartchess 체스 로직\n• ElevenLabs 음성 클립\n• Flutter와 Dart로 개발';

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
  String get squareTrainer => '칸 트레이너';

  @override
  String get squareComingSoon => '칸 트레이너 출시 예정';

  @override
  String get moveTrainer => '수 트레이너';

  @override
  String get moveComingSoon => '수 트레이너 출시 예정';

  @override
  String get promptSquare => '칸';

  @override
  String get promptFile => '파일';

  @override
  String get promptRank => '랭크';
}
