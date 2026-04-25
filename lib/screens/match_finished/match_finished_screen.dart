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

// ─── Controller ───────────────────────────────────────────────────────────────

class MatchFinishedController extends GetxController {
  final step       = 1.obs; // 1=celebrate 2=winner 3=rate 4=summary
  final winnerTeam = ''.obs; // 'A' | 'B' | 'draw'
  // playerId → list of tag strings given
  final ratings    = <String, List<String>>{}.obs;

  static const _rateTags = [
    'Great rallies', 'Sharp serves', 'Strong net',
    'Good teamwork', 'Tactical', 'Consistent',
    'Fun to play', 'Clean lobs', 'Hard hitter',
  ];

  List<String> tagsFor(String uid) => ratings[uid] ?? [];

  void toggleTag(String uid, String tag) {
    final current = List<String>.from(ratings[uid] ?? []);
    if (current.contains(tag)) {
      current.remove(tag);
    } else {
      current.add(tag);
    }
    ratings[uid] = current;
  }

  void next() {
    if (step.value < 4) step.value++;
  }

  void setWinner(String team) {
    winnerTeam.value = team;
    HapticFeedback.mediumImpact();
    next();
  }

  // XP earned: base 50, +10 per win
  int get xpEarned => winnerTeam.value == 'A' ? 60 : 50;

  // New mock level after match
  double get newLevel => (kMe.level + 0.1).clamp(0, 10);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MatchFinishedScreen extends StatelessWidget {
  const MatchFinishedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(MatchFinishedController());
    // Accept either a Game or use the first confirmed game
    final game = (Get.arguments as Game?) ??
        kGames.firstWhereOrNull((g) => g.playerIds.contains(kMe.id)) ??
        kGames.first;

    return Scaffold(
      backgroundColor: AppColors.blue900,
      body: Obx(() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: switch (ctrl.step.value) {
          2 => _WinnerStep(ctrl: ctrl, game: game, key: const ValueKey(2)),
          3 => _RateStep(ctrl: ctrl, game: game, key: const ValueKey(3)),
          4 => _SummaryStep(ctrl: ctrl, game: game, key: const ValueKey(4)),
          _ => _CelebrationStep(ctrl: ctrl, game: game, key: const ValueKey(1)),
        },
      )),
    );
  }
}

// ─── Step 1: Celebration ─────────────────────────────────────────────────────

class _CelebrationStep extends StatefulWidget {
  const _CelebrationStep({super.key, required this.ctrl, required this.game});
  final MatchFinishedController ctrl;
  final Game game;

  @override
  State<_CelebrationStep> createState() => _CelebrationStepState();
}

