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
import '../../l10n/mascot_lines.dart';
import '../../design/icons.dart';

import '../../design/colors.dart';
import '../../db/database.dart';
import '../../design/components.dart';
import '../../design/crop_image.dart';
import '../../design/mascot.dart';
import '../../design/motion.dart';
import '../../design/typography.dart';
import '../../design/widgets.dart';
import '../../timing/dates.dart';
import '../../timing/replan.dart';
import '../../timing/season.dart';
import '../../timing/types.dart';
import '../../timing/weather_adjust.dart';
import '../garden/garden_repository.dart';
import '../garden/growth_log_sheet.dart';
import '../garden/log_node_flow.dart';
import '../garden/plant_detail_screen.dart';
import '../grow/crop_detail_screen.dart';
import '../harvest/harvest_screen.dart';
import '../repository_scope.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import 'season_rows.dart';
import 'season_markers.dart';

/// Rows are fixed height, which is what lets the screen open on today without
/// measuring anything.
const double _nodeRow = 132;
const double _headerRow = 128;
const double _todayRow = 52;
const double _badge = 92;

/// The month marker, smaller than a task node so the path still reads as tasks.
const double _monthDisc = 60;
const double _monthTop = 16;
const double _monthCentre = _monthTop + _monthDisc / 2;

/// Where the badge sits inside its row. The label sits beside it, on the other
/// side of the centre line, so the trail never runs through type.
const double _badgeTop = 14;
const double _badgeCentre = _badgeTop + _badge / 2;

/// Where a stop sits across the row, -1 (left edge) to 1 (right edge). Four
/// positions, repeating: the snake reads without needing a curve solver.
///
/// This is an alignment, not a translation. A `Transform` would move the paint
/// and leave the hit box behind, so a swung node would be tappable nowhere.
double _swing(int i) => switch (i % 4) {
      0 => 0,
      1 => 0.5,
      2 => 0,
      _ => -0.5,
    };

