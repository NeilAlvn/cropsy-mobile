/// Garden planner grid (PRD 5.1): the bed as 30 cm cells. Tap a cell, pick a
/// crop; the cell shows how many plants fit (`vak_per_m2` = plants per 30 cm
/// square). Adjacent cells with a bad companion pairing show a warning once
/// the verified matrix lands (empty until the content update). Layout is
/// saved as JSON on the garden and syncs. cm only.
library;

import 'dart:convert';
import '../../timing/types.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';

import 'package:flutter/material.dart';
import '../../design/icons.dart';

import '../../db/database.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/crop_image.dart';
import '../../design/typography.dart';
import '../repository_scope.dart';
import 'garden_repository.dart';

class PlannerGridScreen extends StatefulWidget {
  const PlannerGridScreen({super.key, required this.garden});
  final GardenRow garden;

  @override
  State<PlannerGridScreen> createState() => _PlannerGridScreenState();
}

class _PlannerGridScreenState extends State<PlannerGridScreen> {
  late int _cols;
  late int _rows;
  late Map<String, String> _cells; // "r,c" → crop slug
  String? _brush;

  @override
  void initState() {
    super.initState();
    final j = widget.garden.layout == null ? <String, dynamic>{} : jsonDecode(widget.garden.layout!) as Map<String, dynamic>;
    _cols = (j['cols'] as num?)?.toInt() ?? 4;
    _rows = (j['rows'] as num?)?.toInt() ?? 3;
    _cells = {for (final e in (j['cells'] as Map<String, dynamic>? ?? {}).entries) e.key: e.value as String};
  }

  Future<void> _save() async {
    await RepositoryScope.of(context).saveLayout(widget.garden.id, {'cols': _cols, 'rows': _rows, 'cells': _cells});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Str.layoutSaved.of(context))));
  }

  List<String> _neighbours(int r, int c) => [
        for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) ?_cells['${r + dr},${c + dc}'],
      ];

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final content = repo.content;
    final warnings = <String>{};
    for (final e in _cells.entries) {
      final parts = e.key.split(',').map(int.parse).toList();
      for (final n in _neighbours(parts[0], parts[1])) {
        if (content.conflict(e.value, n) != null) warnings.add(e.key);
      }
    }
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: AppColors.paper,
        iconTheme: IconThemeData(color: AppColors.ink),
        title: Text(Str.gardenPlanner.of(context), style: AppText.heading(context)),
        actions: [TextButton(onPressed: _save, child: Text(Str.save.of(context)))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(children: [
            Text('${_cols * 30} × ${_rows * 30} cm', style: AppText.label(context)),
            const Spacer(),
            _Stepper(label: 'cols', value: _cols, onChanged: (v) => setState(() => _cols = v)),
            const SizedBox(width: 10),
            _Stepper(label: 'rows', value: _rows, onChanged: (v) => setState(() => _rows = v)),
          ]),
          const SizedBox(height: 12),
          Text(_brush == null
              ? Str.pickACrop.of(context)
              : Str.painting(repo.cropBySlug(_brush!)?.names ??
                      LocalizedText(nl: _brush!, en: _brush!))
                  .of(context),
              style: AppText.caption(context)),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: _cols / _rows,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _cols, mainAxisSpacing: 4, crossAxisSpacing: 4),
              itemCount: _cols * _rows,
              itemBuilder: (context, i) {
                final r = i ~/ _cols, c = i % _cols;
                final key = '$r,$c';
                final slug = _cells[key];
                final crop = slug == null ? null : repo.cropBySlug(slug);
                final count = crop?.vakPerM2?.toInt();
                return GestureDetector(
                  onTap: () => setState(() {
                    if (slug != null && (_brush == null || _brush == slug)) {
                      _cells.remove(key);
                    } else if (_brush != null) {
                      _cells[key] = _brush!;
                    }
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: slug == null ? AppColors.sand : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: warnings.contains(key) ? AppColors.warn : AppColors.border, width: warnings.contains(key) ? 2 : 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: slug == null
                        ? null
                        : Stack(fit: StackFit.expand, children: [
                            CropImage(slug: slug, category: crop?.category ?? 'herb'),
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Pill(label: count == null ? '1×' : '$count×', bg: AppColors.surface),
                            ),
                          ]),
                  ),
                );
              },
            ),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(Str.redCells.of(context), style: AppText.caption(context, color: AppColors.warn)),
          ],
          const SizedBox(height: 18),
          SectionHeader('Your crops'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slug in _paletteSlugs(repo))
                ChoiceChip(
                  avatar: SizedBox(width: 20, height: 20, child: ClipOval(child: CropImage(slug: slug, category: repo.cropCategory(slug)))),
                  label: Text(repo.cropName(slug)),
                  selected: _brush == slug,
                  onSelected: (_) => setState(() => _brush = _brush == slug ? null : slug),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _paletteSlugs(GardenRepository repo) {
    // Plants in the garden first; the rest of the catalogue after.
    final mine = _mine ?? const <String>[];
    final rest = repo.crops.map((c) => c.slug).where((s) => !mine.contains(s)).toList()..sort();
    return [...mine, ...rest];
  }

  List<String>? _mine;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mine == null) {
      RepositoryScope.of(context).plants(widget.garden.id).then((ps) {
        if (mounted) setState(() => _mine = ps.map((p) => p.cropSlug).toSet().toList());
      });
    }
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(visualDensity: VisualDensity.compact, onPressed: value > 1 ? () => onChanged(value - 1) : null, icon: Icon(PhosphorIcons.minusCircle, size: 20)),
        Text('$value $label', style: AppText.caption(context)),
        IconButton(visualDensity: VisualDensity.compact, onPressed: value < 12 ? () => onChanged(value + 1) : null, icon: Icon(PhosphorIcons.plusCircle, size: 20)),
      ]);
}
