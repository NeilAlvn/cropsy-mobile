/// The season path (PRD §7.4) in the Duolingo shape: a snake of chunky node
/// buttons down the growing year, over a seasonal landscape.
///
/// The spine is the season, not the week, because the metric this screen exists
/// for is the July cliff: a week-shaped path is empty in August and says so,
/// while a season-shaped one still has October below you. Months with nothing
/// planned carry a suggestion node, so the path never dead-ends.
///
/// The shape of the path — which months appear, where today sits, which month
/// suggests — lives in season_rows.dart and is tested there. This file only
/// draws it.
library;

import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/crop_image.dart';
import '../../design/mascot.dart';
import '../../design/motion.dart';
import '../../design/typography.dart';
import '../../design/widgets.dart';
import '../../timing/dates.dart';
import '../../timing/season.dart';
import '../../timing/types.dart';
import '../garden/garden_repository.dart';
import '../garden/plant_detail_screen.dart';
import '../grow/crop_detail_screen.dart';
import '../repository_scope.dart';
import 'season_rows.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Rows are fixed height, which is what lets the screen open on today without
/// measuring anything.
const double _nodeRow = 132;
const double _headerRow = 96;
const double _todayRow = 52;
const double _badge = 92;

/// Where the badge sits inside its row. The label sits beside it, on the other
/// side of the centre line, so the trail never runs through type.
const double _badgeTop = 14;
const double _badgeCentre = _badgeTop + _badge / 2;

/// How far a node sits from the centre line, in points. Four positions,
/// repeating: the snake reads without needing a curve solver.
double _swing(int i) => switch (i % 4) {
      0 => 0,
      1 => 78,
      2 => 0,
      _ => -78,
    };

/// Which landscape sits behind a month.
String _landscapeFor(int month) => switch (month) {
      3 || 4 || 5 => 'spring',
      6 || 7 || 8 => 'summer',
      9 || 10 || 11 => 'autumn',
      _ => 'winter',
    };

class SeasonScreen extends StatefulWidget {
  const SeasonScreen({super.key});

  @override
  State<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends State<SeasonScreen> {
  final _scroll = ScrollController();
  Future<List<SeasonNode>>? _nodes;
  bool _jumped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nodes ??= RepositoryScope.of(context).seasonNodes();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final today = parseIso(repo.today);

    return Stack(
      children: [
        // Sky, then ground: both sit behind the scroll, so the path moves over
        // a landscape that stays put.
        const Positioned.fill(child: _Sky()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white],
                stops: [0, 0.35],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/landscape/${_landscapeFor(today.month)}.jpg',
                fit: BoxFit.cover,
                height: 200,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: FutureBuilder<List<SeasonNode>>(
            future: _nodes,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }
              final rows = _build(snap.data ?? const [], today, repo);
              if (rows.whereType<_NodeItem>().isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: MascotSays(
                      pose: MascotPose.idle,
                      size: 96,
                      text: 'Add a plant and your season lays itself out here.',
                    ),
                  ),
                );
              }
              _jumpToToday(rows);
              return CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(child: _Crest(today: today, rows: rows)),
                  SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) => rows[i].build(context),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Turns the path's shape into the rows that draw it. Each node is told where
  /// its neighbours sit so the connector between them joins up.
  List<_Item> _build(List<SeasonNode> nodes, DateTime today, GardenRepository repo) {
    final shape = seasonRows(
      nodes: nodes,
      today: today,
      optionsFor: (month) => repo.whatToGrowIn(month).length,
    );

    // Swing per path stop, worked out first so a node can look ahead and back.
    final swings = <int, double>{};
    var stop = 0;
    for (var i = 0; i < shape.length; i++) {
      final kind = shape[i].kind;
      if (kind == SeasonRowKind.node || kind == SeasonRowKind.suggestion) {
        swings[i] = _swing(stop++);
      }
    }
    double? neighbour(int from, int step) {
      for (var i = from + step; i >= 0 && i < shape.length; i += step) {
        if (swings.containsKey(i)) return swings[i];
        // A month header or the today line breaks the path; the line should
        // stop there rather than reach across the gap.
        if (shape[i].kind != SeasonRowKind.node &&
            shape[i].kind != SeasonRowKind.suggestion) {
          return null;
        }
      }
      return null;
    }

    final rows = <_Item>[];
    for (var i = 0; i < shape.length; i++) {
      final row = shape[i];
      switch (row.kind) {
        case SeasonRowKind.month:
          rows.add(_HeaderItem(
            month: row.month,
            current: row.current,
            repo: repo,
          ));
        case SeasonRowKind.today:
          rows.add(const _TodayItem());
        case SeasonRowKind.node:
          rows.add(_NodeItem(
            node: row.node!,
            today: today,
            repo: repo,
            swing: swings[i]!,
            above: neighbour(i, -1),
            below: neighbour(i, 1),
          ));
        case SeasonRowKind.suggestion:
          rows.add(_SuggestionItem(
            month: row.month,
            count: row.count,
            repo: repo,
            swing: swings[i]!,
            above: neighbour(i, -1),
            below: neighbour(i, 1),
          ));
      }
    }
    return rows;
  }

