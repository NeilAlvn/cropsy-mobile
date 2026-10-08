/// Insights for you (PRD 5.4): weather-driven cards from the live overlay and
/// frost proximity for the garden. Pure over the repository's last
/// observations + frost profile; nothing invented when there is no data.
library;

import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/mascot_lines.dart';

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
        MascotLines.insightHarvestPastFrost(frost.firstFrost)));
  }
  if (crop.frostTender && toFirst >= 0 && toFirst <= 21) {
    out.add(Insight(
        MascotPose.frost,
        MascotLines.insightFirstFrostSoon(toFirst, frost.firstFrost, crop.names)));
  }
  if (crop.frostTender && toLast > 0 && toLast <= 21) {
    out.add(Insight(
        MascotPose.frost,
        MascotLines.insightLastFrostAhead(toLast, frost.lastFrost, crop.names)));
  }
  if (obs != null) {
    final ahead = obs.where((o) => o.date.compareTo(today) >= 0).toList();
    final cold = ahead.where((o) => o.tempMinC <= 2).toList();
    if (cold.isNotEmpty && crop.frostTender) {
      out.add(Insight(
          MascotPose.frost,
          MascotLines.insightColdNight(
              cold.first.tempMinC.round(), cold.first.date.substring(5))));
    }
    final hot = ahead.where((o) => o.tempMaxC >= 30).toList();
    if (hot.isNotEmpty && potLitres != null) {
      out.add(Insight(
          MascotPose.sun,
          MascotLines.insightHeat(
              hot.first.tempMaxC.round(), hot.first.date.substring(5), potLitres)));
    }
    final rain = ahead.take(3).fold<num>(0, (s, o) => s + o.precipMm);
    if (rain >= 15) {
      out.add(Insight(
          MascotPose.rain,
          MascotLines.insightRain(rain.round())));
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
