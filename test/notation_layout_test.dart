import 'dart:io';
import 'dart:math';

import 'package:calvinchesstrainer/core/audio/audio_service.dart';
import 'package:calvinchesstrainer/core/services/analytics_service.dart';
import 'package:calvinchesstrainer/core/services/puzzle_service.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/models/file_rank_game_state.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/screens/file_rank_game_screen.dart';
import 'package:calvinchesstrainer/features/file_rank_trainer/screens/file_rank_menu_screen.dart';
import 'package:calvinchesstrainer/features/letter_trainer/models/letter_game_state.dart';
import 'package:calvinchesstrainer/features/letter_trainer/screens/letter_game_screen.dart';
import 'package:calvinchesstrainer/features/move_trainer/models/move_game_state.dart';
import 'package:calvinchesstrainer/features/move_trainer/screens/move_game_screen.dart';
import 'package:calvinchesstrainer/features/move_trainer/screens/move_menu_screen.dart';
import 'package:calvinchesstrainer/features/pieces/models/which_side_wins_state.dart';
import 'package:calvinchesstrainer/features/pieces/screens/which_side_wins_screen.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SilentAudio implements AudioService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _NoopAnalytics implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Window sizes the notation screens must lay out in without overflowing:
/// iPads both ways (iPad ignores the portrait lock), a small Stage Manager
/// window, and phones.
const _sizes = {
  'iPad portrait': Size(820, 1180),
  'iPad landscape': Size(1180, 820),
  'iPad Pro landscape': Size(1366, 1024),
  'iPad mini landscape': Size(1133, 744),
  'small landscape window': Size(700, 500),
  'phone': Size(375, 812),
  'small phone': Size(320, 568),
};

final _screens = <String, Widget Function()>{
  'files explore': () => const FileRankGameScreen(
      subject: TrainerSubject.files, mode: TrainerMode.explore),
  'squares speed': () => const FileRankGameScreen(
      subject: TrainerSubject.squares, mode: TrainerMode.speed),
  'moves speed': () => const MoveGameScreen(mode: MoveTrainerMode.speed),
  'letters explore': () =>
      const LetterGameScreen(mode: LetterTrainerMode.explore),
  'letters speed': () => const LetterGameScreen(mode: LetterTrainerMode.speed),
  'which side wins practice': () =>
      const WhichSideWinsScreen(mode: WhichSideWinsMode.practice),
  'which side wins speed': () =>
      const WhichSideWinsScreen(mode: WhichSideWinsMode.speed),
  'notation menu': () => const FileRankMenuScreen(),
  'moves menu': () => const MoveMenuScreen(),
};

void main() {
  for (final MapEntry(key: sizeName, value: size) in _sizes.entries) {
    group(sizeName, () {
      for (final MapEntry(key: screenName, value: screen)
          in _screens.entries) {
        testWidgets(screenName, (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(ProviderScope(
            overrides: [
              audioServiceProvider.overrideWithValue(_SilentAudio()),
              analyticsServiceProvider.overrideWithValue(_NoopAnalytics()),
              puzzleServiceProvider.overrideWithValue(
                PuzzleService(random: Random(4))
                  ..loadFromJson(File('assets/puzzles/moves_puzzles.json')
                      .readAsStringSync()),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: screen(),
            ),
          ));
          await tester.pump(); // post-frame startGame
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.takeException(), isNull);

          // Speed rounds: run the clock out so the results card lays out too.
          if (screenName.endsWith('speed')) {
            for (var i = 0; i < 31; i++) {
              await tester.pump(const Duration(seconds: 1));
            }
            expect(find.text("Time's Up!"), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
        });
      }
    });
  }
}
