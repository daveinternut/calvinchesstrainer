import 'package:calvinchesstrainer/core/widgets/trainer_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the size TrainerLayout hands its board builder.
Widget _app({required ValueChanged<double> onBoardSize}) {
  return MaterialApp(
    home: Scaffold(
      body: TrainerLayout(
        header: const [SizedBox(key: Key('header'), height: 60, width: 200)],
        board: (context, size) {
          onBoardSize(size);
          return Container(key: const Key('board'), color: Colors.green);
        },
        footer: const [SizedBox(key: Key('footer'), height: 40, width: 200)],
      ),
    ),
  );
}

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    ValueChanged<double> onBoardSize,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(onBoardSize: onBoardSize));
  }

  testWidgets('portrait iPad stacks header, board, footer', (tester) async {
    late double board;
    await pumpAt(tester, const Size(820, 1180), (s) => board = s);

    final header = tester.getRect(find.byKey(const Key('header')));
    final boardRect = tester.getRect(find.byKey(const Key('board')));
    final footer = tester.getRect(find.byKey(const Key('footer')));
    expect(header.bottom, lessThanOrEqualTo(boardRect.top));
    expect(boardRect.bottom, lessThanOrEqualTo(footer.top));
    expect(board, 820 - 32, reason: 'full width minus the side padding');
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape iPad puts the board left, panel right', (
    tester,
  ) async {
    late double board;
    await pumpAt(tester, const Size(1180, 820), (s) => board = s);

    final boardRect = tester.getRect(find.byKey(const Key('board')));
    final header = tester.getRect(find.byKey(const Key('header')));
    final footer = tester.getRect(find.byKey(const Key('footer')));
    expect(
      header.left,
      greaterThan(boardRect.right),
      reason: 'the panel sits to the right of the board',
    );
    expect(footer.top, greaterThan(header.bottom));
    expect(board, 820 - 32, reason: 'full height minus the vertical padding');
    expect(tester.takeException(), isNull);
  });

  testWidgets('phones and narrow windows keep the column layout', (
    tester,
  ) async {
    for (final size in const [Size(390, 844), Size(500, 400), Size(560, 380)]) {
      late double board;
      await pumpAt(tester, size, (s) => board = s);
      final header = tester.getRect(find.byKey(const Key('header')));
      final boardRect = tester.getRect(find.byKey(const Key('board')));
      expect(header.bottom, lessThanOrEqualTo(boardRect.top), reason: '$size');
      expect(board, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('short landscape windows put the board left, even under 600 wide', (
    tester,
  ) async {
    for (final size in const [Size(750, 369), Size(592, 336), Size(568, 320)]) {
      late double board;
      await pumpAt(tester, size, (s) => board = s);
      final boardRect = tester.getRect(find.byKey(const Key('board')));
      final header = tester.getRect(find.byKey(const Key('header')));
      expect(header.left, greaterThan(boardRect.right), reason: '$size');
      expect(board, greaterThan(200), reason: '$size');
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets(
    'short landscape windows scroll the panel instead of overflowing',
    (tester) async {
      await pumpAt(tester, const Size(700, 300), (_) {});
      expect(tester.takeException(), isNull);
    },
  );
}
