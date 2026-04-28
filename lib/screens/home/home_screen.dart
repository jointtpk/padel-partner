import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/controllers/app_controller.dart';
import '../../app/routes.dart';
import '../../core/mock_data.dart';
import '../../core/models/game.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ad_banner.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/ball_widget.dart';
import '../../core/widgets/chip_widget.dart';
import '../../core/services/deep_link_service.dart';
import '../../core/widgets/floating_nav.dart';
import '../../core/widgets/verified_tick.dart';
import '../../core/widgets/game_card.dart';
import '../../core/widgets/pp_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppController.to;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          // ── Main scrollable content ───────────────────────────────────────
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _HeroHeader(store: store)),
              SliverToBoxAdapter(child: _UpcomingSection(store: store)),
              SliverToBoxAdapter(child: _TrialBannerSection(store: store)),
              SliverToBoxAdapter(child: _QuickActions()),
              SliverToBoxAdapter(child: _FeedSection(store: store)),
              // Bottom padding so last card clears the nav
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
          // ── Floating nav ──────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Obx(() => FloatingNavBar(
              active: NavTab.home,
              unreadCount: store.gameChats.values
                  .expand((msgs) => msgs)
                  .where((m) => m.from != 'me')
                  .length
                  .clamp(0, 9),
              onTab: (tab) => _onNavTap(tab),
            )),
          ),
        ],
      ),
    );
  }

  void _onNavTap(NavTab tab) {
    switch (tab) {
      case NavTab.home:    Get.offAllNamed(Routes.home);
      case NavTab.browse:  Get.toNamed(Routes.browse);
      case NavTab.host:    Get.toNamed(Routes.host);
      case NavTab.chat:    Get.toNamed(Routes.inbox);
      case NavTab.profile: Get.toNamed(Routes.profile);
    }
  }
}

// ─── Hero header ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.store});
  final AppController store;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.blue800, AppColors.blue900],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Faded ball (background decoration)
          Positioned(
            top: -40, right: -60,
            child: Opacity(
              opacity: 0.35,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.3, 0, 0, 0, 0,
                  0, 0.3, 0, 0, 0,
                  0, 0, 0.3, 0, 0,
                  0, 0, 0,   1, 0,
                ]),
                child: const BallWidget(size: 220, glow: false),
              ),
            ),
          ),
          // Dot grid overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: CustomPaint(painter: _DotGridPainter()),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: logo + requests badge + avatar
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    child: const PPLogo(size: 20, dark: true),
                  ),
                  const Spacer(),
                  // Pending requests badge
                  Obx(() {
                    final count = store.totalPendingRequests;
                    if (count == 0) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => Get.toNamed(Routes.requests),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.hot,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count NEW REQ',
                          style: AppFonts.mono(11, color: Colors.white, weight: FontWeight.w700, letterSpacing: 0.05),
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () => Get.toNamed(Routes.profile),
                    child: Obx(() => AvatarWidget(player: store.currentUser.value, size: 40, ring: true)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Streak badge — only when user has played some games
              Obx(() {
                final games = store.currentUser.value.games;
                if (games < 3) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.hot,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '🔥 $games GAMES PLAYED',
                      style: AppFonts.mono(10, color: Colors.white, weight: FontWeight.w700, letterSpacing: 0.10),
                    ),
                  ),
                );
              }),
              // Headline
              Text(
                'Game on,',
                style: AppFonts.display(42, color: Colors.white, height: 0.95, letterSpacing: -0.84),
              ),
              Obx(() {
                final user = store.currentUser.value;
                final firstName = user.name.trim().split(' ').first;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$firstName.',
                      style: AppFonts.display(42, color: AppColors.ball, height: 0.95, letterSpacing: -0.84),
                    ),
                    if (user.isPro) ...[
                      const SizedBox(width: 10),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: VerifiedTick(size: 24),
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: 14),
              // XP bar — derived from current user's level + tier
              Obx(() {
                final user = store.currentUser.value;
                final tier = levelByKey(user.tier);
                final progress = ((user.level - tier.rangeMin) /
                        (tier.rangeMax - tier.rangeMin))
                    .clamp(0.0, 1.0);
                final remaining = (tier.rangeMax - user.level).clamp(0.0, double.infinity);
                return Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Stack(
                          children: [
                            Container(height: 6, color: Colors.white.withOpacity(0.15)),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.ball,
                                  boxShadow: [BoxShadow(color: AppColors.ball.withOpacity(0.53), blurRadius: 12)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'LVL ${user.level.toStringAsFixed(1)} · ${remaining.toStringAsFixed(1)} TO GO',
                      style: AppFonts.mono(10, color: AppColors.ball, weight: FontWeight.w700, letterSpacing: 0.10),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Upcoming matches strip ───────────────────────────────────────────────────
class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection({required this.store});
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final upcoming = _buildUpcoming(store);

      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Text(
                    'My upcoming matches',
                    style: AppFonts.display(18, color: AppColors.ink, letterSpacing: -0.36),
                  ),
                  const Spacer(),
                  Text(
                    '${upcoming.length}',
                    style: AppFonts.mono(11, color: AppColors.ink.withOpacity(0.60)),
                  ),
                ],
              ),
            ),
            if (upcoming.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'No matches booked yet.',
                        style: AppFonts.body(13, color: AppColors.ink.withOpacity(0.60)),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.browse),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.ball,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [BoxShadow(color: AppColors.ball.withOpacity(0.40), blurRadius: 14, offset: const Offset(0, 6))],
                          ),
                          child: Text('Find a game', style: AppFonts.display(12, color: AppColors.ink)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 204,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: upcoming.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _UpcomingCard(item: upcoming[i], store: store),
                ),
              ),
          ],
        ),
      );
    });
  }

  List<_UpcomingItem> _buildUpcoming(AppController store) {
    // Touch the reactive lists explicitly so the enclosing Obx
    // re-runs whenever bookings or hostedGames change.
    // ignore: unused_local_variable
    final bookingsLen = store.bookings.length;
    // ignore: unused_local_variable
    final hostedLen = store.hostedGames.length;

    final items = <_UpcomingItem>[];
    for (final b in store.bookings) {
      final g = kGames.firstWhereOrNull((g) => g.id == b.gameId) ??
          store.hostedGames.firstWhereOrNull((g) => g.id == b.gameId);
      if (g != null) items.add(_UpcomingItem(game: g, status: b.status));
    }
    for (final g in store.hostedGames) {
      if (!items.any((i) => i.game.id == g.id)) {
        items.add(_UpcomingItem(game: g, status: 'hosting'));
      }
    }
    return items;
  }
}

