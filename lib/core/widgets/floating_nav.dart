import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum NavTab { home, browse, host, chat, profile }

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.active,
    required this.onTab,
    this.unreadCount = 0,
  });

  final NavTab active;
  final void Function(NavTab) onTab;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 18,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.ink.withOpacity(0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withOpacity(0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: AppColors.ball.withOpacity(0.06),
                  spreadRadius: 1,
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavItem(id: NavTab.home,    label: 'Home',     icon: _HomeIcon(),    active: active, onTap: onTab),
                _NavItem(id: NavTab.browse,  label: 'Browse',   icon: _SearchIcon(),  active: active, onTap: onTab),
                _HostFAB(onTap: () => onTab(NavTab.host)),
                _NavItem(id: NavTab.chat,    label: 'Messages', icon: _ChatIcon(),    active: active, onTap: onTab, badge: unreadCount),
                _NavItem(id: NavTab.profile, label: 'Me',       icon: _ProfileIcon(), active: active, onTap: onTab),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  final NavTab id;
  final String label;
  final Widget icon;
  final NavTab active;
  final void Function(NavTab) onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final isActive = active == id;
    return GestureDetector(
      onTap: () => onTap(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blue800 : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                icon,
                if (badge > 0)
                  Positioned(
                    top: -4, right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      height: 16,
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: AppColors.hot,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.ink, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$badge',
                          style: AppFonts.mono(9, color: Colors.white, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.display(11, color: Colors.white, letterSpacing: 0.04 * 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HostFAB extends StatelessWidget {
  const _HostFAB({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        transform: Matrix4.translationValues(0, -18, 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.ball,
                border: Border.all(color: AppColors.ink, width: 3),
                boxShadow: [BoxShadow(color: AppColors.ball.withOpacity(0.40), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: const Center(
                child: Icon(Icons.add, color: AppColors.ink, size: 24, weight: 700),
              ),
            ),
            Positioned(
              top: -6, right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.ball, width: 1.5),
                ),
                child: Text('HOST', style: AppFonts.mono(7, color: AppColors.ball, letterSpacing: 0.10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav icons (custom painters) ─────────────────────────────────────────────
class _HomeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Icon(Icons.home_outlined, color: Colors.white, size: 22);
}
class _SearchIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Icon(Icons.search, color: Colors.white, size: 22);
}
class _ChatIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22);
}
class _ProfileIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Icon(Icons.person_outline, color: Colors.white, size: 22);
}
