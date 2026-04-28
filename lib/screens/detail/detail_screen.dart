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
                final myUid = IdentityService.instance.cached;
                final amLocalHost = store.hostedGames.any((g) => g.id == game.id);
                final isHost = (game.hostUid != null && game.hostUid == myUid) ||
                    (game.hostUid == null && amLocalHost);
                if (!isHost) return const SizedBox.shrink();
                return Text(
                  'Tap a slot to assign a player',
                  style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.45), letterSpacing: 0.3),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final positions = store.courtPositions[game.id] ?? const {};
            final assignments = <int, Player>{};
            // Resolve uid → Player. The host's local id is `'me'`, so we
            // pull the host's stamped snapshot first when the slot maps
            // to the host id, then fall back to playerById for everyone
            // else (joiners' own kMe, registered remote players).
            positions.forEach((uid, slot) {
              Player? p;
              if (uid == game.hostId) {
                p = game.hostSnapshot ??
                    (store.hostedGames.any((g) => g.id == game.id)
                        ? store.currentUser.value
                        : null);
              } else if (uid == store.currentUser.value.id) {
                p = store.currentUser.value;
              } else {
                p = playerById(uid);
              }
              if (p != null) assignments[slot] = p;
            });
            final myUid = IdentityService.instance.cached;
            final amLocalHost = store.hostedGames.any((g) => g.id == game.id);
            final isHost = (game.hostUid != null && game.hostUid == myUid) ||
                (game.hostUid == null && amLocalHost);
            return CourtDiagram(
              slotAssignments: assignments,
              slotCount: game.total,
              // Only the host can shuffle the line-up — every other viewer
              // gets a read-only diagram.
              onClaimSlot: isHost
                  ? (slot) async {
                      HapticFeedback.lightImpact();
                      await _showSlotPicker(
                        context: context,
                        game: game,
                        slot: slot,
                        store: store,
                      );
                    }
                  : null,
            );
          }),
        ],
      ),
    );
  }

  /// Opens a bottom sheet listing every player in the line-up so the host
  /// can place one of them on [slot]. Already-placed players are still
  /// shown (with their current slot) so the host can swap.
  Future<void> _showSlotPicker({
    required BuildContext context,
    required Game game,
    required int slot,
    required AppController store,
  }) async {
    // Resolve every line-up id to a Player using the same precedence as
    // the diagram render, so host/me/remote all show correctly.
    final players = <({String uid, Player player})>[];
    for (final uid in game.playerIds) {
      Player? p;
      if (uid == game.hostId) {
        p = game.hostSnapshot ??
            (store.hostedGames.any((g) => g.id == game.id)
                ? store.currentUser.value
                : null);
      } else if (uid == store.currentUser.value.id) {
        p = store.currentUser.value;
      } else {
        p = playerById(uid);
      }
      if (p != null) players.add((uid: uid, player: p));
    }
    final positions = store.courtPositions[game.id] ?? const {};
    String? currentUidOnSlot;
    positions.forEach((uid, s) {
      if (s == slot) currentUidOnSlot = uid;
    });

    await Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20, 16, 20, 20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ink.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Assign player to position ${slot + 1}',
                style: AppFonts.display(18, color: AppColors.ink, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text('Pick a confirmed player from the line-up.',
                style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.55))),
            const SizedBox(height: 16),
            if (players.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No confirmed players yet. Approve a request first.',
                  style: AppFonts.body(13, color: AppColors.ink.withOpacity(0.55)),
                ),
              )
            else
              ...players.map((row) {
                final placedSlot = positions[row.uid];
                final isOnThisSlot = placedSlot == slot;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (isOnThisSlot) {
                        Navigator.of(context).pop();
                        return;
                      }
                      store.setCourtPosition(game.id, row.uid, slot);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOnThisSlot ? AppColors.ball : AppColors.line,
                          width: isOnThisSlot ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          AvatarWidget(player: row.player, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(row.player.name,
                                    style: AppFonts.body(14, color: AppColors.ink, weight: FontWeight.w700)),
                                if (placedSlot != null)
                                  Text(
                                    isOnThisSlot
                                        ? 'Currently in this slot'
                                        : 'Currently in slot ${placedSlot + 1}',
                                    style: AppFonts.body(11, color: AppColors.ink.withOpacity(0.50)),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            isOnThisSlot ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                            color: isOnThisSlot ? AppColors.ball : AppColors.ink.withOpacity(0.40),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            if (currentUidOnSlot != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  store.clearCourtSlot(game.id, slot);
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.hot.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hot.withOpacity(0.30)),
                  ),
                  child: Center(
                    child: Text('Clear this slot',
                        style: AppFonts.body(13, color: AppColors.hot, weight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    // Resolve each id in `game.playerIds`, taking three identity types
    // into account:
    //   * `'me'`         — the host slot (legacy local id). Use the
    //                      embedded hostSnapshot when available so non-host
    //                      viewers see the right person; otherwise only
    //                      use kMe if *we* are the local host.
    //   * our own uid    — the joiner viewing their own slot. Use kMe.
    //   * any other uid  — look up via kRemotePlayers (populated by the
    //                      host's request listener).
    final myUid = IdentityService.instance.cached;
    final amLocalHost = store.hostedGames.any((g) => g.id == game.id);
    // List of (player, isHost, isMe) records so the row can correctly
    // tag the HOST badge using the *source* id, not the resolved player's
    // own id (which is `'me'` for both host-slot and self-slot rendering).
    final rows = <({Player player, bool isHost, bool isMe})>[];
    for (final id in game.playerIds) {
      final isHostSlot = id == game.hostId;
      final isMeSlot = id == myUid;
      Player? p;
      if (isHostSlot) {
        p = game.hostSnapshot ?? (amLocalHost ? store.currentUser.value : null);
      } else if (isMeSlot) {
        p = store.currentUser.value;
      } else {
        p = playerById(id);
      }
      if (p != null) {
        rows.add((player: p, isHost: isHostSlot, isMe: isMeSlot || (isHostSlot && amLocalHost)));
      }
    }
    final emptyCount = game.total - rows.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Players', style: AppFonts.display(16, color: AppColors.ink, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlayerRow(
              player: r.player,
              isHost: r.isHost,
              isMeOverride: r.isMe,
              store: store,
            ),
          )),
          ...List.generate(emptyCount, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EmptyPlayerRow(number: rows.length + i + 1),
          )),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.isHost,
    required this.store,
    this.isMeOverride = false,
  });
  final Player player;
  final bool isHost;
  final AppController store;
  /// Override for "is this me?" decided by the caller using the slot id.
  /// We can't infer it from `player.id == kMe.id` because both the host
  /// slot and the self slot resolve to a Player with `id == 'me'`.
  final bool isMeOverride;

  @override
  Widget build(BuildContext context) {
    final isMe = isMeOverride;
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
    // Only fall back to local kMe when *we* are the host of this game —
    // never use `playerById(hostId)` blindly because hostId is `'me'` for
    // every game and would falsely show the joiner's profile as the host
    // on legacy games that lack a snapshot.
    final amLocalHost = store.hostedGames.any((g) => g.id == game.id);
    final host = game.hostSnapshot ?? (amLocalHost ? store.currentUser.value : null);
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
                if (!amLocalHost)
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
      // The host can edit the game any time before it starts. Past the
      // start, fields are locked because there's nothing meaningful to
      // change retroactively.
      final canEdit = !hasStarted;
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
// Full host-editable view: club, location, court, vibe, schedule, cost, and
// open spots. Edits are allowed any time before the game starts; once it
// has started the Edit button is hidden by the CTA bar.

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
  static const _courtTypes = ['Indoor', 'Outdoor'];

  late TextEditingController _clubCtrl;
  late String _city;
  late String _area;
  late TextEditingController _courtNameCtrl;
  late String _courtType;
  late String _when;
  late TimeOfDay _time;
  late int _duration;
  late int _spots;
  late String _vibe;
  late bool _autoApprove;
  late TextEditingController _totalCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.game;
    _clubCtrl = TextEditingController(text: g.club);
    _city = kPkCities.firstWhere(
      (c) => c.toLowerCase() == _detectCity(g).toLowerCase(),
      orElse: () => kPkCities.first,
    );
    _area = (kPkAreas[_city] ?? const []).firstWhere(
      (a) => a.toLowerCase() == g.area.toLowerCase(),
      orElse: () => g.area,
    );
    final parts = g.court.split(' · ');
    _courtNameCtrl = TextEditingController(text: parts.first);
    _courtType = _courtTypes.firstWhere(
      (t) => parts.length > 1 && parts[1].toLowerCase() == t.toLowerCase(),
      orElse: () => g.weather.toLowerCase() == 'indoor' ? 'Indoor' : 'Outdoor',
    );
    _when = _whens.firstWhere(
      (w) => w.toLowerCase() == g.when.toLowerCase(),
      orElse: () => 'Today',
    );
    _time = _parseTime(g.time);
    _duration = int.tryParse(
            RegExp(r'\d+').firstMatch(g.duration)?.group(0) ?? '') ??
        60;
    _spots = g.spots > 0 ? g.spots : 1;
    _vibe = _vibes.firstWhere(
      (v) => v.toLowerCase() == g.vibe.toLowerCase(),
      orElse: () => 'Social',
    );
    _autoApprove = g.autoApprove;
    _totalCtrl = TextEditingController(
        text: (g.totalCost ?? 0) > 0 ? g.totalCost.toString() : '');
  }

  /// Best-effort city detection: prefer the area's parent city in
  /// `kPkAreas`; fall back to `Karachi` when no mapping matches.
  String _detectCity(Game g) {
    for (final entry in kPkAreas.entries) {
      if (entry.value.any((a) => a.toLowerCase() == g.area.toLowerCase())) {
        return entry.key;
      }
    }
    return 'Karachi';
  }

  @override
  void dispose() {
    _clubCtrl.dispose();
    _courtNameCtrl.dispose();
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
    final club = _clubCtrl.text.trim();
    final courtName = _courtNameCtrl.text.trim();
    if (club.isEmpty || courtName.isEmpty || _area.isEmpty) {
      Get.snackbar(
        '',
        '',
        titleText: Text('Hold up 👋',
            style: AppFonts.display(13, color: AppColors.ink)),
        messageText: Text('Club, area and court name are required.',
            style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.7))),
        backgroundColor: AppColors.ball,
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final updated = widget.game.copyWith(
      club: club,
      area: _area,
      court: '$courtName · $_courtType',
      weather: _courtType == 'Indoor' ? 'Indoor' : '—',
      when: _when,
      time: _formatTime(_time),
      duration: '$_duration min',
      spots: _spots,
      total: _spots + 1,
      vibe: _vibe,
      autoApprove: _autoApprove,
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
                    _label('Club name'),
                    const SizedBox(height: 8),
                    _SheetText(
                      controller: _clubCtrl,
                      hint: 'e.g. Padel Up Karachi',
                    ),
                    const SizedBox(height: 18),

                    _label('City'),
                    const SizedBox(height: 8),
                    _SheetDropdown<String>(
                      value: _city,
                      items: kPkCities,
                      label: (c) => c,
                      onChanged: (v) => setState(() {
                        _city = v ?? _city;
                        _area = (kPkAreas[_city] ?? const []).isNotEmpty
                            ? (kPkAreas[_city]!.first)
                            : '';
                      }),
                    ),
                    const SizedBox(height: 18),

                    _label('Area'),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (_) {
                        final areas = kPkAreas[_city] ?? const <String>[];
                        return _SheetDropdown<String>(
                          value: areas.contains(_area) ? _area : null,
                          items: areas,
                          label: (a) => a,
                          hint: 'Select area',
                          onChanged: (v) => setState(() => _area = v ?? ''),
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    _label('Court name / number'),
                    const SizedBox(height: 8),
                    _SheetText(
                      controller: _courtNameCtrl,
                      hint: 'e.g. Court 2',
                    ),
                    const SizedBox(height: 18),

                    _label('Court type'),
                    const SizedBox(height: 8),
                    _Pills<String>(
                      values: _courtTypes,
                      labels: _courtTypes,
                      selected: _courtType,
                      onTap: (v) => setState(() => _courtType = v),
                    ),
                    const SizedBox(height: 18),

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
                    const SizedBox(height: 18),

                    _label('Approval mode'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _autoApprove = !_autoApprove),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _autoApprove ? '⚡ Auto-approve' : '✋ Manual approval',
                                    style: AppFonts.body(13,
                                        color: AppColors.ink, weight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _autoApprove
                                        ? 'Anyone can join instantly'
                                        : 'You approve each request',
                                    style: AppFonts.body(11,
                                        color: AppColors.ink.withOpacity(0.55)),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 42,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _autoApprove
                                    ? AppColors.ball
                                    : AppColors.ink.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 180),
                                alignment: _autoApprove
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _autoApprove
                                        ? AppColors.ink
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _saving ? null : _confirmCancel,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.hot.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.hot.withOpacity(0.30)),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel match',
                            style: AppFonts.body(14, color: AppColors.hot, weight: FontWeight.w700),
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

  void _confirmCancel() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Cancel this match?',
            style: AppFonts.display(18, color: AppColors.ink)),
        content: Text(
          'The game will be removed from your list and joiners will see it disappear. This can\'t be undone.',
          style: AppFonts.body(13, color: AppColors.ink.withOpacity(0.70)),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('Keep match',
                style: AppFonts.body(13, color: AppColors.ink.withOpacity(0.70))),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // close dialog
              if (mounted) Navigator.of(context).pop(); // close edit sheet
              await AppController.to.cancelHostedGame(widget.game.id);
              Get.offAllNamed(Routes.home);
              Get.snackbar(
                '',
                '',
                titleText: Text('Match cancelled',
                    style: AppFonts.display(14, color: AppColors.ink)),
                messageText: Text('The game has been removed.',
                    style: AppFonts.body(12,
                        color: AppColors.ink.withOpacity(0.65))),
                backgroundColor: AppColors.ball,
                borderRadius: 14,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              );
            },
            child: Text('Cancel match',
                style: AppFonts.body(13, color: AppColors.hot, weight: FontWeight.w700)),
          ),
        ],
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

class _SheetText extends StatelessWidget {
  const _SheetText({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppFonts.body(14, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppFonts.body(14, color: AppColors.ink.withOpacity(0.30)),
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
    );
  }
}

class _SheetDropdown<T> extends StatelessWidget {
  const _SheetDropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    this.hint,
  });

  final T? value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null
              ? Text(hint!, style: AppFonts.body(14, color: AppColors.ink.withOpacity(0.30)))
              : null,
          style: AppFonts.body(14, color: AppColors.ink),
          iconEnabledColor: AppColors.ink.withOpacity(0.45),
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(label(item), style: AppFonts.body(14, color: AppColors.ink)),
                  ))
              .toList(),
          onChanged: onChanged,
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
