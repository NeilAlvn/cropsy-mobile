/// Scan (PRD 4.4 / 7.1): take or pick a photo, send it to our proxy, show
/// ranked guesses. Identify → crop pages ("Not this plant? Change" = pick
/// another guess or search). Diagnose → our own problem pages, always framed
/// as a guess. Without server keys the proxy answers 503 and this says so.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/mascot.dart';
import '../../design/typography.dart';
import '../../scan/scan_api.dart' as api;
import '../diagnose/diagnose_screen.dart';
import '../grow/crop_detail_screen.dart';
import '../paywall/paywall_screen.dart';
import '../repository_scope.dart';

enum ScanMode { identify, diagnose }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, this.mode = ScanMode.identify});
  final ScanMode mode;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  File? _photo;
  bool _busy = false;
  api.ScanResult? _result;
  String? _message;
  late ScanMode _mode = widget.mode;

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    setState(() {
      _photo = File(x.path);
      _result = null;
      _message = null;
    });
    await _send();
  }

  Future<void> _send() async {
    final photo = _photo;
    if (photo == null || !mounted) return;
    final token = AuthScope.maybeOf(context)?.accessToken;
    if (token == null) {
      setState(() => _message = 'Sign in first (Settings) — scans are counted per account.');
      return;
    }
    setState(() => _busy = true);
    try {
      final r = _mode == ScanMode.identify ? await api.identify(photo, token) : await api.diagnose(photo, token);
      if (!mounted) return;
      setState(() => _result = r);
    } on api.ScanException catch (e) {
      if (!mounted) return;
      if (e.premiumRequired) {
        final bought = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const PaywallScreen(), fullscreenDialog: true));
        if (bought == true && mounted) await _send();
        return;
      }
      setState(() => _message = e.notConfigured
          ? 'Photo scanning opens with the beta. The common-problems browser already works offline.'
          : e.quota
              ? 'Daily scan limit reached. Tomorrow again, or unlock lifetime for more.'
              : 'Scan failed (${e.code}). Try again.');
    } catch (_) {
      if (mounted) setState(() => _message = 'No connection. Scans need the network; everything else works offline.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final identify = _mode == ScanMode.identify;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: AppColors.paper,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text(identify ? 'Identify a plant' : 'Diagnose a plant', style: AppText.heading(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          SegmentedButton<ScanMode>(
            segments: const [
              ButtonSegment(value: ScanMode.identify, label: Text('What is it?'), icon: Icon(Icons.search)),
              ButtonSegment(value: ScanMode.diagnose, label: Text('Is it OK?'), icon: Icon(Icons.healing_outlined)),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _result = null;
              _message = null;
            }),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
              clipBehavior: Clip.antiAlias,
              child: _photo == null
                  ? const Center(child: Mascot(MascotPose.thinking, size: 96))
                  : Image.file(_photo!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PrimaryButton(label: 'Take photo', icon: Icons.photo_camera_outlined, onPressed: _busy ? null : () => _pick(ImageSource.camera))),
            const SizedBox(width: 10),
            Expanded(child: SecondaryButton(label: 'From photos', onPressed: _busy ? null : () => _pick(ImageSource.gallery))),
          ]),
          const SizedBox(height: 8),
          Text(
            identify
                ? 'Snap tips: one plant, a leaf or flower filling the frame, daylight.'
                : 'Snap tips: the damaged part sharp and close, plus one wider shot if unsure.',
            style: AppText.caption(context),
          ),
          const SizedBox(height: 20),
          if (_busy) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          if (_message != null) MascotSays(pose: MascotPose.shrug, text: _message!),
          if (_result != null) _Results(result: _result!, identify: identify),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.result, required this.identify});
  final api.ScanResult result;
  final bool identify;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    if (result.reason == 'not_a_plant') {
      return const MascotSays(pose: MascotPose.shrug, text: "That does not look like a plant. We're experts in fruits and veggies — try a leaf or a fruit.");
    }
    if (result.suggestions.isEmpty) {
      return MascotSays(pose: MascotPose.shrug, text: identify ? 'No match. Try a closer shot of a leaf or flower, or search by name.' : (result.healthy == true ? 'Looks healthy from here.' : 'Nothing recognisable. Browse the common problems below instead.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MascotSays(
          pose: identify ? MascotPose.pointing : MascotPose.thinking,
          text: identify ? 'Best guesses, most likely first. Not this plant? Pick another or search by name.' : (result.disclaimer ?? 'This is a guess from the photo, not a diagnosis.'),
        ),
        const SizedBox(height: 12),
        for (final s in result.suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: () {
                if (identify) {
                  final crop = s.cropSlug == null ? null : repo.cropBySlug(s.cropSlug!);
                  if (crop != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop)));
                } else {
                  final problem = s.problemSlug == null ? null : repo.content.problems.where((p) => p.slug == s.problemSlug).firstOrNull;
                  if (problem != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProblemScreen(problem: problem)));
                }
              },
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      identify && s.cropSlug != null ? repo.cropName(s.cropSlug!) : s.name,
                      style: AppText.label(context),
                    ),
                    if (s.latin != null) Text(s.latin!, style: AppText.caption(context)),
                    if (identify && s.cropSlug == null) Text('Not one of our crops yet', style: AppText.caption(context, color: AppColors.muted)),
                    if (!identify && s.problemSlug == null) Text('No guide for this one yet', style: AppText.caption(context, color: AppColors.muted)),
                  ]),
                ),
                Pill(label: '${(s.score * 100).round()}%', color: s.score >= 0.5 ? AppColors.sprout : AppColors.muted),
                if ((identify ? s.cropSlug : s.problemSlug) != null) const Icon(Icons.chevron_right, color: AppColors.muted),
              ]),
            ),
          ),
        if (result.used != null && result.limit != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('${result.used} of ${result.limit} scans used today', style: AppText.caption(context)),
          ),
      ],
    );
  }
}
