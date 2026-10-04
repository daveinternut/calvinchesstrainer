import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One choice in a [SegmentedPicker]: a text [label], or any [child] (a
/// piece image) with a [semanticLabel].
class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    this.label,
    this.child,
    this.semanticLabel,
    this.enabled = true,
  }) : assert(label != null || child != null);

  final T value;
  final String? label;
  final Widget? child;
  final String? semanticLabel;
  final bool enabled;
}

/// The design system's segmented control: options share a grey well, and
/// the selected one lifts out as a white chip with a brand-green ring.
class SegmentedPicker<T> extends StatelessWidget {
  const SegmentedPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 48,
  });

  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.well,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: _segment(options[i])),
          ],
        ],
      ),
    );
  }

  Widget _segment(SegmentOption<T> option) {
    final selected = option.value == value;
    final enabled = option.enabled;
    final content = option.child ??
        Text(
          option.label!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFonts.ui,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.ink : AppColors.ink2,
          ),
        );
    Widget segment = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled && !selected ? () => onChanged(option.value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1F0E1B16),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                  BoxShadow(color: AppColors.brand, spreadRadius: 1.5),
                ]
              : null,
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: enabled ? 1 : 0.3,
          child: content,
        ),
      ),
    );
    // Image-only options (pieces) get a tooltip with their name.
    if (option.semanticLabel != null) {
      segment = Tooltip(message: option.semanticLabel!, child: segment);
    }
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: option.semanticLabel ?? option.label,
      excludeSemantics: true,
      child: segment,
    );
  }
}
