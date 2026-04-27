import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class PPLogo extends StatelessWidget {
  const PPLogo({super.key, this.size = 28, this.dark = false, this.compact = false});

  final double size;
  final bool dark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.ink;
    final tileBg = dark ? AppColors.blue900 : AppColors.ink;

    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: Offset(-size * 0.06, -size * 0.06),
            blurRadius: 0,
          ),
          if (dark) BoxShadow(color: Colors.white.withOpacity(0.10), blurRadius: 0, spreadRadius: 1),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              'PP',
              style: AppFonts.display(
                size * 0.58,
                color: AppColors.ball,
                letterSpacing: size * -0.046,
              ),
            ),
          ),
          Positioned(
            right: size * 0.12,
            bottom: size * 0.18,
            child: Container(
              width: size * 0.09,
              height: size * 0.09,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ball,
              ),
            ),
          ),
        ],
      ),
    );

    if (compact) return tile;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        tile,
        SizedBox(width: size * 0.28),
        Text.rich(
          TextSpan(
            text: 'padel partner',
            style: AppFonts.display(size * 0.72, color: fg, letterSpacing: -0.03 * size * 0.72),
            children: [
              TextSpan(
                text: '.',
                style: AppFonts.display(size * 0.72, color: AppColors.ball, letterSpacing: 0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
