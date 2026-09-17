/// Insights for you (PRD 5.4): weather-driven cards from the live overlay and
/// frost proximity for the garden. Pure over the repository's last
/// observations + frost profile; nothing invented when there is no data.
library;

import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/mascot.dart';
import '../../timing/dates.dart';
import '../../timing/types.dart';
import '../../timing/weather_adjust.dart';

class Insight {
  const Insight(this.pose, this.text);
  final MascotPose pose;

  /// Both languages: an insight is a sentence the gardener reads, and it is
  /// assembled here rather than in the screen.
  final LocalizedText text;
}

List<Insight> insightsFor({
  required Crop crop,
  required FrostProfile frost,
  required String today,
  required List<DayObservation>? obs,
  required int? potLitres,
  String? harvestEnd,
}) {
  final out = <Insight>[];
  final t = parseIso(today);
  final firstFrost = parseIso(frost.firstFrost);
  final lastFrost = parseIso(frost.lastFrost);
  final toFirst = firstFrost.difference(t).inDays;
  final toLast = lastFrost.difference(t).inDays;

  if (crop.frostTender && harvestEnd != null && harvestEnd.compareTo(frost.firstFrost) > 0) {
    out.add(Insight(
        MascotPose.shrug,
        LocalizedText(
          nl: 'Het oogstvenster loopt door tot na de eerste vorst '
              '(${frost.firstFrost}). Doorgaan mag voor wat als eerste rijpt: '
              'zet de pot binnen, of kies volgend jaar een snellere variëteit.',
          en: 'The harvest window runs past the first frost '
              '(${frost.firstFrost}). Grow it anyway for what ripens first, '
              'move the pot inside, or swap for a faster variety next time.',
        )));
  }
  if (crop.frostTender && toFirst >= 0 && toFirst <= 21) {
    out.add(Insight(
        MascotPose.frost,
        LocalizedText(
          nl: 'De eerste vorst wordt over ongeveer $toFirst dagen verwacht '
              '(${frost.firstFrost}). ${crop.names.nl} overleeft dat niet. '
              'Pluk wat rijp is en dek af of zet binnen.',
          en: 'First frost is expected in about $toFirst days '
              '(${frost.firstFrost}). ${crop.names.en} does not survive it. '
              'Pick what is ripe and cover or move it in.',
        )));
  }
  if (crop.frostTender && toLast > 0 && toLast <= 21) {
    out.add(Insight(
        MascotPose.frost,
        LocalizedText(
          nl: 'De laatste vorst is nog ~$toLast dagen weg (${frost.lastFrost}). '
              'Houd ${crop.names.nl.toLowerCase()} binnen tot na de ijsheiligen.',
          en: 'Last frost is still ~$toLast days away (${frost.lastFrost}). '
              'Keep ${crop.names.en.toLowerCase()} inside until after IJsheiligen.',
        )));
  }
  if (obs != null) {
    final ahead = obs.where((o) => o.date.compareTo(today) >= 0).toList();
    final cold = ahead.where((o) => o.tempMinC <= 2).toList();
    if (cold.isNotEmpty && crop.frostTender) {
      out.add(Insight(
          MascotPose.frost,
          LocalizedText(
            nl: 'Koude nacht op komst: ${cold.first.tempMinC.round()}°C op '
                '${cold.first.date.substring(5)}. Dek af of zet de potten binnen.',
            en: 'Cold night ahead: ${cold.first.tempMinC.round()}°C on '
                '${cold.first.date.substring(5)}. Fleece or bring pots in.',
          )));
    }
    final hot = ahead.where((o) => o.tempMaxC >= 30).toList();
    if (hot.isNotEmpty && potLitres != null) {
      out.add(Insight(
          MascotPose.sun,
          LocalizedText(
            nl: '${hot.first.tempMaxC.round()}°C op '
                '${hot.first.date.substring(5)}: een pot van $potLitres L '
                'droogt in één dag uit. Geef water in de ochtend en zet de pot '
                'in de schaduw als dat kan.',
            en: '${hot.first.tempMaxC.round()}°C on '
                '${hot.first.date.substring(5)}: a $potLitres L pot dries out '
                'in a day. Water in the morning, shade the pot if you can.',
          )));
    }
    final rain = ahead.take(3).fold<num>(0, (s, o) => s + o.precipMm);
    if (rain >= 15) {
      out.add(Insight(
          MascotPose.rain,
          LocalizedText(
            nl: '${rain.round()} mm regen in de komende drie dagen. Sla het '
                'water geven over en controleer de gaatjes in de pot.',
            en: '${rain.round()} mm of rain in the next three days. Skip '
                'watering and check the drainage holes.',
          )));
    }
  }
  return out;
}

class InsightsList extends StatelessWidget {
  const InsightsList({super.key, required this.insights});
  final List<Insight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(Str.insightsForYou.of(context)),
        for (final i in insights)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(child: MascotSays.say(pose: i.pose, size: 40, line: i.text)),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Small helper so the detail screen can colour by pose if it wants to.
Color insightColor(MascotPose p) => switch (p) {
      MascotPose.frost => AppColors.frost,
      MascotPose.sun => AppColors.heat,
      MascotPose.rain => AppColors.rain,
      _ => AppColors.sprout,
    };
