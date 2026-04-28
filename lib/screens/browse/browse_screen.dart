import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/controllers/app_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/mock_data.dart' show kPkAreas;
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

  /// Merged pool: Firestore-side games (shared from AppController) + this
  /// device's locally-hosted games, deduplicated by id (a host's own game
  /// appears in both — local takes priority since it's the authoritative
  /// copy on this device).
  List<Game> get pool {
    final byId = <String, Game>{};
    for (final g in AppController.to.remoteGames) {
      byId[g.id] = g;
    }
    for (final g in AppController.to.hostedGames) {
      byId[g.id] = g;
    }
    return byId.values.toList();
  }

  List<Game> get filtered {
    final lvl  = selectedLevel.value;
    final vib  = selectedVibe.value;
    final wh   = selectedWhen.value;
    final ar   = selectedArea.value;
    final q    = searchQuery.value.toLowerCase();

    return pool.where((g) {
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
//
// One compact horizontal row of filter pills. Each pill shows the filter
// name + currently-selected value. Tapping opens a bottom sheet with all
// options for that filter. This replaces the older 4-row layout that took
// too much vertical space and clipped on wider viewports (tablet / web).

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({required this.ctrl});
  final BrowseController ctrl;

  static const _levels      = ['all', 'rookie', 'amateur', 'regular', 'pro', 'elite'];
  static const _levelLabels = ['Any',  'Rookie', 'Amateur', 'Regular', 'Pro',  'Elite'];
  static const _vibes       = ['all', 'competitive', 'social', 'practice', 'beginner-friendly'];
  static const _vibeLabels  = ['Any',  'Competitive', 'Social', 'Practice', 'Beginner'];
  static const _whens       = ['all', 'today', 'tomorrow', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  static const _whenLabels  = ['Any',  'Today', 'Tomorrow', 'Mon',    'Tue',     'Wed',       'Thu',      'Fri',     'Sat',      'Sun'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blue900,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterPill(
              label: 'LEVEL',
              valueRx: ctrl.selectedLevel,
              values: _levels,
              labels: _levelLabels,
              onTap: () => _showSheet(
                context,
                title: 'Level',
                values: _levels,
                labels: _levelLabels,
                rx: ctrl.selectedLevel,
              ),
            ),
            const SizedBox(width: 8),
            _FilterPill(
              label: 'VIBE',
              valueRx: ctrl.selectedVibe,
              values: _vibes,
              labels: _vibeLabels,
              onTap: () => _showSheet(
                context,
                title: 'Vibe',
                values: _vibes,
                labels: _vibeLabels,
                rx: ctrl.selectedVibe,
              ),
            ),
            const SizedBox(width: 8),
            _FilterPill(
              label: 'WHEN',
              valueRx: ctrl.selectedWhen,
              values: _whens,
              labels: _whenLabels,
              onTap: () => _showSheet(
                context,
                title: 'When',
                values: _whens,
                labels: _whenLabels,
                rx: ctrl.selectedWhen,
              ),
            ),
            const SizedBox(width: 8),
            // Area uses a dynamic option list: 'Any' + areas from games
            // currently in the pool, plus the Karachi area catalogue as a
            // fallback so the picker is usable even before any games exist.
            Obx(() {
              final fromPool = <String>{};
              for (final g in ctrl.pool) {
                if (g.area.trim().isNotEmpty) fromPool.add(g.area);
              }
              final all = <String>{...fromPool, ...?kPkAreas['Karachi']}.toList()
                ..sort();
              final values = ['all', ...all];
              final labels = ['Any', ...all.map(_shortenArea)];
              return _FilterPill(
                label: 'AREA',
                valueRx: ctrl.selectedArea,
                values: values,
                labels: labels,
                onTap: () => _showSheet(
                  context,
                  title: 'Area',
                  values: values,
                  labels: labels,
                  rx: ctrl.selectedArea,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Compact a long area name for use in pill labels.
  static String _shortenArea(String s) => s
      .replaceAll('DHA Phase ', 'DHA Ph.')
      .replaceAll('Bahria Town', 'Bahria')
      .replaceAll(' Karachi', '')
      .replaceAll(' Lahore', '')
      .replaceAll(' Islamabad', '');

  void _showSheet(
    BuildContext context, {
    required String title,
    required List<String> values,
    required List<String> labels,
    required RxString rx,
  }) {
    Get.bottomSheet(
      _FilterSheet(
        title: title,
        values: values,
        labels: labels,
        currentValue: rx.value,
        onSelect: (v) {
          rx.value = v;
          Get.back();
        },
      ),
      backgroundColor: Colors.transparent,
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.valueRx,
    required this.values,
    required this.labels,
    required this.onTap,
  });

  final String label;
  final RxString valueRx;
  final List<String> values;
  final List<String> labels;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final v = valueRx.value;
      final isActive = v != 'all';
      final idx = values.indexOf(v);
      // Falls back to "Any" if the current value isn't in the option list
      // (can happen briefly when the dynamic AREA list refreshes).
      final shown = (idx >= 0 ? labels[idx] : 'Any');
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.ball : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(kBorderRadiusPill),
            border: Border.all(
              color: isActive ? AppColors.ball : Colors.white.withOpacity(0.14),
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: AppFonts.mono(
                  9,
                  color: isActive
                      ? AppColors.ink.withOpacity(0.70)
                      : Colors.white.withOpacity(0.50),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                shown,
                style: AppFonts.body(
                  12,
                  color: isActive ? AppColors.ink : Colors.white,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: isActive
                    ? AppColors.ink.withOpacity(0.70)
                    : Colors.white.withOpacity(0.55),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.title,
    required this.values,
    required this.labels,
    required this.currentValue,
    required this.onSelect,
  });

  final String title;
  final List<String> values;
  final List<String> labels;
  final String currentValue;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
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
                Text(title, style: AppFonts.display(20, color: AppColors.ink, letterSpacing: -0.4)),
                const Spacer(),
                GestureDetector(
                  onTap: Get.back,
                  child: Icon(Icons.close_rounded, color: AppColors.ink.withOpacity(0.50)),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 20),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: List.generate(values.length, (i) {
                  final isSelected = values[i] == currentValue;
                  return GestureDetector(
                    onTap: () => onSelect(values[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.ink : Colors.white,
                        borderRadius: BorderRadius.circular(kBorderRadiusPill),
                        border: Border.all(
                          color: isSelected ? AppColors.ink : AppColors.line,
                        ),
                      ),
                      child: Text(
                        labels[i],
                        style: AppFonts.body(
                          13,
                          color: isSelected ? Colors.white : AppColors.ink,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
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