  void _jumpToToday(List<_Item> rows) {
    if (_jumped) return;
    _jumped = true;
    final index = rows.indexWhere((r) => r is _TodayItem);
    if (index < 0) return;
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += rows[i].height;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo((offset - 120).clamp(0, _scroll.position.maxScrollExtent));
    });
  }
}

/// The ground the path runs over: canvas at the top, warming into the accent as
/// it falls, which is the atmosphere the base allows on one surface (3.5).
class _Sky extends StatelessWidget {
  const _Sky();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.canvas, Color(0xFFF6EFE9), Color(0xFFEDF2E4)],
            stops: [0, 0.55, 1],
          ),
        ),
      );
}

// ── rows ────────────────────────────────────────────────────────────────────

abstract class _Item {
  double get height;
  Widget build(BuildContext context);
}

/// The month bar, the path's equivalent of Duolingo's unit header.
class _HeaderItem implements _Item {
  const _HeaderItem({required this.month, required this.current, required this.repo});

  final int month;
  final bool current;
  final GardenRepository repo;

  @override
  double get height => _headerRow;

  @override
  Widget build(BuildContext context) {
    final count = repo.whatToGrowIn(month).length;
    return SizedBox(
      height: _headerRow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: current ? AppColors.accent : AppColors.ink,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_months[month - 1],
                        style: AppText.subheading(context, color: AppColors.onInk)),
                    Text(
                      current ? 'You are here' : '$count crops suit this month',
                      style: AppText.caption(context,
                          color: AppColors.onInk.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              Icon(current ? Icons.place : Icons.calendar_month,
                  color: AppColors.onInk.withValues(alpha: 0.9), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayItem implements _Item {
  const _TodayItem();

  @override
  double get height => _todayRow;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _todayRow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              const Expanded(child: Divider(color: AppColors.hairline, thickness: 2)),
              const SizedBox(width: 12),
              Text('Today', style: AppText.kicker(context, color: AppColors.inkMuted)),
              const SizedBox(width: 12),
              const Expanded(child: Divider(color: AppColors.hairline, thickness: 2)),
            ],
          ),
        ),
      );
}

enum _State { done, now, ahead }

/// Badge art per node kind, for the kinds the season path shows.
String _badgeFor(SeasonNode node) => switch (node.kind) {
      SeasonNodeKind.sowWindow => 'sow',
      SeasonNodeKind.harvestWindow => 'harvest',
      SeasonNodeKind.succession => 'transplant',
    };

class _NodeItem implements _Item {
  const _NodeItem({
    required this.node,
    required this.today,
    required this.repo,
    required this.swing,
    required this.above,
    required this.below,
  });

