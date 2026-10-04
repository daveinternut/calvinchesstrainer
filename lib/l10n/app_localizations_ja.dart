// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Calvin Chess Trainer';

  @override
  String get about => 'このアプリについて';

  @override
  String get calvinChessTrainer => 'Calvin Chess\nTrainer';

  @override
  String get masterTheFundamentals => '基礎をマスターしよう！';

  @override
  String get chessNotation => 'チェスの棋譜記号';

  @override
  String get learnTheBoard => '盤面を覚えよう！';

  @override
  String get chessVision => 'チェスビジョン';

  @override
  String get seeTheBoard => '盤面を見よう！';

  @override
  String get startHere => 'ここから！';

  @override
  String get comingSoon => '近日公開';

  @override
  String get start => 'スタート';

  @override
  String get menu => 'メニュー';

  @override
  String get playAgain => 'もう一度';

  @override
  String get newRecord => '新記録！';

  @override
  String get whatToPractice => '何を練習する？';

  @override
  String get chooseAMode => 'モードを選ぶ';

  @override
  String get files => 'ファイル';

  @override
  String get ranks => 'ランク';

  @override
  String get squares => 'マス';

  @override
  String get moves => '手';

  @override
  String get pieceValue => '駒の価値';

  @override
  String get explore => '探索';

  @override
  String get exploreDesc => 'タップして学ぶ — プレッシャーなし、スコアなし';

  @override
  String get practice => '練習';

  @override
  String get practiceDesc => '自分を試そう — 連勝記録を作ろう！';

  @override
  String get speedRound => 'スピードラウンド';

  @override
  String get speedRoundDesc => '30秒 — いくつ解ける？';

  @override
  String get hardMode => 'ハードモード';

  @override
  String get hardModeBlack => 'プレイヤーが黒を操作！';

  @override
  String get hardModeFlipped => '盤面反転 — 黒の視点！';

  @override
  String get timesUp => '時間切れ！';

  @override
  String get correct => '正解';

  @override
  String get accuracy => '正確率';

  @override
  String get bestStreak => '最高連勝';

  @override
  String bestLabel(int value) {
    return '最高: $value';
  }

  @override
  String get tapFileToHear => '任意のファイルをタップして名前を聞こう';

  @override
  String get tapRankToHear => '任意のランクをタップして名前を聞こう';

  @override
  String get tapSquareToHear => '任意のマスをタップして名前を聞こう';

  @override
  String get tapFile => 'ファイルをタップ';

  @override
  String get tapRank => 'ランクをタップ';

  @override
  String get tapSquare => 'マスをタップ';

  @override
  String get milestoneNice => 'いいね！';

  @override
  String get milestoneAmazing => 'すごい！';

  @override
  String get milestoneIncredible => '信じられない！';

  @override
  String get milestoneUnstoppable => '止められない！';

  @override
  String get milestoneLegendary => '伝説的！';

  @override
  String get milestoneGreat => 'よくできた！';

  @override
  String streakMilestone(int count) {
    return '$count連続！';
  }

  @override
  String get hurry => '急いで！';

  @override
  String get drillType => 'ドリルの種類';

  @override
  String get forksAndSkewers => 'フォークとスキュワー';

  @override
  String get pawnAttack => 'ポーンアタック';

  @override
  String get knightSight => 'ナイトサイト';

  @override
  String get knightFlight => 'ナイトフライト';

  @override
  String get chooseYourPiece => '駒を選ぶ';

  @override
  String get targetPiece => 'ターゲット駒';

  @override
  String get queen => 'クイーン';

  @override
  String get rook => 'ルーク';

  @override
  String get bishop => 'ビショップ';

  @override
  String get knight => 'ナイト';

  @override
  String get findForksNoTimer => 'フォークとスキュワーを見つけよう — 時間制限なし';

  @override
  String get speedRound60Desc => '60秒 — できるだけ多く解こう！';

  @override
  String get concentricDrill => '同心円ドリル';

  @override
  String get concentricDrillDesc => '全ポジションを完了 — タイムを更新しよう！';

  @override
  String get captureAllPawnsNoTimer => '全てのポーンを取ろう — 時間制限なし';

  @override
  String get timed => 'タイムトライアル';

  @override
  String get timedPawnAttackDesc => '3〜8個のポーンを取ろう — タイムを更新しよう！';

  @override
  String get concentric => '同心円';

  @override
  String get retry => 'やり直し';

  @override
  String get skip => 'スキップ';

  @override
  String get none => 'なし';

  @override
  String minimumMoves(int count) {
    return '最小手数: $count';
  }

  @override
  String yourMoves(int count) {
    return 'あなたの手数: $count';
  }

  @override
  String pawnsRemaining(int count) {
    return 'ポーン: $count';
  }

  @override
  String levelOfEight(int level) {
    return 'レベル$level/8';
  }

  @override
  String movesCount(int count) {
    return '手数: $count';
  }

  @override
  String positionOfTotal(int current, int total) {
    return 'ポジション$current/$total';
  }

  @override
  String get tapNoneHint => '解がない場合は「なし」をタップ';

  @override
  String get found => '発見';

  @override
  String foundOfTotal(int found, int total) {
    return '$found/$total';
  }

  @override
  String get drillComplete => 'ドリル完了！';

  @override
  String get allClear => '全クリア！';

  @override
  String get time => '時間';

  @override
  String get errors => 'エラー';

  @override
  String get rounds => 'ラウンド';

  @override
  String solvedCount(int count) {
    return '$count問解答';
  }

  @override
  String titleForksAndSkewers(String piece, String mode) {
    return '$piece — $mode';
  }

  @override
  String titlePawnAttack(String piece, String mode) {
    return 'ポーンアタック — $piece $mode';
  }

  @override
  String titleMovesGame(String mode) {
    return '手 - $mode';
  }

  @override
  String titleFileRankGame(String subject, String mode) {
    return '$subject - $mode';
  }

  @override
  String get makeTheMove => '手を指そう';

  @override
  String get castleKingside => 'キングサイドキャスリング';

  @override
  String get castleQueenside => 'クイーンサイドキャスリング';

  @override
  String pieceTakesOn(String piece, String square) {
    return '$pieceが$squareで取る';
  }

  @override
  String pieceToSquare(String piece, String square) {
    return '$pieceを$squareへ';
  }

  @override
  String get seePositionMakeMove => '局面を見て、手を指そう！';

  @override
  String get aboutWhatIs => 'Calvin Chess Trainerとは？';

  @override
  String get aboutWhatIsBody =>
      '子どもたちにチェスの基礎を教える、楽しいインタラクティブアプリ。チェスビジョンでは、フォーク、スキュワー、ナイトの動き、チェック、駒取り、守られていない駒をひと目で見つける力を鍛えます。チェスの棋譜記号では、ファイル、ランク、マス、駒の記号、指し手、駒の価値を学べます。オープニングエクスプローラーでは、本物のチェスエンジンのヒントを見ながらオープニングを試せます。音声フィードバック、連続正解、保存される自己ベストでやる気が続く！';

  @override
  String get aboutTrainingModes => 'トレーニングモード';

  @override
  String get aboutTrainingModesBody =>
      '• 探索 — 自分のペースで学ぶ\n• 練習 — 自分を試して連続正解を伸ばそう\n• スピードラウンド — 時間と勝負（30秒または60秒）して新記録を目指そう\n• ハードモード — 黒の側から盤を見る';

  @override
  String get aboutCredits => 'クレジットと謝辞';

  @override
  String get aboutCreditsBody =>
      '• チェスアドバイザー: Dattasai Kilari\n• チェスパズル: Lichessデータベース（CC0ライセンス）\n• 盤面UI: Lichess chessground\n• チェスロジック: Lichess dartchess\n• 音声クリップ: ElevenLabs\n• FlutterとDartで開発';

  @override
  String get aboutInspired => 'Rapid Chess Improvementに触発されて';

  @override
  String get aboutInspiredBody =>
      'このアプリはMichael de la Mazaの著書Rapid Chess Improvement（Everyman Chess、2002）に多大な影響を受けています。「チェスビジョン」という概念 — 戦術的パターンや駒の関係を瞬時に認識する能力 — は、トレーニングに対する私の考え方を変えました。彼のアイデアに従い、自分の棋力を劇的に向上させることができ、彼のチェスビジョンのアプローチが新世代のプレイヤーにも盤面をより明確に見る助けになればと願い、Calvin Chess Trainerを作りました。ありがとう、Michael！';

  @override
  String get aboutInternut => 'Internut Educationについて';

  @override
  String get aboutInternutBody =>
      'Internut Educationは子供向けの魅力的な学習アプリを作っています。遊び、練習、ポジティブな強化を通じて学ぶことが最善だと信じています。';

  @override
  String aboutVersion(String version) {
    return 'バージョン $version';
  }

  @override
  String get aboutByInternut => 'Internut Education 製';

  @override
  String get aboutFooter => '世界中の若きチェスプレイヤーに❤️を込めて';

  @override
  String get feedbackTitle => 'フィードバックを送る';

  @override
  String get feedbackBody =>
      'このアプリをもっと良くしたいと思っています！アイデア、バグ報告、好きなところ — なんでもお聞かせください。';

  @override
  String get feedbackHint => 'フィードバックをここに入力...';

  @override
  String get feedbackSend => '送信';

  @override
  String get feedbackSending => '送信中...';

  @override
  String get feedbackThanks => 'フィードバックありがとうございます！';

  @override
  String get feedbackError => '送信できませんでした。もう一度お試しください。';

  @override
  String get feedbackEmpty => '送信前に何か書いてください。';

  @override
  String get tacticsTrainer => 'タクティクストレーナー';

  @override
  String get tacticsComingSoon => 'タクティクストレーナーは近日公開';

  @override
  String get promptSquare => 'マス';

  @override
  String get promptFile => 'ファイル';

  @override
  String get promptRank => 'ランク';

  @override
  String get openingFundamentals => 'オープニング\nエクスプローラー';

  @override
  String get playTheOpening => '序盤を探索しよう！';

  @override
  String get openingPractice => '序盤練習';

  @override
  String get openingChallenge => '序盤チャレンジ';

  @override
  String get playAs => 'プレイする';

  @override
  String get playAsWhite => '白';

  @override
  String get playAsBlack => '黒';

  @override
  String get difficulty => '難易度';

  @override
  String get easy => '簡単';

  @override
  String get medium => '普通';

  @override
  String get hard => '難しい';

  @override
  String get challenge => 'チャレンジ';

  @override
  String get practiceHintsDesc => 'ヒント付きでプレイ — トップ3の手を矢印で表示';

  @override
  String get challengeDesc => '序盤スキルを試そう — メダルを獲得！';

  @override
  String get engineThinking => 'エンジン解析中...';

  @override
  String get yourTurn => 'あなたの番';

  @override
  String get gameOver => 'ゲームオーバー';

  @override
  String youSurvivedMoves(int count) {
    return '$count手生き残りました';
  }

  @override
  String get reviewGame => '棋譜を確認';

  @override
  String get openingTip => '序盤のヒント';

  @override
  String get gotIt => '了解！';

  @override
  String get medalBronze => 'ブロンズ！';

  @override
  String get medalSilver => 'シルバー！';

  @override
  String get medalGold => 'ゴールド！';

  @override
  String get previousMove => '前の手';

  @override
  String get nextMove => '次の手';

  @override
  String get done => '完了';

  @override
  String get thePieces => 'The Pieces';

  @override
  String get knowYourPieces => 'Know your pieces!';

  @override
  String get whichSideWins => 'どっちが勝つ？';

  @override
  String get whichSideWinsDesc => '駒のグループを比べて、価値が高いほうをタップしよう！';

  @override
  String get tapTheSideWorthMore => '価値が高いほうをタップ';

  @override
  String get whichSideWinsPracticeDesc => '連続正解を伸ばそう — 進むほど難しくなるよ！';

  @override
  String get letters => '文字';

  @override
  String get king => 'キング';

  @override
  String get pawn => 'ポーン';

  @override
  String get hardModeBlackPieces => '黒の駒で出題！';

  @override
  String get tapPieceToLearnLetter => '駒をタップして文字を覚えよう！';

  @override
  String get whichPieceForLetter => 'この文字はどの駒？';

  @override
  String get whichLetterForPiece => 'この駒の文字はどれ？';

  @override
  String get tapPieceNoLetter => '文字のない駒をタップ！';

  @override
  String get noLetter => '文字なし';

  @override
  String letterEquals(String letter, String piece) {
    return '$letter = $piece！';
  }

  @override
  String get pawnNoLetterFact => 'ポーンに文字はいらない！';

  @override
  String get mnemonicKing => 'KはKing — キングの頭文字！';

  @override
  String get mnemonicQueen => 'QはQueen — クイーンの頭文字！';

  @override
  String get mnemonicRook => 'RはRook — ルークの頭文字！';

  @override
  String get mnemonicBishop => 'BはBishop — ビショップの頭文字！';

  @override
  String get mnemonicKnight => 'NはkNightのN — Kはキングのものだから！';

  @override
  String get mnemonicPawn => 'ポーンは文字がなくても大活躍！';

  @override
  String get scanDrillChecks => 'チェックを探せ';

  @override
  String get scanDrillCaptures => '駒取りを探せ';

  @override
  String get scanDrillHanging => '無防備の駒';

  @override
  String get scanDrillMate => '1手でメイト';

  @override
  String get scanPromptChecks => 'チェックできるマスをすべてタップしよう！';

  @override
  String get scanPromptCaptures => '取れる相手の駒をすべてタップしよう！';

  @override
  String get scanPromptHanging => '守られていない相手の駒をすべてタップしよう！';

  @override
  String get scanPromptMate => '1手でメイトできる手を見つけよう！';

  @override
  String get scanPracticeDesc => 'タイマーなし — 全部見つけよう！';

  @override
  String get blitz => 'ブリッツ';

  @override
  String get scanBlitzDesc => '60秒でいくつメイトを見つけられるかな？';

  @override
  String get whiteToPlay => '白の番';

  @override
  String get blackToPlay => '黒の番';

  @override
  String get openingExplorer => 'オープニングエクスプローラー';

  @override
  String get startFromOpening => 'オープニングから始める';

  @override
  String get flipBoard => '盤を反転';

  @override
  String get showScores => '評価値を表示';

  @override
  String get hideScores => '評価値を隠す';

  @override
  String get searchOpenings => 'オープニングを検索…';

  @override
  String get noOpeningsFound => 'オープニングが見つかりません';

  @override
  String get popularOpenings => '人気';

  @override
  String get browseByCategory => 'カテゴリーから探す';

  @override
  String get ecoFlankOpenings => 'フランクオープニング';

  @override
  String get ecoSemiOpenGames => 'セミオープンゲーム';

  @override
  String get ecoOpenGames => 'オープンゲーム';

  @override
  String get ecoClosedGames => 'クローズド＆セミクローズド';

  @override
  String get ecoIndianDefenses => 'インディアン・ディフェンス';

  @override
  String get engineUnavailable => 'チェスエンジンを起動できませんでした。';

  @override
  String get visionPromptForks => '自分の駒がキングともう1つの駒を同時に攻撃できるマスをすべてタップしよう！';

  @override
  String get visionPromptKnightSight => 'ナイトが跳べるマスをすべてタップしよう！';

  @override
  String get visionPromptKnightFlight => 'できるだけ少ない手数でナイトをリングまで跳ばそう！';

  @override
  String get visionPromptPawnAttack => 'ポーンを全部取ろう — 色のついたマスには止まらないで！';

  @override
  String get startOver => '最初から';

  @override
  String get loadFailed => '問題を読み込めませんでした。';

  @override
  String get checkmate => 'チェックメイト！';

  @override
  String get draw => '引き分け！';
}
