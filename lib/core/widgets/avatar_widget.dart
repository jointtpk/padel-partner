import 'dart:io';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/tokens.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.player,
    this.size = 36,
    this.ring = false,
  });

  final Player player;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final photo = player.photoPath;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final initials = Center(
      child: Text(
        player.initials,
        style: AppFonts.display(
          size * 0.38,
          color: AppColors.ink,
          letterSpacing: size * -0.007,
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: player.avatarColor,
        border: ring ? Border.all(color: AppColors.ball, width: 2) : null,
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            initials,
            if (hasPhoto)
              Image(
                image: _imageProviderFor(photo),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider _imageProviderFor(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }
}

class EmptySlotWidget extends StatelessWidget {
  const EmptySlotWidget({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.ball.withOpacity(0.12),
        border: Border.all(color: AppColors.ball, width: 2, style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(
          '+',
          style: TextStyle(
            color: AppColors.ball,
            fontSize: size * 0.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
