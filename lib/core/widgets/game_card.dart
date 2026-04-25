import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../models/game.dart';
import '../mock_data.dart';
import 'avatar_widget.dart';
import 'chip_widget.dart';
import 'level_badge.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.onTap,
    this.cardStyle = 'sticker',
  });

  final Game game;
  final VoidCallback onTap;
  final String cardStyle; // 'sticker' | 'glass' | 'solid'

  @override
  Widget build(BuildContext context) {
    return switch (cardStyle) {
      'glass'  => _GlassCard(game: game, onTap: onTap),
      'solid'  => _SolidCard(game: game, onTap: onTap),
      _        => _StickerCard(game: game, onTap: onTap),
    };
  }
}

// ─── Sticker (white paper) ───────────────────────────────────────────────────
class _StickerCard extends StatelessWidget {
  const _StickerCard({required this.game, required this.onTap});
  final Game game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink, width: 2),
          boxShadow: [BoxShadow(color: AppColors.ink.withOpacity(0.12), blurRadius: 0, offset: const Offset(4, 4))],
        ),
        child: _CardBody(game: game, dark: false),
      ),
    );
  }
}

// ─── Solid (dark ink) ────────────────────────────────────────────────────────
class _SolidCard extends StatelessWidget {
  const _SolidCard({required this.game, required this.onTap});
  final Game game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
        ),
        child: _CardBody(game: game, dark: true),
      ),
    );
  }
}

// ─── Glass (cobalt frosted) ───────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.game, required this.onTap});
  final Game game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.blue800.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: _CardBody(game: game, dark: true),
      ),
    );
  }
}

// ─── Shared card body ─────────────────────────────────────────────────────────
class _CardBody extends StatelessWidget {
  const _CardBody({required this.game, required this.dark});
  final Game game;
  final bool dark;

  Color get _fg => dark ? Colors.white : AppColors.ink;
  Color get _fgSub => dark ? Colors.white.withOpacity(0.65) : AppColors.ink.withOpacity(0.60);

  @override
  Widget build(BuildContext context) {
    final players = game.playerIds.map(playerById).whereType<Object>().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: chips
        Row(
          children: [
            if (game.hot) ...[
              PPChip(variant: ChipVariant.hot, child: Text('🔥 FILLING FAST', style: AppFonts.body(10, color: Colors.white, weight: FontWeight.w600))),
              const SizedBox(width: 6),
            ],
            PPChip(
              variant: dark ? ChipVariant.defaultStyle : ChipVariant.ghost,
              child: Text(game.vibe, style: AppFonts.body(10, color: dark ? Colors.white : AppColors.ink, weight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Club name
        Text(
          game.club,
          style: AppFonts.display(22, color: _fg, letterSpacing: -0.44),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${game.area} · ${game.court}',
          style: AppFonts.body(12, color: _fgSub),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // Info row
        Row(
          children: [
            LevelBadge(levelKey: game.levelKey),
            const SizedBox(width: 8),
            _InfoPill(label: game.when, sub: game.time, dark: dark),
            const SizedBox(width: 8),
            _InfoPill(label: game.duration.replaceAll(' min', 'M'), sub: 'min', dark: dark),
          ],
        ),
        const SizedBox(height: 12),

        // Bottom row: avatars + price + spots
        Row(
          children: [
            // Overlapping avatars
            SizedBox(
              height: 28,
              width: (game.playerIds.length * 20 + 8).toDouble().clamp(28, 100),
              child: Stack(
                children: List.generate(game.playerIds.length.clamp(0, 3), (i) {
                  final p = playerById(game.playerIds[i]);
                  if (p == null) return const SizedBox.shrink();
                  return Positioned(
                    left: (i * 18).toDouble(),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: dark ? AppColors.ink : Colors.white, width: 2),
                      ),
                      child: AvatarWidget(player: p, size: 24),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${game.total - game.spots}/${game.total}',
              style: AppFonts.mono(11, color: _fgSub),
            ),
            const Spacer(),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rs ${game.price.toLocaleString()}',
                  style: AppFonts.display(16, color: _fg),
                ),
                Text(
                  'per head',
                  style: AppFonts.mono(9, color: _fgSub, letterSpacing: 0.08),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Spots
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: game.spots > 0
                    ? (dark ? AppColors.ball.withOpacity(0.15) : AppColors.ball.withOpacity(0.20))
                    : (dark ? Colors.white.withOpacity(0.08) : AppColors.mist),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                game.spots > 0 ? '${game.spots} LEFT' : 'FULL',
                style: AppFonts.mono(10,
                  color: game.spots > 0
                      ? (dark ? AppColors.ball : AppColors.ink)
                      : _fgSub,
                  letterSpacing: 0.08,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.sub, required this.dark});
  final String label;
  final String sub;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? Colors.white.withOpacity(0.10) : AppColors.ink.withOpacity(0.06);
    final fg = dark ? Colors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(label, style: AppFonts.display(13, color: fg)),
          if (sub.isNotEmpty) Text(sub, style: AppFonts.mono(9, color: fg.withOpacity(0.55))),
        ],
      ),
    );
  }
}

// Helper: format int as comma-separated string (e.g. 1200 → '1,200')
extension _IntFormat on int {
  String toLocaleString() {
    final s = toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write(',');
      result.write(s[i]);
    }
    return result.toString();
  }
}
