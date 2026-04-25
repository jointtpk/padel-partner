import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/tokens.dart';
import 'avatar_widget.dart';

class CourtDiagram extends StatelessWidget {
  const CourtDiagram({super.key, this.players = const [], this.emptySlots = 0});

  final List<Player> players;
  final int emptySlots;

  static const _positions = [
    Alignment(-0.56, -0.64), // top-left
    Alignment(0.56, -0.64),  // top-right
    Alignment(-0.56, 0.64),  // bottom-left
    Alignment(0.56, 0.64),   // bottom-right
  ];

  @override
  Widget build(BuildContext context) {
    final all = [...players, ...List<Player?>.filled((4 - players.length).clamp(0, 4), null)];

    return AspectRatio(
      aspectRatio: 2.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ball, width: 2),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.blue800, AppColors.blue900],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Court lines SVG
              CustomPaint(painter: _CourtLinePainter(), size: Size.infinite),

              // Players
              for (int i = 0; i < all.length && i < 4; i++)
                Align(
                  alignment: _positions[i],
                  child: all[i] != null
                      ? AvatarWidget(player: all[i]!, size: 40, ring: true)
                      : const EmptySlotWidget(size: 40),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourtLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.ball.withOpacity(0.30)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final glassPaint = Paint()
      ..color = AppColors.ball.withOpacity(0.30)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Glass walls
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
        const Radius.circular(10),
      ),
      glassPaint,
    );

    // Net (vertical center line)
    final netPaint = Paint()
      ..color = AppColors.ball
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.10),
      Offset(size.width / 2, size.height * 0.90),
      netPaint,
    );

    // Service box lines (horizontal at 50%)
    canvas.drawLine(
      Offset(size.width * 0.15, size.height / 2),
      Offset(size.width * 0.85, size.height / 2),
      linePaint,
    );

    // NET label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'NET',
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 9,
          color: AppColors.ball,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