/// Where a stop's centre lands, given the row's width and the stop's size.
double _centreX(double width, double swing, double stop) =>
    width / 2 + swing * (width - stop) / 2;

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
  Future<
      ({
        List<SeasonNode> nodes,
        List<SeasonMarker> markers,
        List<SeasonTask> tasks,
        Set<String> logged,
        int streak
      })>? _data;
  bool _jumped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= _load();
  }

  /// The path is the plants' own nodes plus everything the season itself puts
  /// on it: frost dates, the seed order, the photo, the payoff, the recap and
  /// whatever the weather changed today.
  Future<
      ({
        List<SeasonNode> nodes,
        List<SeasonMarker> markers,
        List<SeasonTask> tasks,
        Set<String> logged,
        int streak
      })> _load() async {
    final repo = RepositoryScope.of(context);
    final premium = PurchaseScope.maybeOf(context)?.premium ?? false;
    final today = parseIso(repo.today);
    final nodes = await repo.seasonNodes();
    final plants = await repo.plants();
    final tally = await repo.seasonTally();

    // A node is done when the gardener logged it, not when its date passed.
    final logged = <String>{};
    for (final plant in plants) {
      for (final node in await repo.pathFor(plant.id)) {
        if (node.loggedOn != null) logged.add('${plant.id}:${node.kind.name}');
      }
    }

    // One photo a month is the ask, so the marker only appears when this month
    // has none yet.
    final stamp = repo.today.substring(0, 7);
    var photoThisMonth = false;
    for (final plant in plants) {
      for (final entry in await repo.journal(plant.id)) {
        if (entry.photoPath != null && entry.entryOn.startsWith(stamp)) {
          photoThisMonth = true;
          break;
        }
      }
      if (photoThisMonth) break;
    }

    // The weather overlay already runs for This Week; the path shows the same
    // change, so the two never disagree.
    LocalizedText? weatherTitle, weatherCaption;
    for (final item in await repo.thisWeek()) {
      final hint = item.hint;
      if (hint == null || hint.action == AdjustAction.none) continue;
      (weatherTitle, weatherCaption) = switch (hint.action) {
        AdjustAction.skip => (Str.rainDidIt, Str.rainDidItSub),
        AdjustAction.bringForward => (Str.heatComing, Str.heatComingSub),
        AdjustAction.defer => (Str.soilCold, Str.soilColdSub),
        AdjustAction.none => (null, null),
      };
      break;
    }

    final markers = seasonMarkers(MarkerFacts(
      today: today,
      frost: repo.frost,
      plantCount: plants.length,
      photoThisMonth: photoThisMonth,
      euros: tally.euros,
      kilos: tally.kg,
      weatherTitle: weatherTitle,
      weatherCaption: weatherCaption,
    ));
    final tasks = [
      for (final t in await repo.seasonTasks())
        SeasonTask(
          nodeId: t.node.id,
          plantId: t.plantId,
          cropSlug: t.cropSlug,
          kind: switch (t.node.kind) {
            NodeKind.potOn => 'pot_on',
            NodeKind.transplant => 'transplant',
            NodeKind.thin => 'thin',
            NodeKind.feed => 'feed',
            _ => 'sow',
          },
          due: t.node.due,
          title: Str.stepOnCrop(
            nodeKindLine(t.node.kind),
            repo.cropBySlug(t.cropSlug)?.names ??
                LocalizedText(nl: t.cropSlug, en: t.cropSlug),
          ),
        ),
    ];

    final streak = await repo.streak(premium: premium);

    return (
      nodes: nodes,
      markers: markers,
      tasks: tasks,
      logged: logged,
      streak: streak.count,
    );
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
              child: ColorFiltered(
                // The ground art is painted for daylight. At night it sits
                // under the same dimming the rest of the scheme gets, rather
                // than glowing at the foot of a dark screen.
                colorFilter: ColorFilter.mode(
                  AppColors.canvas.withValues(alpha: AppColors.isDark ? 0.55 : 0),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/landscape/${_landscapeFor(today.month)}.jpg',
                  fit: BoxFit.cover,
                  height: 200,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: FutureBuilder<
              ({
                List<SeasonNode> nodes,
                List<SeasonMarker> markers,
                List<SeasonTask> tasks,
                Set<String> logged,
                int streak
              })>(
            future: _data,
            builder: (context, snap) {
              final data = snap.data;
              if (data == null) return const SizedBox.shrink();
              final rows =
                  _build(data.nodes, data.markers, data.tasks, data.logged, today, repo);
              if (data.nodes.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: MascotSays.say(
                      pose: MascotPose.idle,
                      size: 96,
                      line: MascotLines.seasonEmpty,
                    ),
                  ),
                );
              }
              _jumpToToday(rows);
              return CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(
                    child: _Crest(today: today, rows: rows, streak: data.streak),
                  ),
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
  List<_Item> _build(List<SeasonNode> nodes, List<SeasonMarker> markers,
      List<SeasonTask> tasks, Set<String> logged, DateTime today, GardenRepository repo) {
    final shape = seasonRows(
      nodes: nodes,
      today: today,
      optionsFor: (month) => repo.whatToGrowIn(month).length,
      markers: markers,
      tasks: tasks,
    );

    // Swing per path stop, worked out first so a stop can look ahead and back.
    // A month marker sits on the centre line and restarts the snake under it.
    final swings = <int, double>{};
    var stop = 0;
    for (var i = 0; i < shape.length; i++) {
      switch (shape[i].kind) {
        case SeasonRowKind.month:
          swings[i] = 0;
          stop = 1;
        case SeasonRowKind.node:
        case SeasonRowKind.marker:
        case SeasonRowKind.task:
        case SeasonRowKind.suggestion:
          swings[i] = _swing(stop++);
        case SeasonRowKind.today:
          break;
      }
    }
    // The today line is a divider, not a stop: the trail runs behind it.
    double? neighbour(int from, int step) {
      for (var i = from + step; i >= 0 && i < shape.length; i += step) {
        if (swings.containsKey(i)) return swings[i];
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
            above: neighbour(i, -1),
            below: neighbour(i, 1),
          ));
        case SeasonRowKind.today:
          rows.add(const _TodayItem());
        case SeasonRowKind.node:
          rows.add(_NodeItem(
            node: row.node!,
            today: today,
            repo: repo,
            logged: logged,
            onChanged: _reload,
            swing: swings[i]!,
            above: neighbour(i, -1),
            below: neighbour(i, 1),
          ));
        case SeasonRowKind.task:
          rows.add(_TaskItem(
            task: row.task!,
            today: today,
            repo: repo,
            onChanged: _reload,
            swing: swings[i]!,
            above: neighbour(i, -1),
            below: neighbour(i, 1),
          ));
        case SeasonRowKind.marker:
          rows.add(_MarkerItem(
            marker: row.marker!,
            today: today,
            repo: repo,
            onChanged: _reload,
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

  /// After a log, the path's states and every downstream date can have moved,
  /// so it is rebuilt from the repository rather than patched in place.
  Future<void> _reload() async {
    if (!mounted) return;
    // Load first, swap after: the path keeps its current shape until the new
    // one is ready, rather than blanking for a frame.
    final next = _load();
    await next;
    if (!mounted) return;
    setState(() {
      _data = next;
      // Already where the gardener was; do not yank the scroll back to today.
      _jumped = true;
    });
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
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.skyTop, AppColors.skyMid, AppColors.canvas],
            stops: [0, 0.45, 1],
          ),
        ),
      );
}

// ── rows ────────────────────────────────────────────────────────────────────

abstract class _Item {
  double get height;
  Widget build(BuildContext context);
}

/// The month marker: a stop on the path like any other, but a different shape
/// and colour, so a month reads as a milestone rather than as another task.
class _HeaderItem implements _Item {
  const _HeaderItem({
    required this.month,
    required this.current,
    required this.repo,
    required this.above,
    required this.below,
  });

  final int month;
  final bool current;
  final GardenRepository repo;
  final double? above;
  final double? below;

  @override
  double get height => _headerRow;

  @override
  Widget build(BuildContext context) {
    final count = repo.whatToGrowIn(month).length;
    return SizedBox(
      height: _headerRow,
      child: CustomPaint(
        painter: _TrailPainter(
          swing: 0,
          above: above,
          below: below,
          dashed: !current,
          centre: _monthCentre,
          radius: _monthDisc / 2 + 4,
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(Str.monthTitle(month).of(context),
                          style: AppText.subheading(context),
                          textAlign: TextAlign.right),
                      Text(
                          (current ? Str.youAreHere : Str.cropsSuitMonth(count)).of(context),
                          style: AppText.caption(context),
                          textAlign: TextAlign.right,
                          maxLines: 2),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -1),
              child: Padding(
                padding: const EdgeInsets.only(top: _monthTop),
                child: _MonthDisc(month: month, current: current),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amber, not green: the months are the path's own markers, and colouring them
/// like the task nodes would make the year read as more things to do.
class _MonthDisc extends StatelessWidget {
  const _MonthDisc({required this.month, required this.current});

  final int month;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final face = current ? AppColors.amber : AppColors.amberSoft;
    final rim = current ? AppColors.amberDeep : AppColors.amber;
    return Container(
      width: _monthDisc,
      height: _monthDisc,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: face,
        // The raised rim the node buttons have, drawn rather than rendered.
        border: Border.all(color: rim, width: 3),
        boxShadow: [
          BoxShadow(color: rim, offset: const Offset(0, 4), blurRadius: 0),
        ],
      ),
      child: Text(
        Str.monthShort(month).of(context),
        style: AppText.kicker(context,
            color: current ? AppColors.onAmber : AppColors.amberDeep),
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
              Expanded(child: Divider(color: AppColors.hairline, thickness: 2)),
              const SizedBox(width: 12),
              Text(Str.today.of(context),
                  style: AppText.kicker(context, color: AppColors.inkMuted)),
              const SizedBox(width: 12),
              Expanded(child: Divider(color: AppColors.hairline, thickness: 2)),
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
    required this.logged,
    required this.onChanged,
    required this.swing,
    required this.above,
    required this.below,
  });

  final SeasonNode node;
  final DateTime today;
  final GardenRepository repo;

  /// `plantId:nodeKind` for everything the gardener has logged.
  final Set<String> logged;

  /// Called when a log changed the plan.
  final VoidCallback onChanged;
  final double swing;
  final double? above;
  final double? below;

  @override
  double get height => _nodeRow;

  _State get state {
    if (_isLogged) return _State.done;
    // A window that has passed unlogged is not a failure, and the base bans
    // "overdue" anywhere (PRD §7.2), so it simply reads as no longer open.
    if (parseIso(node.end).isBefore(today)) return _State.ahead;
    if (!parseIso(node.start).isAfter(today)) return _State.now;
    return _State.ahead;
  }

  bool get _isLogged {
    final plantId = node.plantId;
    if (plantId == null) return false;
    return switch (node.kind) {
      SeasonNodeKind.sowWindow => logged.contains('$plantId:sow'),
      SeasonNodeKind.harvestWindow => logged.contains('$plantId:harvest') ||
          logged.contains('$plantId:harvested'),
      SeasonNodeKind.succession => false,
    };
  }

  LocalizedText _label(BuildContext context) => switch (node.kind) {
        SeasonNodeKind.sowWindow => Str.sowCrop(_crop(context)),
        SeasonNodeKind.harvestWindow => Str.harvestCrop(_crop(context)),
        SeasonNodeKind.succession => Str.followOn(_crop(context)),
      };

  /// The crop's own name, which the snapshot carries in both languages.
  LocalizedText _crop(BuildContext context) =>
      repo.cropBySlug(node.cropSlug)?.names ??
      LocalizedText(nl: node.cropSlug, en: node.cropSlug);

  @override
  Widget build(BuildContext context) => _PathStop(
        swing: swing,
        above: above,
        below: below,
        state: state,
        label: _label(context).of(context),
        caption: _window(node.start, node.end, context),
        badge: 'assets/nodes/${_badgeFor(node)}.png',
        corner: CropImage(
          slug: node.cropSlug,
          category: repo.cropCategory(node.cropSlug),
        ),
        onTap: () => _open(context),
      );
}

extension on _NodeItem {
  /// A node the gardener can act on opens its log sheet, so the path is where
  /// the work is recorded rather than a table of contents for other screens.
  Future<void> _open(BuildContext context) async {
    if (node.kind == SeasonNodeKind.succession) return _planIt(context);

    final plantId = node.plantId;
    if (plantId == null) {
      final crop = repo.cropBySlug(node.cropSlug);
      if (crop != null && context.mounted) {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop)));
      }
      return;
    }

    final task = await _taskFor(plantId);
    if (!context.mounted) return;
    if (task == null) {
      // Nothing loggable: the plant is still being planned, so its own screen
      // is the right place to start it.
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: plantId)));
      onChanged();
      return;
    }
    if (await openNodeLog(context, repo, plantId, task)) onChanged();
  }

  /// The plant's own unlogged node behind this window, if there is one.
  Future<PathNode?> _taskFor(String plantId) async {
    final wanted = switch (node.kind) {
      SeasonNodeKind.sowWindow => const [NodeKind.sow, NodeKind.transplant],
      SeasonNodeKind.harvestWindow => const [NodeKind.harvest],
      SeasonNodeKind.succession => const <NodeKind>[],
    };
    if (wanted.isEmpty) return null;
    for (final candidate in await repo.pathFor(plantId)) {
      if (wanted.contains(candidate.kind) &&
          candidate.loggedOn == null &&
          !candidate.skipped) {
        return candidate;
      }
    }
    return null;
  }

  /// A succession prompt is an offer, so its tap takes it: the crop joins the
  /// garden's planning list, the same act the planning screen calls "Plan it".
  Future<void> _planIt(BuildContext context) async {
    final gardens = await repo.gardens();
    if (gardens.isEmpty) return;
    final crop = repo.cropBySlug(node.cropSlug);
    await repo.addPlant(
      gardenId: gardens.first.id,
      cropSlug: node.cropSlug,
      potLitres: crop?.minPotLitres?.toInt(),
    );
    if (!context.mounted) return;
    Haptics.complete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${repo.cropName(node.cropSlug)} added to Planning'),
    ));
  }
}

