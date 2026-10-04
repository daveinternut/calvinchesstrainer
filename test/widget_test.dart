import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calvinchesstrainer/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CalvinChessTrainerApp(),
      ),
    );

    expect(find.text('Calvin Chess Trainer'), findsOneWidget);
    expect(find.text('Train what puzzles skip'), findsOneWidget);
    expect(find.text('Vision'), findsOneWidget);
    expect(find.text('Notation'), findsOneWidget);
  });
}
