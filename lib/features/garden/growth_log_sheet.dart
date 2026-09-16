/// Growth log entry (PRD 5.5): "How is your Tomato doing?" — mood, up to nine
/// photos, a note, the growth stage. Photos are copied into the app's
/// documents dir; upload to Supabase Storage follows once the bucket is live.
library;

import 'dart:io';
import '../../design/motion.dart';

import 'package:flutter/material.dart';
import '../../design/icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../db/uuid.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';

class GrowthLog {
  const GrowthLog({required this.mood, required this.note, required this.stage, required this.photoPaths});
  final int? mood;
  final String note;
  final String? stage;
  final List<String> photoPaths;
}

const moods = <(int, String, String)>[(1, '😟', 'Bad'), (2, '😐', 'Okay'), (3, '🙂', 'Good'), (4, '🤩', 'Excellent')];
const growthStages = ['starting', 'seedling', 'vegetative', 'flowering', 'harvesting', 'harvested'];

String stageLabel(String s) => s[0].toUpperCase() + s.substring(1);

Future<GrowthLog?> showGrowthLogSheet(BuildContext context, {required String cropName, String? currentStage}) {
  return showAppSheet<GrowthLog>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.paper,
    builder: (_) => _Sheet(cropName: cropName, currentStage: currentStage),
  );
}

class _Sheet extends StatefulWidget {
  const _Sheet({required this.cropName, required this.currentStage});
  final String cropName;
  final String? currentStage;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  int? _mood;
  late String? _stage = widget.currentStage;
  final _note = TextEditingController();
  final _photos = <String>[];
  final _picker = ImagePicker();

  Future<void> _addPhoto(ImageSource source) async {
    if (_photos.length >= 9) return;
    final x = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 82);
    if (x == null) return;
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'journal'));
    await dir.create(recursive: true);
    final dest = p.join(dir.path, '${newUuid()}.jpg');
    await File(x.path).copy(dest);
    if (mounted) setState(() => _photos.add(dest));
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
            Text('How is your ${widget.cropName} doing?', style: AppText.title(context)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (v, emoji, label) in moods)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mood = v),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _mood == v ? AppColors.sprout : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(children: [
                          Text(emoji, style: const TextStyle(fontSize: 24)),
                          Text(label, style: AppText.caption(context, color: _mood == v ? AppColors.onAccent : AppColors.muted)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Growth stage', style: AppText.label(context)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in growthStages)
                  ChoiceChip(label: Text(stageLabel(s)), selected: _stage == s, onSelected: (_) => setState(() => _stage = s)),
              ],
            ),
            const SizedBox(height: 14),
            Text('Photos (${_photos.length}/9)', style: AppText.label(context)),
            const SizedBox(height: 6),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _PhotoButton(icon: PhosphorIcons.camera, onTap: () => _addPhoto(ImageSource.camera)),
                  _PhotoButton(icon: PhosphorIcons.images, onTap: () => _addPhoto(ImageSource.gallery)),
                  for (final path in _photos)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(path), width: 72, height: 72, fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _note,
              maxLines: 3,
              style: AppText.body(context),
              decoration: const InputDecoration(labelText: 'Note (optional)', hintText: 'First flowers, aphids on the tips…'),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Save log',
              onPressed: () => Navigator.pop(context, GrowthLog(mood: _mood, note: _note.text.trim(), stage: _stage, photoPaths: List.of(_photos))),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Icon(icon, color: AppColors.sprout),
          ),
        ),
      );
}
