// Renders the store artwork from the app's own widgets, at the exact pixel
// sizes each store asks for:
//
//   flutter test tool/store_assets/store_assets_test.dart
//
// - the app icon (assets/images/app_icon.png) and the Android adaptive icon
//   layers (resources/icon/), from the LogoMark geometry
// - App Store screenshots: iPhone 6.5" (1284×2778) and iPad 13" landscape
//   (2752×2064), in resources/store/ios/
// - Google Play: phone (1080×1920) and tablet (2560×1440) screenshots, the
//   512 px icon and the 1024×500 feature graphic, in resources/store/android/
//
// Each screenshot is a real screen, rendered in a phone- or tablet-sized
// window with seeded game state, then placed under a caption. It lives in
// tool/ so `flutter test` (test/ only) never runs it. After changing the icon,
// run `dart run flutter_launcher_icons`.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/core/services/opening_book_service.dart';
import 'package:calvinchesstrainer/core/services/personal_bests_service.dart';
import 'package:calvinchesstrainer/core/services/puzzle_service.dart';
import 'package:calvinchesstrainer/core/services/scan_position_service.dart';
import 'package:calvinchesstrainer/core/services/stockfish_service.dart';
import 'package:calvinchesstrainer/core/theme/app_theme.dart';
import 'package:calvinchesstrainer/features/chess_vision/models/chess_vision_state.dart';
import 'package:calvinchesstrainer/features/chess_vision/providers/chess_vision_provider.dart';
import 'package:calvinchesstrainer/features/chess_vision/screens/chess_vision_game_screen.dart';
import 'package:calvinchesstrainer/features/drills/drill_catalog.dart';
import 'package:calvinchesstrainer/features/drills/models/drill.dart';
import 'package:calvinchesstrainer/features/drills/providers/drill_prefs_provider.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/models/file_rank_game_state.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/providers/file_rank_game_provider.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/screens/file_rank_game_screen.dart';
import 'package:calvinchesstrainer/features/home/screens/home_screen.dart';
import 'package:calvinchesstrainer/features/move_trainer/models/move_game_state.dart';
import 'package:calvinchesstrainer/features/move_trainer/providers/move_game_provider.dart';
import 'package:calvinchesstrainer/features/move_trainer/screens/move_game_screen.dart';
import 'package:calvinchesstrainer/features/opening_trainer/models/opening_game_state.dart';
import 'package:calvinchesstrainer/features/opening_trainer/providers/opening_game_provider.dart';
import 'package:calvinchesstrainer/features/opening_trainer/screens/opening_game_screen.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:chessground/chessground.dart' show PieceSet;
import 'package:dartchess/dartchess.dart' show Chess, Setup, Side;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ------------------------------------------------------------------ devices

enum _Bar { iphone, ipad, android }

/// An output size, and the app window rendered inside it.
class _Device {
  const _Device({
    required this.dir,
    required this.canvas,
    required this.window,
    required this.safe,
    required this.bar,
    required this.screenWidth,
  });

  /// Output folder, from the repo root.
  final String dir;

  /// The image the store wants, in pixels.
  final Size canvas;

  /// The app window, in logical points.
  final Size window;

  /// Status bar and home-indicator insets, in points.
  final EdgeInsets safe;
  final _Bar bar;

  /// How wide the window is drawn in the output, in pixels. It runs off the
  /// bottom edge.
  final double screenWidth;

  bool get landscape => canvas.width > canvas.height;
}

const _iphone = _Device(
  dir: 'resources/store/ios/iphone',
  canvas: Size(1284, 2778), // 6.5" slot
  window: Size(428, 926), // iPhone 14 Plus
  safe: EdgeInsets.only(top: 47, bottom: 34),
  bar: _Bar.iphone,
  screenWidth: 1060,
);

