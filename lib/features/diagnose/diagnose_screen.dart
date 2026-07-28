/// Diagnose — a Phase-2 feature shown as a polished stub so Luuk can react to the
/// full vision. AI plant-health diagnosis (camera) + a disease library by plant
/// part. No real AI in the prototype.
library;

import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../scan/scan_screen.dart';

class DiagnoseScreen extends StatelessWidget {
  const DiagnoseScreen({super.key});

  static const _parts = [
    ('🌿', 'Whole plant'),
    ('🍃', 'Leaves'),
    ('🌱', 'Stems'),
    ('🍅', 'Fruit'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text('Diagnose', style: AppText.kicker(context)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              children: [
                const Text('🩺', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 10),
                Text('Diagnose a sick plant', style: AppText.title(context)),
                const SizedBox(height: 4),
                Text('Snap a photo and get its health back',
                    style: AppText.bodyMuted(context), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Auto diagnose',
                  icon: Icons.center_focus_strong,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ScanScreen(mode: ScanMode.diagnose))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader('Common problems'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              for (final (emoji, label) in _parts)
                AppCard(
                  onTap: () {},
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text(label, style: AppText.heading(context)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Coming soon — Phase 2',
                style: AppText.caption(context)),
          ),
        ],
      ),
    );
  }
}
