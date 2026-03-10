import 'package:flutter/material.dart';

import '../models/opening_game_state.dart';

class MedalProgress extends StatelessWidget {
  final int userMoveCount;

  const MedalProgress({
    super.key,
    required this.userMoveCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MedalIcon(
          label: '3',
          earned: userMoveCount >= 3,
          level: MedalLevel.bronze,
        ),
        const SizedBox(width: 8),
        _MedalIcon(
          label: '6',
          earned: userMoveCount >= 6,
          level: MedalLevel.silver,
        ),
        const SizedBox(width: 8),
        _MedalIcon(
          label: '10',
          earned: userMoveCount >= 10,
          level: MedalLevel.gold,
        ),
      ],
    );
  }
}

class _MedalIcon extends StatelessWidget {
  final String label;
  final bool earned;
  final MedalLevel level;

  const _MedalIcon({
    required this.label,
    required this.earned,
    required this.level,
  });

  Color get _color => switch (level) {
        MedalLevel.bronze => const Color(0xFFCD7F32),
        MedalLevel.silver => const Color(0xFFC0C0C0),
        MedalLevel.gold => const Color(0xFFFFD700),
        MedalLevel.none => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: earned ? _color : Colors.grey.shade300,
            boxShadow: earned
                ? [
                    BoxShadow(
                      color: _color.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              earned ? Icons.emoji_events : Icons.emoji_events_outlined,
              size: 16,
              color: earned ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: earned ? _color : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
