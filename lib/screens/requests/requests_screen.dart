import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/tokens.dart';
import '../../core/mock_data.dart';
import '../../core/models/game.dart';
import '../../core/models/booking.dart';
import '../../core/models/player.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/widgets/chip_widget.dart';
import '../../app/controllers/app_controller.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────
// Receives an optional Game via Get.arguments to jump to a specific game.
// If null, shows all pending requests across hosted games.

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focusGame = Get.arguments as Game?;
    final store = AppController.to;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(
        children: [
          _Header(focusGame: focusGame),
          Expanded(child: _Body(store: store, focusGame: focusGame)),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.focusGame});
  final Game? focusGame;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.blue900,
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 22),
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
              Expanded(
                child: Text(
                  focusGame != null ? focusGame!.club : 'Join requests',
                  style: AppFonts.display(22, color: Colors.white, letterSpacing: -0.4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (focusGame != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 50),
              child: Text(
                '${focusGame!.area} · ${focusGame!.when}, ${focusGame!.time}',
                style: AppFonts.body(12, color: Colors.white.withOpacity(0.55)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.store, required this.focusGame});
  final AppController store;
  final Game? focusGame;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Build list of (game, requests) pairs
      final allRequests = store.requests;

      // Determine which games to show
      List<String> gameIds;
      if (focusGame != null) {
        gameIds = [focusGame!.id];
      } else {
        gameIds = allRequests.keys
            .where((id) => (allRequests[id] ?? []).isNotEmpty)
            .toList();
      }

      if (gameIds.isEmpty || gameIds.every((id) => (allRequests[id] ?? []).isEmpty)) {
        return _EmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        itemCount: gameIds.length,
        itemBuilder: (_, i) {
          final gameId = gameIds[i];
          final reqs = allRequests[gameId] ?? [];
          if (reqs.isEmpty) return const SizedBox.shrink();

          final game = focusGame ??
              kGames.firstWhereOrNull((g) => g.id == gameId) ??
              store.hostedGames.firstWhereOrNull((g) => g.id == gameId);

          return _GameRequestGroup(
            game: game,
            gameId: gameId,
            requests: reqs,
            store: store,
          );
        },
      );
    });
  }
}

// ─── Game group ───────────────────────────────────────────────────────────────

class _GameRequestGroup extends StatelessWidget {
  const _GameRequestGroup({
    required this.game,
    required this.gameId,
    required this.requests,
    required this.store,
  });

  final Game? game;
  final String gameId;
  final List<JoinRequest> requests;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Game label (only shown when not focused on a single game)
        if (game != null) ...[
          _GameLabel(game: game!),
          const SizedBox(height: 12),
        ],
        ...requests.map((req) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RequestCard(gameId: gameId, request: req, store: store),
        )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _GameLabel extends StatelessWidget {
  const _GameLabel({required this.game});
  final Game game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blue900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.club, style: AppFonts.display(14, color: Colors.white, letterSpacing: -0.2)),
                Text(
                  '${game.area} · ${game.when}, ${game.time}',
                  style: AppFonts.body(11, color: Colors.white.withOpacity(0.55)),
                ),
              ],
            ),
          ),
          LevelBadge(levelKey: game.levelKey),
        ],
      ),
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.gameId, required this.request, required this.store});
  final String gameId;
  final JoinRequest request;
  final AppController store;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fadeOut;
  String? _verdict; // 'approved' | 'declined'

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeOut = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _approve() {
    HapticFeedback.mediumImpact();
    setState(() => _verdict = 'approved');
    _anim.forward().then((_) {
      widget.store.approveJoin(widget.gameId, widget.request.userId);
    });
  }

  void _decline() {
    HapticFeedback.lightImpact();
    setState(() => _verdict = 'declined');
    _anim.forward().then((_) {
      widget.store.declineJoin(widget.gameId, widget.request.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = playerById(widget.request.userId);

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeOut),
      child: SizeTransition(
        sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeOut),
        child: _verdict != null
            ? _VerdictBanner(verdict: _verdict!, playerName: player?.name ?? 'Player')
            : _CardContent(
                player: player,
                request: widget.request,
                onApprove: _approve,
                onDecline: _decline,
              ),
      ),
    );
  }
}

class _VerdictBanner extends StatelessWidget {
  const _VerdictBanner({required this.verdict, required this.playerName});
  final String verdict;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    final approved = verdict == 'approved';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: approved ? AppColors.success.withOpacity(0.10) : AppColors.mist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: approved ? AppColors.success.withOpacity(0.30) : AppColors.line),
      ),
      child: Row(
        children: [
          Text(approved ? '✓' : '✕', style: TextStyle(
            fontSize: 16,
            color: approved ? AppColors.success : AppColors.ink.withOpacity(0.35),
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(width: 10),
          Text(
            approved ? '$playerName approved' : '$playerName declined',
            style: AppFonts.body(13, color: approved ? AppColors.success : AppColors.ink.withOpacity(0.40), weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.player,
    required this.request,
    required this.onApprove,
    required this.onDecline,
  });

  final Player? player;
  final JoinRequest request;
  final VoidCallback onApprove;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player row
          Row(
            children: [
              player != null
                  ? AvatarWidget(player: player!, size: 48)
                  : _UnknownAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player?.name ?? 'Unknown player',
                      style: AppFonts.body(15, color: AppColors.ink, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (player != null) ...[
                          LevelBadge(levelKey: player!.tier),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          player?.handle ?? '',
                          style: AppFonts.body(11, color: AppColors.ink.withOpacity(0.45)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Stats
              if (player != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${player!.wins}W',
                      style: AppFonts.display(15, color: AppColors.ink, letterSpacing: -0.2),
                    ),
                    Text(
                      '${player!.games} games',
                      style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.40)),
                    ),
                  ],
                ),
            ],
          ),

          // Note
          if (request.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💬', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.note,
                      style: AppFonts.body(12, color: AppColors.ink.withOpacity(0.75), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 4),
          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              request.when,
              style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.35), letterSpacing: 0.3),
            ),
          ),

          const SizedBox(height: 14),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onDecline,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('Decline', style: AppFonts.body(14, color: AppColors.ink.withOpacity(0.65), weight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onApprove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('Approve', style: AppFonts.body(14, color: Colors.white, weight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnknownAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: AppColors.mist,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line),
      ),
      child: Icon(Icons.person_outline_rounded, color: AppColors.ink.withOpacity(0.35), size: 24),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.blue50, shape: BoxShape.circle),
              child: const Center(child: Text('✅', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            Text('All clear', style: AppFonts.display(20, color: AppColors.ink, letterSpacing: -0.4)),
            const SizedBox(height: 8),
            Text(
              'No pending join requests. Share your game to fill those spots!',
              style: AppFonts.body(13, color: AppColors.ink.withOpacity(0.55), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
