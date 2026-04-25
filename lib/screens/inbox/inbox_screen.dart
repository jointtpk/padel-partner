import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/tokens.dart';
import '../../core/mock_data.dart';
import '../../core/widgets/floating_nav.dart';
import '../../app/controllers/app_controller.dart';
import '../../app/routes.dart' show Routes;

// ─── Screen ───────────────────────────────────────────────────────────────────

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
      body: Stack(
        children: [
          Column(
            children: [
              _Header(tab: _tab),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _GameChatsTab(store: store),
                    _FriendChatsTab(store: store),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: FloatingNavBar(
              active: NavTab.chat,
              onTab: (NavTab tab) {
                switch (tab) {
                  case NavTab.home: Get.offAllNamed(Routes.home); break;
                  case NavTab.browse: Get.offAllNamed(Routes.browse); break;
                  case NavTab.profile: Get.toNamed(Routes.profile); break;
                  case NavTab.host: Get.toNamed(Routes.host); break;
                  default: break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.tab});
  final TabController tab;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.blue900,
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inbox', style: AppFonts.display(26, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 14),
          TabBar(
            controller: tab,
            indicatorColor: AppColors.ball,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.ball,
            unselectedLabelColor: Colors.white.withOpacity(0.45),
            labelStyle: AppFonts.body(14, weight: FontWeight.w600),
            unselectedLabelStyle: AppFonts.body(14),
            tabs: const [
              Tab(text: 'Games'),
              Tab(text: 'Friends'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Game chats tab ───────────────────────────────────────────────────────────

class _GameChatsTab extends StatelessWidget {
  const _GameChatsTab({required this.store});
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show chats for confirmed/hosted bookings that have messages or at least exist
      final myGameIds = store.bookings
          .where((b) => b.status == 'confirmed' || b.status == 'hosting')
          .map((b) => b.gameId)
          .toList();

      // Also include any game with existing chat messages
      final chatGameIds = store.gameChats.keys.toList();
      final allIds = {...myGameIds, ...chatGameIds}.toList();

      if (allIds.isEmpty) {
        return _EmptyTab(
          icon: '🎾',
          title: 'No game chats yet',
          sub: 'Join or host a game to start chatting with your team.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line, indent: 72),
        itemCount: allIds.length,
        itemBuilder: (_, i) {
          final gameId = allIds[i];
          final game = kGames.firstWhereOrNull((g) => g.id == gameId) ??
              store.hostedGames.firstWhereOrNull((g) => g.id == gameId);
          final messages = store.gameChats[gameId] ?? [];
          final last = messages.isNotEmpty ? messages.last : null;

          return _GameChatRow(
            gameId: gameId,
            clubName: game?.club ?? 'Game chat',
            subtitle: game != null ? '${game.area} · ${game.when}' : gameId,
            lastMessage: last?.text,
            lastTime: last?.t,
            isHosting: store.bookings.any((b) => b.gameId == gameId && b.status == 'hosting'),
          );
        },
      );
    });
  }
}

class _GameChatRow extends StatelessWidget {
  const _GameChatRow({
    required this.gameId,
    required this.clubName,
    required this.subtitle,
    required this.lastMessage,
    required this.lastTime,
    required this.isHosting,
  });

  final String gameId;
  final String clubName;
  final String subtitle;
  final String? lastMessage;
  final String? lastTime;
  final bool isHosting;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.chat,
        arguments: {'gameId': gameId, 'title': clubName, 'type': 'game'},
      ),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Court icon avatar
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.blue800, AppColors.blue900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: Text('🎾', style: TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clubName,
                          style: AppFonts.body(14, color: AppColors.ink, weight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastTime != null)
                        Text(lastTime!, style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.35))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.40), letterSpacing: 0.2),
                  ),
                  if (lastMessage != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      lastMessage!,
                      style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.55)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (isHosting) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.ball.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('HOST', style: AppFonts.mono(8, color: AppColors.ink, letterSpacing: 0.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Friend chats tab ─────────────────────────────────────────────────────────

class _FriendChatsTab extends StatelessWidget {
  const _FriendChatsTab({required this.store});
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final chatFriendIds = store.friendChats.keys.toList();

      if (chatFriendIds.isEmpty) {
        return _EmptyTab(
          icon: '👋',
          title: 'No messages yet',
          sub: 'Add friends from a game and start chatting.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line, indent: 72),
        itemCount: chatFriendIds.length,
        itemBuilder: (_, i) {
          final uid = chatFriendIds[i];
          final player = playerById(uid);
          final messages = store.friendChats[uid] ?? [];
          final last = messages.isNotEmpty ? messages.last : null;
          final isMe = last?.from == 'me';

          return _FriendChatRow(
            uid: uid,
            playerName: player?.name ?? 'Unknown',
            handle: player?.handle ?? '',
            avatarColor: player?.avatarColor ?? AppColors.mist,
            initials: player?.initials ?? '??',
            lastMessage: last != null ? (isMe ? 'You: ${last.text}' : last.text) : null,
            lastTime: last?.t,
          );
        },
      );
    });
  }
}

class _FriendChatRow extends StatelessWidget {
  const _FriendChatRow({
    required this.uid,
    required this.playerName,
    required this.handle,
    required this.avatarColor,
    required this.initials,
    required this.lastMessage,
    required this.lastTime,
  });

  final String uid;
  final String playerName;
  final String handle;
  final Color avatarColor;
  final String initials;
  final String? lastMessage;
  final String? lastTime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.chat,
        arguments: {'userId': uid, 'title': playerName, 'type': 'friend'},
      ),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initials, style: AppFonts.display(18, color: AppColors.ink, letterSpacing: -0.3)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          playerName,
                          style: AppFonts.body(14, color: AppColors.ink, weight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastTime != null)
                        Text(lastTime!, style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.35))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(handle, style: AppFonts.body(11, color: AppColors.ink.withOpacity(0.40))),
                  if (lastMessage != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      lastMessage!,
                      style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.55)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
