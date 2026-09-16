/// F1 — "Grow": browse/search the crop catalogue (the 60 verified crops). Tap a
/// crop for its planting calendar with the "why".
library;

import 'package:flutter/material.dart';
import '../../design/icons.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../timing/types.dart';
import '../repository_scope.dart';
import 'crop_detail_screen.dart';

class GrowScreen extends StatefulWidget {
  const GrowScreen({super.key});

  @override
  State<GrowScreen> createState() => _GrowScreenState();
}

class _GrowScreenState extends State<GrowScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final crops = repo.crops
        .where((c) =>
            _query.isEmpty ||
            c.names.en.toLowerCase().contains(_query.toLowerCase()) ||
            c.names.nl.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.names.en.compareTo(b.names.en));

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grow', style: AppText.kicker(context)),
                const SizedBox(height: 2),
                Text.rich(TextSpan(
                  style: AppText.display(context),
                  children: [
                    TextSpan(text: 'Pick something '),
                    TextSpan(
                        text: 'to grow',
                        style: TextStyle(color: AppColors.sprout)),
                  ],
                )),
                const SizedBox(height: 14),
                _SearchField(onChanged: (q) => setState(() => _query = q)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: crops.length,
              itemBuilder: (context, i) => _CropCard(crop: crops[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: AppText.body(context),
      decoration: InputDecoration(
        hintText: 'Search 60 crops…',
        hintStyle: AppText.bodyMuted(context),
        prefixIcon: Icon(PhosphorIcons.magnifyingGlass, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.sprout),
        ),
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  const _CropCard({required this.crop});
  final Crop crop;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryDot(crop.category, size: 12),
              const Spacer(),
              if (crop.containerOk)
                Icon(PhosphorIcons.checkCircle,
                    size: 15, color: AppColors.sprout),
            ],
          ),
          const Spacer(),
          Text(crop.names.en, style: AppText.heading(context)),
          const SizedBox(height: 2),
          Text(
            crop.containerOk && crop.minPotLitres != null
                ? '${crop.minPotLitres}L pot · ${crop.sun}'
                : crop.sun,
            style: AppText.caption(context),
          ),
        ],
      ),
    );
  }
}