const _ipad = _Device(
  dir: 'resources/store/ios/ipad',
  canvas: Size(2752, 2064), // 13" slot, landscape
  window: Size(1376, 1032), // iPad Pro 13"
  safe: EdgeInsets.only(top: 24, bottom: 20),
  bar: _Bar.ipad,
  screenWidth: 2240,
);

const _androidPhone = _Device(
  dir: 'resources/store/android/phone',
  canvas: Size(1080, 1920), // Play wants 9:16
  window: Size(411, 731),
  safe: EdgeInsets.only(top: 24, bottom: 16),
  bar: _Bar.android,
  screenWidth: 820,
);

const _androidTablet = _Device(
  dir: 'resources/store/android/tablet',
  canvas: Size(2560, 1440), // 16:9; fits both the 7" and 10" slots
  window: Size(1280, 800),
  safe: EdgeInsets.only(top: 24, bottom: 16),
  bar: _Bar.android,
  screenWidth: 1840,
);

// ------------------------------------------------------------------- scenes

/// One screenshot: a screen, its caption and how to get it into shape.
class _Scene {
  const _Scene({
    required this.file,
    required this.title,
    required this.subtitle,
    required this.screen,
    this.overrides = const [],
    this.seed,
    this.play,
  });

  final String file;
  final String title;
  final String subtitle;
  final Widget screen;
  final List<Object> overrides;

  /// Runs before the screen is built (saved bests, Continue).
  final void Function(ProviderContainer container)? seed;

  /// Runs once the screen is up (taps, the clock).
  final Future<void> Function(WidgetTester tester, ProviderContainer c)? play;
}

List<_Scene> _scenes() => [
      _Scene(
        file: '01-home.png',
        title: 'Train what puzzles skip',
        subtitle: 'A five-minute daily warm-up for board vision',
        screen: const HomeScreen(),
        seed: _seedHome,
      ),
      _Scene(
        file: '02-find-checks.png',
        title: 'See every check',
        subtitle: 'Real positions. Find them all, named in notation.',
        screen: const ChessVisionGameScreen(
          drill: VisionDrillType.findChecks,
          piece: WhitePiece.queen,
          mode: VisionMode.practice,
        ),
        overrides: [scanPositionServiceProvider.overrideWithValue(_scans)],
        play: (tester, c) => _solveThenFind(tester, c, 2),
      ),
      _Scene(
        file: '03-forks-and-skewers.png',
        title: 'Spot double attacks',
        subtitle: 'Find the squares that hit two targets at once',
        screen: const ChessVisionGameScreen(
          drill: VisionDrillType.forksAndSkewers,
          piece: WhitePiece.queen,
          target: TargetPiece.rook,
          mode: VisionMode.practice,
        ),
        play: (tester, c) => _solveThenFind(tester, c, 1),
      ),
      _Scene(
        file: '04-name-the-square.png',
        title: 'Know every square',
        subtitle: 'Find squares, files and ranks without thinking',
        screen: const FileRankGameScreen(
          subject: TrainerSubject.squares,
          mode: TrainerMode.speed,
        ),
        play: (tester, c) async {
          final notifier = c.read(fileRankGameProvider.notifier);
          for (var i = 0; i < 7; i++) {
            final s = c.read(fileRankGameProvider);
            notifier.handleBoardTap(
                s.currentTargetIndex!, s.currentTargetRankIndex!);
            await tester.pump(const Duration(milliseconds: 700));
          }
          // Let the streak banner come and go.
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(seconds: 1));
          }
        },
      ),
      _Scene(
        file: '05-read-moves.png',
        title: 'Read notation fluently',
        subtitle: 'Play the move straight from its notation',
        screen: const MoveGameScreen(mode: MoveTrainerMode.practice),
        play: (tester, c) async {
          // Solve the first puzzle, so the next one shows a streak.
          final puzzle = c.read(moveGameProvider).currentPuzzle!;
          c.read(moveGameProvider.notifier).handleMove(puzzle.expectedMove);
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 500));
          }
        },
        overrides: [
          puzzleServiceProvider
              .overrideWithValue(_ChosenPuzzles(const ['Ng5+', 'Bxf7#'])),
        ],
      ),
      _Scene(
        file: '06-opening-explorer.png',
        title: 'Explore the openings',
        subtitle: 'Book moves, Stockfish hints and an eval bar',
        screen: const OpeningGameScreen(
          mode: OpeningMode.practice,
          difficulty: OpeningDifficulty.easy,
          playerColor: Side.white,
        ),
        overrides: [
          stockfishServiceProvider.overrideWithValue(_ShowcaseEngine()),
          openingBookServiceProvider.overrideWithValue(_book),
        ],
        play: (tester, c) async {
          await tester.runAsync(() => c
              .read(openingGameProvider.notifier)
              .startFromOpening('1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6'));
          for (var i = 0; i < 6; i++) {
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 50)));
            await tester.pump(const Duration(milliseconds: 200));
          }
        },
      ),
    ];