/// A plant's own pending step between sowing and harvest: pot on, plant out,
/// thin, feed. Tapping it logs it, the same as any other node.
class _TaskItem implements _Item {
  const _TaskItem({
    required this.task,
    required this.today,
    required this.repo,
    required this.onChanged,
    required this.swing,
    required this.above,
    required this.below,
  });

  final SeasonTask task;
  final DateTime today;
  final GardenRepository repo;
  final VoidCallback onChanged;
  final double swing;
  final double? above;
  final double? below;

  @override
  double get height => _nodeRow;

  _State get state {
    final due = parseIso(task.due);
    // A step is open from its due date on: it does not expire, it waits.
    return due.isAfter(today) ? _State.ahead : _State.now;
  }

  @override
  Widget build(BuildContext context) => _PathStop(
        swing: swing,
        above: above,
        below: below,
        state: state,
        label: task.title.of(context),
        caption: _day(task.due, context),
        badge: 'assets/nodes/${task.kind}.png',
        corner: CropImage(
          slug: task.cropSlug,
          category: repo.cropCategory(task.cropSlug),
        ),
        onTap: () => _open(context),
      );

  Future<void> _open(BuildContext context) async {
    final node = (await repo.pathFor(task.plantId))
        .where((n) => n.id == task.nodeId)
        .firstOrNull;
    if (node == null || !context.mounted) return;
    if (await openNodeLog(context, repo, task.plantId, node)) onChanged();
  }
}

