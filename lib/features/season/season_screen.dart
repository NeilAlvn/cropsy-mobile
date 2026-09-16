/// The season path (PRD §7.4, the Duolingo shape): one vertical path down the
/// growing year, months as sections, today marked, every node a real moment in
/// this garden.
///
/// The spine is the season, not the week, because the metric this screen exists
/// for is the July cliff: in August a week-shaped path is empty and says so,
/// while a season-shaped one still shows what is coming. Months with nothing
/// planned carry a suggestion node drawn from the catalogue for that month, so
/// the path never dead-ends.
///
/// Tapping a plant's node drops into that plant's own path, which is the
/// per-plant view in §7.1.
library;

import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
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

/// One row of the path. Every row is the same height, which is what lets the
/// screen jump to today without measuring anything.
const double _rowHeight = 112;
const double _nodeSize = 72;
const double _headerHeight = 64;

/// Width of the column the node sits in. The node swings inside this column, so
/// a node can never clip the screen edge or slide under its own label.
const double _nodeColumn = 124;

/// Where the node sits inside its column, -1 to 1. The path reads as a snake,
/// the way Duolingo's does, without needing a curve solver: four positions.
double _swing(int i) => switch (i % 4) {
      0 => 0,
      1 => 1,
      2 => 0,
      _ => -1,
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

    return SafeArea(
      bottom: false,
      child: FutureBuilder<List<SeasonNode>>(
        future: _nodes,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          final rows = _build(snap.data ?? const [], today, repo);
          if (rows.whereType<_NodeRow>().isEmpty) {
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
              SliverToBoxAdapter(child: _Header(today: today, rows: rows)),
              SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, i) => rows[i].build(context),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  /// Turns the path's shape (see season_rows.dart) into the rows that draw it.
  List<_Row> _build(List<SeasonNode> nodes, DateTime today, GardenRepository repo) {
    final shape = seasonRows(
      nodes: nodes,
      today: today,
      optionsFor: (month) => repo.whatToGrowIn(month).length,
    );
    final rows = <_Row>[];
    var swing = 0;
    for (final row in shape) {
      switch (row.kind) {
        case SeasonRowKind.month:
          rows.add(_MonthRow(month: row.month, current: row.current));
        case SeasonRowKind.today:
          rows.add(_TodayRow(today));
        case SeasonRowKind.node:
          rows.add(_NodeRow(
              node: row.node!, today: today, swing: _swing(swing++), repo: repo));
        case SeasonRowKind.suggestion:
          rows.add(_SuggestionRow(
              month: row.month,
              count: row.count,
              swing: _swing(swing++),
              repo: repo));
      }
    }
    return rows;
  }

  /// Opens on today. Rows are fixed height, so the offset is arithmetic.
  void _jumpToToday(List<_Row> rows) {
    if (_jumped) return;
    _jumped = true;
    final index = rows.indexWhere((r) => r is _TodayRow);
    if (index < 0) return;
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += rows[i].height;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
    });
  }
}

// ── rows ────────────────────────────────────────────────────────────────────

abstract class _Row {
  double get height;
  Widget build(BuildContext context);
}

class _MonthRow implements _Row {
  const _MonthRow({required this.month, required this.current});

  final int month;
  final bool current;

  @override
  double get height => _headerHeight;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _headerHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Text(_months[month - 1],
                  style: AppText.heading(context,
                      color: current ? AppColors.accent : AppColors.ink)),
              const SizedBox(width: 12),
              const Expanded(child: Divider(color: AppColors.hairline, height: 1)),
            ],
          ),
        ),
      );
}

class _TodayRow implements _Row {
  const _TodayRow(this.today);

  final DateTime today;

  @override
  double get height => 44;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Text('Today', style: AppText.kicker(context, color: AppColors.onInk)),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Divider(color: AppColors.ink, height: 1)),
            ],
          ),
        ),
      );
}

enum _NodeState { past, now, ahead }

class _NodeRow implements _Row {
  _NodeRow({required this.node, required this.today, required this.swing, required this.repo});

  final SeasonNode node;
  final DateTime today;
  final double swing;
  final GardenRepository repo;

  @override
  double get height => _rowHeight;

  _NodeState get state {
    final start = parseIso(node.start);
    final end = parseIso(node.end);
    if (end.isBefore(today)) return _NodeState.past;
    if (!start.isAfter(today)) return _NodeState.now;
    return _NodeState.ahead;
  }

  String get _title => switch (node.kind) {
        SeasonNodeKind.sowWindow => 'Sow ${repo.cropName(node.cropSlug)}',
        SeasonNodeKind.harvestWindow => 'Harvest ${repo.cropName(node.cropSlug)}',
        SeasonNodeKind.succession => 'Follow on with ${repo.cropName(node.cropSlug)}',
      };

