import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/move_game_state.dart';

class MoveMenuScreen extends StatefulWidget {
  final MoveTrainerMode initialMode;
  final bool initialHardMode;

  const MoveMenuScreen({
    super.key,
    this.initialMode = MoveTrainerMode.practice,
    this.initialHardMode = false,
  });

  @override
  State<MoveMenuScreen> createState() => _MoveMenuScreenState();
}

class _MoveMenuScreenState extends State<MoveMenuScreen> {
  late MoveTrainerMode _mode = widget.initialMode;
  late bool _isHardMode = widget.initialHardMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moves'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'See a position, make the move!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Text(
                'Choose a mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              _buildModeCard(
                MoveTrainerMode.practice,
                'Practice',
                'Quiz yourself — build your streak!',
                Icons.school_rounded,
                const Color(0xFF1565C0),
              ),
              const SizedBox(height: 10),
              _buildModeCard(
                MoveTrainerMode.speed,
                'Speed Round',
                '30 seconds — how many can you get?',
                Icons.timer_rounded,
                const Color(0xFFE65100),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => setState(() => _isHardMode = !_isHardMode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isHardMode
                        ? const Color(0xFFB71C1C)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isHardMode
                          ? const Color(0xFFB71C1C)
                          : Colors.grey.shade300,
                      width: _isHardMode ? 2 : 1,
                    ),
                    boxShadow: _isHardMode
                        ? [
                            BoxShadow(
                              color: const Color(0xFFB71C1C)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: _isHardMode
                            ? Colors.white
                            : Colors.grey.shade400,
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
                                color: _isHardMode
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'User controls black!',
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
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
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

  Widget _buildModeCard(
    MoveTrainerMode mode,
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
    context.push(
      '/move-trainer/game'
      '?mode=${_mode.name}'
      '&hardMode=$_isHardMode',
    );
  }
}
