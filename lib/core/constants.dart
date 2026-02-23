class ChessConstants {
  static const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  static const ranks = ['1', '2', '3', '4', '5', '6', '7', '8'];


  static const boardSize = 8;

  static List<String> get allSquares {
    return [
      for (final file in files)
        for (final rank in ranks) '$file$rank',
    ];
  }

  static String squareName(int fileIndex, int rankIndex) {
    return '${files[fileIndex]}${ranks[rankIndex]}';
  }
}

class TimerConstants {
  static const defaultDurationSeconds = 60;
  static const blitzDurationSeconds = 30;
  static const marathonDurationSeconds = 180;
}
