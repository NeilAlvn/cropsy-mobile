/// Plant detail — the per-plant home for the journal (F5) and quick harvest
/// logging (F7). Journal photos are placeholder tiles in the prototype; real
/// camera/gallery capture comes with the feature build.
library;

import 'dart:io';
import '../../design/motion.dart';

import 'package:flutter/material.dart';
import '../../design/icons.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../../timing/replan.dart';
import '../repository_scope.dart';
import 'garden_repository.dart';
import '../../sync/photo_uploader.dart';
import 'growth_log_sheet.dart';
import 'insights.dart';
import '../grow/crop_detail_screen.dart';
import 'timeline_view.dart';

class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({super.key, required this.plantId});
  final String plantId;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<GardenPlantRow?>(
      future: repo.plantById(widget.plantId),
      builder: (context, snap) {
        final plant = snap.data;
        return Scaffold(
          backgroundColor: AppColors.paper,
          appBar: AppBar(
            backgroundColor: AppColors.paper,
            surfaceTintColor: AppColors.paper,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.ink),
            title: plant == null
                ? null
                : Text(repo.cropName(plant.cropSlug),
                    style: AppText.heading(context)),
            actions: plant == null
                ? null
                : [
                    PopupMenuButton<String>(
                      icon: Icon(PhosphorIcons.dotsThree, color: AppColors.ink),
                      color: AppColors.surface,
                      onSelected: (v) => switch (v) {
                        'edit' => _editPlant(repo, plant),
                        'stop' => _stopGrowing(repo, plant),
                        'remove' => _removePlant(repo, plant),
                        _ => null,
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: _menuRow(PhosphorIcons.slidersHorizontal, 'Edit plant'),
                        ),
                        if (plant.plantedOn != null)
                          PopupMenuItem(
                            value: 'stop',
                            child: _menuRow(
                                PhosphorIcons.arrowCounterClockwise, 'Move back to planning'),
                          ),
                        PopupMenuItem(
                          value: 'remove',
                          child: _menuRow(PhosphorIcons.trash,
                              'Remove from garden',
                              color: AppColors.warn),
                        ),
                      ],
                    ),
                  ],
          ),
          body: plant == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    Row(
                      children: [
                        CategoryDot(repo.cropCategory(plant.cropSlug), size: 14),
                        const SizedBox(width: 8),
                        Text(
                          plant.potLitres != null
                              ? '${plant.potLitres} L pot'
                              : 'in ground',
                          style: AppText.bodyMuted(context),
                        ),
                        if (plant.plantedOn != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· planted ${DateFormat('d MMM').format(parseIso(plant.plantedOn!))}',
                            style: AppText.bodyMuted(context),
                          ),
                        ],
                        const Spacer(),
                        // GrowIt 5.4: the crop's guide (calendar, how-tos, FAQ) one tap away.
                        if (repo.cropBySlug(plant.cropSlug) case final crop?)
                          TextButton(
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop))),
                            child: Text('Growing guide →', style: AppText.label(context, color: AppColors.sprout)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: '＋ Growth log',
                            onPressed: () => _addJournal(repo),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Log harvest',
                            color: AppColors.clay,
                            onPressed: () => _logHarvest(repo, plant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (plant.plantedOn != null) ...[
                      _StageRow(plant: plant, repo: repo, onChanged: () => setState(() {})),
                      const SizedBox(height: 16),
                      if (repo.cropBySlug(plant.cropSlug) case final crop?)
                        FutureBuilder<List<PathNode>>(
                          future: repo.pathFor(plant.id),
                          builder: (context, snap) {
                            final harvest = snap.data?.where((n) => n.kind == NodeKind.harvest).firstOrNull;
                            return InsightsList(
                              insights: insightsFor(
                                crop: crop,
                                frost: repo.frost,
                                today: repo.today,
                                obs: repo.lastObservations,
                                potLitres: plant.potLitres,
                                harvestEnd: harvest?.until ?? harvest?.due,
                              ),
                            );
                          },
                        ),
                      SectionHeader('Your path'),
                      TimelineView(plantId: plant.id),
                      const SizedBox(height: 24),
                    ],
                    SectionHeader('Journal'),
                    _Journal(plantId: plant.id, repo: repo),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _addJournal(GardenRepository repo) async {
    final plant = await repo.plantById(widget.plantId);
    if (!mounted || plant == null) return;
    final log = await showGrowthLogSheet(context, cropName: repo.cropName(plant.cropSlug), currentStage: plant.stage);
    if (log == null) return;
    await repo.addJournalEntry(
      plantId: widget.plantId,
      note: log.note,
      mood: log.mood,
      stage: log.stage,
      photoPaths: log.photoPaths,
    );
    if (mounted) setState(() {});
    // Signed in → push the photos now; offline just waits for the next sync.
    if (log.photoPaths.isNotEmpty && mounted) AuthScope.maybeOf(context)?.syncNow();
  }

  Future<void> _logHarvest(GardenRepository repo, GardenPlantRow plant) async {
    final result = await showAppSheet<(double, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (_) => _HarvestSheet(
        cropName: repo.cropName(plant.cropSlug),
        pricedUnit: repo.content.prices[plant.cropSlug]?.unit,
      ),
    );
    if (result != null) {
      await repo.logHarvest(
        cropSlug: plant.cropSlug,
        plantId: plant.id,
        quantity: result.$1,
        unit: result.$2,
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harvest logged 🧺')),
        );
      }
    }
  }

  Future<void> _editPlant(GardenRepository repo, GardenPlantRow plant) async {
    final changed = await showAppSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (_) => _EditPlantSheet(plant: plant, today: repo.today),
    );
    // The sheet writes through the repo itself; just refresh on return.
    if (changed == true && mounted) setState(() {});
  }

  Future<void> _stopGrowing(GardenRepository repo, GardenPlantRow plant) async {
    await repo.stopGrowing(plant.id);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${repo.cropName(plant.cropSlug)} moved to planning')),
      );
    }
  }

  Future<void> _removePlant(GardenRepository repo, GardenPlantRow plant) async {
    final name = repo.cropName(plant.cropSlug);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Remove $name?', style: AppText.title(context)),
        content: Text(
          'This takes $name out of your garden. Any harvests you already '
          'logged stay in your season history.',
          style: AppText.bodyMuted(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warn),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await repo.removePlant(plant.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed from your garden')),
        );
      }
    }
  }

  Widget _menuRow(IconData icon, String label, {Color? color}) =>
      Row(children: [
        Icon(icon, size: 20, color: color ?? AppColors.ink),
        const SizedBox(width: 12),
        Text(label, style: AppText.body(context, color: color)),
      ]);
}

