import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/features/letter_trainer/models/letter_game_state.dart';
import 'package:calvinchesstrainer/features/letter_trainer/providers/letter_game_provider.dart';
import 'package:calvinchesstrainer/features/letter_trainer/screens/letter_game_screen.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Audio and analytics touch platform channels / Firebase, so tests swap in
/// inert fakes via provider overrides.
class _SilentAudioService implements AudioService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoopAnalyticsService implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// Type left to inference: flutter_riverpod 3.x doesn't export `Override`.
final _sharedOverrides = [
  audioServiceProvider.overrideWithValue(_SilentAudioService()),
  analyticsServiceProvider.overrideWithValue(_NoopAnalyticsService()),
];

Widget _app(LetterTrainerMode mode, {bool isHardMode = false}) {
  return ProviderScope(
    overrides: _sharedOverrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LetterGameScreen(mode: mode, isHardMode: isHardMode),
    ),
  );
}

ProviderContainer _readContainer(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(LetterGameScreen)),
  );
}

void main() {
  group('LetterGameNotifier', () {
    test('startGame generates a question with all six pieces as options', () {
      final container = ProviderContainer(overrides: _sharedOverrides);
      addTearDown(container.dispose);

      container
          .read(letterGameProvider.notifier)
          .startGame(LetterTrainerMode.practice);
      final state = container.read(letterGameProvider);

      expect(state.currentQuestion, isNotNull);
      final question = state.currentQuestion!;
      expect(question.options.length, 6);
      expect(question.options.toSet(), LetterPiece.values.toSet());
      expect(state.isWaitingForNext, false);
      expect(state.isGameOver, false);
    });

    test('letter tiles keep fixed order, piece prompts never lack a letter '
        'unless it is the pawn trick', () {
      final container = ProviderContainer(overrides: _sharedOverrides);
      addTearDown(container.dispose);
      final notifier = container.read(letterGameProvider.notifier);

      LetterPiece? previousTarget;
      for (var i = 0; i < 200; i++) {
        notifier.startGame(LetterTrainerMode.practice);
        final question = container.read(letterGameProvider).currentQuestion!;

        if (question.direction == LetterQuestionDirection.pieceToLetter) {
          expect(question.options, LetterPiece.values,
              reason: 'letter tiles should keep K Q R B N – order');
        }
        if (question.isNoLetterPrompt) {
          expect(question.target, LetterPiece.pawn);
        }
        previousTarget = question.target;
      }
      expect(previousTarget, isNotNull);
    });

    test('speed mode starts with a 30 second countdown', () {
      final container = ProviderContainer(overrides: _sharedOverrides);
      addTearDown(container.dispose);

      container
          .read(letterGameProvider.notifier)
          .startGame(LetterTrainerMode.speed);

      expect(container.read(letterGameProvider).timeRemainingSeconds, 30);
      // Dispose before the periodic timer fires to avoid pending-timer noise.
      container.dispose();
    });
  });

  group('LetterGameScreen — practice', () {
    testWidgets('correct answer builds streak and reveals the pairing',
        (tester) async {
      await tester.pumpWidget(_app(LetterTrainerMode.practice));
      await tester.pump(); // post-frame startGame

      final container = _readContainer(tester);
      var state = container.read(letterGameProvider);
      final target = state.currentQuestion!.target;

      await tester.tap(find.byKey(ValueKey('answer_${target.name}')));
      await tester.pump();

      state = container.read(letterGameProvider);
      expect(state.streak, 1);
      expect(state.totalCorrect, 1);
      expect(state.totalAttempts, 1);
      expect(state.lastFeedback?.result, AnswerResult.correct);
      expect(state.isWaitingForNext, true);

      // The reveal line ("N = Knight!" or the pawn fact) is on screen.
      if (target.hasLetter) {
        expect(
          find.textContaining('${target.letter} = '),
          findsOneWidget,
        );
      } else {
        expect(find.text("Pawns don't need a letter!"), findsOneWidget);
      }

      // After the 700ms correct delay a fresh question arrives.
      await tester.pump(const Duration(milliseconds: 800));
      state = container.read(letterGameProvider);
      expect(state.isWaitingForNext, false);
      expect(state.lastFeedback, isNull);
      expect(state.currentQuestion!.target, isNot(target));
    });

    testWidgets('wrong answer resets the streak and highlights the answer',
        (tester) async {
      await tester.pumpWidget(_app(LetterTrainerMode.practice));
      await tester.pump();

      final container = _readContainer(tester);
      var state = container.read(letterGameProvider);
      final target = state.currentQuestion!.target;
      final wrong = state.currentQuestion!.options
          .firstWhere((piece) => piece != target);

      await tester.tap(find.byKey(ValueKey('answer_${wrong.name}')));
      await tester.pump();

      state = container.read(letterGameProvider);
      expect(state.streak, 0);
      expect(state.totalCorrect, 0);
      expect(state.totalAttempts, 1);
      expect(state.lastFeedback?.result, AnswerResult.incorrect);
      expect(state.lastFeedback?.correct, target);

      // Input is gated during the feedback window.
      await tester.tap(find.byKey(ValueKey('answer_${target.name}')));
      await tester.pump();
      expect(container.read(letterGameProvider).totalAttempts, 1);

      await tester.pump(const Duration(milliseconds: 1300));
    });
  });

  group('LetterGameScreen — explore', () {
    testWidgets('shows all six cards; tapping reveals the mnemonic',
        (tester) async {
      await tester.pumpWidget(_app(LetterTrainerMode.explore));
      await tester.pump();

      expect(find.text('Tap a piece to learn its letter!'), findsOneWidget);
      for (final piece in LetterPiece.values) {
        expect(find.byKey(ValueKey('explore_${piece.name}')), findsOneWidget);
      }

      await tester.tap(find.byKey(const ValueKey('explore_knight')));
      await tester.pump();
      expect(
        find.text('N is for kNight — the King already took K!'),
        findsOneWidget,
      );

      // The mnemonic stays until another card is tapped.
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byKey(const ValueKey('explore_pawn')));
      await tester.pump();
      expect(
        find.text("Pawns are so brave they don't need a letter!"),
        findsOneWidget,
      );
    });
  });

  group('LetterGameScreen — speed', () {
    testWidgets('round ends after 30 seconds with the results card',
        (tester) async {
      await tester.pumpWidget(_app(LetterTrainerMode.speed));
      await tester.pump();

      final container = _readContainer(tester);
      expect(container.read(letterGameProvider).timeRemainingSeconds, 30);

      // Answer one question so the results have something to show.
      final target =
          container.read(letterGameProvider).currentQuestion!.target;
      await tester.tap(find.byKey(ValueKey('answer_${target.name}')));
      await tester.pump();

      for (var i = 0; i < 31; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      final state = container.read(letterGameProvider);
      expect(state.isGameOver, true);
      expect(state.timeRemainingSeconds, 0);
      expect(find.text("Time's Up!"), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);
    });
  });
}
