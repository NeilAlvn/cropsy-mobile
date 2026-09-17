/// Diagnose (PRD 5.7 / 7.1): the offline common-problems browser by plant
/// part, from the verified content snapshot. Auto-diagnose (third-party API)
/// is Phase 4 and stays greyed until then — never the headline.
library;

import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';
import '../../design/icons.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/mascot.dart';
import '../../design/typography.dart';
import '../../timing/content_snapshot.dart';
import '../repository_scope.dart';
import '../scan/scan_screen.dart';

const _parts = <(String, String, String)>[
  ('whole', '🌿', 'Whole plant'),
  ('leaves', '🍃', 'Leaves'),
  ('stems', '🌱', 'Stems'),
  ('flowers', '🌸', 'Flowers'),
  ('fruits', '🍅', 'Fruits'),
  ('roots', '🥕', 'Roots'),
];

class DiagnoseScreen extends StatefulWidget {
  const DiagnoseScreen({super.key});

  @override
  State<DiagnoseScreen> createState() => _DiagnoseScreenState();
}

class _DiagnoseScreenState extends State<DiagnoseScreen> {
  String? _part;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final all = repo.content.problems;
    final problems = _part == null ? all : all.where((p) => p.parts.contains(_part)).toList();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(Str.diagnose.of(context), style: AppText.kicker(context)),
          const SizedBox(height: 10),
          AppCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen(mode: ScanMode.diagnose))),
            child: Row(children: [
              Icon(PhosphorIcons.crosshairSimple, color: AppColors.sprout),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Str.autoDiagnose.of(context), style: AppText.label(context)),
                    Text(Str.autoDiagnoseSub.of(context), style: AppText.caption(context)),
                  ],
                ),
              ),
              Icon(PhosphorIcons.caretRight, color: AppColors.muted),
            ]),
          ),
          const SizedBox(height: 24),
          SectionHeader(Str.commonProblems.of(context)),
          Text(Str.byPlantPart.of(context), style: AppText.caption(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(label: Text(Str.all.of(context)), selected: _part == null, onSelected: (_) => setState(() => _part = null)),
              for (final (key, emoji, label) in _parts)
                ChoiceChip(label: Text('$emoji $label'), selected: _part == key, onSelected: (_) => setState(() => _part = key)),
            ],
          ),
          const SizedBox(height: 16),
          if (all.isEmpty)
            const MascotSays(
              pose: MascotPose.thinking,
              text: 'The 25 problems common on Dutch balconies, slakken, luizen, meeldauw, neusrot, are being written and checked. They land with the content update.',
            )
          else if (problems.isEmpty)
            Text(Str.nothingForThatPart.of(context), style: AppText.bodyMuted(context))
          else
            for (final p in problems)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProblemScreen(problem: p))),
                  child: Row(children: [
                    Pill(label: p.kind, color: p.kind == 'pest' ? AppColors.clay : AppColors.sky),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.names.of(context), style: AppText.heading(context)),
                          Text(p.symptoms.of(context), style: AppText.caption(context), maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (p.draft) const Padding(padding: EdgeInsets.only(top: 4), child: Align(alignment: Alignment.centerLeft, child: DraftBadge(compact: true))),
                        ],
                      ),
                    ),
                    Icon(PhosphorIcons.caretRight, color: AppColors.muted),
                  ]),
                ),
              ),
        ],
      ),
    );
  }
}

class ProblemScreen extends StatelessWidget {
  const ProblemScreen({super.key, required this.problem});
  final Problem problem;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    Widget section(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SectionHeader(title),
            Text(body, style: AppText.body(context)),
          ]),
        );
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: AppColors.paper,
        iconTheme: IconThemeData(color: AppColors.ink),
        title: Text(problem.names.of(context), style: AppText.heading(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(problem.names.nl, style: AppText.bodyMuted(context)),
          if (problem.draft) const Padding(padding: EdgeInsets.only(top: 8), child: DraftBadge()),
          const SizedBox(height: 12),
          section('Symptoms', problem.symptoms.of(context)),
          section('Treatment (organic first)', problem.treatment.of(context)),
          section('Prevention', problem.prevention.of(context)),
          if (problem.affects.isNotEmpty) ...[
            SectionHeader(Str.oftenOn.of(context)),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final s in problem.affects) Pill(label: repo.cropNames(s).of(context))]),
          ],
        ],
      ),
    );
  }
}
