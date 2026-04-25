import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class BallWidget extends StatelessWidget {
  const BallWidget({super.key, this.size = 44, this.glow = true, this.seam = true});

  final double size;
  final bool glow;
  final bool seam;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.36, -0.44),
          colors: [Color(0xFFF2FF7A), AppColors.ball, AppColors.ballDeep],
          stops: [0.0, 0.38, 1.0],
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.ball.withOpacity(0.53),
                  blurRadius: size * 0.6,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
              ],
      ),
      child: seam
          ? CustomPaint(painter: _BallSeamPainter())
          : null,
    );
  }
}

class _BallSeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.80)
      ..strokeWidth = size.width * 0.025
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final top = Path()
      ..moveTo(size.width * 0.10, size.height * 0.30)
      ..quadraticBezierTo(
          size.width * 0.50, size.height * 0.10,
          size.width * 0.90, size.height * 0.30);
    canvas.drawPath(top, paint);

    final bottom = Path()
      ..moveTo(size.width * 0.10, size.height * 0.70)
      ..quadraticBezierTo(
          size.width * 0.50, size.height * 0.90,
          size.width * 0.90, size.height * 0.70);
    canvas.drawPath(bottom, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