class _UpcomingItem {
  const _UpcomingItem({required this.game, required this.status});
  final Game game;
  final String status;
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.item, required this.store});
  final _UpcomingItem item;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    final g = item.game;
    final isPending  = item.status == 'pending';
    final isHosting  = item.status == 'hosting';
    final isDark     = !isPending;

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.detail, arguments: g),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPending ? Colors.white : AppColors.ink,
          borderRadius: BorderRadius.circular(18),
          border: isPending ? Border.all(color: AppColors.blue800, width: 2, style: BorderStyle.solid) : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!isPending)
              Positioned(top: -20, right: -20, child: Opacity(opacity: 0.40, child: const BallWidget(size: 80))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PPChip(
                      variant: isHosting
                          ? ChipVariant.ball
                          : (isPending ? ChipVariant.ghost : ChipVariant.defaultStyle),
                      child: Text(
                        isHosting ? '👑 HOSTING' : (isPending ? '⏳ AWAITING' : '✓ CONFIRMED'),
                        style: AppFonts.body(10,
                          color: isHosting ? AppColors.ink : (isPending ? AppColors.ink : Colors.white),
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${g.when} · ${g.time}',
                      style: AppFonts.mono(10,
                        color: isDark ? Colors.white.withOpacity(0.70) : AppColors.ink.withOpacity(0.70),
                        letterSpacing: 0.08,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  g.club,
                  style: AppFonts.display(20, color: isDark ? Colors.white : AppColors.ink, letterSpacing: -0.20),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${g.area} · ${g.court}',
                  style: AppFonts.body(12, color: isDark ? Colors.white.withOpacity(0.65) : AppColors.ink.withOpacity(0.65)),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Player slots row
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPending ? AppColors.paper : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _AvatarStack(playerIds: g.playerIds, total: g.total, dark: isDark),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${g.total - g.spots}/${g.total}',
                            style: AppFonts.display(16,
                              color: isDark ? Colors.white : AppColors.ink,
                              letterSpacing: -0.16,
                            ),
                          ),
                          Text(
                            g.spots > 0 ? '${g.spots} OPEN' : 'FULL',
                            style: AppFonts.mono(8,
                              color: isDark ? Colors.white.withOpacity(0.60) : AppColors.ink.withOpacity(0.60),
                              letterSpacing: 0.12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isHosting && g.spots > 0) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final url = await DeepLinkService.buildShareUrl(g);
                      final text =
                          "🎾 I'm hosting a padel game at ${g.club} (${g.area}) — "
                          "${g.when} ${g.time}. "
                          "${g.spots} spot${g.spots > 1 ? 's' : ''} open.\n\n"
                          "Tap to join: $url";
                      await Share.share(text, subject: 'Join my padel game');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.ball,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '🎾 SHARE TO FILL ${g.spots} SPOT${g.spots > 1 ? 'S' : ''}',
                        textAlign: TextAlign.center,
                        style: AppFonts.mono(9, color: AppColors.ink, letterSpacing: 0.12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.playerIds, required this.total, required this.dark});
  final List<String> playerIds;
  final int total;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: (total * 22 + 4).toDouble(),
      child: Stack(
        children: List.generate(total, (i) {
          final pid = i < playerIds.length ? playerIds[i] : null;
          final p = pid != null ? playerById(pid) : null;
          return Positioned(
            left: (i * 18).toDouble(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: dark ? AppColors.ink : Colors.white,
                  width: 2,
                ),
              ),
              child: p != null
                  ? AvatarWidget(player: p, size: 26)
                  : Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.ball.withOpacity(0.15),
                        border: Border.all(color: AppColors.ball, width: 1.5),
                      ),
                      child: Center(
                        child: Text('+', style: TextStyle(color: AppColors.ball, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Trial banner ─────────────────────────────────────────────────────────────
class _TrialBannerSection extends StatelessWidget {
  const _TrialBannerSection({required this.store});
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (store.subscription.value.plan != 'trial') return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: TrialBanner(
          daysLeft: store.subscription.value.daysLeft,
          onUpgrade: () => Get.toNamed(Routes.subscription),
        ),
      );
    });
  }
}

// ─── Quick action 2-up grid ───────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Get.toNamed(Routes.browse),
              child: Container(
                height: 104,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: [
                    Positioned(right: -10, bottom: -10, child: Opacity(opacity: 0.5, child: const BallWidget(size: 60, glow: false))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FIND', style: AppFonts.mono(10, color: Colors.white.withOpacity(0.60), letterSpacing: 0.10)),
                        const SizedBox(height: 4),
                        Text('Join a\ngame', style: AppFonts.display(20, color: Colors.white, height: 1.05, letterSpacing: -0.40)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Get.toNamed(Routes.host),
              child: Container(
                height: 104,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ball,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20, bottom: -20,
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 4),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CREATE', style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.60), letterSpacing: 0.10)),
                        const SizedBox(height: 4),
                        Text('Host a\nmatch', style: AppFonts.display(20, color: AppColors.ink, height: 1.05, letterSpacing: -0.40)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Open courts feed ─────────────────────────────────────────────────────────
class _FeedSection extends StatelessWidget {
  const _FeedSection({required this.store});
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Filter out games the user has already booked or is hosting themselves
      final bookedIds = store.bookings.map((b) => b.gameId).toSet();
      final myId = store.currentUser.value.id;
      final feed = <Game>[
        ...kGames.where((g) => !bookedIds.contains(g.id)),
        ...store.hostedGames.where((g) =>
            g.hostId != myId && !bookedIds.contains(g.id)),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: Row(
              children: [
                Text(
                  'Open courts',
                  style: AppFonts.display(22, color: AppColors.ink, letterSpacing: -0.44),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.browse),
                  child: Text(
                    'See all →',
                    style: AppFonts.body(13, color: AppColors.blue800, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (feed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        const Text('🎾', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 10),
                        Text(
                          'No open courts right now',
                          style: AppFonts.display(14, color: AppColors.ink, letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first — host a match and friends can join.',
                          textAlign: TextAlign.center,
                          style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.55)),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => Get.toNamed(Routes.host),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Host a match',
                              style: AppFonts.body(13, color: Colors.white, weight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (store.subscription.value.plan != 'pro') ...[
                    const SizedBox(height: 12),
                    const AdBanner(variant: 'court'),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ...feed.take(2).map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GameCard(
                      game: g,
                      onTap: () => Get.toNamed(Routes.detail, arguments: g),
                    ),
                  )),
                  if (store.subscription.value.plan != 'pro') ...[
                    const AdBanner(variant: 'court'),
                    const SizedBox(height: 12),
                  ],
                  ...feed.skip(2).map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GameCard(
                      game: g,
                      onTap: () => Get.toNamed(Routes.detail, arguments: g),
                    ),
                  )),
                ],
              ),
            ),
        ],
      );
    });
  }
}

// ─── Dot grid background painter ─────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.40);
    const spacing = 4.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