/// Solves the round on the board, then finds [found] squares of the next.
Future<void> _solveThenFind(
    WidgetTester tester, ProviderContainer c, int found) async {
  final notifier = c.read(chessVisionProvider.notifier);
  for (final square in c.read(chessVisionProvider).correctSquares.toList()) {
    notifier.handleBoardTap(square);
    await tester.pump(const Duration(milliseconds: 300));
  }
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  final next = c.read(chessVisionProvider).correctSquares.toList()..sort();
  for (final square in next.take(found)) {
    notifier.handleBoardTap(square);
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// A played-in look: a few saved bests and something to Continue.
void _seedHome(ProviderContainer c) {
  final bests = c.read(personalBestsProvider.notifier);
  void best(DrillConfig config, int score) =>
      bests.submit(config.drill.bestKey(config)!, score);

  best(const DrillConfig(drill: DrillId.findChecks, mode: DrillMode.speed), 9);
  best(const DrillConfig(drill: DrillId.hangingPieces, mode: DrillMode.speed),
      7);
  best(
      const DrillConfig(drill: DrillId.forksAndSkewers, mode: DrillMode.speed),
      14);
  best(const DrillConfig(drill: DrillId.squares, mode: DrillMode.speed), 23);
  best(const DrillConfig(drill: DrillId.filesRanks, mode: DrillMode.speed),
      31);
  best(const DrillConfig(drill: DrillId.readMoves, mode: DrillMode.speed), 11);
  // Tiles show a best once the drill has been played; Forks & Skewers last,
  // so it's the one to Continue.
  final prefs = c.read(drillPrefsProvider.notifier);
  for (final drill in const [
    DrillId.findChecks,
    DrillId.hangingPieces,
    DrillId.squares,
    DrillId.filesRanks,
    DrillId.readMoves,
    DrillId.forksAndSkewers,
  ]) {
    prefs.recordStart(DrillConfig(drill: drill, mode: DrillMode.speed));
  }
}

// ---------------------------------------------------------------- fakes

class _SilentAudio implements AudioService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoopAnalytics implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Always deals the same Find Checks position (four checks).
class _FixedScans extends ScanPositionService {
  static final _position = () {
    const fen = '2r3k1/2p3pp/1BQ2p2/7q/8/3bP3/5PP1/R5K1 w - - 0 33';
    final position = Chess.fromSetup(Setup.parseFen(fen));
    return ScanPosition(
      fen: fen,
      position: position,
      targetCount: 4,
      sideToMove: position.turn,
    );
  }();

  @override
  Future<void> load(ScanSetKind kind) async {}

  @override
  int count(ScanSetKind kind) => 1;

  @override
  ScanPosition getRandom(ScanSetKind kind, {ScanPosition? exclude}) =>
      _position;
}

final _scans = _FixedScans();

/// Deals the puzzles whose answers are [sans], in order: the first gets
/// solved, the second is on screen (a mate in a full middlegame).
class _ChosenPuzzles extends PuzzleService {
  _ChosenPuzzles(this.sans) : super(random: Random(1)) {
    // A test-only loader; this file is test tooling.
    // ignore: invalid_use_of_visible_for_testing_member
    loadFromJson(File('assets/puzzles/moves_puzzles.json').readAsStringSync());
  }

  final List<String> sans;
  var _dealt = 0;

  @override
  ParsedPuzzle getRandomPuzzle({ParsedPuzzle? exclude, Side? sideToMove}) {
    final want = sans[min(_dealt++, sans.length - 1)];
    for (var i = 0; i < 2000; i++) {
      final puzzle = super.getRandomPuzzle(sideToMove: sideToMove);
      if (puzzle.san == want) return puzzle;
    }
    return super.getRandomPuzzle(exclude: exclude, sideToMove: sideToMove);
  }
}
final _book = OpeningBookService();

/// Plausible Stockfish answers for the Ruy Lopez position in the opening
/// scene (5. O-O, d3, Qe2 at about +0.3); nothing for anything else.
class _ShowcaseEngine implements StockfishService {
  static const _ruyLopez =
      'r1bqkb1r/1ppp1ppp/p1n2n2/4p3/B3P3/5N2/PPPP1PPP/RNBQK2R w KQkq';

  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  bool get isBusy => false;

  @override
  Future<void> initialize() async => _ready = true;

  @override
  void stopSearch() {}

  @override
  Future<EvalResult> evaluate(String fen, {int? depth, int? movetime}) async {
    await initialize();
    return EvalResult(centipawns: 31, depth: depth ?? 18);
  }

  @override
  Future<String?> getBestMove(String fen,
          {int? depth, int? movetime, int skillLevel = 20}) async =>
      fen.startsWith(_ruyLopez) ? 'e1g1' : null;

  @override
  Future<List<ScoredMove>> getTopMoves(String fen,
      {int count = 3,
      int? depth,
      int? movetime,
      void Function(int depth)? onDepth}) async {
    await initialize();
    onDepth?.call(18);
    if (!fen.startsWith(_ruyLopez)) return const [];
    return const [
      ScoredMove(uci: 'e1g1', centipawns: 31, multipvIndex: 1),
      ScoredMove(uci: 'd2d3', centipawns: 24, multipvIndex: 2),
      ScoredMove(uci: 'd1e2', centipawns: 19, multipvIndex: 3),
    ];
  }

  @override
  void disposeWhenIdle() {}

  @override
  void dispose() {}
}

// ------------------------------------------------------------------- tests

void main() {
  setUpAll(() async {
    await _loadFonts();
    await _book.load();
  });

  testWidgets('app icon, adaptive icon layers, Play icon', (tester) async {
    await _paintIcon(tester, 1024, 'assets/images/app_icon.png');
    await _paintIcon(tester, 512, 'resources/store/android/icon-512.png');
    await _paintIcon(tester, 1024, 'resources/icon/app_icon_background.png',
        layer: _IconLayer.background);
    await _paintIcon(tester, 1024, 'resources/icon/app_icon_foreground.png',
        layer: _IconLayer.foreground);
    await _paintIcon(tester, 1024, 'resources/icon/app_icon_monochrome.png',
        layer: _IconLayer.monochrome);
  });

  testWidgets('Play feature graphic', (tester) async {
    await _renderToFile(
      tester,
      const Size(1024, 500),
      const _FeatureGraphic(),
      'resources/store/android/feature-graphic-1024x500.png',
    );
  });

  for (final (name, device) in const [
    ('iPhone 6.5"', _iphone),
    ('iPad 13"', _ipad),
    ('Android phone', _androidPhone),
    ('Android tablet', _androidTablet),
  ]) {
    testWidgets('$name screenshots', (tester) async {
      final dir = Directory(device.dir);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      dir.createSync(recursive: true);
      for (final scene in _scenes()) {
        final screen = await _renderScreen(tester, device, scene);
        await _renderToFile(
          tester,
          device.canvas,
          _ShotFrame(device: device, scene: scene, screen: screen),
          '${device.dir}/${scene.file}',
        );
        screen.dispose();
      }
    });
  }
}

// --------------------------------------------------------------- rendering

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File(file).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Bricolage', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'assets/fonts/BricolageGrotesque-$w.ttf',
  ]);
  await load('GeistMono', [
    for (final w in ['Regular', 'Medium', 'SemiBold'])
      'assets/fonts/GeistMono-$w.ttf',
  ]);
  // flutter_tester lives in <flutter>/bin/cache/artifacts/engine/<platform>/.
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
  final material = '${artifacts.path}/material_fonts';
  await load('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
  await load('Roboto', [
    '$material/Roboto-Regular.ttf',
    '$material/Roboto-Medium.ttf',
    '$material/Roboto-Bold.ttf',
  ]);
}

