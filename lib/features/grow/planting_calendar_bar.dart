/// The planting-calendar bar — Cropsy's take on GrowIt's signature detail, but
/// computed from the real frost-relative engine, so the bands shift with the
/// user's region instead of being a static picture.
///
/// A 12-month chart from the season start (Jan, or Jul in the south) with three lanes — Sow / Plant out / Harvest —
/// each drawn as coloured bands positioned by day-of-season, plus a vertical
/// "today" marker and month labels.
library;

import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';

import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../../timing/engine.dart';
import '../../timing/season_year.dart';
import '../../timing/types.dart';

enum _Lane { sow, plantOut, harvest }

class _Band {
  const _Band(this.lane, this.start, this.end, this.color);
  final _Lane lane;
  final double start; // 0..1 across the year
  final double end;
  final Color color;
}

/// Position on a cyclic 365-day axis, so a band that runs into the next
/// season (garlic: planted Oct, harvested Jul) wraps instead of vanishing.
@visibleForTesting
double calendarFrac(DateTime d, DateTime start) => (d.difference(start).inDays % 365) / 365;

double _frac(DateTime d, DateTime start) => calendarFrac(d, start);

class PlantingCalendarBar extends StatelessWidget {
  const PlantingCalendarBar({
    super.key,
    required this.crop,
    required this.frost,
    required this.today,
  });

  final Crop crop;
  final FrostProfile frost;
  final String today;

  List<_Band> _bands() {
    final start = seasonStart(
      seasonYearOf(today, south: frost.south),
      south: frost.south,
    );
    final windows = scheduleCrop(crop, frost);
    final bands = <_Band>[];
    for (final w in windows) {
      switch (w.method) {
        case MethodType.sowIndoor:
          bands.add(
            _Band(
              _Lane.sow,
              _frac(parseIso(w.start), start),
              _frac(parseIso(w.end), start),
              AppColors.bandSowIndoor,
            ),
          );
        case MethodType.sowDirect:
          bands.add(
            _Band(
              _Lane.sow,
              _frac(parseIso(w.start), start),
              _frac(parseIso(w.end), start),
              AppColors.bandSowOutdoor,
            ),
          );
        case MethodType.transplant:
        case MethodType.plant:
          bands.add(
            _Band(
              _Lane.plantOut,
              _frac(parseIso(w.start), start),
              _frac(parseIso(w.end), start),
              AppColors.bandPlantOut,
            ),
          );
      }
    }
    // Harvest band: from the earliest establishment date + harvest days.
    if (windows.isNotEmpty) {
      final establish = windows
          .map((w) => parseIso(w.start))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final hs = establish.add(Duration(days: crop.harvestDaysMin.toInt()));
      final he = establish.add(Duration(days: crop.harvestDaysMax.toInt()));
      bands.add(
        _Band(
          _Lane.harvest,
          _frac(hs, start),
          _frac(he, start),
          AppColors.bandHarvest,
        ),
      );
    }
    return bands;
  }

  @override
  Widget build(BuildContext context) {
    final bands = _bands();
    final todayFrac = _frac(
      parseIso(today),
      seasonStart(seasonYearOf(today, south: frost.south), south: frost.south),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final lane in _Lane.values) ...[
          _LaneRow(
            label: switch (lane) {
              _Lane.sow => Str.sow,
              _Lane.plantOut => Str.plantOut,
              _Lane.harvest => Str.harvest,
            }.of(context),
            bands: bands.where((b) => b.lane == lane).toList(),
            todayFrac: todayFrac,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 2),
        _MonthAxis(south: frost.south),
        const SizedBox(height: 12),
        _Legend(),
      ],
    );
  }
}

const _labelWidth = 68.0;

class _LaneRow extends StatelessWidget {
  const _LaneRow({
    required this.label,
    required this.bands,
    required this.todayFrac,
  });
  final String label;
  final List<_Band> bands;
  final double todayFrac;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: _labelWidth,
          child: Text(label, style: AppText.caption(context)),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return SizedBox(
                height: 18,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.sand,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    for (final b in bands)
                      Positioned(
                        left: b.start * w,
                        // A wrapped band (end < start) runs to the edge of the axis.
                        width: (((b.end < b.start ? 1.0 : b.end) - b.start) * w).clamp(4.0, w),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: b.color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    Positioned(
                      left: (todayFrac * w).clamp(0.0, w - 2),
                      top: -2,
                      bottom: -2,
                      child: Container(width: 2, color: AppColors.ink),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthAxis extends StatelessWidget {
  const _MonthAxis({required this.south});
  final bool south;
  static const _labels = [
    'J',
    'F',
    'M',
    'A',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: _labelWidth),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < 12; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      _labels[monthAt(i, south: south) - 1],
                      style: AppText.caption(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppText.caption(context)),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        dot(AppColors.bandSowIndoor, Str.sowIndoors.of(context)),
        dot(AppColors.bandSowOutdoor, Str.sowOutdoors.of(context)),
        dot(AppColors.bandPlantOut, Str.plantOut.of(context)),
        dot(AppColors.bandHarvest, Str.harvest.of(context)),
      ],
    );
  }
}