class _Journal extends StatelessWidget {
  const _Journal({required this.plantId, required this.repo});
  final String plantId;
  final GardenRepository repo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<JournalEntryRow>>(
      future: repo.journal(plantId),
      builder: (context, snap) {
        final entries = snap.data ?? const [];
        if (entries.isEmpty) {
          return Text('No entries yet. Add one to start the timeline.',
              style: AppText.bodyMuted(context));
        }
        return Column(
          children: [
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.sand,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: e.photoPath == null
                            ? Text(
                                e.mood == null ? '📝' : moods[e.mood!.clamp(1, 4) - 1].$2,
                                style: const TextStyle(fontSize: 22),
                              )
                            : FutureBuilder<File?>(
                                future: PhotoUploader.localFile(e.photoPath!),
                                builder: (context, snap) => snap.data == null
                                    ? Icon(PhosphorIcons.image, color: AppColors.muted)
                                    : Image.file(snap.data!, fit: BoxFit.cover),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE d MMM').format(parseIso(e.entryOn)),
                              style: AppText.label(context, color: AppColors.sprout),
                            ),
                            const SizedBox(height: 2),
                            if (e.stage != null)
                              Text(stageLabel(e.stage!), style: AppText.caption(context)),
                            if (e.note != null) Text(e.note!, style: AppText.body(context)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HarvestSheet extends StatefulWidget {
  const _HarvestSheet({required this.cropName, this.pricedUnit});

  final String cropName;

  /// The unit this crop is priced in, when it has a price at all. The sheet
  /// opens on it, so a logged harvest lands in the tally by default.
  final String? pricedUnit;

  @override
  State<_HarvestSheet> createState() => _HarvestSheetState();
}

class _HarvestSheetState extends State<_HarvestSheet> {
  final _qty = TextEditingController();
  late String _unit = widget.pricedUnit ?? 'pcs';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log harvest', style: AppText.title(context)),
          Text(widget.cropName, style: AppText.bodyMuted(context)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _qty,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppText.body(context),
                decoration: const InputDecoration(labelText: 'How much?', hintText: 'e.g. 6 or 0.4'),
              ),
            ),
            const SizedBox(width: 10),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'pcs', label: Text('pieces')), ButtonSegment(value: 'kg', label: Text('kg'))],
              selected: {_unit},
              onSelectionChanged: (v) => setState(() => _unit = v.first),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            switch (widget.pricedUnit) {
              null => 'This crop has no shop price yet, so it counts towards the '
                  'yield but not towards money saved.',
              final priced when priced == _unit =>
                'Counts towards your season tally.',
              final priced =>
                'Your tally prices this crop per $priced, so this adds to the '
                'yield but not to money saved.',
            },
            style: AppText.caption(context),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save harvest',
            color: AppColors.clay,
            onPressed: () {
              final q = double.tryParse(_qty.text.replaceAll(',', '.'));
              if (q == null || q <= 0) return;
              Navigator.pop(context, (q, _unit));
            },
          ),
        ],
      ),
    );
  }
}

