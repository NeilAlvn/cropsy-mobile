/// Mock premium paywall — GrowIt-style trial screen. No real purchase (this is a
/// prototype). Note: unlike GrowIt's, this one carries visible Terms/Privacy
/// links on the purchase screen (the Apple 3.1.2(c) lesson from Farmsy).
library;

import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _plan = 0; // 0 = yearly trial, 1 = monthly

  static const _benefits = [
    'Your first 7 days are free',
    'Weather-aware reminders, tuned to your region',
    'The full 60-crop planting calendar',
    'Plant identification & health diagnosis',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.muted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const Center(child: Text('🌱', style: TextStyle(fontSize: 56))),
                  const SizedBox(height: 16),
                  Text('Grow more with\nCropsy Premium',
                      textAlign: TextAlign.center,
                      style: AppText.display(context)),
                  const SizedBox(height: 20),
                  for (final b in _benefits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.sprout, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(b, style: AppText.body(context))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PlanCard(
                          title: 'Yearly',
                          price: '€29.99 / yr',
                          note: '7 days free',
                          selected: _plan == 0,
                          onTap: () => setState(() => _plan = 0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PlanCard(
                          title: 'Monthly',
                          price: '€4.99 / mo',
                          note: '',
                          selected: _plan == 1,
                          onTap: () => setState(() => _plan = 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Column(
                children: [
                  PrimaryButton(
                    label: _plan == 0 ? 'Start 7-day free trial' : 'Continue',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Prototype — no real purchase')));
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 10),
                  DefaultTextStyle(
                    style: AppText.caption(context),
                    child: const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: [
                        Text('Cancel anytime · '),
                        Text('Terms', style: TextStyle(color: AppColors.sprout)),
                        Text('·'),
                        Text('Privacy', style: TextStyle(color: AppColors.sprout)),
                        Text('·'),
                        Text('Restore', style: TextStyle(color: AppColors.sprout)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.note,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String price;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.sprout : AppColors.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.heading(context)),
            const SizedBox(height: 4),
            Text(price, style: AppText.body(context)),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(note, style: AppText.caption(context, color: AppColors.sprout)),
            ],
          ],
        ),
      ),
    );
  }
}