/// Everything on the path that is not a plant's own task: the frost dates, the
/// seed order, the monthly photo, the payoff, the recap, and what the weather
/// changed today.
class _MarkerItem implements _Item {
  const _MarkerItem({
    required this.marker,
    required this.today,
    required this.repo,
    required this.onChanged,
    required this.swing,
    required this.above,
    required this.below,
  });

  final SeasonMarker marker;
  final DateTime today;
  final GardenRepository repo;

  /// A logged photo takes this month's marker off the path.
  final VoidCallback onChanged;
  final double swing;
  final double? above;
  final double? below;

  @override
  double get height => _nodeRow;

  _State get state {
    final on = parseIso(marker.on);
    if (on.isBefore(today)) return _State.done;
    // A marker has no window, so "now" is the day itself.
    if (on.isAtSameMomentAs(today)) return _State.now;
    return _State.ahead;
  }

  String get _badgeAsset => switch (marker.kind) {
        SeasonMarkerKind.ijsheiligen => 'frost',
        SeasonMarkerKind.lastFrost => 'frost',
        SeasonMarkerKind.firstFrost => 'frost',
        SeasonMarkerKind.orderSeeds => 'seeds',
        SeasonMarkerKind.photo => 'photo',
        SeasonMarkerKind.payoff => 'tally',
        SeasonMarkerKind.recap => 'recap',
        SeasonMarkerKind.weather => 'rain',
      };

