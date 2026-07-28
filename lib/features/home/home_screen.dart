/// Home — the catalogue browse (GrowIt-shaped): region header, search + Add
/// plant, a mock premium banner, and "What to grow in [month]" with filter chips
/// and a photo-card grid. Our differentiator: the recommendations come from the
/// real frost-relative engine for the user's region.
library;

import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../design/widgets.dart';
import '../../timing/dates.dart';
import '../../timing/types.dart';
import '../grow/crop_detail_screen.dart';
import '../paywall/paywall_screen.dart';
import '../repository_scope.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _month;
  String _filter = 'all';
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Default the month to "today" — read here, not in initState, since it
    // depends on the inherited RepositoryScope.
    _month ??= parseIso(RepositoryScope.of(context).today).month;
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final List<Crop> crops = _query.isNotEmpty
        ? (repo.crops
            .where((c) =>
                c.names.en.toLowerCase().contains(_query.toLowerCase()) ||
                c.names.nl.toLowerCase().contains(_query.toLowerCase()))
            .toList()
          ..sort((a, b) => a.names.en.compareTo(b.names.en)))
        : repo.whatToGrowIn(_month!, filter: _filter);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(region: repo.regionName)),
          SliverToBoxAdapter(child: _SearchRow(onChanged: (q) => setState(() => _query = q))),
          SliverToBoxAdapter(child: _PremiumBanner(onTap: () => _openPaywall(context))),
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: _WhatToGrowHeader(
                month: _month!,
                filter: _filter,
                onMonth: _pickMonth,
                onFilter: (f) => setState(() => _filter = f),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text('${crops.length} results',
                    style: AppText.kicker(context)),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => PhotoCard(
                  crop: crops[i],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CropDetailScreen(crop: crops[i]))),
                ),
                childCount: crops.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPaywall(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen(), fullscreenDialog: true),
      );

  Future<void> _pickMonth() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('What to grow in…', style: AppText.title(context)),
            ),
            for (var m = 1; m <= 12; m++)
              ListTile(
                title: Text(_months[m - 1], style: AppText.body(context)),
                trailing: m == _month
                    ? const Icon(Icons.check, color: AppColors.sprout)
                    : null,
                onTap: () => Navigator.pop(context, m),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _month = picked);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.region});
  final String region;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 18, color: AppColors.sprout),
          const SizedBox(width: 4),
          Expanded(
            child: Text(region,
                style: AppText.label(context), overflow: TextOverflow.ellipsis),
          ),
          const Icon(Icons.workspace_premium, color: AppColors.medium),
          const SizedBox(width: 14),
          const Icon(Icons.settings_outlined, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppText.body(context),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search vegetables',
                hintStyle: AppText.bodyMuted(context),
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppColors.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: AppColors.sprout),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppColors.medium, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Try Cropsy Premium free for 7 days',
                      style: AppText.label(context, color: Colors.white)),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhatToGrowHeader extends StatelessWidget {
  const _WhatToGrowHeader({
    required this.month,
    required this.filter,
    required this.onMonth,
    required this.onFilter,
  });
  final int month;
  final String filter;
  final VoidCallback onMonth;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Text('What to grow in ', style: AppText.title(context)),
                GestureDetector(
                  onTap: onMonth,
                  child: Row(
                    children: [
                      Text(_months[month - 1],
                          style: AppText.title(context, color: AppColors.sprout)),
                      const Icon(Icons.arrow_drop_down, color: AppColors.sprout),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilterChipsRow(
            options: const [
              ('all', 'All'),
              ('indoors', 'Start indoors'),
              ('outside', 'Plant outside'),
              ('easy', 'Easy'),
            ],
            selected: filter,
            onSelect: onFilter,
          ),
        ],
      ),
    );
  }
}
