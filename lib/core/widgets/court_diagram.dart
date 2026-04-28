import 'package:flutter/material.dart';
import '../models/player.dart';
import '../theme/tokens.dart';
import 'avatar_widget.dart';

class CourtDiagram extends StatelessWidget {
  const CourtDiagram({
    super.key,
    this.slotAssignments = const {},
    this.onClaimSlot,
  });

  /// slotIndex (0..3) -> Player who has claimed it.
  final Map<int, Player> slotAssignments;

  /// Tapped on an empty slot. When null, empty slots are not interactive.
  final ValueChanged<int>? onClaimSlot;

  static const _positions = [
    Alignment(-0.56, -0.64), // 0: top-left
    Alignment(0.56, -0.64),  // 1: top-right
    Alignment(-0.56, 0.64),  // 2: bottom-left
    Alignment(0.56, 0.64),   // 3: bottom-right
  ];

  @override
  Widget build(BuildContext context) {
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
              CustomPaint(painter: _CourtLinePainter(), size: Size.infinite),
              for (int i = 0; i < 4; i++)
                Align(
                  alignment: _positions[i],
                  child: _slotAt(i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotAt(int i) {
    final p = slotAssignments[i];
    if (p != null) {
      return AvatarWidget(player: p, size: 40, ring: true);
    }
    if (onClaimSlot != null) {
      return GestureDetector(
        onTap: () => onClaimSlot!(i),
        child: const EmptySlotWidget(size: 40),
      );
    }
    return const EmptySlotWidget(size: 40);
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

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 6, size.width - 12, size.height - 12),
        const Radius.circular(10),
      ),
      glassPaint,
    );

    final netPaint = Paint()
      ..color = AppColors.ball
      ..strokeWidth = 2.0;
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.10),
      Offset(size.width / 2, size.height * 0.90),
      netPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.15, size.height / 2),
      Offset(size.width * 0.85, size.height / 2),
      linePaint,
    );

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