/// Lets asset images (pieces, glyphs) finish loading.
Future<void> _settle(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp).first);
  await tester.runAsync(() async {
    for (final image in PieceSet.cburnett.assets.values) {
      await precacheImage(image, context);
    }
  });
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The scene's screen in the device's window, at the pixel size it will have
/// in the screenshot.
Future<ui.Image> _renderScreen(
    WidgetTester tester, _Device device, _Scene scene) async {
  final ratio = device.screenWidth / device.window.width;
  tester.view.physicalSize = device.window * ratio;
  tester.view.devicePixelRatio = ratio;
  tester.view.padding = FakeViewPadding(
      top: device.safe.top * ratio, bottom: device.safe.bottom * ratio);
  tester.view.viewPadding = FakeViewPadding(
      top: device.safe.top * ratio, bottom: device.safe.bottom * ratio);
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: [
    audioServiceProvider.overrideWithValue(_SilentAudio()),
    analyticsServiceProvider.overrideWithValue(_NoopAnalytics()),
    ...scene.overrides.cast(),
  ]);
  scene.seed?.call(container);

  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(
    key: key,
    child: UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.noScaling),
          child: Stack(children: [
            child!,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: device.safe.top,
              child: _StatusBar(style: device.bar),
            ),
          ]),
        ),
        home: scene.screen,
      ),
    ),
  ));
  await tester.pump(); // post-frame startGame
  await tester.pump(const Duration(milliseconds: 100));
  await _settle(tester);
  if (scene.play != null) await scene.play!(tester, container);
  await _settle(tester);

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => boundary.toImage(pixelRatio: ratio)))!;

  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5)); // let timers wind down
  container.dispose();
  return image;
}