  final SeasonNode node;
  final DateTime today;
  final GardenRepository repo;
  final double swing;
  final double? above;
  final double? below;

  @override
  double get height => _nodeRow;

  _State get state {
    if (parseIso(node.end).isBefore(today)) return _State.done;
    if (!parseIso(node.start).isAfter(today)) return _State.now;
    return _State.ahead;
  }

  String get _label => switch (node.kind) {
        SeasonNodeKind.sowWindow => 'Sow ${repo.cropName(node.cropSlug)}',
        SeasonNodeKind.harvestWindow => 'Harvest ${repo.cropName(node.cropSlug)}',
        SeasonNodeKind.succession => 'Follow on: ${repo.cropName(node.cropSlug)}',
      };

  @override
  Widget build(BuildContext context) => _PathStop(
        swing: swing,
        above: above,
        below: below,
        state: state,
        label: _label,
        caption: _window(node.start, node.end),
        badge: 'assets/nodes/${_badgeFor(node)}.png',
        corner: CropImage(
          slug: node.cropSlug,
          category: repo.cropCategory(node.cropSlug),
        ),
        onTap: () {
          final plantId = node.plantId;
          if (plantId != null && node.kind != SeasonNodeKind.succession) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlantDetailScreen(plantId: plantId)));
            return;
          }
          final crop = repo.cropBySlug(node.cropSlug);
          if (crop != null) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop)));
          }
        },
      );
}

/// A future month with nothing planned. The point of the season spine: never a
/// dead end, always something that could still go in.
class _SuggestionItem implements _Item {
  const _SuggestionItem({
    required this.month,
    required this.count,
    required this.repo,
    required this.swing,
    required this.above,
    required this.below,
  });

  final int month;
  final int count;
  final GardenRepository repo;
  final double swing;
  final double? above;
  final double? below;

  @override
  double get height => _nodeRow;

  @override
  Widget build(BuildContext context) => _PathStop(
        swing: swing,
        above: above,
        below: below,
        state: _State.ahead,
        chest: true,
        label: '$count crops can still go in',
        caption: 'Nothing planned for ${_months[month - 1]}',
        badge: 'assets/nodes/chest.png',
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (context) =>
              _MonthOptions(month: month, crops: repo.whatToGrowIn(month)),
        ),
      );
}

/// One stop on the path: the connector, the button, and its label.
class _PathStop extends StatelessWidget {
  const _PathStop({
    required this.swing,
    required this.above,
    required this.below,
    required this.state,
    required this.label,
    required this.caption,
    required this.badge,
    required this.onTap,
    this.corner,
    this.chest = false,
  });

  final double swing;
  final double? above;
  final double? below;
  final _State state;
  final String label;
  final String caption;
  final String badge;
  final VoidCallback onTap;
  final Widget? corner;
  final bool chest;

