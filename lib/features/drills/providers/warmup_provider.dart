import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chess_vision/models/chess_vision_state.dart' show WhitePiece;
import '../models/drill.dart';

/// The daily warm-up: five quick timed drills that train what puzzles skip.
/// Four 60-second vision rounds and one 30-second squares round from Black's
/// side — about five minutes.
class WarmupState {
  const WarmupState({this.steps = const [], this.index = 0, this.scores = const []});

  final List<DrillConfig> steps;

  /// The step being played (== steps.length once the last one is done).
  final int index;

  /// Each finished step's score, in order.
  final List<int> scores;

  bool get isActive => steps.isNotEmpty && index < steps.length;
  bool get isComplete => steps.isNotEmpty && index >= steps.length;
  DrillConfig? get current => isActive ? steps[index] : null;
  DrillConfig? get next => index + 1 < steps.length ? steps[index + 1] : null;
  bool get isLastStep => isActive && index == steps.length - 1;
}

/// App-lifetime; never saved (a warm-up is one sitting).
final warmupProvider = NotifierProvider<WarmupNotifier, WarmupState>(
  WarmupNotifier.new,
);

class WarmupNotifier extends Notifier<WarmupState> {
  @override
  WarmupState build() => const WarmupState();

  /// The five steps for [day]. Forks & Skewers rotates its piece daily so
  /// the warm-up doesn't drill the same geometry every morning.
  static List<DrillConfig> stepsFor(DateTime day) {
    final piece = WhitePiece.values[day.weekday % WhitePiece.values.length];
    return [
      const DrillConfig(drill: DrillId.findChecks, mode: DrillMode.speed),
      const DrillConfig(drill: DrillId.hangingPieces, mode: DrillMode.speed),
      DrillConfig(
        drill: DrillId.forksAndSkewers,
        mode: DrillMode.speed,
        piece: piece,
      ),
      const DrillConfig(
        drill: DrillId.squares,
        mode: DrillMode.speed,
        blackSide: true,
      ),
      const DrillConfig(drill: DrillId.mateInOne, mode: DrillMode.speed),
    ];
  }

  /// Starts a fresh warm-up and returns its first step.
  DrillConfig start({DateTime? now}) {
    state = WarmupState(steps: stepsFor(now ?? DateTime.now()));
    return state.steps.first;
  }

  /// Records the current step's [score] and moves on. Returns the next step,
  /// or null when that was the last one.
  DrillConfig? completeStep(int score) {
    if (!state.isActive) return null;
    state = WarmupState(
      steps: state.steps,
      index: state.index + 1,
      scores: [...state.scores, score],
    );
    return state.current;
  }

  void end() => state = const WarmupState();
}