class _CelebrationStepState extends State<_CelebrationStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final top = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Confetti
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => CustomPaint(
            painter: _ConfettiPainter(progress: _anim.value),
            size: Size.infinite,
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              SizedBox(height: top > 0 ? 0 : 20),
              const Spacer(),

              // Trophy
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: AppColors.ball,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.ball.withOpacity(0.50), blurRadius: 40, spreadRadius: 6)],
                ),
                child: const Center(child: Text('🏆', style: TextStyle(fontSize: 48))),
              ),

              const SizedBox(height: 24),
              Text('Match over!', style: AppFonts.display(38, color: Colors.white, letterSpacing: -0.8)),
              const SizedBox(height: 8),
              Text(
                '${widget.game.club} · ${widget.game.when}',
                style: AppFonts.body(14, color: Colors.white.withOpacity(0.55)),
              ),

              const SizedBox(height: 32),

              // Player avatars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.game.playerIds.take(4).map((id) {
                  final p = playerById(id);
                  if (p == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      children: [
                        AvatarWidget(player: p, size: 52, ring: p.id == kMe.id),
                        const SizedBox(height: 6),
                        Text(
                          p.id == kMe.id ? 'You' : p.name.split(' ').first,
                          style: AppFonts.mono(9, color: Colors.white.withOpacity(0.55)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
                child: _PrimaryBtn(
                  label: 'Who won?',
                  onTap: widget.ctrl.next,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Step 2: Winner ───────────────────────────────────────────────────────────

class _WinnerStep extends StatelessWidget {
  const _WinnerStep({super.key, required this.ctrl, required this.game});
  final MatchFinishedController ctrl;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final players = game.playerIds.map(playerById).whereType<Player>().toList();
    // Split 2v2 — first 2 vs last 2
    final teamA = players.take(2).toList();
    final teamB = players.length > 2 ? players.skip(2).toList() : <Player>[];
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Column(
        children: [
          _StepHeader(step: 2, title: 'Who won?'),
          const Spacer(),

          Text('Select the winning team', style: AppFonts.body(14, color: Colors.white.withOpacity(0.55))),
          const SizedBox(height: 24),

          // Team A
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _TeamCard(
              label: 'Team A',
              players: teamA,
              onTap: () => ctrl.setWinner('A'),
            ),
          ),

          const SizedBox(height: 14),
          Text('vs', style: AppFonts.display(20, color: Colors.white.withOpacity(0.30), letterSpacing: -0.3)),
          const SizedBox(height: 14),

          // Team B
          if (teamB.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _TeamCard(
                label: 'Team B',
                players: teamB,
                onTap: () => ctrl.setWinner('B'),
              ),
            ),

          const Spacer(),

          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
            child: GestureDetector(
              onTap: () {
                ctrl.winnerTeam.value = 'draw';
                ctrl.next();
              },
              child: Text(
                "It was a draw",
                style: AppFonts.body(13, color: Colors.white.withOpacity(0.40)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatefulWidget {
  const _TeamCard({required this.label, required this.players, required this.onTap});
  final String label;
  final List<Player> players;
  final VoidCallback onTap;

  @override
  State<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<_TeamCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.ball.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.label, style: AppFonts.mono(10, color: AppColors.ball, letterSpacing: 0.4)),
              ),
              const SizedBox(width: 16),
              ...widget.players.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    AvatarWidget(player: p, size: 36),
                    const SizedBox(width: 6),
                    Text(p.name.split(' ').first, style: AppFonts.body(13, color: Colors.white, weight: FontWeight.w600)),
                  ],
                ),
              )),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.30), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 3: Rate players ─────────────────────────────────────────────────────

class _RateStep extends StatelessWidget {
  const _RateStep({super.key, required this.ctrl, required this.game});
  final MatchFinishedController ctrl;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final others = game.playerIds
        .where((id) => id != kMe.id)
        .map(playerById)
        .whereType<Player>()
        .toList();
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Column(
        children: [
          _StepHeader(step: 3, title: 'Rate your team'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              children: [
                Text(
                  'Tap words that describe each player',
                  style: AppFonts.body(13, color: Colors.white.withOpacity(0.50)),
                ),
                const SizedBox(height: 20),
                ...others.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _PlayerRater(player: p, ctrl: ctrl),
                )),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
            child: _PrimaryBtn(label: 'See summary', onTap: ctrl.next),
          ),
        ],
      ),
    );
  }
}

class _PlayerRater extends StatelessWidget {
  const _PlayerRater({required this.player, required this.ctrl});
  final Player player;
  final MatchFinishedController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AvatarWidget(player: player, size: 36),
            const SizedBox(width: 10),
            Text(player.name, style: AppFonts.body(14, color: Colors.white, weight: FontWeight.w700)),
            const SizedBox(width: 8),
            LevelBadge(levelKey: player.tier),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() {
          final selected = ctrl.tagsFor(player.id);
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MatchFinishedController._rateTags.map((tag) {
              final active = selected.contains(tag);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ctrl.toggleTag(player.id, tag);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? AppColors.ball : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(kBorderRadiusPill),
                    border: Border.all(
                      color: active ? AppColors.ball : Colors.white.withOpacity(0.14),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: AppFonts.body(12,
                      color: active ? AppColors.ink : Colors.white.withOpacity(0.70),
                      weight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

// ─── Step 4: Summary ─────────────────────────────────────────────────────────

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({super.key, required this.ctrl, required this.game});
  final MatchFinishedController ctrl;
  final Game game;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final isWinner = ctrl.winnerTeam.value == 'A' &&
        game.playerIds.take(2).contains(kMe.id);
    final isDraw = ctrl.winnerTeam.value == 'draw';
    final level = levelByKey(kMe.tier);

    return SafeArea(
      child: Column(
        children: [
          _StepHeader(step: 4, title: 'Match summary'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              children: [
                // Result banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDraw
                          ? [AppColors.blue800, AppColors.blue700]
                          : isWinner
                              ? [const Color(0xFF1A7A45), const Color(0xFF13B07B)]
                              : [const Color(0xFF7A1A1A), const Color(0xFFB04040)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isDraw ? '🤝' : isWinner ? '🏆' : '💪',
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDraw ? 'Draw' : isWinner ? 'You won!' : 'Tough match',
                              style: AppFonts.display(22, color: Colors.white, letterSpacing: -0.4),
                            ),
                            Text(
                              isDraw
                                  ? 'A well-fought tie'
                                  : isWinner
                                      ? 'Great performance on the court'
                                      : 'Keep going — improvement takes time',
                              style: AppFonts.body(12, color: Colors.white.withOpacity(0.65), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // XP gained
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('XP EARNED', style: AppFonts.mono(9, color: Colors.white.withOpacity(0.40), letterSpacing: 0.6)),
                          const SizedBox(height: 4),
                          Text('+${ctrl.xpEarned} XP', style: AppFonts.display(28, color: AppColors.ball, letterSpacing: -0.5)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('NEW LEVEL', style: AppFonts.mono(9, color: Colors.white.withOpacity(0.40), letterSpacing: 0.6)),
                          const SizedBox(height: 4),
                          Text('${ctrl.newLevel.toStringAsFixed(1)}', style: AppFonts.display(28, color: Colors.white, letterSpacing: -0.5)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Progress bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          LevelBadge(levelKey: kMe.tier),
                          const Spacer(),
                          Text(
                            '${ctrl.newLevel.toStringAsFixed(1)} / ${level.rangeMax.toStringAsFixed(1)}',
                            style: AppFonts.mono(10, color: Colors.white.withOpacity(0.45)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ((ctrl.newLevel - level.rangeMin) /
                              (level.rangeMax - level.rangeMin)).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withOpacity(0.10),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ball),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Ratings given
                if (ctrl.ratings.isNotEmpty) ...[
                  Text('Your ratings', style: AppFonts.display(15, color: Colors.white, letterSpacing: -0.3)),
                  const SizedBox(height: 12),
                  ...ctrl.ratings.entries.map((e) {
                    final p = playerById(e.key);
                    if (p == null || e.value.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SummaryRatingRow(player: p, tags: e.value),
                    );
                  }),
                ],
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
            child: _PrimaryBtn(
              label: 'Back to home',
              onTap: () => Get.offAllNamed(Routes.home),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRatingRow extends StatelessWidget {
  const _SummaryRatingRow({required this.player, required this.tags});
  final Player player;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvatarWidget(player: player, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6, runSpacing: 6,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.ball.withOpacity(0.15),
                borderRadius: BorderRadius.circular(kBorderRadiusPill),
              ),
              child: Text(t, style: AppFonts.body(11, color: AppColors.ball, weight: FontWeight.w600)),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Shared step header ───────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.title});
  final int step;
  final String title;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('STEP $step OF 4', style: AppFonts.mono(10, color: Colors.white.withOpacity(0.40), letterSpacing: 0.7)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: AppFonts.display(26, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (i) => Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < 3 ? 5 : 0),
                decoration: BoxDecoration(
                  color: i < step ? AppColors.ball : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

// ─── Primary button ───────────────────────────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: AppColors.ball,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(label, style: AppFonts.body(16, color: AppColors.ink, weight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ─── Confetti painter (reused from join screen) ───────────────────────────────

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress});
  final double progress;

  static final _rng = math.Random(13);
  static final _pieces = List.generate(55, (i) => (
    x:     _rng.nextDouble(),
    startY: -0.1 - _rng.nextDouble() * 0.4,
    speed:  0.4 + _rng.nextDouble() * 0.6,
    size:   4.0 + _rng.nextDouble() * 6,
    color:  _kColors[i % _kColors.length],
    rot:    _rng.nextDouble() * math.pi * 2,
    rotSpd: (_rng.nextDouble() - 0.5) * 8,
    wide:   _rng.nextBool(),
  ));

  static const _kColors = [AppColors.ball, Colors.white, AppColors.blue200, AppColors.hot, AppColors.warn];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _pieces) {
      final t = (progress * p.speed * 1.5).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final x = p.x * size.width;
      final y = (p.startY + t * 1.4) * size.height;
      final opacity = (1.0 - t * t).clamp(0.0, 1.0);
      if (y > size.height || opacity <= 0) continue;
      paint.color = p.color.withOpacity(opacity * 0.85);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + p.rotSpd * t);
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
