// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Calvin Chess Trainer';

  @override
  String get about => '关于';

  @override
  String get calvinChessTrainer => 'Calvin Chess\nTrainer';

  @override
  String get masterTheFundamentals => '掌握基础！';

  @override
  String get chessNotation => '国际象棋记谱';

  @override
  String get learnTheBoard => '认识棋盘！';

  @override
  String get chessVision => '棋盘视觉';

  @override
  String get seeTheBoard => '看清棋盘！';

  @override
  String get comingSoon => '即将推出';

  @override
  String get start => '开始';

  @override
  String get menu => '菜单';

  @override
  String get playAgain => '再玩一次';

  @override
  String get newRecord => '新纪录！';

  @override
  String get whatToPractice => '练习什么？';

  @override
  String get chooseAMode => '选择模式';

  @override
  String get files => '列';

  @override
  String get ranks => '行';

  @override
  String get squares => '格';

  @override
  String get moves => '着法';

  @override
  String get explore => '探索';

  @override
  String get exploreDesc => '点击学习 — 无压力，无计分';

  @override
  String get practice => '练习';

  @override
  String get practiceDesc => '自我测试 — 建立连胜！';

  @override
  String get speedRound => '限时挑战';

  @override
  String get speedRoundDesc => '30秒 — 你能答对多少？';

  @override
  String get hardMode => '困难模式';

  @override
  String get hardModeBlack => '用户执黑！';

  @override
  String get hardModeFlipped => '棋盘翻转 — 黑方视角！';

  @override
  String get timesUp => '时间到！';

  @override
  String get correct => '正确';

  @override
  String get accuracy => '准确率';

  @override
  String get bestStreak => '最佳连胜';

  @override
  String bestLabel(int value) {
    return '最佳：$value';
  }

  @override
  String get tapFileToHear => '点击任意列听其名称';

  @override
  String get tapRankToHear => '点击任意行听其名称';

  @override
  String get tapSquareToHear => '点击任意格听其名称';

  @override
  String get tapFile => '点击列';

  @override
  String get tapRank => '点击行';

  @override
  String get tapSquare => '点击格';

  @override
  String get milestoneNice => '不错！';

  @override
  String get milestoneAmazing => '太棒了！';

  @override
  String get milestoneIncredible => '难以置信！';

  @override
  String get milestoneUnstoppable => '势不可挡！';

  @override
  String get milestoneLegendary => '传奇！';

  @override
  String get milestoneGreat => '很好！';

  @override
  String streakMilestone(int count) {
    return '连续$count个！';
  }

  @override
  String get hurry => '快！';

  @override
  String get drillType => '练习类型';

  @override
  String get forksAndSkewers => '双攻与串击';

  @override
  String get pawnAttack => '兵的攻击';

  @override
  String get knightSight => '马的视野';

  @override
  String get knightFlight => '马的飞行';

  @override
  String get chooseYourPiece => '选择你的棋子';

  @override
  String get targetPiece => '目标棋子';

  @override
  String get queen => '后';

  @override
  String get rook => '车';

  @override
  String get bishop => '象';

  @override
  String get knight => '马';

  @override
  String get findForksNoTimer => '寻找双攻与串击 — 不限时';

  @override
  String get speedRound60Desc => '60秒 — 尽可能多地解题！';

  @override
  String get concentricDrill => '同心圆练习';

  @override
  String get concentricDrillDesc => '完成所有位置 — 超越你的时间！';

  @override
  String get captureAllPawnsNoTimer => '吃掉所有兵 — 不限时';

  @override
  String get timed => '计时';

  @override
  String get timedPawnAttackDesc => '清除3到8个兵 — 超越你的时间！';

  @override
  String get concentric => '同心圆';

  @override
  String get retry => '重试';

  @override
  String get skip => '跳过';

  @override
  String get none => '没有';

  @override
  String minimumMoves(int count) {
    return '最少步数：$count';
  }

  @override
  String yourMoves(int count) {
    return '你的步数：$count';
  }

  @override
  String pawnsRemaining(int count) {
    return '剩余兵：$count';
  }

  @override
  String levelOfEight(int level) {
    return '第$level级（共8级）';
  }

  @override
  String movesCount(int count) {
    return '步数：$count';
  }

  @override
  String positionOfTotal(int current, int total) {
    return '位置 $current/$total';
  }

  @override
  String get tapNoneHint => '如果没有解法，点击「没有」';

  @override
  String get found => '已找到';

  @override
  String foundOfTotal(int found, int total) {
    return '$found/$total';
  }

  @override
  String get drillComplete => '练习完成！';

  @override
  String get allClear => '全部通关！';

  @override
  String get time => '时间';

  @override
  String get errors => '错误';

  @override
  String get rounds => '回合';

  @override
  String solvedCount(int count) {
    return '已解$count题';
  }

  @override
  String titleForksAndSkewers(String piece, String mode) {
    return '$piece — $mode';
  }

  @override
  String titlePawnAttack(String piece, String mode) {
    return '兵的攻击 — $piece $mode';
  }

  @override
  String titleMovesGame(String mode) {
    return '着法 - $mode';
  }

  @override
  String titleFileRankGame(String subject, String mode) {
    return '$subject - $mode';
  }

  @override
  String get makeTheMove => '走出这步棋';

  @override
  String get castleKingside => '王翼易位';

  @override
  String get castleQueenside => '后翼易位';

  @override
  String pieceTakesOn(String piece, String square) {
    return '$piece吃$square';
  }

  @override
  String pieceToSquare(String piece, String square) {
    return '$piece到$square';
  }

  @override
  String get seePositionMakeMove => '看棋局，走棋！';

  @override
  String get aboutWhatIs => '什么是Calvin Chess Trainer？';

  @override
  String get aboutWhatIsBody =>
      '一款有趣的互动应用，教孩子们国际象棋基础。通过练习、测验和限时挑战学习列、行、格和棋子走法——配有语音反馈和连胜追踪，让你保持动力！';

  @override
  String get aboutTrainingModes => '训练模式';

  @override
  String get aboutTrainingModesBody =>
      '• 探索 — 按自己的节奏学习\n• 练习 — 自我测试，建立连胜\n• 限时挑战 — 30秒，你能答对多少？\n• 困难模式 — 隐藏坐标，迎接真正的挑战';

  @override
  String get aboutCredits => '致谢';

  @override
  String get aboutCreditsBody =>
      '• 国际象棋谜题来自Lichess数据库（CC0许可）\n• 棋盘界面由Lichess chessground提供\n• 棋逻辑由Lichess dartchess提供\n• 语音片段由ElevenLabs制作\n• 使用Flutter和Dart开发';

  @override
  String get aboutInspired => '灵感来自《Rapid Chess Improvement》';

  @override
  String get aboutInspiredBody =>
      '这款应用深受Michael de la Maza的著作《Rapid Chess Improvement》（Everyman Chess，2002）的启发。他的「棋盘视觉」概念——即时识别战术模式和棋子关系的能力——改变了我对训练的思考方式。遵循他的理念极大地提高了我的棋艺，我创建Calvin Chess Trainer，希望他的棋盘视觉方法能帮助新一代棋手更清楚地看懂棋盘。谢谢你，Michael！';

  @override
  String get aboutInternut => '关于Internut Education';

  @override
  String get aboutInternutBody =>
      'Internut Education为孩子们创建有趣的学习应用。我们相信最好的学习方式是通过游戏、练习和积极的鼓励。';

  @override
  String aboutVersion(String version) {
    return '版本 $version';
  }

  @override
  String get aboutByInternut => 'Internut Education出品';

  @override
  String get aboutFooter => '用❤️为全世界的小棋手而做';

  @override
  String get feedbackTitle => '发送反馈';

  @override
  String get feedbackBody => '我们一直在努力让这款应用更好！无论是建议、发现的问题还是喜欢的地方——我们都很想听听您的想法。';

  @override
  String get feedbackHint => '在这里输入您的反馈...';

  @override
  String get feedbackSend => '发送反馈';

  @override
  String get feedbackSending => '发送中...';

  @override
  String get feedbackThanks => '感谢您的反馈！';

  @override
  String get feedbackError => '发送失败，请重试。';

  @override
  String get feedbackEmpty => '请先写点内容再发送。';

  @override
  String get tacticsTrainer => '战术训练';

  @override
  String get tacticsComingSoon => '战术训练即将推出';

  @override
  String get squareTrainer => '格位训练';

  @override
  String get squareComingSoon => '格位训练即将推出';

  @override
  String get moveTrainer => '着法训练';

  @override
  String get moveComingSoon => '着法训练即将推出';

  @override
  String get promptSquare => '格';

  @override
  String get promptFile => '列';

  @override
  String get promptRank => '行';

  @override
  String get openingFundamentals => '开局\n探索器';

  @override
  String get playTheOpening => '探索开局！';

  @override
  String get openingPractice => '开局练习';

  @override
  String get openingChallenge => '开局挑战';

  @override
  String get playAs => '执棋';

  @override
  String get playAsWhite => '白方';

  @override
  String get playAsBlack => '黑方';

  @override
  String get difficulty => '难度';

  @override
  String get easy => '简单';

  @override
  String get medium => '中等';

  @override
  String get hard => '困难';

  @override
  String get challenge => '挑战';

  @override
  String get practiceHintsDesc => '带提示练习 — 显示前3步最佳着法箭头';

  @override
  String get challengeDesc => '测试你的开局水平 — 赢取奖牌！';

  @override
  String get engineThinking => '引擎分析中...';

  @override
  String get yourTurn => '轮到你';

  @override
  String get gameOver => '游戏结束';

  @override
  String youSurvivedMoves(int count) {
    return '你坚持了$count步';
  }

  @override
  String get reviewGame => '复盘';

  @override
  String get openingTip => '开局提示';

  @override
  String get gotIt => '知道了！';

  @override
  String get medalBronze => '铜牌！';

  @override
  String get medalSilver => '银牌！';

  @override
  String get medalGold => '金牌！';

  @override
  String get previousMove => '上一步';

  @override
  String get nextMove => '下一步';

  @override
  String get done => '完成';

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