  @override
  Widget build(BuildContext context) => _PathStop(
        swing: swing,
        above: above,
        below: below,
        // A frost date is never "done" the way a task is: it is a fact about
        // the year, so it never carries a tick.
        state: state == _State.done ? _State.ahead : state,
        label: marker.title.of(context),
        caption: marker.caption.of(context),
        badge: 'assets/nodes/$_badgeAsset.png',
        onTap: () => _open(context),
      );

  void _open(BuildContext context) {
    switch (marker.kind) {
      case SeasonMarkerKind.photo:
        _openPhoto(context);
      case SeasonMarkerKind.payoff:
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const HarvestScreen()));
      case SeasonMarkerKind.orderSeeds:
        showAppSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (context) => _MonthOptions(month: 3, crops: repo.whatToGrowIn(3)),
        );
      case SeasonMarkerKind.recap:
        _recap(context);
      case SeasonMarkerKind.ijsheiligen:
      case SeasonMarkerKind.lastFrost:
      case SeasonMarkerKind.firstFrost:
      case SeasonMarkerKind.weather:
        _tell(context);
    }
  }

  /// The year in figures. PRD §7.5: the tally is the payoff, not points.
  Future<void> _recap(BuildContext context) async {
    final tally = await repo.seasonTally();
    final plants = await repo.plants();
    final harvested = plants.where((p) => p.stage == 'harvested').length;
    if (!context.mounted) return;
    await showAppSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Mascot(MascotPose.celebrating, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(Str.recapTitle(today.year).of(context),
                      style: AppText.heading(context)),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _Figure(
                        value: '${plants.length}',
                        label: Str.plantsGrown.of(context))),
                const SizedBox(width: 12),
                Expanded(
                    child: _Figure(
                        value: '$harvested', label: Str.picked.of(context))),
                const SizedBox(width: 12),
                Expanded(
                  child: _Figure(
                    value: '€${tally.euros.round()}',
                    label: Str.saved.of(context),
                  ),
                ),
              ]),
              if (tally.unpriced > 0) ...[
                const SizedBox(height: 10),
                Text('${tally.unpriced} harvests have no price yet, so they are not counted.',
                    style: AppText.caption(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The mascot explains the marker. Base 8.13: a sheet, not a dialog.
  void _tell(BuildContext context) => showAppSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(marker.title.of(context), style: AppText.heading(context)),
              const SizedBox(height: 12),
              MascotSays.say(
                pose: switch (marker.kind) {
                  SeasonMarkerKind.recap => MascotPose.celebrating,
                  SeasonMarkerKind.weather => MascotPose.rain,
                  _ => MascotPose.frost,
                },
                size: 72,
                line: _explain(),
              ),
            ],
          ),
        ),
      );

  /// The mascot's own explanation of the marker, from the deck.
  LocalizedText _explain() => switch (marker.kind) {
        SeasonMarkerKind.ijsheiligen => MascotLines.ijsheiligen,
        SeasonMarkerKind.lastFrost => MascotLines.lastFrost,
        SeasonMarkerKind.firstFrost => MascotLines.firstFrost,
        SeasonMarkerKind.recap => MascotLines.recap,
        SeasonMarkerKind.orderSeeds => MascotLines.seedOrder,
        _ => marker.caption,
      };

  /// The month's photo, taken from the path: pick the plant if there is more
  /// than one, then the same growth log the plant screen uses.
  Future<void> _openPhoto(BuildContext context) async {
    final growing = await repo.growingPlants();
    if (!context.mounted || growing.isEmpty) return;

    var plant = growing.first;
    if (growing.length > 1) {
      final picked = await showAppSheet<GardenPlantRow>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Which plant?', style: AppText.heading(context)),
                const SizedBox(height: 12),
                for (final p in growing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      onTap: () => Navigator.pop(context, p),
                      child: Row(children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: ClipOval(
                            child: CropImage(
                              slug: p.cropSlug,
                              category: repo.cropCategory(p.cropSlug),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(repo.cropName(p.cropSlug), style: AppText.subheading(context)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      if (picked == null || !context.mounted) return;
      plant = picked;
    }

    final log = await showGrowthLogSheet(
      context,
      cropName: repo.cropName(plant.cropSlug),
      currentStage: plant.stage,
    );
    if (log == null) return;
    await repo.addJournalEntry(
      plantId: plant.id,
      note: log.note,
      mood: log.mood,
      stage: log.stage,
      photoPaths: log.photoPaths,
    );
    Haptics.complete();
    onChanged();
  }
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
        label: Str.cropsCanGoIn(count).of(context),
        caption: Str.nothingPlanned(Str.month(month)).of(context),
        badge: 'assets/nodes/chest.png',
        onTap: () => showAppSheet<void>(
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
              alignment: Alignment(swing, -1),
              child: Padding(
                padding: const EdgeInsets.only(top: _badgeTop),
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
                            decoration: BoxDecoration(
                              color: AppColors.positive,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(PhosphorIcons.check,
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
                            decoration: BoxDecoration(
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
                maxLines: 2),
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
    this.centre = _badgeCentre,
    this.radius = _badge / 2 + 2,
  });

  final double swing;
  final double? above;
  final double? below;
  final bool dashed;

  /// Where this row's stop sits, and how wide it is, so the trail meets its
  /// edge. A month marker is smaller and sits higher than a task node.
  final double centre;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.12)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stop = Offset(_centreX(size.width, swing, radius * 2), centre);

    // The neighbours' badges sit at the same height inside their own rows, so
    // the trail leaves this row's top and bottom edges aimed straight at them.
    if (above != null) {
      _segment(canvas, paint, Offset(_centreX(size.width, above!, radius * 2), centre - _nodeRow),
          Offset(stop.dx, stop.dy - radius));
    }
    if (below != null) {
      _segment(canvas, paint, Offset(stop.dx, stop.dy + radius),
          Offset(_centreX(size.width, below!, radius * 2), centre + _nodeRow));
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
      old.swing != swing ||
      old.above != above ||
      old.below != below ||
      old.dashed != dashed ||
      old.centre != centre;
}

/// One figure in the recap.
class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Text(value,
                style: AppText.title(context).copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                maxLines: 1),
            Text(label,
                style: AppText.caption(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

/// The season's header: where the year stands, above the first stop.
class _Crest extends StatelessWidget {
  const _Crest({required this.today, required this.rows, required this.streak});

  final DateTime today;
  final List<_Item> rows;

  /// Consecutive days with a task ticked or skipped with a reason (§7.3).
  final int streak;

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
          Text(Str.season.of(context), style: AppText.kicker(context)),
          Text(Str.yearInGarden(today.year).of(context), style: AppText.title(context)),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: Text(
                (open > 0 ? Str.openAndDone(open, done) : Str.doneNothingOpen(done))
                    .of(context),
                style: AppText.bodyMuted(context),
              ),
            ),
            if (streak > 0)
              Pill(
                label: '$streak day${streak == 1 ? '' : 's'}',
                icon: PhosphorIcons.fire,
                color: AppColors.onAccentSoft,
                bg: AppColors.accentSoft,
              ),
          ]),
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
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(Str.stillSowable(Str.month(month)).of(context),
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

String _day(String iso, BuildContext context) {
  final d = parseIso(iso);
  return '${d.day} ${Str.monthShort(d.month).of(context)}';
}

String _window(String start, String end, BuildContext context) {
  String fmt(DateTime d) => '${d.day} ${Str.monthShort(d.month).of(context)}';
  final s = parseIso(start);
  final e = parseIso(end);
  return start == end ? fmt(s) : '${fmt(s)} – ${fmt(e)}';
}
