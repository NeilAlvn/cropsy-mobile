/// The app shell — GrowIt-shaped: Home · My Garden · (scan FAB) · Explore ·
/// Diagnose. The centre FAB opens the camera scan flow (a Phase-2 stub).
library;

import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/typography.dart';
import 'diagnose/diagnose_screen.dart';
import 'explore/explore_screen.dart';
import 'garden/garden_screen.dart';
import 'home/home_screen.dart';
import 'scan/scan_screen.dart';

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
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _Tab(icon: Icons.home_rounded, label: 'Home', index: 0, current: _index, onTap: _select),
                _Tab(icon: Icons.grass_rounded, label: 'My Garden', index: 1, current: _index, onTap: _select),
                _ScanButton(onTap: _openScan),
                _Tab(icon: Icons.eco_rounded, label: 'Explore', index: 2, current: _index, onTap: _select),
                _Tab(icon: Icons.healing_rounded, label: 'Diagnose', index: 3, current: _index, onTap: _select),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _select(int i) => setState(() => _index = i);
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
    final color = on ? AppColors.sprout : AppColors.muted;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: AppText.caption(context, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.sprout,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.sprout.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.center_focus_strong, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
