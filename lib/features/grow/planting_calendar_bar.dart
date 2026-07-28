/// The planting-calendar bar — Cropsy's take on GrowIt's signature detail, but
/// computed from the real frost-relative engine, so the bands shift with the
/// user's region instead of being a static picture.
///
/// A 12-month (Jan→Dec) chart with three lanes — Sow / Plant out / Harvest —
/// each drawn as coloured bands positioned by day-of-year, plus a vertical
/// "today" marker and month labels.
library;

import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/typography.dart';
import '../../timing/dates.dart';
import '../../timing/engine.dart';
import '../../timing/types.dart';

enum _Lane { sow, plantOut, harvest }

class _Band {
  const _Band(this.lane, this.start, this.end, this.color);
  final _Lane lane;
  final double start; // 0..1 across the year
  final double end;
  final Color color;
}

double _dayFrac(String iso) {
  final d = parseIso(iso);
  final jan1 = DateTime.utc(d.year, 1, 1);
  final doy = d.difference(jan1).inDays;
  return (doy / 365).clamp(0.0, 1.0);
}

double _dayFracFromDate(DateTime d) {
  final jan1 = DateTime.utc(d.year, 1, 1);
  return (d.difference(jan1).inDays / 365).clamp(0.0, 1.0);
}

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
    final windows = scheduleCrop(crop, frost);
    final bands = <_Band>[];
    for (final w in windows) {
      switch (w.method) {
        case MethodType.sowIndoor:
          bands.add(_Band(_Lane.sow, _dayFrac(w.start), _dayFrac(w.end),
              AppColors.bandSowIndoor));
        case MethodType.sowDirect:
          bands.add(_Band(_Lane.sow, _dayFrac(w.start), _dayFrac(w.end),
              AppColors.bandSowOutdoor));
        case MethodType.transplant:
        case MethodType.plant:
          bands.add(_Band(_Lane.plantOut, _dayFrac(w.start), _dayFrac(w.end),
              AppColors.bandPlantOut));
      }
    }
    // Harvest band: from the earliest establishment date + harvest days.
    if (windows.isNotEmpty) {
      final establish = windows
          .map((w) => parseIso(w.start))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final hs = establish.add(Duration(days: crop.harvestDaysMin.toInt()));
      final he = establish.add(Duration(days: crop.harvestDaysMax.toInt()));
      bands.add(_Band(_Lane.harvest, _dayFracFromDate(hs), _dayFracFromDate(he),
          AppColors.bandHarvest));
    }
    return bands;
  }

  @override
  Widget build(BuildContext context) {
    final bands = _bands();
    final todayFrac = _dayFrac(today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final lane in _Lane.values) ...[
          _LaneRow(
            label: switch (lane) {
              _Lane.sow => 'Sow',
              _Lane.plantOut => 'Plant out',
              _Lane.harvest => 'Harvest',
            },
            bands: bands.where((b) => b.lane == lane).toList(),
            todayFrac: todayFrac,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 2),
        const _MonthAxis(),
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
          child: LayoutBuilder(builder: (context, c) {
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
                      width: ((b.end - b.start) * w).clamp(4.0, w),
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
          }),
        ),
      ],
    );
  }
}

class _MonthAxis extends StatelessWidget {
  const _MonthAxis();
  static const _labels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: _labelWidth),
        Expanded(
          child: Row(
            children: [
              for (final m in _labels)
                Expanded(
                  child: Center(
                    child: Text(m, style: AppText.caption(context)),
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
                  color: c, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 5),
            Text(label, style: AppText.caption(context)),
          ],
        );
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        dot(AppColors.bandSowIndoor, 'Sow indoors'),
        dot(AppColors.bandSowOutdoor, 'Sow outdoors'),
        dot(AppColors.bandPlantOut, 'Plant out'),
        dot(AppColors.bandHarvest, 'Harvest'),
      ],
    );
  }
}
