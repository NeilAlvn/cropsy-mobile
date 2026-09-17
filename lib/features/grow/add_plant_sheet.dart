/// "Set plant details" (PRD 4.3): planting date, how it started, where it
/// lives (place), pot size when in a container, variety (free text until the
/// varieties table lands in Phase 2). Pops the values; the caller writes.
library;

import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';
import '../../design/icons.dart';
import '../../design/motion.dart';
import 'package:intl/intl.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../../timing/types.dart';

class PlantDetails {
  const PlantDetails({
    required this.plantedOn,
    required this.method,
    required this.place,
    required this.potLitres,
    required this.variety,
  });
  final String plantedOn;
  final MethodType method;
  final String place;
  final int? potLitres;
  final String? variety;
}

final places = <(String, LocalizedText, IconData)>[
  ('ground', Str.placeGround, PhosphorIcons.flowerLotus),
  ('raised_bed', Str.placeRaisedBed, PhosphorIcons.squaresFour),
  ('outdoor_container', Str.placePotOutside, PhosphorIcons.buildings),
  ('indoor_container', Str.placePotInside, PhosphorIcons.browsers),
];

LocalizedText methodLabel(MethodType m) => switch (m) {
      MethodType.sowIndoor => Str.methodSowedIndoors,
      MethodType.sowDirect => Str.methodSowedOutside,
      MethodType.transplant => Str.methodPlantedSeedling,
      MethodType.plant => Str.methodPlantedSets,
    };

Future<PlantDetails?> showAddPlantSheet(BuildContext context, {required Crop crop, required String today}) {
  return showAppSheet<PlantDetails>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    builder: (_) => _Sheet(crop: crop, today: today),
  );
}

class _Sheet extends StatefulWidget {
  const _Sheet({required this.crop, required this.today});
  final Crop crop;
  final String today;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late String _on = widget.today;
  late MethodType _method = _methods.first;
  late String _place = widget.crop.containerOk ? 'outdoor_container' : 'ground';
  late final _pot = TextEditingController(text: widget.crop.minPotLitres?.toString() ?? '');
  final _variety = TextEditingController();

  List<MethodType> get _methods {
    // Offer what the crop supports, outdoor starts first (a bought seedling is
    // the common balcony case), plus "planted a seedling" for anything sown
    // indoors — nurseries sell those.
    final types = widget.crop.methods.map((m) => m.type).toSet();
    if (types.contains(MethodType.sowIndoor)) types.add(MethodType.transplant);
    const order = [MethodType.transplant, MethodType.sowDirect, MethodType.plant, MethodType.sowIndoor];
    return [for (final t in order) if (types.contains(t)) t];
  }

  bool get _container => _place.endsWith('container');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseIso(_on),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _on = toIso(DateTime.utc(picked.year, picked.month, picked.day)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Str.setPlantDetails.of(context), style: AppText.title(context)),
            Text(widget.crop.names.of(context), style: AppText.bodyMuted(context)),
            const SizedBox(height: 4),
            Text(Str.plantDetailsSub.of(context), style: AppText.caption(context)),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Icon(PhosphorIcons.calendarBlank, size: 20, color: AppColors.sprout),
                  const SizedBox(width: 12),
                  Text(Str.plantingDate.of(context), style: AppText.bodyMuted(context)),
                  const Spacer(),
                  Text(DateFormat('d MMM yyyy').format(parseIso(_on)), style: AppText.label(context)),
                  Icon(PhosphorIcons.caretRight, color: AppColors.muted),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Text(Str.howDidItStart.of(context), style: AppText.label(context)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _methods)
                  ChoiceChip(label: Text(methodLabel(m).of(context)), selected: _method == m, onSelected: (_) => setState(() => _method = m)),
              ],
            ),
            const SizedBox(height: 14),
            Text(Str.whereDoesItLive.of(context), style: AppText.label(context)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (key, label, icon) in places)
                  ChoiceChip(
                    avatar: Icon(icon, size: 16),
                    label: Text(label.of(context)),
                    selected: _place == key,
                    onSelected: (_) => setState(() => _place = key),
                  ),
              ],
            ),
            if (_container) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _pot,
                keyboardType: TextInputType.number,
                style: AppText.body(context),
                decoration: InputDecoration(
                  labelText: Str.potSizeLitres.of(context),
                  helperText: widget.crop.minPotLitres == null ? null : Str.atLeastLitres(widget.crop.minPotLitres!.toInt()).of(context),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _variety,
              style: AppText.body(context),
              decoration: InputDecoration(labelText: Str.varietyOptional.of(context), hintText: Str.varietyHint.of(context)),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: Str.growingIt.of(context),
              icon: PhosphorIcons.leaf,
              onPressed: () => Navigator.pop(
                context,
                PlantDetails(
                  plantedOn: _on,
                  method: _method,
                  place: _place,
                  potLitres: _container ? int.tryParse(_pot.text.trim()) : null,
                  variety: _variety.text.trim().isEmpty ? null : _variety.text.trim(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
