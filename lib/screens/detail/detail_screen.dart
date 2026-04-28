import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/tokens.dart';
import '../../core/mock_data.dart';
import '../../core/models/game.dart';
import '../../core/models/game_time.dart';
import '../../core/models/player.dart';
import '../../core/services/identity_service.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/chip_widget.dart';
import '../../core/widgets/court_diagram.dart';
import '../../core/widgets/verified_tick.dart';
import '../../app/controllers/app_controller.dart';
import '../../app/routes.dart' show Routes;

// ─── Screen ───────────────────────────────────────────────────────────────────

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Get.arguments as Game;
    final store = AppController.to;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _HeroSliver(game: game),
              SliverToBoxAdapter(child: _CourtSection(game: game)),
              SliverToBoxAdapter(child: _InfoGrid(game: game)),
              SliverToBoxAdapter(child: _PlayersSection(game: game, store: store)),
              SliverToBoxAdapter(child: _HostSection(game: game, store: store)),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: _BackBtn(),
          ),
          // Sticky CTA
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _StickyCtaBar(game: game, store: store),
          ),
        ],
      ),
    );
  }
}

// ─── Hero sliver ─────────────────────────────────────────────────────────────

class _HeroSliver extends StatelessWidget {
  const _HeroSliver({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.blue900, Color(0xFF0D2580)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 56, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chips row
            Row(
              children: [
                if (game.hot) ...[
                  PPChip(
                    variant: ChipVariant.hot,
                    child: Text('🔥 FILLING FAST', style: AppFonts.body(10, color: Colors.white, weight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 6),
                ],
                PPChip(
                  variant: ChipVariant.defaultStyle,
                  child: Text(game.vibe, style: AppFonts.body(10, color: Colors.white, weight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Club name
            Text(
              game.club,
              style: AppFonts.display(28, color: Colors.white, letterSpacing: -0.6),
            ),
            const SizedBox(height: 4),
            Text(
              '${game.area} · ${game.court}',
              style: AppFonts.body(13, color: Colors.white.withOpacity(0.65)),
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(
              children: [
                _HeroStat(label: game.when, sub: game.time),
                const SizedBox(width: 10),
                _HeroStat(label: game.duration.replaceAll(' min', ''), sub: 'min'),
                const SizedBox(width: 10),
                _HeroStat(label: game.weather, sub: ''),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs ${_fmt(game.price)}',
                      style: AppFonts.display(20, color: AppColors.ball),
                    ),
                    Text('per head', style: AppFonts.mono(9, color: Colors.white.withOpacity(0.50))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Level badge + spots
            Row(
              children: [
                LevelBadge(levelKey: game.levelKey),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: game.spots > 0
                        ? AppColors.ball.withOpacity(0.15)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(kBorderRadiusPill),
                  ),
                  child: Text(
                    game.spots > 0 ? '${game.spots} spot${game.spots == 1 ? '' : 's'} left' : 'FULL',
                    style: AppFonts.mono(10,
                      color: game.spots > 0 ? AppColors.ball : Colors.white.withOpacity(0.55),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.sub});
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: AppFonts.display(13, color: Colors.white)),
          if (sub.isNotEmpty)
            Text(sub, style: AppFonts.mono(9, color: Colors.white.withOpacity(0.50))),
        ],
      ),
    );
  }
}

// ─── Court diagram section ────────────────────────────────────────────────────

class _CourtSection extends StatelessWidget {
  const _CourtSection({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    final store = AppController.to;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Line-up', style: AppFonts.display(16, color: AppColors.ink, letterSpacing: -0.3)),
              const Spacer(),
              Obx(() {
                final me = store.currentUser.value;
                final myUid = IdentityService.instance.cached;
                final amLocalHost = store.hostedGames.any((g) => g.id == game.id);
                final isHost = (game.hostUid != null && game.hostUid == myUid) ||
                    (game.hostUid == null && amLocalHost);
                final eligible = isHost ||
                    game.playerIds.contains(me.id) ||
                    store.getBookingStatus(game.id) == 'confirmed';
                final hasSlot = (store.courtPositions[game.id] ?? const {}).containsKey(me.id);
                if (!eligible || hasSlot) return const SizedBox.shrink();
                return Text(
                  'Tap a + to pick your spot',
                  style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.45), letterSpacing: 0.3),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final me = store.currentUser.value;
            final positions = store.courtPositions[game.id] ?? const {};
            final assignments = <int, Player>{};
            positions.forEach((uid, slot) {
              final p = playerById(uid);
              if (p != null) assignments[slot] = p;
            });
            final myUid = IdentityService.instance.cached;
            final amLocalHost = store.hostedGames.any((g) => g.id == game.id);
            final isHost = (game.hostUid != null && game.hostUid == myUid) ||
                (game.hostUid == null && amLocalHost);
            final eligible = isHost ||
                game.playerIds.contains(me.id) ||
                store.getBookingStatus(game.id) == 'confirmed';
            return CourtDiagram(
              slotAssignments: assignments,
              onClaimSlot: eligible
                  ? (slot) {
                      HapticFeedback.lightImpact();
                      store.claimCourtPosition(game.id, me.id, slot);
                    }
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

// ─── Info grid ────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details', style: AppFonts.display(16, color: AppColors.ink, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _InfoTile(icon: '📅', label: 'Date', value: '${game.when}, ${game.time}')),
              const SizedBox(width: 10),
              Expanded(child: _InfoTile(icon: '⏱', label: 'Duration', value: game.duration)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _InfoTile(icon: '🌤', label: 'Weather', value: game.weather)),
              const SizedBox(width: 10),
              Expanded(child: _InfoTile(
                icon: game.autoApprove ? '⚡' : '✋',
                label: 'Entry',
                value: game.autoApprove ? 'Auto-approve' : 'Host approves',
              )),
            ],
          ),
          if (game.totalCost != null) ...[
            const SizedBox(height: 10),
            _InfoTile(icon: '💰', label: 'Total court cost', value: 'Rs ${_fmt(game.totalCost!)}'),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final String icon;
  final String label;
  final String value;

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
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(label, style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.45), letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value, style: AppFonts.body(13, color: AppColors.ink, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Players section ──────────────────────────────────────────────────────────

class _PlayersSection extends StatelessWidget {
  const _PlayersSection({required this.game, required this.store});
  final Game game;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    // Resolve each id in playerIds to a Player. The host's id is `'me'`
    // (legacy local-only id), which on the joiner's device would resolve to
    // the joiner's own kMe — wrong. Prefer the embedded hostSnapshot for
    // the host slot.
    final players = <Player>[];
    for (final id in game.playerIds) {
      Player? p;
      if (id == game.hostId && game.hostSnapshot != null) {
        p = game.hostSnapshot;
      } else {
        p = playerById(id);
      }
      if (p != null) players.add(p);
    }
    final emptyCount = game.total - players.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Players', style: AppFonts.display(16, color: AppColors.ink, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          ...players.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlayerRow(player: p, isHost: p.id == game.hostId, store: store),
          )),
          ...List.generate(emptyCount, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EmptyPlayerRow(number: players.length + i + 1),
          )),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.isHost, required this.store});
  final Player player;
  final bool isHost;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    final isMe = player.id == kMe.id;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          AvatarWidget(player: player, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(player.name, style: AppFonts.body(14, color: AppColors.ink, weight: FontWeight.w600)),
                    if (player.isPro) ...[
                      const SizedBox(width: 5),
                      const VerifiedTick(size: 13),
                    ],
                    const SizedBox(width: 6),
                    if (isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.blue50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('HOST', style: AppFonts.mono(8, color: AppColors.blue800, letterSpacing: 0.5)),
                      ),
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ball.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('YOU', style: AppFonts.mono(8, color: AppColors.ink, letterSpacing: 0.5)),
                      ),
                  ],
                ),
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
          if (!isMe && !isHost)
            Obx(() {
              final status = store.getFriendStatus(player.id);
              return _FriendBtn(uid: player.id, status: status, store: store);
            }),
        ],
      ),
    );
  }
}

class _FriendBtn extends StatelessWidget {
  const _FriendBtn({required this.uid, required this.status, required this.store});
  final String uid;
  final String status;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    if (status == 'friends') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(kBorderRadiusPill),
        ),
        child: Text('Friends', style: AppFonts.body(11, color: AppColors.success, weight: FontWeight.w600)),
      );
    }
    if (status == 'pending_out') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(kBorderRadiusPill),
        ),
        child: Text('Pending', style: AppFonts.body(11, color: AppColors.ink.withOpacity(0.50))),
      );
    }
    return GestureDetector(
      onTap: () => store.addFriend(uid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(kBorderRadiusPill),
        ),
        child: Text(
          status == 'pending_in' ? 'Accept' : '+ Add',
          style: AppFonts.body(11, color: Colors.white, weight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _EmptyPlayerRow extends StatelessWidget {
  const _EmptyPlayerRow({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          const EmptySlotWidget(size: 44),
          const SizedBox(width: 12),
          Text(
            'Open spot #$number',
            style: AppFonts.body(13, color: AppColors.ink.withOpacity(0.35)),
          ),
        ],
      ),
    );
  }
}

// ─── Host section ─────────────────────────────────────────────────────────────

class _HostSection extends StatelessWidget {
  const _HostSection({required this.game, required this.store});
  final Game game;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    // Prefer the host snapshot embedded in the game (correct on any device).
    // Only fall back to playerById when there is no snapshot — that path is
    // safe for locally-stored legacy games where the user *is* the host.
    final host = game.hostSnapshot ?? playerById(game.hostId);
    if (host == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hosted by', style: AppFonts.display(16, color: AppColors.ink, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                AvatarWidget(player: host, size: 52, ring: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(host.name,
                                style: AppFonts.display(16, color: AppColors.ink, letterSpacing: -0.2),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (host.isPro) ...[
                            const SizedBox(width: 6),
                            const VerifiedTick(size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(host.handle, style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.50))),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          LevelBadge(levelKey: host.tier),
                          const SizedBox(width: 8),
                          Text(
                            '${host.wins}W · ${host.games} games',
                            style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.45)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (host.id != kMe.id)
                  Obx(() {
                    final status = store.getFriendStatus(host.id);
                    return _FriendBtn(uid: host.id, status: status, store: store);
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Back button ──────────────────────────────────────────────────────────────

class _BackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: Get.back,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── Sticky CTA bar ───────────────────────────────────────────────────────────

class _StickyCtaBar extends StatelessWidget {
  const _StickyCtaBar({required this.game, required this.store});
  final Game game;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Obx(() {
      final status = store.getBookingStatus(game.id);
      // Cross-device host check: prefer the Firebase/sync UID stamped on
      // the game (set in AppController.addHostedGame). Only fall back to
      // local presence in `hostedGames` when no uid is available — using
      // `hostId == 'me'` directly is unsafe because every user's kMe.id is
      // 'me' and would falsely flag joiners as the host.
      final myUid = IdentityService.instance.cached;
      final amLocalHost = store.hostedGames.any((g) => g.id == game.id);
      final isHosting = (game.hostUid != null && game.hostUid == myUid) ||
          (game.hostUid == null && amLocalHost);

      return Container(
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border(top: BorderSide(color: AppColors.line)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: _ctaContent(status, isHosting),
      );
    });
  }

  Widget _ctaContent(String status, bool isHosting) {
    final hasStarted = GameTime.hasStarted(game);

    if (isHosting) {
      // The host can still edit the game while no other player has joined
      // (i.e. only their own id is in playerIds). Locking edits the moment
      // someone else is in keeps the deal honest for joiners.
      final canEdit = !hasStarted && game.playerIds.length <= 1;
      return Row(
        children: [
          if (canEdit) ...[
            Expanded(
              child: _CtaBtn(
                label: 'Edit',
                color: AppColors.mist,
                textColor: AppColors.ink,
                onTap: () => _openEditSheet(),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: canEdit ? 2 : 3,
            child: _CtaBtn(
              label: 'Manage requests',
              color: AppColors.ink,
              textColor: Colors.white,
              onTap: () => Get.toNamed(Routes.requests, arguments: game),
            ),
          ),
          const SizedBox(width: 10),
          _CtaBtn(
            label: 'Chat',
            color: AppColors.ball,
            textColor: AppColors.ink,
            onTap: () => Get.toNamed(Routes.chat, arguments: {'gameId': game.id, 'title': game.club}),
          ),
        ],
      );
    }

    // Joiners can't request to join after the start time has passed.
    // Confirmed bookings still get the chat shortcut.
    if (hasStarted && status != 'confirmed') {
      return _StaticBanner(
        title: 'Game has already started',
        body: 'You can no longer request to join.',
      );
    }

    switch (status) {
      case 'confirmed':
        return _CtaBtn(
          label: 'Open match chat',
          color: AppColors.ball,
          textColor: AppColors.ink,
          fullWidth: true,
          onTap: () => Get.toNamed(Routes.chat, arguments: {'gameId': game.id, 'title': game.club}),
        );

      case 'pending':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text('Request sent', style: AppFonts.display(15, color: AppColors.ink, letterSpacing: -0.2)),
              const SizedBox(height: 2),
              Text('Waiting for host approval', style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.55))),
            ],
          ),
        );

      default:
        if (game.spots == 0) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text('Game is full', style: AppFonts.body(15, color: AppColors.ink.withOpacity(0.50), weight: FontWeight.w600)),
            ),
          );
        }
        return _CtaBtn(
          label: game.autoApprove ? 'Join game · Rs ${_fmt(game.price)}' : 'Request to join · Rs ${_fmt(game.price)}',
          color: AppColors.ink,
          textColor: Colors.white,
          fullWidth: true,
          onTap: () {
            HapticFeedback.mediumImpact();
            store.requestJoin(game.id);
            if (game.autoApprove) {
              Get.toNamed(Routes.join, arguments: game);
            } else {
              Get.snackbar(
                '',
                '',
                titleText: Text('Request sent!', style: AppFonts.display(14, color: AppColors.ink)),
                messageText: Text('You\'ll be notified when the host approves.', style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.65))),
                backgroundColor: AppColors.ball,
                borderRadius: 14,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              );
            }
          },
        );
    }
  }

  void _openEditSheet() {
    Get.bottomSheet(
      _EditGameSheet(game: game),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _CtaBtn extends StatelessWidget {
  const _CtaBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(label, style: AppFonts.body(15, color: textColor, weight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _StaticBanner extends StatelessWidget {
  const _StaticBanner({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(title,
              style: AppFonts.display(15, color: AppColors.ink, letterSpacing: -0.2)),
          const SizedBox(height: 2),
          Text(body,
              style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.55))),
        ],
      ),
    );
  }
}

// ─── Edit game sheet ─────────────────────────────────────────────────────────
// Lets the host change the most-likely-to-need-changing fields while no
// joiner has confirmed yet. Court / area / vibe / spots are kept editable;
// club name and weather are not (those rarely change post-publish).

class _EditGameSheet extends StatefulWidget {
  const _EditGameSheet({required this.game});
  final Game game;

  @override
  State<_EditGameSheet> createState() => _EditGameSheetState();
}

class _EditGameSheetState extends State<_EditGameSheet> {
  static const _whens = ['Today', 'Tomorrow', 'Saturday', 'Sunday', 'Monday'];
  static const _vibes = ['Social', 'Competitive', 'Practice', 'Beginner-friendly'];
  static const _durations = [60, 90, 120];

  late String _when;
  late TimeOfDay _time;
  late int _duration;
  late int _spots;
  late String _vibe;
  late TextEditingController _totalCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _when = _whens.firstWhere(
      (w) => w.toLowerCase() == widget.game.when.toLowerCase(),
      orElse: () => 'Today',
    );
    _time = _parseTime(widget.game.time);
    _duration = int.tryParse(
            RegExp(r'\d+').firstMatch(widget.game.duration)?.group(0) ?? '') ??
        60;
    _spots = widget.game.spots > 0 ? widget.game.spots : 1;
    _vibe = _vibes.firstWhere(
      (v) => v.toLowerCase() == widget.game.vibe.toLowerCase(),
      orElse: () => 'Social',
    );
    _totalCtrl = TextEditingController(
        text: (widget.game.totalCost ?? 0) > 0
            ? widget.game.totalCost.toString()
            : '');
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})\s*([AaPp][Mm])$').firstMatch(s.trim());
    if (m == null) return const TimeOfDay(hour: 18, minute: 0);
    var h = int.parse(m.group(1)!);
    final mm = int.parse(m.group(2)!);
    final period = m.group(3)!.toUpperCase();
    if (period == 'PM' && h < 12) h += 12;
    if (period == 'AM' && h == 12) h = 0;
    return TimeOfDay(hour: h, minute: mm);
  }

  String _formatTime(TimeOfDay t) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h12:$m $period';
  }

  int get _pricePerHead {
    final t = int.tryParse(_totalCtrl.text) ?? 0;
    final heads = _spots + 1;
    if (heads == 0) return 0;
    return (t / heads).ceil();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final updated = widget.game.copyWith(
      when: _when,
      time: _formatTime(_time),
      duration: '$_duration min',
      spots: _spots,
      total: _spots + 1,
      vibe: _vibe,
      price: _pricePerHead,
      totalCost: int.tryParse(_totalCtrl.text) ?? widget.game.totalCost,
    );
    AppController.to.updateHostedGame(updated);
    if (mounted) Navigator.of(context).pop();
    Get.snackbar(
      '',
      '',
      titleText: Text('Game updated', style: AppFonts.display(14, color: AppColors.ink)),
      messageText: Text('Your changes are saved.',
          style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.65))),
      backgroundColor: AppColors.ball,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.ink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text('Edit game', style: AppFonts.display(20, color: AppColors.ink, letterSpacing: -0.4)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded, color: AppColors.ink.withOpacity(0.50)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Day'),
                    const SizedBox(height: 8),
                    _Pills<String>(
                      values: _whens,
                      labels: _whens,
                      selected: _when,
                      onTap: (v) => setState(() => _when = v),
                    ),
                    const SizedBox(height: 18),

                    _label('Start time'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (picked != null) setState(() => _time = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Text(_formatTime(_time),
                                style: AppFonts.display(20, color: AppColors.ink, letterSpacing: -0.3)),
                            const Spacer(),
                            Icon(Icons.access_time_rounded, color: AppColors.ink.withOpacity(0.40)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _label('Duration'),
                    const SizedBox(height: 8),
                    _Pills<int>(
                      values: _durations,
                      labels: _durations.map((d) => '$d min').toList(),
                      selected: _duration,
                      onTap: (v) => setState(() => _duration = v),
                    ),
                    const SizedBox(height: 18),

                    _label('Vibe'),
                    const SizedBox(height: 8),
                    _Pills<String>(
                      values: _vibes,
                      labels: const ['Social', 'Competitive', 'Practice', 'Beginner'],
                      selected: _vibe,
                      onTap: (v) => setState(() => _vibe = v),
                    ),
                    const SizedBox(height: 18),

                    _label('Open spots (excluding you)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StepBtn(
                          icon: Icons.remove_rounded,
                          onTap: () {
                            if (_spots > 1) setState(() => _spots--);
                          },
                        ),
                        const SizedBox(width: 18),
                        Text('$_spots', style: AppFonts.display(28, color: AppColors.ink)),
                        const SizedBox(width: 18),
                        _StepBtn(
                          icon: Icons.add_rounded,
                          onTap: () {
                            if (_spots < 3) setState(() => _spots++);
                          },
                        ),
                        const SizedBox(width: 14),
                        Text('${_spots + 1} players total',
                            style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.55))),
                      ],
                    ),
                    const SizedBox(height: 18),

                    _label('Total court cost (Rs)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _totalCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. 4800',
                        hintStyle: AppFonts.body(13, color: AppColors.ink.withOpacity(0.30)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.ball, width: 2),
                        ),
                      ),
                    ),
                    if (_pricePerHead > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.ball.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Rs $_pricePerHead per head · ${_spots + 1} players',
                          style: AppFonts.body(12, color: AppColors.ink, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _saving ? null : _save,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _saving ? AppColors.ink.withOpacity(0.50) : AppColors.ink,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              _saving ? 'Saving…' : 'Save changes',
                              style: AppFonts.body(15, color: Colors.white, weight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.55), letterSpacing: 0.4),
      );
}

class _Pills<T> extends StatelessWidget {
  const _Pills({
    required this.values,
    required this.labels,
    required this.selected,
    required this.onTap,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: List.generate(values.length, (i) {
        final active = values[i] == selected;
        return GestureDetector(
          onTap: () => onTap(values[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.ball : Colors.white,
              borderRadius: BorderRadius.circular(kBorderRadiusPill),
              border: Border.all(color: active ? AppColors.ball : AppColors.line),
            ),
            child: Text(
              labels[i],
              style: AppFonts.body(
                12,
                color: AppColors.ink,
                weight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, color: AppColors.ink, size: 20),
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