/// Renders [child] at [size] pixels and writes it as an opaque RGB PNG.
Future<void> _renderToFile(
    WidgetTester tester, Size size, Widget child, String path) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.resetPadding();
  tester.view.resetViewPadding();
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: RepaintBoundary(
        key: key,
        child: SizedBox.fromSize(size: size, child: child),
      ),
    ),
  ));
  await _settleImagesOnly(tester);
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(_encodeRgbPng(image.width, image.height, rgba));
    image.dispose();
  });
}

Future<void> _settleImagesOnly(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
}

/// A PNG with no alpha channel (App Store Connect rejects screenshots that
/// have one). [rgba] must be opaque.
Uint8List _encodeRgbPng(int width, int height, Uint8List rgba) {
  final stride = width * 3 + 1;
  final raw = Uint8List(stride * height);
  for (var y = 0; y < height; y++) {
    var o = y * stride + 1; // byte 0 of each row: filter "none"
    var i = y * width * 4;
    for (var x = 0; x < width; x++, i += 4, o += 3) {
      raw[o] = rgba[i];
      raw[o + 1] = rgba[i + 1];
      raw[o + 2] = rgba[i + 2];
    }
  }

  final out = BytesBuilder();
  void chunk(String type, List<int> data) {
    final typed = [...type.codeUnits, ...data];
    out
      ..add(_u32(data.length))
      ..add(typed)
      ..add(_u32(_crc32(typed)));
  }

  out.add(const [137, 80, 78, 71, 13, 10, 26, 10]);
  chunk('IHDR', [..._u32(width), ..._u32(height), 8, 2, 0, 0, 0]);
  chunk('IDAT', ZLibCodec(level: 9).encode(raw));
  chunk('IEND', const []);
  return out.toBytes();
}

