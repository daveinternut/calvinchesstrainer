import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/which_side_wins_state.dart';

class PiecesMenuScreen extends StatefulWidget {
  final WhichSideWinsMode initialMode;
  final PiecesDifficulty initialDifficulty;

  const PiecesMenuScreen({
    super.key,
    this.initialMode = WhichSideWinsMode.practice,
    this.initialDifficulty = PiecesDifficulty.easy,
  });

  @override
  State<PiecesMenuScreen> createState() => _PiecesMenuScreenState();
}

class _PiecesMenuScreenState extends State<PiecesMenuScreen> {
  late WhichSideWinsMode _mode = widget.initialMode;
  late PiecesDifficulty _difficulty = widget.initialDifficulty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.thePieces),
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
                    // Section: Which Side Wins game
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0277BD),
                            const Color(0xFF0277BD).withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0277BD)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.balance_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.whichSideWins,
                            style: const TextStyle(
                              fontFamily: 'BradBunR',
                              fontSize: 32,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.whichSideWinsDesc,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    Text(
                      l10n.difficulty,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildDifficultyChip(
                          PiecesDifficulty.easy,
                          l10n.easy,
                          l10n.piecesEasyDesc,
                        ),
                        const SizedBox(width: 8),
                        _buildDifficultyChip(
                          PiecesDifficulty.medium,
                          l10n.medium,
                          l10n.piecesMediumDesc,
                        ),
                        const SizedBox(width: 8),
                        _buildDifficultyChip(
                          PiecesDifficulty.hard,
                          l10n.hard,
                          l10n.piecesHardDesc,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Text(
                      l10n.chooseAMode,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 12),
                    _buildModeCard(
                      WhichSideWinsMode.practice,
                      l10n.practice,
                      l10n.whichSideWinsPracticeDesc,
                      Icons.school_rounded,
                      const Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 10),
                    _buildModeCard(
                      WhichSideWinsMode.speed,
                      l10n.speedRound,
                      l10n.speedRoundDesc,
                      Icons.timer_rounded,
                      const Color(0xFFE65100),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.push(
                      '/the-pieces/which-side-wins?mode=${_mode.name}&difficulty=${_difficulty.name}',
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    l10n.start,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(
    PiecesDifficulty difficulty,
    String label,
    String description,
  ) {
    final selected = _difficulty == difficulty;
    const color = Color(0xFF0277BD);
    return Expanded(
      child: Tooltip(
        message: description,
        child: GestureDetector(
          onTap: () => setState(() => _difficulty = difficulty),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : Colors.grey.shade300,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: selected ? color : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    WhichSideWinsMode mode,
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
          color: selected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? color
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: selected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
