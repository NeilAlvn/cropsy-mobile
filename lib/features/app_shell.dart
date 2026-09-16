/// The app shell — Home · My Garden · (scan) · Explore · Diagnose.
///
/// Base 8.8: a detached glass pill at the bottom centre, 64 tall, 44 targets,
/// no labels. The scan tab is the one emphasised action, a 52 accent circle
/// inside the pill. Content scrolls underneath it, which is what makes the
/// glass read as glass.
library;

import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/glass.dart';
import 'diagnose/diagnose_screen.dart';
import 'explore/explore_screen.dart';
import 'garden/garden_screen.dart';
import 'home/home_screen.dart';
import 'scan/scan_screen.dart';

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

  static const _tabs = [
    HomeScreen(),
    GardenScreen(),
    ExploreScreen(),
    DiagnoseScreen(),
  ];

  void _openScan() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const ScanScreen(),
        fullscreenDialog: true,
      ));

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
          MediaQuery(
            data: mq.copyWith(
              padding: mq.padding.copyWith(bottom: mq.padding.bottom + inset),
            ),
            child: IndexedStack(index: _index, children: _tabs),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: mq.padding.bottom > 0 ? mq.padding.bottom : _barGap,
            child: Center(
              child: _TabPill(
                index: _index,
                onSelect: (i) => setState(() => _index = i),
                onScan: _openScan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.index,
    required this.onSelect,
    required this.onScan,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

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
            _Tab(icon: Icons.home_rounded, label: 'Home', index: 0, current: index, onTap: onSelect),
            _Tab(icon: Icons.grass_rounded, label: 'My garden', index: 1, current: index, onTap: onSelect),
            _ScanTab(onTap: onScan),
            _Tab(icon: Icons.eco_rounded, label: 'Explore', index: 2, current: index, onTap: onSelect),
            _Tab(icon: Icons.healing_rounded, label: 'Diagnose', index: 3, current: index, onTap: onSelect),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: SizedBox(
          width: 52,
          height: 44,
          child: Icon(icon, size: 24, color: on ? AppColors.ink : AppColors.inkMuted),
        ),
      ),
    );
  }
}

class _ScanTab extends StatelessWidget {
  const _ScanTab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Scan a plant',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.center_focus_strong,
                  color: AppColors.onAccent, size: 26),
            ),
          ),
        ),
      );
}
