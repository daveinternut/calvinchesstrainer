import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/file_rank_game_state.dart';


class FileRankMenuScreen extends StatefulWidget {
  final TrainerSubject initialSubject;
  final TrainerMode initialMode;
  final bool initialReverse;
  final bool initialHardMode;

  const FileRankMenuScreen({
    super.key,
    this.initialSubject = TrainerSubject.files,
    this.initialMode = TrainerMode.explore,
    this.initialReverse = false,
    this.initialHardMode = false,
  });

  @override
  State<FileRankMenuScreen> createState() => _FileRankMenuScreenState();
}

class _FileRankMenuScreenState extends State<FileRankMenuScreen> {
  late TrainerSubject _subject = widget.initialSubject;
  late TrainerMode _mode = widget.initialMode;
  late bool _isReverse = widget.initialReverse;
  late bool _isHardMode = widget.initialHardMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Notation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What to practice?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildSubjectChip(TrainerSubject.files, 'Files', Icons.view_column),
                  const SizedBox(width: 8),
                  _buildSubjectChip(TrainerSubject.ranks, 'Ranks', Icons.view_stream),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSubjectChip(TrainerSubject.squares, 'Squares', Icons.grid_on),
                  const SizedBox(width: 8),
                  _buildSubjectChip(TrainerSubject.moves, 'Moves', Icons.swap_horiz_rounded),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Choose a mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              if (_subject != TrainerSubject.moves) ...[
                _buildModeCard(
                  TrainerMode.explore,
                  'Explore',
                  'Tap to learn — no pressure, no scoring',
                  Icons.touch_app_rounded,
                  AppColors.primary,
                ),
                const SizedBox(height: 10),
              ],
              _buildModeCard(
                TrainerMode.practice,
                'Practice',
                'Quiz yourself — build your streak!',
                Icons.school_rounded,
                const Color(0xFF1565C0),
              ),
              const SizedBox(height: 10),
              _buildModeCard(
                TrainerMode.speed,
                'Speed Round',
                '30 seconds — how many can you get?',
                Icons.timer_rounded,
                const Color(0xFFE65100),
              ),
              const SizedBox(height: 28),
              if (_mode != TrainerMode.explore) ...[
                if (_subject != TrainerSubject.moves) ...[
                  GestureDetector(
                    onTap: () => setState(() => _isReverse = !_isReverse),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isReverse ? const Color(0xFF1565C0) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isReverse ? const Color(0xFF1565C0) : Colors.grey.shade300,
                          width: _isReverse ? 2 : 1,
                        ),
                        boxShadow: _isReverse
                            ? [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            color: _isReverse ? Colors.white : Colors.grey.shade400,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REVERSE MODE',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: _isReverse ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isReverse
                                      ? 'See the board, pick the name'
                                      : 'Hear the name, tap the board',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isReverse
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isReverse)
                            const Icon(Icons.check_circle, color: Colors.white, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                GestureDetector(
                  onTap: () => setState(() => _isHardMode = !_isHardMode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isHardMode ? const Color(0xFFB71C1C) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isHardMode ? const Color(0xFFB71C1C) : Colors.grey.shade300,
                        width: _isHardMode ? 2 : 1,
                      ),
                      boxShadow: _isHardMode
                          ? [BoxShadow(color: const Color(0xFFB71C1C).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: _isHardMode ? Colors.white : Colors.grey.shade400,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HARD MODE',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: _isHardMode ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _subject == TrainerSubject.moves
                                    ? 'User controls black!'
                                    : 'Board flipped — black\'s perspective!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isHardMode
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isHardMode)
                          const Icon(Icons.check_circle, color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
              const Spacer(),
              SizedBox(
                height: 56,
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectChip(TrainerSubject subject, String label, IconData icon) {
    final selected = _subject == subject;
    return Expanded(
      child: ChoiceChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => setState(() {
          _subject = subject;
          if (subject == TrainerSubject.moves) {
            if (_mode == TrainerMode.explore) {
              _mode = TrainerMode.practice;
            }
            _isReverse = false;
          }
        }),
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
    TrainerMode mode,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _mode = mode;
        if (mode == TrainerMode.explore) {
          _isReverse = false;
          _isHardMode = false;
        }
      }),
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
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 28),
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
                      color: selected ? Colors.white : AppColors.textPrimary,
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
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    if (_subject == TrainerSubject.moves) {
      context.go(
        '/move-trainer/game'
        '?mode=${_mode.name}'
        '&hardMode=$_isHardMode',
      );
    } else {
      context.go(
        '/file-rank-trainer/game'
        '?subject=${_subject.name}'
        '&mode=${_mode.name}'
        '&reverse=$_isReverse'
        '&hardMode=$_isHardMode',
      );
    }
  }
}
