/// The Duolingo timeline engine (PRD §7): builds a plant's path of nodes and
/// re-derives the future when the user logs reality.
///
/// Two rules, nothing more (PRD §13: anchor-shifting only, no per-crop cases):
///   1. [buildPath] — crop fields + a start date → dated nodes.
///   2. [logNode]   — a logged date that differs from plan by > threshold
///                    shifts every unlogged downstream node by the same delta.
///                    The past is never mutated. Nothing is "overdue"; it is
///                    "moved".
///
/// Direct port of the backend `src/timing/replan.ts`; proven equal to the day
/// against `docs/fixtures/replan.fixture.json`.
library;

import 'dates.dart';
import 'types.dart';

enum NodeKind { sow, potOn, transplant, thin, feed, water, harvest, harvested }

const _kindToWire = <NodeKind, String>{
  NodeKind.sow: 'sow',
  NodeKind.potOn: 'pot_on',
  NodeKind.transplant: 'transplant',
  NodeKind.thin: 'thin',
  NodeKind.feed: 'feed',
  NodeKind.water: 'water',
  NodeKind.harvest: 'harvest',
  NodeKind.harvested: 'harvested',
};
final _kindFromWire = {for (final e in _kindToWire.entries) e.value: e.key};

String nodeKindToWire(NodeKind k) => _kindToWire[k]!;
NodeKind nodeKindFromWire(String s) {
  final k = _kindFromWire[s];
  if (k == null) throw ArgumentError('unknown node kind: $s');
  return k;
}

class PathNode {
  const PathNode({
    required this.id,
    required this.kind,
    required this.plannedDue,
    required this.due,
    this.until,
    this.loggedOn,
    this.skipped = false,
    this.movedReason,
  });

  final String id;
  final NodeKind kind;

  /// The date the original plan gave this node. Never changes.
  final String plannedDue;

  /// Where the node sits now (after replans).
  final String due;

  /// Window end for `harvest` (inclusive); null for point-in-time nodes.
  final String? until;

  /// The date the user did it, or null.
  final String? loggedOn;
  final bool skipped;

  /// Set when a replan moved this node; shown instead of "overdue".
  final LocalizedText? movedReason;

  PathNode copyWith({
    String? due,
    String? until,
    String? loggedOn,
    bool? skipped,
    LocalizedText? movedReason,
  }) =>
      PathNode(
        id: id,
        kind: kind,
        plannedDue: plannedDue,
        due: due ?? this.due,
        until: until ?? this.until,
        loggedOn: loggedOn ?? this.loggedOn,
        skipped: skipped ?? this.skipped,
        movedReason: movedReason ?? this.movedReason,
      );