  @override
  Widget build(BuildContext context) {
    final art = Image.asset(badge, width: _badge, height: _badge, excludeFromSemantics: true);
    // The label takes the half the node is not in, so a swung node and its text
    // never fight, and the trail down the middle stays clear.
    final labelLeft = swing >= 0;

    return SizedBox(
      height: _nodeRow,
      child: CustomPaint(
        painter: _TrailPainter(
          swing: swing,
          above: above,
          below: below,
          dashed: state != _State.done,
        ),
        child: Stack(
          children: [
            Align(
              alignment: labelLeft ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.46,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        labelLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                    children: [
                      if (state == _State.now) ...[
                        _NowBubble(label: label),
                        const SizedBox(height: 4),
                      ] else
                        Text(
                          label,
                          textAlign: labelLeft ? TextAlign.left : TextAlign.right,
                          style: AppText.label(context,
                              color: state == _State.done
                                  ? AppColors.inkMuted
                                  : AppColors.ink),
                          maxLines: 2,
                        ),
                      Text(
                        caption,
                        textAlign: labelLeft ? TextAlign.left : TextAlign.right,
                        style: AppText.caption(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: _badgeTop),
                child: Transform.translate(
                  offset: Offset(swing, 0),
                  child: Pressable(
                    onTap: onTap,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Opacity(opacity: state == _State.done ? 0.75 : 1, child: art),
                        if (state == _State.done)
                          Positioned(
                            right: -2,
                            bottom: 4,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.positive,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  size: 18, color: AppColors.onSemantic),
                            ),
                          ),
                        if (corner != null)
                          Positioned(
                            left: -6,
                            top: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surface,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: ClipOval(child: corner),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The label on the node that is open now, the way Duolingo bubbles "Start".
class _NowBubble extends StatelessWidget {
  const _NowBubble({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: Text(label,
                style: AppText.label(context, color: AppColors.accent),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      );
}

/// The trail between stops: half a segment up to the previous node, half down
/// to the next, so no row needs to own the whole path.
class _TrailPainter extends CustomPainter {
  const _TrailPainter({
    required this.swing,
    required this.above,
    required this.below,
    required this.dashed,
  });

  final double swing;
  final double? above;
  final double? below;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.12)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final centre = Offset(size.width / 2 + swing, _badgeCentre);
    // The badge's own height, so the trail meets its edge rather than its centre.
    const radius = _badge / 2 + 2;

    // The neighbours' badges sit at the same height inside their own rows, so
    // the trail leaves this row's top and bottom edges aimed straight at them.
    if (above != null) {
      _segment(canvas, paint, Offset(size.width / 2 + above!, _badgeCentre - _nodeRow),
          Offset(centre.dx, centre.dy - radius));
    }
    if (below != null) {
      _segment(canvas, paint, Offset(centre.dx, centre.dy + radius),
          Offset(size.width / 2 + below!, _badgeCentre + _nodeRow));
    }
  }

  void _segment(Canvas canvas, Paint paint, Offset a, Offset b) {
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(a.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, (d + 10).clamp(0, metric.length)), paint);
        d += 20;
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.swing != swing || old.above != above || old.below != below || old.dashed != dashed;
}

/// The season's header: where the year stands, above the first stop.
class _Crest extends StatelessWidget {
  const _Crest({required this.today, required this.rows});

  final DateTime today;
  final List<_Item> rows;

  @override
  Widget build(BuildContext context) {
    final nodes = rows.whereType<_NodeItem>().toList();
    final open = nodes.where((n) => n.state == _State.now).length;
    final done = nodes.where((n) => n.state == _State.done).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Season', style: AppText.kicker(context)),
          Text('${today.year} in your garden', style: AppText.title(context)),
          const SizedBox(height: 4),
          Text(
            open > 0 ? '$open open now · $done done' : '$done done · nothing open today',
            style: AppText.bodyMuted(context),
          ),
        ],
      ),
    );
  }
}

/// What could still go in this month. Base 8.13: a sheet, not a screen, because
/// it is a detour from the path rather than a place.
class _MonthOptions extends StatelessWidget {
  const _MonthOptions({required this.month, required this.crops});

  final int month;
  final List<Crop> crops;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Still sowable in ${_months[month - 1]}',
                  style: AppText.heading(context)),
              const SizedBox(height: 4),
              Text('${crops.length} crops for your region.',
                  style: AppText.bodyMuted(context)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: crops.length,
                  itemBuilder: (context, i) => PhotoCard(
                    crop: crops[i],
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CropDetailScreen(crop: crops[i]))),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

String _window(String start, String end) {
  final s = parseIso(start);
  final e = parseIso(end);
  String fmt(DateTime d) => '${d.day} ${_months[d.month - 1].substring(0, 3)}';
  return start == end ? fmt(s) : '${fmt(s)} – ${fmt(e)}';
}
