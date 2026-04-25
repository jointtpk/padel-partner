import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/tokens.dart';
import '../../core/mock_data.dart';
import '../../core/models/game.dart';
import '../../core/models/player.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/chip_widget.dart';
import '../../app/routes.dart' show Routes;

// ─── Screen ───────────────────────────────────────────────────────────────────

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> with TickerProviderStateMixin {
  late AnimationController _confettiCtrl;
  late AnimationController _ticketCtrl;
  late Animation<double> _ticketSlide;
  late Animation<double> _ticketFade;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _ticketCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _ticketSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(parent: _ticketCtrl, curve: Curves.easeOutCubic),
    );
    _ticketFade = CurvedAnimation(parent: _ticketCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ticketCtrl.forward();
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _ticketCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Get.arguments as Game;
    final bottom = MediaQuery.of(context).padding.bottom;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.blue900,
      body: Stack(
        children: [
          // Confetti layer
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(progress: _confettiCtrl.value),
              size: Size.infinite,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: top > 0 ? 0 : 20),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 28),
                      // Ball icon
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.ball,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ball.withOpacity(0.45),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🎾', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'You\'re in!',
                        style: AppFonts.display(36, color: Colors.white, letterSpacing: -0.8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Game confirmed. See you on the court.',
                        style: AppFonts.body(14, color: Colors.white.withOpacity(0.60)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Ticket
                Expanded(
                  child: AnimatedBuilder(
                    animation: _ticketCtrl,
                    builder: (_, child) => FadeTransition(
                      opacity: _ticketFade,
                      child: Transform.translate(
                        offset: Offset(0, _ticketSlide.value),
                        child: child,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _MatchTicket(game: game),
                      ),
                    ),
                  ),
                ),

                // CTA buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 16),
                  child: Column(
                    children: [
                      _CtaBtn(
                        label: 'Open match chat',
                        primary: true,
                        onTap: () => Get.offAllNamed(
                          Routes.chat,
                          arguments: {'gameId': game.id, 'title': game.club},
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CtaBtn(
                        label: 'Back to home',
                        primary: false,
                        onTap: () => Get.offAllNamed(Routes.home),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Match ticket ─────────────────────────────────────────────────────────────

class _MatchTicket extends StatelessWidget {
  const _MatchTicket({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final players = game.playerIds.map(playerById).whereType<Player>().toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ball.withOpacity(0.25),
            blurRadius: 40,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ticket top — cobalt band
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: const BoxDecoration(
              color: AppColors.blue900,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.club,
                            style: AppFonts.display(20, color: Colors.white, letterSpacing: -0.4),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${game.area} · ${game.court}',
                            style: AppFonts.body(12, color: Colors.white.withOpacity(0.55)),
                          ),
                        ],
                      ),
                    ),
                    LevelBadge(levelKey: game.levelKey),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _TicketStat(label: 'DATE', value: game.when),
                    _TicketDivider(),
                    _TicketStat(label: 'TIME', value: game.time),
                    _TicketDivider(),
                    _TicketStat(label: 'DURATION', value: game.duration.replaceAll(' min', 'min')),
                  ],
                ),
              ],
            ),
          ),

          // Tear line
          _TearLine(),

          // Ticket bottom — white section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Players row
                Text(
                  'YOUR TEAM',
                  style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.40), letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ...players.take(4).map((p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          AvatarWidget(player: p, size: 44, ring: p.id == kMe.id),
                          const SizedBox(height: 4),
                          Text(
                            p.id == kMe.id ? 'You' : p.name.split(' ').first,
                            style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.55)),
                          ),
                        ],
                      ),
                    )),
                    ...List.generate(game.spots, (i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          const EmptySlotWidget(size: 44),
                          const SizedBox(height: 4),
                          Text('Open', style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.30))),
                        ],
                      ),
                    )),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(color: AppColors.line, height: 1),
                const SizedBox(height: 16),

                // Price + vibe row
                Row(
                  children: [
                    Expanded(
                      child: _TicketDetail(
                        label: 'YOUR COST',
                        value: 'Rs ${_fmt(game.price)}',
                        accent: true,
                      ),
                    ),
                    Expanded(
                      child: _TicketDetail(label: 'VIBE', value: game.vibe),
                    ),
                    Expanded(
                      child: _TicketDetail(
                        label: 'ENTRY',
                        value: game.autoApprove ? '⚡ Auto' : '✓ Approved',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                // Barcode decoration
                _Barcode(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketStat extends StatelessWidget {
  const _TicketStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.mono(8, color: Colors.white.withOpacity(0.40), letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(value, style: AppFonts.display(14, color: Colors.white, letterSpacing: -0.2)),
        ],
      ),
    );
  }
}

class _TicketDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 32,
      color: Colors.white.withOpacity(0.12),
      margin: const EdgeInsets.symmetric(horizontal: 14),
    );
  }
}

