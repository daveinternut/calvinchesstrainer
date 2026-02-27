import 'package:chessground/chessground.dart' show PieceSet;
import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chess_vision_state.dart';

class ChessVisionMenuScreen extends StatefulWidget {
  final VisionDrillType initialDrill;
  final WhitePiece initialPiece;
  final TargetPiece initialTarget;
  final VisionMode initialMode;

  const ChessVisionMenuScreen({
    super.key,
    this.initialDrill = VisionDrillType.forksAndSkewers,
    this.initialPiece = WhitePiece.queen,
    this.initialTarget = TargetPiece.rook,
    this.initialMode = VisionMode.practice,
  });

  @override
  State<ChessVisionMenuScreen> createState() => _ChessVisionMenuScreenState();
}

class _ChessVisionMenuScreenState extends State<ChessVisionMenuScreen> {
  late VisionDrillType _drill = widget.initialDrill;
  late WhitePiece _piece = widget.initialPiece;
  late TargetPiece _target = widget.initialTarget;
  late VisionMode _mode = widget.initialMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess Vision'),
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
                'Drill type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDrillChip(
                    VisionDrillType.forksAndSkewers,
                    'Forks & Skewers',
                    Icons.call_split_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildDrillChip(
                    VisionDrillType.pawnAttack,
                    'Pawn Attack',
                    Icons.gps_not_fixed_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDrillChip(
                    VisionDrillType.knightSight,
                    'Knight Sight',
                    Icons.open_with_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildDrillChip(
                    VisionDrillType.knightFlight,
                    'Knight Flight',
                    Icons.route_rounded,
                  ),
                ],
              ),
              if (_drill == VisionDrillType.forksAndSkewers) ...[
                const SizedBox(height: 24),
                Text(
                  'Choose your piece',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final p in WhitePiece.values) ...[
                      if (p != WhitePiece.values.first)
                        const SizedBox(width: 8),
                      _buildPieceImageChip(
                        pieceKind: p.pieceKind,
                        selected: _piece == p,
                        onSelected: () => setState(() => _piece = p),
                        selectedColor: AppColors.primary,
                        tooltip: p.label,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Target piece',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final t in TargetPiece.values) ...[
                      if (t != TargetPiece.values.first)
                        const SizedBox(width: 8),
                      _buildPieceImageChip(
                        pieceKind: t.pieceKind,
                        selected: _target == t,
                        onSelected: () => setState(() => _target = t),
                        selectedColor: Colors.grey.shade800,
                        tooltip: t.label,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Choose a mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                _buildModeCard(
                  VisionMode.practice,
                  'Practice',
                  'Find forks and skewers — no timer',
                  Icons.school_rounded,
                  const Color(0xFF1565C0),
                ),
                const SizedBox(height: 10),
                _buildModeCard(
                  VisionMode.speed,
                  'Speed Round',
                  '60 seconds — solve as many as you can!',
                  Icons.timer_rounded,
                  const Color(0xFFE65100),
                ),
                const SizedBox(height: 10),
                _buildModeCard(
                  VisionMode.concentric,
                  'Concentric Drill',
                  'Complete all positions — beat your time!',
                  Icons.track_changes_rounded,
                  const Color(0xFF6A1B9A),
                ),
              ],
              if (_drill == VisionDrillType.pawnAttack) ...[
                const SizedBox(height: 24),
                Text(
                  'Choose your piece',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final p in WhitePiece.values) ...[
                      if (p != WhitePiece.values.first)
                        const SizedBox(width: 8),
                      _buildPieceImageChip(
                        pieceKind: p.pieceKind,
                        selected: _piece == p,
                        onSelected: () => setState(() => _piece = p),
                        selectedColor: AppColors.primary,
                        tooltip: p.label,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Choose a mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                _buildModeCard(
                  VisionMode.practice,
                  'Practice',
                  'Capture all pawns — no timer',
                  Icons.school_rounded,
                  const Color(0xFF1565C0),
                ),
                const SizedBox(height: 10),
                _buildModeCard(
                  VisionMode.speed,
                  'Timed',
                  'Clear 3 to 8 pawns — beat your time!',
                  Icons.timer_rounded,
                  const Color(0xFFE65100),
                ),
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

  Widget _buildDrillChip(
    VisionDrillType drill,
    String label,
    IconData icon,
  ) {
    final selected = _drill == drill;
    return Expanded(
      child: ChoiceChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => setState(() => _drill = drill),
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

  Widget _buildPieceImageChip({
    required PieceKind pieceKind,
    required bool selected,
    required VoidCallback onSelected,
    required Color selectedColor,
    required String tooltip,
  }) {
    final asset = PieceSet.cburnett.assets[pieceKind];
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onSelected,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: selected ? selectedColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? selectedColor : Colors.grey.shade300,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: selectedColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: SizedBox(
                width: 44,
                height: 44,
                child: asset != null ? Image(image: asset) : const SizedBox(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    VisionMode mode,
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
    final effectiveMode = (_drill == VisionDrillType.knightSight ||
            _drill == VisionDrillType.knightFlight)
        ? VisionMode.practice
        : _mode;
    context.push(
      '/chess-vision/game'
      '?drill=${_drill.name}'
      '&piece=${_piece.name}'
      '&target=${_target.name}'
      '&mode=${effectiveMode.name}',
    );
  }
}
