import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum ChipVariant { defaultStyle, ball, dark, ghost, hot }

class PPChip extends StatelessWidget {
  const PPChip({super.key, required this.child, this.variant = ChipVariant.defaultStyle});

  final Widget child;
  final ChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      ChipVariant.ball    => (AppColors.ball, AppColors.ink, null),
      ChipVariant.dark    => (AppColors.ink, Colors.white, null),
      ChipVariant.ghost   => (AppColors.ink.withOpacity(0.06), AppColors.ink, Border.all(color: AppColors.ink.withOpacity(0.10))),
      ChipVariant.hot     => (AppColors.hot, Colors.white, null),
      _                   => (Colors.white.withOpacity(0.15), Colors.white, Border.all(color: Colors.white.withOpacity(0.25))),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border,
      ),
      child: DefaultTextStyle(
        style: AppFonts.body(11, color: fg, weight: FontWeight.w600, letterSpacing: 0.02),
        child: child,
      ),
    );
  }
}

class StickerWidget extends StatelessWidget {
  const StickerWidget({
    super.key,
    required this.child,
    this.rotate = -8,
    this.color = AppColors.ball,
    this.fg = AppColors.ink,
  });

  final Widget child;
  final double rotate;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate * 3.14159 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ink.withOpacity(0.25), width: 1.5, style: BorderStyle.solid),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withOpacity(0.08), offset: const Offset(0, -2), blurRadius: 0),
          ],
        ),
        child: DefaultTextStyle(
          style: AppFonts.display(12, color: fg, letterSpacing: 0.04 * 12),
          child: child,
        ),
      ),
    );
  }
}

class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.levelKey, this.size = 'md'});

  final String levelKey;
  final String size; // 'sm' | 'md' | 'lg'

  @override
  Widget build(BuildContext context) {
    final lvl = levelByKey(levelKey);
    final (pad, fs) = switch (size) {
      'sm' => (const EdgeInsets.symmetric(horizontal: 8, vertical: 3), 9.0),
      'lg' => (const EdgeInsets.symmetric(horizontal: 14, vertical: 7), 13.0),
      _    => (const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 10.0),
    };

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: lvl.color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'T${lvl.tier}',
            style: AppFonts.mono(fs - 1, color: lvl.fg.withOpacity(0.65)),
          ),
          const SizedBox(width: 4),
          Text(
            lvl.label.toUpperCase(),
            style: AppFonts.display(fs, color: lvl.fg, letterSpacing: 0.05 * fs),
          ),
        ],
      ),
    );
  }
}
