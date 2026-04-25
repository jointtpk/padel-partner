import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum PPButtonVariant { primary, ball, blue, outline, glass }

class PPButton extends StatefulWidget {
  const PPButton({
    super.key,
    required this.child,
    this.variant = PPButtonVariant.primary,
    this.onTap,
    this.disabled = false,
    this.size = 'lg',
    this.style,
  });

  final Widget child;
  final PPButtonVariant variant;
  final VoidCallback? onTap;
  final bool disabled;
  final String size; // 'lg' | 'md' | 'sm'
  final BoxDecoration? style;

  @override
  State<PPButton> createState() => _PPButtonState();
}

class _PPButtonState extends State<PPButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pad = switch (widget.size) {
      'sm' => const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      'md' => const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      _    => const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    };
    final fs = switch (widget.size) {
      'sm' => 12.0,
      'md' => 14.0,
      _    => 16.0,
    };
    final r = switch (widget.size) {
      'sm' => 10.0,
      'md' => 14.0,
      _    => 18.0,
    };

    final (bg, fg, border, shadow) = switch (widget.variant) {
      PPButtonVariant.ball => (
          AppColors.ball, AppColors.ink, null,
          [BoxShadow(color: AppColors.ball.withOpacity(0.40), blurRadius: 20, offset: const Offset(0, 8))],
        ),
      PPButtonVariant.blue => (
          AppColors.blue800, Colors.white, null,
          <BoxShadow>[],
        ),
      PPButtonVariant.outline => (
          Colors.transparent, AppColors.ink,
          Border.all(color: AppColors.ink, width: 1.5),
          <BoxShadow>[],
        ),
      PPButtonVariant.glass => (
          Colors.white.withOpacity(0.12), Colors.white,
          Border.all(color: Colors.white.withOpacity(0.25)),
          <BoxShadow>[],
        ),
      _ => (
          AppColors.ink, Colors.white, null,
          [BoxShadow(color: AppColors.ink.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))],
        ),
    };

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.disabled) widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: widget.disabled ? 0.45 : 1.0,
          child: Container(
            width: double.infinity,
            padding: pad,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(r),
              border: border,
              boxShadow: widget.disabled ? [] : shadow,
            ),
            child: Center(
              child: DefaultTextStyle(
                style: AppFonts.display(fs, color: fg, letterSpacing: 0.02 * fs),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