  factory PathNode.fromJson(Map<String, dynamic> j) => PathNode(
        id: j['id'] as String,
        kind: nodeKindFromWire(j['kind'] as String),
        plannedDue: j['planned_due'] as String,
        due: j['due'] as String,
        until: j['until'] as String?,
        loggedOn: j['logged_on'] as String?,
        skipped: j['skipped'] as bool? ?? false,
        movedReason: j['moved_reason'] == null
            ? null
            : LocalizedText.fromJson(j['moved_reason'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': nodeKindToWire(kind),
        'planned_due': plannedDue,
        'due': due,
        'until': until,
        'logged_on': loggedOn,
        'skipped': skipped,
        'moved_reason': movedReason?.toJson(),
      };
}

class PathStart {
  const PathStart({required this.method, required this.on});

  final MethodType method;

  /// ISO date the user sowed / planted / transplanted.
  final String on;
}

// How long after emergence a seedling is handled. Fixed, not per-crop (§13).
const _potOnAfterEmergenceDays = 14;
const _thinAfterEmergenceDays = 7;
// Feeding starts here when the path has no transplant node to anchor on.
const _feedStartWithoutTransplantDays = 28;
const _maxFeedNodes = 30;

PathNode _node(String id, NodeKind kind, String due, [String? until]) =>
    PathNode(id: id, kind: kind, plannedDue: due, due: due, until: until);

/// Derive the path for one plant. Missing crop fields simply omit the node they
/// would have produced, so a crop with only timing data still yields
/// start → harvest.
List<PathNode> buildPath(Crop crop, PathStart start, String plantId) {
  final on = parseIso(start.on);
  String at(num days) => toIso(addDays(on, days));
  String id(NodeKind kind, [int n = 0]) =>
      '$plantId-${nodeKindToWire(kind)}${n != 0 ? '-$n' : ''}';
  final nodes = <PathNode>[];

  // Start node. `plant` (tubers, sets, crowns) is a sow-equivalent: it goes in
  // the ground on this date. Bought seedlings start at the transplant.
  final startsAtTransplant = start.method == MethodType.transplant;
  final startKind = startsAtTransplant ? NodeKind.transplant : NodeKind.sow;
  nodes.add(_node(id(startKind), startKind, start.on));

  String? transplantDue = startsAtTransplant ? start.on : null;

  if (start.method == MethodType.sowIndoor) {
    if (crop.germinationDays != null) {
      nodes.add(_node(id(NodeKind.potOn), NodeKind.potOn,
          at(crop.germinationDays! + _potOnAfterEmergenceDays)));
    }
    if (crop.daysToTransplant != null) {
      transplantDue = at(crop.daysToTransplant!);
      nodes.add(_node(id(NodeKind.transplant), NodeKind.transplant, transplantDue));
    }
  }
  if (start.method == MethodType.sowDirect && crop.germinationDays != null) {
    nodes.add(_node(id(NodeKind.thin), NodeKind.thin,
        at(crop.germinationDays! + _thinAfterEmergenceDays)));
  }

  // Harvest window. harvest days count from the plant's OUTDOOR start: the
  // transplant for indoor-started crops, otherwise the sow/plant date.
  final harvestFrom = parseIso(transplantDue ?? start.on);
  final harvestDue = toIso(addDays(harvestFrom, crop.harvestDaysMin));
  final harvestUntil = toIso(addDays(harvestFrom, crop.harvestDaysMax));
  nodes.add(_node(id(NodeKind.harvest), NodeKind.harvest, harvestDue, harvestUntil));

  if (crop.feedCadenceDays != null) {
    var feed = parseIso(transplantDue ?? at(_feedStartWithoutTransplantDays));
    final stop = parseIso(harvestDue);
    for (var n = 1; n <= _maxFeedNodes; n++) {
      feed = addDays(feed, crop.feedCadenceDays!);
      if (!feed.isBefore(stop)) break;
      nodes.add(_node(id(NodeKind.feed, n), NodeKind.feed, toIso(feed)));
    }
  }

  // Sorted by date; ties keep insertion order (start node first). List.sort is
  // not guaranteed stable, so sort by (due, insertion index).
  final indexed = nodes.asMap().entries.toList()
    ..sort((a, b) {
      final c = a.value.due.compareTo(b.value.due);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return indexed.map((e) => e.value).toList(growable: false);
}

class ReplanParams {
  const ReplanParams({
    this.thresholdDays = 5,
    this.firstFrost,
    this.frostMarginDays = 14,
  });

  /// Logged-vs-plan difference (days) above which downstream nodes move.
  final int thresholdDays;

  /// Average first autumn frost for the garden, or null to skip the warning.
  final String? firstFrost;

  /// Harvest windows ending within this many days of first frost warn.
  final int frostMarginDays;

  factory ReplanParams.fromJson(Map<String, dynamic> j) => ReplanParams(
        thresholdDays: (j['thresholdDays'] as num).toInt(),
        firstFrost: j['firstFrost'] as String?,
        frostMarginDays: (j['frostMarginDays'] as num).toInt(),
      );
}

const defaultReplan = ReplanParams();

class ReplanWarning {
  const ReplanWarning({required this.nodeId, required this.reason});

  final String code = 'harvest_near_frost';
  final String nodeId;
  final LocalizedText reason;

  Map<String, dynamic> toJson() =>
      {'code': code, 'node_id': nodeId, 'reason': reason.toJson()};
}

class ReplanResult {
  const ReplanResult({
    required this.nodes,
    required this.shiftDays,
    required this.warnings,
  });

  final List<PathNode> nodes;

  /// Days every downstream node moved (0 = within threshold, nothing moved).
  final int shiftDays;
  final List<ReplanWarning> warnings;
}

const _kindNl = <NodeKind, String>{
  NodeKind.sow: 'zaaien',
  NodeKind.potOn: 'verpotten',
  NodeKind.transplant: 'uitplanten',
  NodeKind.thin: 'uitdunnen',
  NodeKind.feed: 'bemesten',
  NodeKind.water: 'water geven',
  NodeKind.harvest: 'oogsten',
  NodeKind.harvested: 'geoogst',
};
const _kindEn = <NodeKind, String>{
  NodeKind.sow: 'sowing',
  NodeKind.potOn: 'potting on',
  NodeKind.transplant: 'planting out',
  NodeKind.thin: 'thinning',
  NodeKind.feed: 'feeding',
  NodeKind.water: 'watering',
  NodeKind.harvest: 'harvest',
  NodeKind.harvested: 'harvested',
};

int _diffDays(String a, String b) =>
    ((parseIso(a).millisecondsSinceEpoch - parseIso(b).millisecondsSinceEpoch) /
            msPerDay)
        .round();

/// Record that [nodeId] was done on [loggedOn] and re-derive the future.
/// Returns a new list; the input is not mutated.
ReplanResult logNode(
  List<PathNode> nodes,
  String nodeId,
  String loggedOn, {
  ReplanParams params = defaultReplan,
}) {
  final i = nodes.indexWhere((n) => n.id == nodeId);
  if (i < 0) throw ArgumentError('unknown node: $nodeId');
  final anchor = nodes[i];
  final out = List<PathNode>.of(nodes);
  out[i] = anchor.copyWith(loggedOn: loggedOn);

  final delta = _diffDays(loggedOn, anchor.due);
  if (delta.abs() <= params.thresholdDays) {
    return ReplanResult(nodes: out, shiftDays: 0, warnings: const []);
  }

  final sign = delta > 0 ? '+' : '−';
  final reason = LocalizedText(
    nl: 'Verplaatst ($sign${delta.abs()} dagen): ${_kindNl[anchor.kind]} was '
        '${delta > 0 ? 'later' : 'eerder'} dan gepland.',
    en: 'Moved ($sign${delta.abs()} days): ${_kindEn[anchor.kind]} was '
        '${delta > 0 ? 'later' : 'earlier'} than planned.',
  );

  final warnings = <ReplanWarning>[];
  for (var j = i + 1; j < out.length; j++) {
    final n = out[j];
    if (n.loggedOn != null || n.skipped) continue; // never mutate the past
    final moved = n.copyWith(
      due: toIso(addDays(parseIso(n.due), delta)),
      until: n.until == null ? null : toIso(addDays(parseIso(n.until!), delta)),
      movedReason: reason,
    );
    out[j] = moved;

    final firstFrost = params.firstFrost;
    if (moved.kind == NodeKind.harvest && firstFrost != null) {
      final limit =
          toIso(addDays(parseIso(firstFrost), -params.frostMarginDays));
      final end = moved.until ?? moved.due;
      if (end.compareTo(limit) > 0) {
        warnings.add(ReplanWarning(
          nodeId: moved.id,
          reason: LocalizedText(
            nl: 'De oogst loopt nu tot $end, dicht bij de eerste vorst '
                '($firstFrost). Toch doorgaan, of een sneller ras kiezen?',
            en: 'Harvest now runs until $end, close to first frost '
                '($firstFrost). Grow it anyway, or swap for a faster variety?',
          ),
        ));
      }
    }
  }
  return ReplanResult(nodes: out, shiftDays: delta, warnings: warnings);
}
