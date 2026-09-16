/// The app shell — Home · My Garden · (season) · Explore · Diagnose.
///
/// Base 8.8: a detached glass pill at the bottom centre, 64 tall, 44 targets,
/// no labels. The emphasised action in the middle is the season path, because
/// that is the loop the app exists for; scanning is an occasional utility and
/// lives where the intent arises, at the top of Diagnose and on a plant.
/// Content scrolls underneath the pill, which is what makes the glass read as
/// glass.
library;

import 'package:flutter/material.dart';
import '../design/icons.dart';
import 'package:flutter/rendering.dart';

import '../design/colors.dart';
import '../design/glass.dart';
import '../design/motion.dart';
import 'diagnose/diagnose_screen.dart';
import 'explore/explore_screen.dart';
import 'garden/garden_screen.dart';
import 'home/home_screen.dart';
import 'season/season_screen.dart';

/// Pill height plus the gap the base asks for above the home indicator.
const double _barHeight = 64;
const double _barGap = 12;

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _barHidden = false;

  // Not const: a const child is not rebuilt when its parent is, and these
  // screens read colour tokens at build time.
  final _tabs = const [
    HomeScreen(),
    GardenScreen(),
    SeasonScreen(),
    ExploreScreen(),
    DiagnoseScreen(),
  ];

  /// One listener for every screen: the bar answers the user's scroll
  /// direction, so no screen has to wire a controller to it.
  bool _onScroll(UserScrollNotification n) {
    if (n.depth != 0) return false;
    final hide = switch (n.direction) {
      ScrollDirection.reverse => true,
      ScrollDirection.forward => false,
      ScrollDirection.idle => _barHidden,
    };
    if (hide != _barHidden) setState(() => _barHidden = hide);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Base 4: content never ends under the floating bar. Screens read this
    // through their own SafeArea, so nothing below has to know the bar exists.
    final inset = _barHeight + _barGap + 24;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: _onScroll,
            child: MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(bottom: mq.padding.bottom + inset),
              ),
              child: IndexedStack(index: _index, children: _tabs),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: mq.padding.bottom > 0 ? mq.padding.bottom : _barGap,
            child: Center(
              child: AnimatedSlide(
                offset: _barHidden ? const Offset(0, 1.6) : Offset.zero,
                duration: Motion.of(context)[Motion.sheet],
                curve: _barHidden ? Motion.easeExit : Motion.easeEnter,
                child: _TabPill(
                  index: _index,
                  onSelect: (i) => setState(() => _index = i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(_barHeight / 2),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: _barHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Tab(
                icon: PhosphorIcons.house,
                activeIcon: PhosphorFill.house,
                label: 'Home',
                index: 0,
                current: index,
                onTap: onSelect),
            _Tab(
                icon: PhosphorIcons.plant,
                activeIcon: PhosphorFill.plant,
                label: 'My garden',
                index: 1,
                current: index,
                onTap: onSelect),
            _SeasonTab(active: index == 2, onTap: () => onSelect(2)),
            _Tab(
                icon: PhosphorIcons.leaf,
                activeIcon: PhosphorFill.leaf,
                label: 'Explore',
                index: 3,
                current: index,
                onTap: onSelect),
            _Tab(
                icon: PhosphorIcons.bandaids,
                activeIcon: PhosphorFill.bandaids,
                label: 'Diagnose',
                index: 4,
                current: index,
                onTap: onSelect),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  final IconData icon;

  /// The Fill weight of the same glyph, for the selected tab (base 7).
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final on = index == current;
    // Labels are not drawn (base 8.8) but the screen reader still reads them.
    return Semantics(
      selected: on,
      label: label,
      button: true,
      child: Pressable(
        onTap: () => onTap(index),
        child: SizedBox(
          width: 52,
          height: 44,
          child: Icon(
            on ? activeIcon : icon,
            size: 24,
            color: on ? AppColors.ink : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// The one emphasised tab (base 8.8): a 52 accent circle inside the pill, never
/// rising above it.
class _SeasonTab extends StatelessWidget {
  const _SeasonTab({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: active,
        label: 'Season path',
        child: Pressable(
          onTap: onTap,
          haptic: Haptics.press,
          child: Container(
            width: 56,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIcons.path,
                  color: AppColors.onAccent, size: 26),
            ),
          ),
        ),
      );
}
