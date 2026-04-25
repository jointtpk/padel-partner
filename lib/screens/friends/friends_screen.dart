import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/tokens.dart';
import '../../core/mock_data.dart';
import '../../core/models/player.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/chip_widget.dart';
import '../../app/controllers/app_controller.dart';
import '../../app/routes.dart' show Routes;

// ─── Screen ───────────────────────────────────────────────────────────────────

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
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
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(
        children: [
          _Header(tab: _tab, store: store),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _FriendsTab(store: store),
                _RequestsTab(store: store),
                _SuggestedTab(store: store),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.tab, required this.store});
  final TabController tab;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.blue900,
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              const SizedBox(width: 14),
              Text('Friends', style: AppFonts.display(24, color: Colors.white, letterSpacing: -0.4)),
            ],
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: tab,
            indicatorColor: AppColors.ball,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.ball,
            unselectedLabelColor: Colors.white.withOpacity(0.45),
            labelStyle: AppFonts.body(13, weight: FontWeight.w600),
            unselectedLabelStyle: AppFonts.body(13),
            tabs: [
              const Tab(text: 'Friends'),
              Tab(
                child: Obx(() {
                  final n = store.pendingFriendRequests;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      if (n > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 18, height: 18,
                          decoration: const BoxDecoration(color: AppColors.hot, shape: BoxShape.circle),
                          child: Center(child: Text('$n', style: AppFonts.mono(9, color: Colors.white))),
                        ),
                      ],
                    ],
                  );
                }),
              ),
              const Tab(text: 'Suggested'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Friends tab ──────────────────────────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({required this.store});
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final friends = store.friends
          .where((f) => f.status == 'friends')
          .map((f) => playerById(f.userId))
          .whereType<Player>()
          .toList();

      if (friends.isEmpty) {
        return _EmptyState(
          icon: '👥',
          title: 'No friends yet',
          sub: 'Join a game and connect with players you meet on the court.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line, indent: 68),
        itemCount: friends.length,
        itemBuilder: (_, i) => _FriendRow(player: friends[i], store: store),
      );
    });
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.player, required this.store});
  final Player player;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          AvatarWidget(player: player, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: AppFonts.body(14, color: AppColors.ink, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    LevelBadge(levelKey: player.tier),
                    const SizedBox(width: 6),
                    Text(player.handle, style: AppFonts.body(11, color: AppColors.ink.withOpacity(0.45))),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Get.toNamed(
              Routes.chat,
              arguments: {'userId': player.id, 'title': player.name, 'type': 'friend'},
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(kBorderRadiusPill),
              ),
              child: Text('Message', style: AppFonts.body(12, color: Colors.white, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Requests tab ─────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.store});
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final incoming = store.friends
          .where((f) => f.status == 'pending_in')
          .map((f) => playerById(f.userId))
          .whereType<Player>()
          .toList();

      final outgoing = store.friends
          .where((f) => f.status == 'pending_out')
          .map((f) => playerById(f.userId))
          .whereType<Player>()
          .toList();

      if (incoming.isEmpty && outgoing.isEmpty) {
        return _EmptyState(
          icon: '✅',
          title: 'All caught up',
          sub: 'No pending friend requests.',
        );
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          if (incoming.isNotEmpty) ...[
            _SectionLabel('Requests received'),
            const SizedBox(height: 12),
            ...incoming.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _IncomingRequestCard(player: p, store: store),
            )),
            const SizedBox(height: 8),
          ],
          if (outgoing.isNotEmpty) ...[
            _SectionLabel('Sent'),
            const SizedBox(height: 12),
            ...outgoing.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OutgoingRequestCard(player: p),
            )),
          ],
        ],
      );
    });
  }
}

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({required this.player, required this.store});
  final Player player;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          AvatarWidget(player: player, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: AppFonts.body(14, color: AppColors.ink, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    LevelBadge(levelKey: player.tier),
                    const SizedBox(width: 6),
                    Text('${player.wins}W · ${player.games} games', style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.45))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  store.approveFriend(player.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(kBorderRadiusPill),
                  ),
                  child: Text('Accept', style: AppFonts.body(12, color: Colors.white, weight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  // Remove the pending_in entry
                  store.friends.removeWhere((f) => f.userId == player.id);
                },
                child: Text('Decline', style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.45))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutgoingRequestCard extends StatelessWidget {
  const _OutgoingRequestCard({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          AvatarWidget(player: player, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: AppFonts.body(14, color: AppColors.ink, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                LevelBadge(levelKey: player.tier),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(kBorderRadiusPill),
            ),
            child: Text('Pending', style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.50))),
          ),
        ],
      ),
    );
  }
}

// ─── Suggested tab ────────────────────────────────────────────────────────────

class _SuggestedTab extends StatelessWidget {
  const _SuggestedTab({required this.store});
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Suggest players from recent games who aren't already friends
      final friendIds = store.friends.map((f) => f.userId).toSet()..add(kMe.id);
      final suggested = kPlayers.where((p) => !friendIds.contains(p.id)).toList();

      if (suggested.isEmpty) {
        return _EmptyState(
          icon: '🎉',
          title: 'You know everyone!',
          sub: 'Play more games to meet new players.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: suggested.length,
        itemBuilder: (_, i) => _SuggestedCard(player: suggested[i], store: store),
      );
    });
  }
}

class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard({required this.player, required this.store});
  final Player player;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    // Find shared game
    final sharedGame = kGames.firstWhereOrNull((g) =>
        g.playerIds.contains(player.id) && g.playerIds.contains(kMe.id));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          AvatarWidget(player: player, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: AppFonts.body(14, color: AppColors.ink, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    LevelBadge(levelKey: player.tier),
                    const SizedBox(width: 6),
                    Text(player.city, style: AppFonts.body(11, color: AppColors.ink.withOpacity(0.45))),
                  ],
                ),
                if (sharedGame != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.sports_tennis_rounded, size: 11, color: AppColors.blue700),
                      const SizedBox(width: 4),
                      Text(
                        'Played at ${sharedGame.club}',
                        style: AppFonts.body(11, color: AppColors.blue700),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            final status = store.getFriendStatus(player.id);
            return GestureDetector(
              onTap: status == 'none'
                  ? () {
                      HapticFeedback.selectionClick();
                      store.addFriend(player.id);
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.45), letterSpacing: 0.5),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.sub});
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
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(title, style: AppFonts.display(18, color: AppColors.ink, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(sub, style: AppFonts.body(13, color: AppColors.ink.withOpacity(0.50), height: 1.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