List<int> _u32(int v) => [v >> 24 & 255, v >> 16 & 255, v >> 8 & 255, v & 255];

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 255] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

// ------------------------------------------------------------------- frame

/// A screenshot: caption on brand green, the screen below running off the
/// bottom edge.
class _ShotFrame extends StatelessWidget {
  const _ShotFrame({
    required this.device,
    required this.scene,
    required this.screen,
  });

  final _Device device;
  final _Scene scene;
  final ui.Image screen;

  @override
  Widget build(BuildContext context) {
    final w = device.canvas.width;
    final h = device.canvas.height;
    final screenW = screen.width.toDouble();
    final screenH = screen.height.toDouble();
    // The screen sits on the bottom edge; the caption fills the space above.
    final top = h - screenH;
    final unit = device.landscape ? h / 1400 : w / 1000;
    final radius = screenW * (device.landscape ? 0.022 : 0.06);

    return ColoredBox(
      color: AppColors.brand,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _Checks(unit: unit))),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 64 * unit),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    scene.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.ui,
                      fontSize: 76 * unit,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.6 * unit,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16 * unit),
                  Text(
                    scene.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.ui,
                      fontSize: 38 * unit,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  SizedBox(height: 10 * unit),
                ],
              ),
            ),
          ),
          Positioned(
            top: top,
            left: (w - screenW) / 2,
            width: screenW,
            height: screenH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x55041F15),
                    blurRadius: 60 * unit,
                    offset: Offset(0, 18 * unit),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                child: RawImage(
                  image: screen,
                  width: screenW,
                  height: screenH,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The faint checkerboard in the top corner, as on the home warm-up card.
class _Checks extends CustomPainter {
  _Checks({required this.unit});

  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = 70 * unit;
    final cols = (size.width / cell).ceil();
    final rows = (size.height * 0.4 / cell).ceil();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if ((r + c).isOdd) continue;
        // Fades out away from the top-right corner.
        final dx = (cols - c) / cols;
        final dy = r / rows;
        final t = (1 - (dx * 0.9 + dy * 0.9)).clamp(0.0, 1.0);
        if (t <= 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(c * cell, r * cell, cell, cell),
          Paint()..color = Colors.white.withValues(alpha: 0.06 * t),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Checks old) => old.unit != unit;
}

/// A clean status bar for the window's top inset.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.style});

  final _Bar style;

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.ink;
    TextStyle text(double size) => TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: ink,
          letterSpacing: -0.2,
          decoration: TextDecoration.none,
        );

    return switch (style) {
      _Bar.iphone => Padding(
          padding: const EdgeInsets.fromLTRB(46, 14, 30, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('9:41', style: text(17)),
              const Spacer(),
              const _SignalBars(height: 11),
              const SizedBox(width: 6),
              const Icon(Icons.wifi_rounded, size: 17, color: ink),
              const SizedBox(width: 6),
              const _Battery(width: 25, height: 12),
            ],
          ),
        ),
      _Bar.ipad => Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
          child: Row(
            children: [
              Text('9:41', style: text(14)),
              const SizedBox(width: 8),
              Text('Mon Oct 5',
                  style: text(14).copyWith(fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.wifi_rounded, size: 15, color: ink),
              const SizedBox(width: 6),
              Text('100%',
                  style: text(13).copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(width: 5),
              const _Battery(width: 23, height: 11),
            ],
          ),
        ),
      _Bar.android => Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 16, 0),
          child: Row(
            children: [
              Text('9:00', style: text(13).copyWith(fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.wifi_rounded, size: 15, color: ink),
              const SizedBox(width: 4),
              const Icon(Icons.signal_cellular_4_bar_rounded,
                  size: 14, color: ink),
              const SizedBox(width: 4),
              const Icon(Icons.battery_full_rounded, size: 15, color: ink),
            ],
          ),
        ),
    };
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 1.6),
          Container(
            width: 3,
            height: height * (0.4 + 0.2 * i),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ],
    );
  }
}

