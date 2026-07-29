/// Plant detail — the per-plant home for the journal (F5) and quick harvest
/// logging (F7). Journal photos are placeholder tiles in the prototype; real
/// camera/gallery capture comes with the feature build.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../repository_scope.dart';
import 'garden_repository.dart';

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
            iconTheme: const IconThemeData(color: AppColors.ink),
            title: plant == null
                ? null
                : Text(repo.cropName(plant.cropSlug),
                    style: AppText.heading(context)),
            actions: plant == null
                ? null
                : [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, color: AppColors.ink),
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
                          child: _menuRow(Icons.tune, 'Edit plant'),
                        ),
                        if (plant.plantedOn != null)
                          PopupMenuItem(
                            value: 'stop',
                            child: _menuRow(
                                Icons.undo, 'Move back to planning'),
                          ),
                        PopupMenuItem(
                          value: 'remove',
                          child: _menuRow(Icons.delete_outline,
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
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: '＋ Journal entry',
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
                    SectionHeader('Journal'),
                    _Journal(plantId: plant.id, repo: repo),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _addJournal(GardenRepository repo) async {
    final note = await _promptText(context, 'Journal entry', 'How\'s it doing?');
    if (note != null && note.isNotEmpty) {
      await repo.addJournalEntry(plantId: widget.plantId, note: note);
      if (mounted) setState(() {});
    }
  }

  Future<void> _logHarvest(GardenRepository repo, GardenPlantRow plant) async {
    final result = await showModalBottomSheet<(String, double)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (_) => _HarvestSheet(cropName: repo.cropName(plant.cropSlug)),
    );
    if (result != null) {
      await repo.logHarvest(
        cropSlug: plant.cropSlug,
        plantId: plant.id,
        amount: result.$1,
        valueEuros: result.$2,
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
    final changed = await showModalBottomSheet<bool>(
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

  Widget _menuRow(IconData icon, String label, {Color color = AppColors.ink}) =>
      Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: AppText.body(context, color: color)),
      ]);
}

Future<String?> _promptText(
    BuildContext context, String title, String hint) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title, style: AppText.title(context)),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        style: AppText.body(context),
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
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
                        alignment: Alignment.center,
                        child: const Icon(Icons.photo_camera_outlined,
                            color: AppColors.muted),
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
                            Text(e.note ?? '', style: AppText.body(context)),
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
  const _HarvestSheet({required this.cropName});
  final String cropName;

  @override
  State<_HarvestSheet> createState() => _HarvestSheetState();
}

class _HarvestSheetState extends State<_HarvestSheet> {
  final _amount = TextEditingController();
  final _value = TextEditingController();

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
          TextField(
            controller: _amount,
            autofocus: true,
            style: AppText.body(context),
            decoration: const InputDecoration(
                labelText: 'What did you pick?',
                hintText: 'e.g. 6 courgettes, a big bowl'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _value,
            keyboardType: TextInputType.number,
            style: AppText.body(context),
            decoration: const InputDecoration(
                labelText: 'Value grown (optional)',
                hintText: 'e.g. €4.50 — leave blank to just count it'),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save harvest',
            color: AppColors.clay,
            onPressed: () {
              final v = double.tryParse(_value.text.replaceAll(',', '.')) ?? 0;
              Navigator.pop(
                context,
                (_amount.text.isEmpty ? 'a harvest' : _amount.text, v),
              );
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
                    const Icon(Icons.event, size: 20, color: AppColors.sprout),
                    const SizedBox(width: 12),
                    Text('Planted', style: AppText.bodyMuted(context)),
                    const Spacer(),
                    Text(DateFormat('d MMM yyyy').format(parseIso(_plantedOn!)),
                        style: AppText.label(context)),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
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
