import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/tokens.dart';
import '../../core/mock_data.dart';
import '../../core/models/player.dart';
import '../../core/models/game.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/chip_widget.dart';
import '../../core/widgets/game_card.dart';
import '../../app/controllers/app_controller.dart';
import '../../app/routes.dart' show Routes;

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppController.to;
    final passedPlayer = Get.arguments as Player?;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Obx(() {
        // If a player was passed as argument, show their profile;
        // else show the current logged-in user (reactive).
        final player = passedPlayer ?? store.currentUser.value;
        final isOwnProfile = player.id == store.currentUser.value.id;

        return NestedScrollView(
          headerSliverBuilder: (_, __) => [
            _ProfileHeaderSliver(player: player, isOwn: isOwnProfile, store: store),
          ],
          body: Column(
            children: [
              _TabBar(tab: _tab),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _StatsTab(player: player),
                    _HistoryTab(player: player, store: store),
                    _PartnersTab(player: player, store: store),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Profile header sliver ────────────────────────────────────────────────────

class _ProfileHeaderSliver extends StatelessWidget {
  const _ProfileHeaderSliver({required this.player, required this.isOwn, required this.store});
  final Player player;
  final bool isOwn;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final level = levelByKey(player.tier);

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.blue900, Color(0xFF0D2580)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, top + 10, 20, 24),
        child: Column(
          children: [
            // Top bar
            Row(
              children: [
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                  ),
                ),
                const Spacer(),
                if (isOwn) ...[
                  GestureDetector(
                    onTap: () => Get.toNamed(Routes.editProfile),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Get.toNamed(Routes.subscription),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.ball.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(kBorderRadiusPill),
                        border: Border.all(color: AppColors.ball.withOpacity(0.30)),
                      ),
                      child: Obx(() {
                        final sub = store.subscription.value;
                        return Text(
                          sub.plan == 'pro' ? '⭐ Pro' : '${sub.daysLeft}d trial',
                          style: AppFonts.mono(10, color: AppColors.ball, letterSpacing: 0.3),
                        );
                      }),
                    ),
                  ),
                ] else
                  Obx(() {
                    final status = store.getFriendStatus(player.id);
                    return _FriendPill(uid: player.id, status: status, store: store);
                  }),
              ],
            ),

            const SizedBox(height: 24),

            // Avatar + name
            AvatarWidget(player: player, size: 80, ring: true),
            const SizedBox(height: 14),
            Text(player.name, style: AppFonts.display(26, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(player.handle, style: AppFonts.body(13, color: Colors.white.withOpacity(0.55))),
                Container(
                  width: 3, height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle),
                ),
                Text(player.city, style: AppFonts.body(13, color: Colors.white.withOpacity(0.55))),
              ],
            ),

            const SizedBox(height: 16),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _StatCell(value: '${player.wins}', label: 'WINS'),
                  _StatDivider(),
                  _StatCell(value: '${player.games}', label: 'GAMES'),
                  _StatDivider(),
                  _StatCell(value: '${(player.winRate * 100).round()}%', label: 'WIN RATE'),
                  _StatDivider(),
                  _StatCell(value: '${player.level}', label: 'LEVEL'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Level progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LevelBadge(levelKey: player.tier),
                    const Spacer(),
                    Text(
                      '${player.level} / ${level.rangeMax.toStringAsFixed(1)}',
                      style: AppFonts.mono(10, color: Colors.white.withOpacity(0.50)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ((player.level - level.rangeMin) /
                        (level.rangeMax - level.rangeMin))
                        .clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ball),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  level.desc,
                  style: AppFonts.body(11, color: Colors.white.withOpacity(0.45), height: 1.3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppFonts.display(18, color: Colors.white, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text(label, style: AppFonts.mono(8, color: Colors.white.withOpacity(0.40), letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 32,
    color: Colors.white.withOpacity(0.10),
  );
}

class _FriendPill extends StatelessWidget {
  const _FriendPill({required this.uid, required this.status, required this.store});
  final String uid;
  final String status;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    if (status == 'friends') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(kBorderRadiusPill),
        ),
        child: Text('Friends', style: AppFonts.body(12, color: AppColors.success, weight: FontWeight.w600)),
      );
    }
    if (status == 'pending_out') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(kBorderRadiusPill),
        ),
        child: Text('Request sent', style: AppFonts.body(12, color: Colors.white.withOpacity(0.60))),
      );
    }
    return GestureDetector(
      onTap: () => store.addFriend(uid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.ball,
          borderRadius: BorderRadius.circular(kBorderRadiusPill),
        ),
        child: Text(
          status == 'pending_in' ? 'Accept request' : '+ Add friend',
          style: AppFonts.body(12, color: AppColors.ink, weight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Tab bar ──────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab});
  final TabController tab;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tab,
        indicatorColor: AppColors.blue900,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.ink.withOpacity(0.40),
        labelStyle: AppFonts.body(13, weight: FontWeight.w700),
        unselectedLabelStyle: AppFonts.body(13),
        tabs: const [
          Tab(text: 'Stats'),
          Tab(text: 'History'),
          Tab(text: 'Partners'),
        ],
      ),
    );
  }
}