class _Battery extends StatelessWidget {
  const _Battery({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            border: Border.all(
                color: AppColors.ink.withValues(alpha: 0.4), width: 1),
            borderRadius: BorderRadius.circular(height * 0.3),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(height * 0.18),
            ),
          ),
        ),
        Container(
          width: 1.6,
          height: height * 0.36,
          margin: const EdgeInsets.only(left: 1),
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------- icon

enum _IconLayer { full, background, foreground, monochrome }

/// The LogoMark as an app icon: a knight's L-move on a 3×3 grid, from a white
/// start to an amber target. [_IconLayer.full] fills the square (stores and
/// iOS round the corners themselves); the adaptive layers are transparent
/// and keep the mark inside Android's safe zone.
class _IconPainter extends CustomPainter {
  const _IconPainter(this.layer);

  final _IconLayer layer;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    if (layer == _IconLayer.full || layer == _IconLayer.background) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF14795B), Color(0xFF0B5A40)],
          ).createShader(Offset.zero & size),
      );
      if (layer == _IconLayer.background) return;
    }
    // The grid spans 30 of the LogoMark's 40 units; scale it to [grid] of
    // the icon. Android shows the middle 72 dp of a 108 dp adaptive layer,
    // masked to a circle at worst: 0.46 keeps the whole grid inside it.
    final grid = layer == _IconLayer.full ? 0.66 : 0.46;
    final k = s * grid / 30;
    canvas.translate(s * (1 - grid) / 2, s * (1 - grid) / 2);
    canvas.scale(k);

    final mono = layer == _IconLayer.monochrome;
    final cell = Paint()
      ..color = Colors.white.withValues(alpha: mono ? 0.35 : 0.15);
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        if ((c + r).isEven) {
          canvas.drawRect(Rect.fromLTWH(c * 10.0, r * 10.0, 10, 10), cell);
        }
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(11, 1, 8, 8), const Radius.circular(2)),
      Paint()..color = mono ? Colors.white : AppColors.amber,
    );
    canvas.drawPath(
      Path()
        ..moveTo(5, 25)
        ..lineTo(5, 5)
        ..lineTo(15, 5),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(const Offset(5, 25), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.layer != layer;
}

Future<void> _paintIcon(WidgetTester tester, int px, String path,
    {_IconLayer layer = _IconLayer.full}) async {
  final size = Size.square(px.toDouble());
  if (layer == _IconLayer.full || layer == _IconLayer.background) {
    await _renderToFile(
        tester, size, CustomPaint(painter: _IconPainter(layer)), path);
    return;
  }
  // Adaptive layers keep their transparency.
  final recorder = ui.PictureRecorder();
  _IconPainter(layer).paint(Canvas(recorder), size);
  await tester.runAsync(() async {
    final image = await recorder.endRecording().toImage(px, px);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(png.buffer.asUint8List());
    image.dispose();
  });
}

// --------------------------------------------------------- feature graphic

/// Play's 1024×500 banner: the icon and the name, centred, on brand green.
class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.brand,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _Checks(unit: 0.62))),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 168,
                  height: 168,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55041F15),
                        blurRadius: 36,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: const CustomPaint(
                        painter: _IconPainter(_IconLayer.full)),
                  ),
                ),
                const SizedBox(width: 44),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calvin Chess Trainer',
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: 58,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Board vision and notation drills',
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
