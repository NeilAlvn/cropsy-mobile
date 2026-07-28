/// Scan — the center-FAB camera flow, shown as a stub (Phase 2, no real camera).
/// Identify a plant or diagnose its health from a photo.
library;

import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/typography.dart';

enum ScanMode { identify, diagnose }

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key, this.mode = ScanMode.identify});
  final ScanMode mode;

  @override
  Widget build(BuildContext context) {
    final title = mode == ScanMode.identify ? 'Identify a plant' : 'Diagnose a plant';
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white70, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.eco_rounded, color: Colors.white24, size: 64),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(title, style: AppText.title(context, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Point at a plant — prototype preview',
                        style: AppText.bodyMuted(context)
                            .copyWith(color: Colors.white54)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Action(icon: Icons.photo_library_outlined, label: 'Photos'),
                  _Shutter(),
                  _Action(icon: Icons.tips_and_updates_outlined, label: 'Snap tips'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: AppColors.sprout,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
      );
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 6),
          Text(label,
              style: AppText.caption(context).copyWith(color: Colors.white70)),
        ],
      );
}