  @override
  Widget build(BuildContext context) => _PathRow(
        swing: swing,
        state: state,
        title: _title,
        subtitle: _window(node.start, node.end),
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
        art: CropImage(
          slug: node.cropSlug,
          category: repo.cropCategory(node.cropSlug),
        ),
      );
}

/// A future month with nothing planned. The point of the season spine: never a
/// dead end, always something that could still go in.
class _SuggestionRow implements _Row {
  const _SuggestionRow({
    required this.month,
    required this.count,
    required this.swing,
    required this.repo,
  });

  final int month;
  final int count;
  final double swing;
  final GardenRepository repo;

  @override
  double get height => _rowHeight;

  @override
  Widget build(BuildContext context) => _PathRow(
        swing: swing,
        state: _NodeState.ahead,
        ghost: true,
        title: '$count crops can still go in',
        subtitle: 'Nothing planned for ${_months[month - 1]} yet',
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (context) => _MonthOptions(month: month, crops: repo.whatToGrowIn(month)),
        ),
        art: const Mascot(MascotPose.pointing, size: _nodeSize),
      );
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

/// The node itself: a circle on the path, with its label beside it.
class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.swing,
    required this.state,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.art,
    this.ghost = false,
  });

  final double swing;
  final _NodeState state;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget art;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final ringColor = switch (state) {
      _NodeState.past => AppColors.hairline,
      _NodeState.now => AppColors.accent,
      _NodeState.ahead => AppColors.hairline,
    };
    return SizedBox(
      height: _rowHeight,
      child: Pressable(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              SizedBox(
                width: _nodeColumn,
                height: _rowHeight,
                child: CustomPaint(
                  painter: _ConnectorPainter(swing: swing, dashed: state == _NodeState.ahead),
                  child: Align(
                    alignment: Alignment(swing, 0),
                    child: Container(
                      width: _nodeSize,
                      height: _nodeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tile,
                        border: Border.all(
                            color: ringColor, width: state == _NodeState.now ? 3 : 1),
                      ),
                      child: ClipOval(
                        child: Opacity(
                          opacity: state == _NodeState.past || ghost ? 0.55 : 1,
                          child: art,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: AppText.subheading(context,
                            color: state == _NodeState.past
                                ? AppColors.inkMuted
                                : AppColors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppText.caption(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (state == _NodeState.now)
                Pill(
                  label: 'Now',
                  color: AppColors.onAccentSoft,
                  bg: AppColors.accentSoft,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.today, required this.rows});

  final DateTime today;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final nodes = rows.whereType<_NodeRow>().toList();
    final now = nodes.where((n) => n.state == _NodeState.now).length;
    final done = nodes.where((n) => n.state == _NodeState.past).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Season', style: AppText.kicker(context)),
          const SizedBox(height: 4),
          Text('${today.year} in your garden', style: AppText.title(context)),
          const SizedBox(height: 6),
          Text(
            now > 0
                ? '$now open now, $done behind you.'
                : '$done behind you. Nothing open today.',
            style: AppText.bodyMuted(context),
          ),
        ],
      ),
    );
  }
}

String _window(String start, String end) {
  final s = parseIso(start);
  final e = parseIso(end);
  String fmt(DateTime d) => '${d.day} ${_months[d.month - 1].substring(0, 3)}';
  return start == end ? fmt(s) : '${fmt(s)} – ${fmt(e)}';
}


/// The line between nodes. Each row draws its own half-segments, up and down
/// from its node, so no row needs to know about its neighbours.
class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({required this.swing, required this.dashed});

  final double swing;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hairline
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final x = size.width / 2 + swing * (size.width - _nodeSize) / 2;
    final top = Offset(x, 0);
    final nodeTop = Offset(x, size.height / 2 - _nodeSize / 2);
    final nodeBottom = Offset(x, size.height / 2 + _nodeSize / 2);
    final bottom = Offset(x, size.height);
    if (dashed) {
      _dash(canvas, paint, top, nodeTop);
      _dash(canvas, paint, nodeBottom, bottom);
    } else {
      canvas.drawLine(top, nodeTop, paint);
      canvas.drawLine(nodeBottom, bottom, paint);
    }
  }

  void _dash(Canvas canvas, Paint paint, Offset a, Offset b) {
    const dash = 5.0, gap = 5.0;
    final total = (b - a).distance;
    for (var d = 0.0; d < total; d += dash + gap) {
      final t1 = d / total;
      final t2 = ((d + dash) / total).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset.lerp(a, b, t1)!,
        Offset.lerp(a, b, t2)!,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.swing != swing || old.dashed != dashed;
}