/// Edit a plant's pot size and planted date — the "fix a mistake after adding"
/// path. Writes straight through the repository and pops `true` on save.
class _EditPlantSheet extends StatefulWidget {
  const _EditPlantSheet({required this.plant, required this.today});
  final GardenPlantRow plant;
  final String today;

  @override
  State<_EditPlantSheet> createState() => _EditPlantSheetState();
}

class _EditPlantSheetState extends State<_EditPlantSheet> {
  late final TextEditingController _pot =
      TextEditingController(text: widget.plant.potLitres?.toString() ?? '');
  late String? _plantedOn = widget.plant.plantedOn;

  Future<void> _pickDate() async {
    final base = parseIso(_plantedOn ?? widget.today);
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _plantedOn =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit plant', style: AppText.title(context)),
          Text(repo.cropName(widget.plant.cropSlug),
              style: AppText.bodyMuted(context)),
          const SizedBox(height: 16),
          TextField(
            controller: _pot,
            keyboardType: TextInputType.number,
            style: AppText.body(context),
            decoration: const InputDecoration(
                labelText: 'Pot size (litres)',
                hintText: 'leave blank for in-ground'),
          ),
          if (_plantedOn != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.calendarBlank, size: 20, color: AppColors.sprout),
                    const SizedBox(width: 12),
                    Text('Planted', style: AppText.bodyMuted(context)),
                    const Spacer(),
                    Text(DateFormat('d MMM yyyy').format(parseIso(_plantedOn!)),
                        style: AppText.label(context)),
                    const SizedBox(width: 6),
                    Icon(PhosphorIcons.caretRight, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save changes',
            onPressed: () async {
              final pot = int.tryParse(_pot.text.trim());
              await repo.updatePlant(widget.plant.id,
                  potLitres: pot, plantedOn: _plantedOn);
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }
}

const _stages = ['starting', 'seedling', 'vegetative', 'flowering', 'harvesting', 'harvested'];

/// GrowIt 5.4: growth stage row → picker.
class _StageRow extends StatelessWidget {
  const _StageRow({required this.plant, required this.repo, required this.onChanged});
  final GardenPlantRow plant;
  final GardenRepository repo;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final stage = plant.stage ?? 'starting';
    return AppCard(
      child: Row(
        children: [
          Text('Growth stage', style: AppText.bodyMuted(context)),
          const Spacer(),
          DropdownButton<String>(
            value: stage,
            underline: const SizedBox.shrink(),
            items: [
              for (final s in _stages)
                DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1), style: AppText.label(context))),
            ],
            onChanged: (v) async {
              if (v == null) return;
              await repo.setStage(plant.id, v);
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}
