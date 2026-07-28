/// The tabbed app shell: This Week · Garden · Grow · Harvest. Shown after
/// onboarding. Keeps each tab's state alive via an IndexedStack.
library;

import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/typography.dart';
import 'garden/garden_screen.dart';
import 'grow/grow_screen.dart';
import 'harvest/harvest_screen.dart';
import 'this_week/this_week_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    ThisWeekScreen(),
    GardenScreen(),
    GrowScreen(),
    HarvestScreen(),
  ];

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
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.sprout.withValues(alpha: 0.15),
              labelTextStyle: WidgetStateProperty.all(
                AppText.caption(context, color: AppColors.ink),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              height: 64,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.checklist_rounded, color: AppColors.muted),
                  selectedIcon: Icon(Icons.checklist_rounded, color: AppColors.sprout),
                  label: 'This Week',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grass_rounded, color: AppColors.muted),
                  selectedIcon: Icon(Icons.grass_rounded, color: AppColors.sprout),
                  label: 'Garden',
                ),
                NavigationDestination(
                  icon: Icon(Icons.eco_rounded, color: AppColors.muted),
                  selectedIcon: Icon(Icons.eco_rounded, color: AppColors.sprout),
                  label: 'Grow',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_florist_rounded, color: AppColors.muted),
                  selectedIcon: Icon(Icons.local_florist_rounded, color: AppColors.sprout),
                  label: 'Harvest',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
