import 'dart:math' as math;

import 'package:chessground/chessground.dart' show PieceSet;
import 'package:dartchess/dartchess.dart' show PieceKind;
import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
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
  /// Keeps the options readable on a wide (landscape iPad) window instead of
  /// stretching chips and cards edge to edge.
  static const double _maxContentWidth = 720;

  late VisionDrillType _drill;
  late WhitePiece _piece;
  late TargetPiece _target;
  late VisionMode _mode;

  @override
  void initState() {
    super.initState();
    _piece = widget.initialPiece;
    _target = _allowedTarget(widget.initialTarget, _piece);
    _drill = widget.initialDrill;
    _mode = widget.initialMode;
    _selectDrill(widget.initialDrill);
  }

  /// Knight vs knight has no fork anywhere (the knights can always take each
  /// other), so a knight can't pick the knight target.
  static bool _isTargetAllowed(TargetPiece target, WhitePiece piece) =>
      !(piece == WhitePiece.knight && target == TargetPiece.knight);

  static TargetPiece _allowedTarget(TargetPiece target, WhitePiece piece) =>
      _isTargetAllowed(target, piece) ? target : TargetPiece.rook;

  /// Switches drill and moves the mode selection onto what this drill will
  /// really run, so the highlighted mode card is always the one that starts
  /// (concentric is forks-only). Knight drills show no mode cards, so the
  /// choice is kept for when the player comes back to a drill that has them.
  void _selectDrill(VisionDrillType drill) {
    _drill = drill;
    if (!drill.isKnightDrill) _mode = drill.effectiveMode(_mode);
  }

  void _selectPiece(WhitePiece piece) {
    _piece = piece;
    _target = _allowedTarget(_target, piece);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Centre the options in a column of at most _maxContentWidth; the scroll
    // area itself stays full width.
    final usableWidth = MediaQuery.sizeOf(context).width -
        MediaQuery.paddingOf(context).horizontal;
    final sidePadding = math.max(24.0, (usableWidth - _maxContentWidth) / 2);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chessVision),
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
                padding: EdgeInsets.fromLTRB(sidePadding, 24, sidePadding, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.drillType,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildDrillChip(
                          VisionDrillType.forksAndSkewers,
                          l10n.forksAndSkewers,
                          Icons.call_split_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildDrillChip(
                          VisionDrillType.pawnAttack,
                          l10n.pawnAttack,
                          Icons.gps_not_fixed_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildDrillChip(
                          VisionDrillType.knightSight,
                          l10n.knightSight,
                          Icons.open_with_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildDrillChip(
                          VisionDrillType.knightFlight,
                          l10n.knightFlight,
                          Icons.route_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildDrillChip(
                          VisionDrillType.findChecks,
                          l10n.scanDrillChecks,
                          Icons.bolt_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildDrillChip(
                          VisionDrillType.findCaptures,
                          l10n.scanDrillCaptures,
                          Icons.gps_fixed_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildDrillChip(
                          VisionDrillType.hangingPieces,
                          l10n.scanDrillHanging,
                          Icons.radar_rounded,
                        ),
                        const SizedBox(width: 8),
                        _buildDrillChip(
                          VisionDrillType.mateInOne,
                          l10n.scanDrillMate,
                          Icons.flag_rounded,
                        ),
                      ],
                    ),
                    if (_drill == VisionDrillType.forksAndSkewers) ...[
                      const SizedBox(height: 24),
                      Text(
                        l10n.chooseYourPiece,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              onSelected: () =>
                                  setState(() => _selectPiece(p)),
                              selectedColor: AppColors.primary,
                              tooltip: p.localizedLabel(l10n),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.targetPiece,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              enabled: _isTargetAllowed(t, _piece),
                              onSelected: () => setState(() => _target = t),
                              selectedColor: Colors.grey.shade800,
                              tooltip: t.localizedLabel(l10n),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.chooseAMode,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildModeCard(
                        VisionMode.practice,
                        l10n.practice,
                        l10n.findForksNoTimer,
                        Icons.school_rounded,
                        const Color(0xFF1565C0),
                      ),
                      const SizedBox(height: 10),
                      _buildModeCard(
                        VisionMode.speed,
                        l10n.speedRound,
                        l10n.speedRound60Desc,
                        Icons.timer_rounded,
                        const Color(0xFFE65100),
                      ),
                      const SizedBox(height: 10),
                      _buildModeCard(
                        VisionMode.concentric,
                        l10n.concentricDrill,
                        l10n.concentricDrillDesc,
                        Icons.track_changes_rounded,
                        const Color(0xFF6A1B9A),
                      ),
                    ],
                    if (_drill == VisionDrillType.pawnAttack) ...[
                      const SizedBox(height: 24),
                      Text(
                        l10n.chooseYourPiece,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                              onSelected: () =>
                                  setState(() => _selectPiece(p)),
                              selectedColor: AppColors.primary,
                              tooltip: p.localizedLabel(l10n),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.chooseAMode,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildModeCard(
                        VisionMode.practice,
                        l10n.practice,
                        l10n.captureAllPawnsNoTimer,
                        Icons.school_rounded,
                        const Color(0xFF1565C0),
                      ),
                      const SizedBox(height: 10),
                      _buildModeCard(
                        VisionMode.speed,
                        l10n.timed,
                        l10n.timedPawnAttackDesc,
                        Icons.timer_rounded,
                        const Color(0xFFE65100),
                      ),
                    ],
                    if (_drill.isScanDrill) ...[
                      const SizedBox(height: 16),
                      // The prompt doubles as the drill explainer.
                      Text(
                        _scanDescription(l10n),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.chooseAMode,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildModeCard(
                        VisionMode.practice,
                        l10n.practice,
                        l10n.scanPracticeDesc,
                        Icons.school_rounded,
                        const Color(0xFF1565C0),
                      ),
                      const SizedBox(height: 10),
                      _buildModeCard(
                        VisionMode.speed,
                        _drill == VisionDrillType.mateInOne
                            ? l10n.blitz
                            : l10n.speedRound,
                        _drill == VisionDrillType.mateInOne
                            ? l10n.scanBlitzDesc
                            : l10n.speedRound60Desc,
                        Icons.timer_rounded,
                        const Color(0xFFE65100),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 16),
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
                  child: Text(l10n.start),
                ),
              ),
            ),
          ],
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
            // Long labels (French, Spanish, Russian…) shrink to fit a phone's
            // half-width chip instead of overflowing it.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1),
              ),
            ),
          ],
        ),
        selected: selected,
        onSelected: (_) => setState(() => _selectDrill(drill)),
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
    bool enabled = true,
  }) {
    final asset = PieceSet.cburnett.assets[pieceKind];
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: enabled ? onSelected : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: enabled ? 1 : 0.3,
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
                  child:
                      asset != null ? Image(image: asset) : const SizedBox(),
                ),
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

  String _scanDescription(AppLocalizations l10n) => switch (_drill) {
        VisionDrillType.findChecks => l10n.scanPromptChecks,
        VisionDrillType.findCaptures => l10n.scanPromptCaptures,
        VisionDrillType.hangingPieces => l10n.scanPromptHanging,
        VisionDrillType.mateInOne => l10n.scanPromptMate,
        _ => '',
      };

  void _startGame() {
    final effectiveMode = _drill.effectiveMode(_mode);
    context.push(
      '/chess-vision/game'
      '?drill=${_drill.name}'
      '&piece=${_piece.name}'
      '&target=${_allowedTarget(_target, _piece).name}'
      '&mode=${effectiveMode.name}',
    );
  }
}