class _TicketDetail extends StatelessWidget {
  const _TicketDetail({required this.label, required this.value, this.accent = false});
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.mono(8, color: AppColors.ink.withOpacity(0.40), letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppFonts.display(14,
            color: accent ? AppColors.blue900 : AppColors.ink,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Tear line ────────────────────────────────────────────────────────────────

class _TearLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          // Left notch
          Transform.translate(
            offset: const Offset(-12, 0),
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: AppColors.blue900.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Dashed line
          Expanded(
            child: CustomPaint(painter: _DashPainter()),
          ),
          // Right notch
          Transform.translate(
            offset: const Offset(12, 0),
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: AppColors.blue900.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashW = 6.0;
    const gapW = 4.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Barcode decoration ───────────────────────────────────────────────────────

class _Barcode extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 44),
      painter: _BarcodePainter(),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  static final _rng = math.Random(42); // fixed seed = same bars every time
  static final _bars = List.generate(60, (_) => _rng.nextDouble());

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink.withOpacity(0.08);
    double x = 0;
    for (final w in _bars) {
      final barW = w * 5 + 1;
      canvas.drawRect(Rect.fromLTWH(x, 0, barW, size.height * 0.85), paint);
      x += barW + 2;
      if (x > size.width) break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Confetti painter ─────────────────────────────────────────────────────────

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});
  final double progress;

  static final _rng = math.Random(7);
  static final _pieces = List.generate(60, (i) => _ConfettiPiece(
    x: _rng.nextDouble(),
    startY: -0.1 - _rng.nextDouble() * 0.4,
    speed: 0.4 + _rng.nextDouble() * 0.6,
    size: 4 + _rng.nextDouble() * 6,
    color: _kConfettiColors[i % _kConfettiColors.length],
    rotation: _rng.nextDouble() * math.pi * 2,
    rotationSpeed: (_rng.nextDouble() - 0.5) * 8,
    wide: _rng.nextBool(),
  ));

  static const _kConfettiColors = [
    AppColors.ball,
    Colors.white,
    AppColors.blue200,
    AppColors.hot,
    AppColors.warn,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _pieces) {
      final t = ((progress * p.speed * 1.5)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final x = p.x * size.width;
      final y = (p.startY + t * 1.4) * size.height;
      final opacity = (1.0 - (t * t)).clamp(0.0, 1.0);
      if (y > size.height || opacity <= 0) continue;

      paint.color = p.color.withOpacity(opacity * 0.85);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + p.rotationSpeed * t);
      if (p.wide) {
        canvas.drawRect(Rect.fromLTWH(-p.size, -p.size * 0.35, p.size * 2, p.size * 0.7), paint);
      } else {
        canvas.drawRect(Rect.fromLTWH(-p.size * 0.4, -p.size * 0.4, p.size * 0.8, p.size * 0.8), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.wide,
  });
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
  final double rotationSpeed;
  final bool wide;
}

// ─── CTA button ───────────────────────────────────────────────────────────────

class _CtaBtn extends StatelessWidget {
  const _CtaBtn({required this.label, required this.primary, required this.onTap});
  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: primary ? AppColors.ball : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: AppFonts.body(15, color: primary ? AppColors.ink : Colors.white, weight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _fmt(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
