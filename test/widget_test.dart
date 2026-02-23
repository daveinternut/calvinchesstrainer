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

    expect(find.text('Calvin Chess\nTrainer'), findsOneWidget);
    expect(find.text('Master the fundamentals'), findsOneWidget);
    expect(find.text('Chess Notation'), findsOneWidget);
  });
}
