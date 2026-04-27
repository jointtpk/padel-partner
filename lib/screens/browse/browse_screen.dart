import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/tokens.dart';
import '../../core/mock_data.dart';
import '../../core/models/game.dart';
import '../../core/widgets/game_card.dart';
import '../../core/widgets/floating_nav.dart';
import '../../app/routes.dart' show Routes;

// ─── Controller ───────────────────────────────────────────────────────────────

class BrowseController extends GetxController {
  final selectedLevel = 'all'.obs;
  final selectedVibe  = 'all'.obs;
  final selectedWhen  = 'all'.obs;
  final selectedArea  = 'all'.obs;
  final searchQuery   = ''.obs;

  final searchCtrl = TextEditingController();

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  List<Game> get filtered {
    // Touch all reactive deps unconditionally so Obx subscribes even when
    // the source list is empty (otherwise predicate body never runs).
    final lvl  = selectedLevel.value;
    final vib  = selectedVibe.value;
    final wh   = selectedWhen.value;
    final ar   = selectedArea.value;
    final q    = searchQuery.value.toLowerCase();

    return kGames.where((g) {
      if (lvl != 'all' && g.levelKey != lvl) return false;
      if (vib != 'all' && g.vibe.toLowerCase() != vib) return false;
      if (wh  != 'all' && g.when.toLowerCase() != wh) return false;
      if (ar  != 'all' && g.area != ar) return false;
      if (q.isNotEmpty) {
        final match = g.club.toLowerCase().contains(q) ||
                      g.area.toLowerCase().contains(q) ||
                      g.vibe.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  void clearAll() {
    selectedLevel.value = 'all';
    selectedVibe.value  = 'all';
    selectedWhen.value  = 'all';
    selectedArea.value  = 'all';
    searchQuery.value   = '';
    searchCtrl.clear();
  }

  bool get hasFilters =>
      selectedLevel.value != 'all' ||
      selectedVibe.value  != 'all' ||
      selectedWhen.value  != 'all' ||
      selectedArea.value  != 'all' ||
      searchQuery.value.isNotEmpty;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(BrowseController());
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          Column(
            children: [
              _SearchHeader(ctrl: ctrl),
              _FilterStrip(ctrl: ctrl),
              Expanded(child: _Body(ctrl: ctrl)),
            ],
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: FloatingNavBar(
              active: NavTab.browse,
              onTab: (NavTab tab) {
                switch (tab) {
                  case NavTab.home: Get.offAllNamed(Routes.home); break;
                  case NavTab.chat: Get.toNamed(Routes.inbox); break;
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

// ─── Search header ────────────────────────────────────────────────────────────

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.ctrl});
  final BrowseController ctrl;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.blue900,
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Find a game', style: AppFonts.display(24, color: Colors.white, letterSpacing: -0.5)),
              const Spacer(),
              Obx(() => ctrl.hasFilters
                  ? GestureDetector(
                      onTap: ctrl.clearAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.ball,
                          borderRadius: BorderRadius.circular(kBorderRadiusPill),
                        ),
                        child: Text('CLEAR', style: AppFonts.mono(10, color: AppColors.ink, letterSpacing: 0.5)),
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.50), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ctrl.searchCtrl,
                    onChanged: (v) => ctrl.searchQuery.value = v,
                    style: AppFonts.body(14, color: Colors.white),
                    cursorColor: AppColors.ball,
                    decoration: InputDecoration(
                      hintText: 'Club, area, or vibe…',
                      hintStyle: AppFonts.body(14, color: Colors.white.withOpacity(0.38)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                Obx(() => ctrl.searchQuery.value.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          ctrl.searchCtrl.clear();
                          ctrl.searchQuery.value = '';
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.50), size: 18),
                        ),
                      )
                    : const SizedBox(width: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter strip ─────────────────────────────────────────────────────────────

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.ctrl});
  final BrowseController ctrl;

  static const _levels      = ['all', 'rookie', 'amateur', 'regular', 'pro', 'elite'];
  static const _levelLabels = ['All', 'Rookie', 'Amateur', 'Regular', 'Pro', 'Elite'];
  static const _vibes       = ['all', 'competitive', 'social', 'practice', 'beginner-friendly'];
  static const _vibeLabels  = ['All', 'Competitive', 'Social', 'Practice', 'Beginner'];
  static const _whens       = ['all', 'today', 'tmrw', 'sat', 'sun'];
  static const _whenLabels  = ['Any', 'Today', 'Tomorrow', 'Saturday', 'Sunday'];
  static const _areas       = ['all', 'DHA Phase 8', 'DHA Phase 6', 'Clifton', 'Bahria Town', 'PECHS'];
  static const _areaLabels  = ['Any', 'DHA Ph.8', 'DHA Ph.6', 'Clifton', 'Bahria', 'PECHS'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blue900,
      child: Column(
        children: [
          _FilterRow(label: 'LEVEL', values: _levels, labels: _levelLabels, selected: ctrl.selectedLevel),
          _FilterRow(label: 'VIBE',  values: _vibes,  labels: _vibeLabels,  selected: ctrl.selectedVibe),
          _FilterRow(label: 'WHEN',  values: _whens,  labels: _whenLabels,  selected: ctrl.selectedWhen),
          _FilterRow(label: 'AREA',  values: _areas,  labels: _areaLabels,  selected: ctrl.selectedArea),
          Container(height: 1, color: Colors.white.withOpacity(0.08)),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.values,
    required this.labels,
    required this.selected,
  });

  final String label;
  final List<String> values;
  final List<String> labels;
  final RxString selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                label,
                style: AppFonts.mono(9, color: Colors.white.withOpacity(0.40), letterSpacing: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              // Pull the reactive value into a local so Obx subscribes here
              // instead of inside the deferred itemBuilder closure.
              final sel = selected.value;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemCount: values.length,
                itemBuilder: (_, i) {
                  final active = sel == values[i];
                  return GestureDetector(
                    onTap: () => selected.value = values[i],
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? AppColors.ball : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(kBorderRadiusPill),
                        border: Border.all(
                          color: active ? AppColors.ball : Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: Text(
                        labels[i],
                        style: AppFonts.body(
                          11,
                          color: active ? AppColors.ink : Colors.white.withOpacity(0.75),
                          weight: active ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.ctrl});
  final BrowseController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final games = ctrl.filtered;
      if (games.isEmpty) return _EmptyState(ctrl: ctrl);
      return _GameList(games: games);
    });
  }
}

// ─── Game list ────────────────────────────────────────────────────────────────

class _GameList extends StatelessWidget {
  const _GameList({required this.games});
  final List<Game> games;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  '${games.length} game${games.length == 1 ? '' : 's'} found',
                  style: AppFonts.mono(11, color: AppColors.ink.withOpacity(0.45), letterSpacing: 0.3),
                ),
                const Spacer(),
                _SortPill(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GameCard(
                  game: games[i],
                  cardStyle: games[i].levelKey == 'elite' ? 'glass' : 'sticker',
                  onTap: () => Get.toNamed(Routes.detail, arguments: games[i]),
                ),
              ),
              childCount: games.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sort pill ────────────────────────────────────────────────────────────────

class _SortPill extends StatefulWidget {
  @override
  State<_SortPill> createState() => _SortPillState();
}

class _SortPillState extends State<_SortPill> {
  int _sort = 0;
  static const _labels = ['Soonest', 'Price ↑', 'Price ↓'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _sort = (_sort + 1) % _labels.length),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.ink.withOpacity(0.06),
          borderRadius: BorderRadius.circular(kBorderRadiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 13, color: AppColors.ink.withOpacity(0.55)),
            const SizedBox(width: 4),
            Text(_labels[_sort], style: AppFonts.mono(10, color: AppColors.ink.withOpacity(0.55))),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ctrl});
  final BrowseController ctrl;

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
              decoration: const BoxDecoration(
                color: AppColors.blue50,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🎾', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            Text('No games found', style: AppFonts.display(20, color: AppColors.ink, letterSpacing: -0.4)),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later for new games.',
              style: AppFonts.body(13, color: AppColors.ink.withOpacity(0.55), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: ctrl.clearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(kBorderRadiusPill),
                ),
                child: Text(
                  'Clear filters',
                  style: AppFonts.body(14, color: Colors.white, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
