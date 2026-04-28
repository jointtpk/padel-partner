import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Gold verified tick badge for Pro subscribers.
///
/// Renders a small filled circle with a check mark — meant to sit inline
/// next to a player's name. Pass [size] to scale; default 14px works well
/// next to body text. Use [onAvatar] for the slightly larger, ringed
/// variant that sits as a corner overlay on an avatar.
class VerifiedTick extends StatelessWidget {
  const VerifiedTick({super.key, this.size = 14, this.onAvatar = false});

  final double size;
  final bool onAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.ball,
        shape: BoxShape.circle,
        border: onAvatar
            ? Border.all(color: Colors.white, width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        Icons.check_rounded,
        size: size * (onAvatar ? 0.62 : 0.72),
        color: AppColors.ink,
      ),
    );
  }
}
