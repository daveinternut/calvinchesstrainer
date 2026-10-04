import 'package:flutter/material.dart';
import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../pieces/models/which_side_wins_state.dart';
import '../models/file_rank_game_state.dart';

class FileRankMenuScreen extends StatefulWidget {
  final TrainerSubject initialSubject;
  final TrainerMode initialMode;
  final bool initialHardMode;

  const FileRankMenuScreen({
    super.key,
    this.initialSubject = TrainerSubject.files,
    this.initialMode = TrainerMode.explore,
    this.initialHardMode = false,
  });

  @override
  State<FileRankMenuScreen> createState() => _FileRankMenuScreenState();
}

class _FileRankMenuScreenState extends State<FileRankMenuScreen> {
  static const double _maxContentWidth = 640;

  late TrainerSubject _subject = widget.initialSubject;
  late TrainerMode _mode = widget.initialMode;
  late bool _isHardMode = widget.initialHardMode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chessNotation),
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
                child: Center(
                  child: ConstrainedBox(
                    // A landscape iPad would otherwise stretch every chip
                    // and card across the whole screen.
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.whatToPractice,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildSubjectChip(
                              TrainerSubject.files,
                              l10n.files,
                              Icons.view_column,
                            ),
                            const SizedBox(width: 8),
                            _buildSubjectChip(
                              TrainerSubject.ranks,
                              l10n.ranks,
                              Icons.view_stream,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildSubjectChip(
                              TrainerSubject.squares,
                              l10n.squares,
                              Icons.grid_on,
                            ),
                            const SizedBox(width: 8),
                            _buildSubjectChip(
                              TrainerSubject.letters,
                              l10n.letters,
                              Icons.abc_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildSubjectChip(
                              TrainerSubject.moves,
                              l10n.moves,
                              Icons.swap_horiz_rounded,
                            ),
                            const SizedBox(width: 8),
                            _buildSubjectChip(
                              TrainerSubject.pieceValue,
                              l10n.pieceValue,
                              Icons.balance_rounded,
                            ),
                          ],
                        ),
                        if (_subject == TrainerSubject.pieceValue) ...[
                          const SizedBox(height: 16),
                          _buildPieceValueBanner(l10n),
                        ],
                        const SizedBox(height: 28),
                        Text(
                          l10n.chooseAMode,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (_subjectHasExplore(_subject)) ...[
                          _buildModeCard(
                            TrainerMode.explore,
                            l10n.explore,
                            l10n.exploreDesc,
                            Icons.touch_app_rounded,
                            AppColors.primary,
                          ),
                          const SizedBox(height: 10),
                        ],
                        _buildModeCard(
                          TrainerMode.practice,
                          l10n.practice,
                          _subject == TrainerSubject.pieceValue
                              ? l10n.whichSideWinsPracticeDesc
                              : l10n.practiceDesc,
                          Icons.school_rounded,
                          const Color(0xFF1565C0),
                        ),
                        const SizedBox(height: 10),
                        _buildModeCard(
                          TrainerMode.speed,
                          l10n.speedRound,
                          l10n.speedRoundDesc,
                          Icons.timer_rounded,
                          const Color(0xFFE65100),
                        ),
                        const SizedBox(height: 28),
                        if (_mode != TrainerMode.explore &&
                            _subject != TrainerSubject.pieceValue) ...[
                          MergeSemantics(
                            child: Semantics(
                              button: true,
                              toggled: _isHardMode,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _isHardMode = !_isHardMode),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
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
                                              color: const Color(
                                                0xFFB71C1C,
                                              ).withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.hardMode,
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
                                              switch (_subject) {
                                                TrainerSubject.moves =>
                                                  l10n.hardModeBlack,
                                                TrainerSubject.letters =>
                                                  l10n.hardModeBlackPieces,
                                                _ => l10n.hardModeFlipped,
                                              },
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _isHardMode
                                                    ? Colors.white.withValues(
                                                        alpha: 0.85,
                                                      )
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_isHardMode)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
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
            ),
          ],
        ),
      ),
    );
  }

  /// Moves and Piece Value are quiz-only drills — there is nothing to tap
  /// around and discover, so they skip Explore mode.
  static bool _subjectHasExplore(TrainerSubject subject) =>
      subject != TrainerSubject.moves && subject != TrainerSubject.pieceValue;

  /// Piece Value plays out on its own screen (Which Side Wins), so introduce
  /// it here the way its old standalone menu used to.
  Widget _buildPieceValueBanner(AppLocalizations l10n) {
    const accent = Color(0xFF0277BD);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.balance_rounded, size: 36, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whichSideWins,
                  style: const TextStyle(
                    fontFamily: 'BradBunR',
                    fontSize: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.whichSideWinsDesc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectChip(
    TrainerSubject subject,
    String label,
    IconData icon,
  ) {
    final selected = _subject == subject;
    return Expanded(
      child: ChoiceChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            // Some locales spell these out at length ("Ценность фигур") —
            // let the label give way rather than overflow the chip.
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        selected: selected,
        onSelected: (_) => setState(() {
          _subject = subject;
          if (!_subjectHasExplore(subject) && _mode == TrainerMode.explore) {
            _mode = TrainerMode.practice;
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
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: () => setState(() {
            _mode = mode;
            if (mode == TrainerMode.explore) {
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
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
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
                  const Icon(Icons.check_circle, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame() {
    if (_subject == TrainerSubject.moves) {
      context.push(
        '/move-trainer/game'
        '?mode=${_mode.name}'
        '&hardMode=$_isHardMode',
      );
    } else if (_subject == TrainerSubject.letters) {
      context.push(
        '/letter-trainer/game'
        '?mode=${_mode.name}'
        '&hardMode=$_isHardMode',
      );
    } else if (_subject == TrainerSubject.pieceValue) {
      // Which Side Wins has only practice/speed; explore is unreachable here.
      final mode = _mode == TrainerMode.speed
          ? WhichSideWinsMode.speed
          : WhichSideWinsMode.practice;
      context.push('/the-pieces/which-side-wins?mode=${mode.name}');
    } else {
      context.push(
        '/file-rank-trainer/game'
        '?subject=${_subject.name}'
        '&mode=${_mode.name}'
        '&hardMode=$_isHardMode',
      );
    }
  }
}
