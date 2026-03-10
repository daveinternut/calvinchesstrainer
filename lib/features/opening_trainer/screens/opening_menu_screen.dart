import 'package:chessground/chessground.dart' show PieceSet;
import 'package:dartchess/dartchess.dart' show PieceKind, Side;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/opening_game_state.dart';

class OpeningMenuScreen extends StatefulWidget {
  final OpeningMode initialMode;
  final OpeningDifficulty initialDifficulty;
  final Side initialColor;

  const OpeningMenuScreen({
    super.key,
    this.initialMode = OpeningMode.practice,
    this.initialDifficulty = OpeningDifficulty.easy,
    this.initialColor = Side.white,
  });

  @override
  State<OpeningMenuScreen> createState() => _OpeningMenuScreenState();
}

class _OpeningMenuScreenState extends State<OpeningMenuScreen> {
  late OpeningMode _mode = widget.initialMode;
  late OpeningDifficulty _difficulty = widget.initialDifficulty;
  late Side _playerColor = widget.initialColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opening Fundamentals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Play as',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildColorChip(
                          Side.white,
                          PieceKind.whiteKing,
                          'White',
                        ),
                        const SizedBox(width: 12),
                        _buildColorChip(
                          Side.black,
                          PieceKind.blackKing,
                          'Black',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Difficulty',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildDifficultyChip(
                          OpeningDifficulty.easy,
                          'Easy',
                          Icons.sentiment_satisfied_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildDifficultyChip(
                          OpeningDifficulty.medium,
                          'Medium',
                          Icons.sentiment_neutral_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildDifficultyChip(
                          OpeningDifficulty.hard,
                          'Hard',
                          Icons.sentiment_very_dissatisfied_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Choose a mode',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 12),
                    _buildModeCard(
                      OpeningMode.practice,
                      'Practice',
                      'Play with hints — top 3 moves shown as arrows',
                      Icons.school_rounded,
                      const Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 10),
                    _buildModeCard(
                      OpeningMode.challenge,
                      'Challenge',
                      'Test your opening skills — earn medals!',
                      Icons.emoji_events_rounded,
                      const Color(0xFFE65100),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _startGame,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Start'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip(Side color, PieceKind pieceKind, String label) {
    final selected = _playerColor == color;
    final asset = PieceSet.cburnett.assets[pieceKind];
    final chipColor =
        color == Side.white ? Colors.white : Colors.grey.shade800;
    final borderColor = color == Side.white
        ? (selected ? AppColors.primary : Colors.grey.shade300)
        : (selected ? AppColors.primary : Colors.grey.shade500);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _playerColor = color),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : chipColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child:
                    asset != null ? Image(image: asset) : const SizedBox(),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(
    OpeningDifficulty diff,
    String label,
    IconData icon,
  ) {
    final selected = _difficulty == diff;
    return Expanded(
      child: ChoiceChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color:
                    selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => setState(() => _difficulty = diff),
        showCheckmark: false,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildModeCard(
    OpeningMode mode,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? Colors.white : color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    context.push(
      '/opening-trainer/game'
      '?mode=${_mode.name}'
      '&difficulty=${_difficulty.name}'
      '&playerColor=${_playerColor.name}',
    );
  }
}