// ─── Stats tab ────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    final level = levelByKey(player.tier);
    final nextLevel = kLevels.firstWhereOrNull((l) => l.tier == level.tier + 1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // Rating word-pills (no stars)
        Text('Ratings', style: AppFonts.display(16, color: AppColors.ink, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _ratingTags(player).map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: level.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(kBorderRadiusPill),
              border: Border.all(color: level.color.withOpacity(0.35)),
            ),
            child: Text(tag, style: AppFonts.body(12, color: AppColors.ink, weight: FontWeight.w600)),
          )).toList(),
        ),

        const SizedBox(height: 24),
        Text('Performance', style: AppFonts.display(16, color: AppColors.ink, letterSpacing: -0.3)),
        const SizedBox(height: 12),

        // Performance tiles 2×2
        Row(
          children: [
            Expanded(child: _PerfTile(label: 'Win streak', value: '${_streak(player)}', unit: 'games')),
            const SizedBox(width: 10),
            Expanded(child: _PerfTile(label: 'Avg per month', value: '${(player.games / 6).round()}', unit: 'games')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _PerfTile(label: 'Losses', value: '${player.games - player.wins}', unit: 'total')),
            const SizedBox(width: 10),
            Expanded(child: _PerfTile(label: 'Win rate', value: '${(player.winRate * 100).round()}', unit: '%')),
          ],
        ),

        if (nextLevel != null) ...[
          const SizedBox(height: 24),
          Text('Next level: ${nextLevel.label}', style: AppFonts.display(16, color: AppColors.ink, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: nextLevel.color, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${nextLevel.tier}', style: AppFonts.display(18, color: nextLevel.fg)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nextLevel.label, style: AppFonts.body(14, color: AppColors.ink, weight: FontWeight.w700)),
                      Text(nextLevel.desc, style: AppFonts.body(11, color: AppColors.ink.withOpacity(0.55), height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<String> _ratingTags(Player p) {
    if (p.tier == 'elite') return ['Dominant', 'Net Master', 'Smash King', 'Tactical'];
    if (p.tier == 'pro')   return ['Sharp', 'Consistent', 'Strategic', 'Reliable'];
    if (p.tier == 'regular') return ['Solid Rallier', 'Court Reader', 'Improving'];
    if (p.tier == 'amateur') return ['Working on it', 'Eager', 'Getting there'];
    return ['Learning', 'New Player'];
  }

  int _streak(Player p) => (p.wins * 0.18).round().clamp(1, 9);
}

class _PerfTile extends StatelessWidget {
  const _PerfTile({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.45), letterSpacing: 0.4)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppFonts.display(26, color: AppColors.ink, letterSpacing: -0.5)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit, style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.40))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── History tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.player, required this.store});
  final Player player;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    // Games this player appears in
    final games = kGames.where((g) => g.playerIds.contains(player.id)).toList();

    if (games.isEmpty) {
      return _EmptyTab(icon: '📋', title: 'No games yet', sub: 'Games will appear here after they\'re played.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: games.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GameCard(
          game: games[i],
          cardStyle: 'sticker',
          onTap: () => Get.toNamed(Routes.detail, arguments: games[i]),
        ),
      ),
    );
  }
}

// ─── Partners tab ─────────────────────────────────────────────────────────────

class _PartnersTab extends StatelessWidget {
  const _PartnersTab({required this.player, required this.store});
  final Player player;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    // Co-players from shared games
    final partnerIds = <String>{};
    for (final g in kGames) {
      if (g.playerIds.contains(player.id)) {
        partnerIds.addAll(g.playerIds.where((id) => id != player.id));
      }
    }

    final partners = partnerIds
        .map(playerById)
        .whereType<Player>()
        .toList();

    if (partners.isEmpty) {
      return _EmptyTab(icon: '🤝', title: 'No partners yet', sub: 'Players met in games will appear here.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line, indent: 68),
      itemCount: partners.length,
      itemBuilder: (_, i) {
        final p = partners[i];
        final isOwn = player.id == AppController.to.currentUser.value.id;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              AvatarWidget(player: p, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: AppFonts.body(14, color: AppColors.ink, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        LevelBadge(levelKey: p.tier),
                        const SizedBox(width: 6),
                        Text(p.city, style: AppFonts.body(11, color: AppColors.ink.withOpacity(0.45))),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwn)
                Obx(() {
                  final status = store.getFriendStatus(p.id);
                  if (status == 'friends') {
                    return GestureDetector(
                      onTap: () => Get.toNamed(
                        Routes.chat,
                        arguments: {'userId': p.id, 'title': p.name, 'type': 'friend'},
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(kBorderRadiusPill),
                        ),
                        child: Text('Message', style: AppFonts.body(12, color: Colors.white, weight: FontWeight.w600)),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => store.addFriend(p.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: status == 'none' ? AppColors.ink : AppColors.mist,
                        borderRadius: BorderRadius.circular(kBorderRadiusPill),
                      ),
                      child: Text(
                        status == 'none' ? '+ Add' : 'Sent',
                        style: AppFonts.body(12,
                          color: status == 'none' ? Colors.white : AppColors.ink.withOpacity(0.45),
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

// ─── Empty tab ────────────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.icon, required this.title, required this.sub});
  final String icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 14),
            Text(title, style: AppFonts.display(18, color: AppColors.ink, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(sub, style: AppFonts.body(13, color: AppColors.ink.withOpacity(0.50), height: 1.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
