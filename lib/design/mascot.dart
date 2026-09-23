/// The mascot's 12 pose slots (PRD §6) — a terracotta pot with a seedling,
/// rendered as a glossy 3D character, one cut-out image per pose under
/// assets/mascot. Screens build against this API, so a later swap to Rive or
/// Lottie touches only this file.
///
/// The art is still, so the life is in the widget: a slow breath where the
/// mascot is the subject of the screen, and a spring pop whenever the pose
/// changes, so a reaction reads as a reaction rather than as a swapped file.
///
/// Three poses also ship split in two — `<pose>_body.png` and `<pose>_stem.png`
/// — so the seedling sways on its own axis, out of phase with the breath. Only
/// the seedling: the leaf-arms sit flush against the pot with no limb between,
/// so rotating them buries them in it rather than waving them. `idle` has a
/// second body with its eyes closed, which is the blink.
///
/// tool/mascot_layers.py is what cuts the layers, and tool/specs/mascot.json
/// is what draws the poses.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../l10n/app_lang.dart';
import '../timing/types.dart';
import 'motion.dart';

enum MascotPose {
  idle,
  wave,
  thinking,
  celebrating,
  sleeping,
  watering,
  holdingSeedling,
  shrug,
  pointing,
  rain,
  sun,
  frost,
}

const _asset = <MascotPose, String>{
  MascotPose.idle: 'idle',
  MascotPose.wave: 'wave',
  MascotPose.thinking: 'thinking',
  MascotPose.celebrating: 'celebrating',
  MascotPose.sleeping: 'sleeping',
  MascotPose.watering: 'watering',
  MascotPose.holdingSeedling: 'holding_seedling',
  MascotPose.shrug: 'shrug',
  MascotPose.pointing: 'pointing',
  MascotPose.rain: 'rain',
  MascotPose.sun: 'sun',
  MascotPose.frost: 'frost',
};

/// Poses that ship as a body plus a seedling, and so can sway.
const _layered = {MascotPose.idle, MascotPose.wave, MascotPose.thinking};

/// Poses with a second, eyes-closed body.
const _blinks = {MascotPose.idle};

/// Where the stem meets the soil, in [Alignment] terms. Measured by
/// tool/mascot_layers.py, which reports the same point for all three poses.
const _stemPivot = Alignment(0.013, -0.41);

class Mascot extends StatefulWidget {
  const Mascot(this.pose, {super.key, this.size = 56});

  final MascotPose pose;
  final double size;

  /// Below this the mascot is a label next to a row, not the subject of the
  /// screen, and a breathing thumbnail in a scrolling list is noise — and one
  /// looping controller per row. At or above it the mascot breathes.
  static const double _breathingSize = 64;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  /// 0 → 1 → 0, the breath. Null where the mascot is too small to breathe, so
  /// a list of rows costs no tickers.
  AnimationController? _breath;

  /// Scale multiplier the pose change springs back to 1. Unbounded so the
  /// spring can overshoot past 1 and settle.
  late final AnimationController _react = AnimationController.unbounded(value: 1, vsync: this);

  /// Sways and blinks ride on the same gate as the breath: below this size the
  /// mascot is a label beside a row, and secondary motion there is noise. Under
  /// reduced motion none of it exists — not "runs and is ignored", but no
  /// controller and no timer at all.
  bool get _breathes => widget.size >= Mascot._breathingSize && !Motion.of(context).reduced;
  bool get _alive => _breathes && _layered.contains(widget.pose);

  AnimationController? _sway;
  Timer? _blinkTimer;
  bool _blinking = false;

  /// Not initState: the gates read the reduce-motion setting, which lives in
  /// the inherited widgets. This also re-runs when that setting changes, so
  /// turning reduced motion on stops the tickers rather than merely hiding them.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (old.pose != widget.pose) _pop();
    if (old.size != widget.size || old.pose != widget.pose) _syncMotion();
  }

  /// Holds the breath controller's existence to the current size: a mascot that
  /// shrinks into a row stops breathing, and stops costing a ticker.
  void _syncMotion() {
    if (_breathes && _breath == null) {
      _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
        ..repeat(reverse: true);
    } else if (!_breathes && _breath != null) {
      _breath!.dispose();
      _breath = null;
    }
    // Deliberately not a multiple of the breath: two loops that divide evenly
    // lock into one motion, and the character starts looking like a machine.
    if (_alive && _sway == null) {
      _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 4100))
        ..repeat(reverse: true);
    } else if (!_alive && _sway != null) {
      _sway!.dispose();
      _sway = null;
    }
    if (_alive && _blinks.contains(widget.pose)) {
      _blinkTimer ??= Timer(_untilNextBlink(), _blink);
    } else {
      _blinkTimer?.cancel();
      _blinkTimer = null;
      _blinking = false;
    }
  }

  /// Four to nine seconds apart. A fixed interval is the thing that gives a
  /// blinking character away.
  Duration _untilNextBlink() => Duration(milliseconds: 4000 + _random.nextInt(5000));

  static final _random = math.Random();

  void _blink() {
    if (!mounted) return;
    setState(() => _blinking = true);
    Timer(const Duration(milliseconds: 130), () {
      if (!mounted) return;
      setState(() => _blinking = false);
      _blinkTimer = Timer(_untilNextBlink(), _blink);
    });
  }

  /// Dip, then spring back through 1 and settle. The velocity is what makes it
  /// overshoot: the press spring on its own is too damped to read as a hop.
  void _pop() {
    if (Motion.of(context).reduced) return;
    _react
      ..value = 0.94
      ..animateWith(SpringSimulation(Motion.springPress, 0.94, 1, 2.4));
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _sway?.dispose();
    _breath?.dispose();
    _react.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final name = _asset[widget.pose];

    Widget art(String file) =>
        Image.asset('assets/mascot/$file.png', fit: BoxFit.contain, excludeFromSemantics: true);

    // The art is a cut-out, so it stands free on whatever it is put on rather
    // than inside a tile of its own.
    final Widget image = !_alive || motion.reduced
        ? KeyedSubtree(key: ValueKey(widget.pose), child: art(name!))
        : KeyedSubtree(
            key: ValueKey(widget.pose),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Behind the pot, so the cut where the stem leaves the soil is
                // never on screen.
                AnimatedBuilder(
                  animation: _sway!,
                  builder: (context, child) => Transform.rotate(
                    // ±0.16 rad is a plant in a draught, not a metronome.
                    angle: 0.16 * (Curves.easeInOut.transform(_sway!.value) - 0.5),
                    alignment: _stemPivot,
                    child: child,
                  ),
                  child: art('${name}_stem'),
                ),
                art(_blinking ? '${name}_body_blink' : '${name}_body'),
              ],
            ),
          );

    final swapped = AnimatedSwitcher(
      duration: motion[Motion.standard],
      switchInCurve: Motion.easeEnter,
      switchOutCurve: Motion.easeExit,
      // The default builder stacks the two poses under loose constraints, and
      // an Image with nothing decoded yet answers loose constraints with zero.
      // Expanding the stack keeps both poses at the size we were given.
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: image,
    );

    if (motion.reduced) {
      return SizedBox(width: widget.size, height: widget.size, child: swapped);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _react]),
        builder: (context, child) {
          // easeInOut over the triangular controller: a linear breath reverses
          // with a visible corner at each end.
          final breath = _breath == null ? 0.0 : Curves.easeInOut.transform(_breath!.value);
          // Rises as it swells, the way a chest does.
          return Transform.translate(
            offset: Offset(0, -1.5 * breath),
            child: Transform.scale(scale: (1 + 0.025 * breath) * _react.value, child: child),
          );
        },
        child: swapped,
      ),
    );
  }
}

/// A line the mascot says, next to its pose. Used for empty states, plan
/// changes and the "not behind" sheet.
class MascotSays extends StatelessWidget {
  const MascotSays({super.key, required this.pose, required this.text, this.size = 56})
    : line = null;

  /// The deck's own lines (lib/l10n/mascot_lines.dart), which carry both
  /// languages and pick one at build time.
  const MascotSays.say({
    super.key,
    required this.pose,
    required LocalizedText this.line,
    this.size = 56,
  }) : text = '';

  final MascotPose pose;
  final String text;
  final LocalizedText? line;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Mascot(pose, size: size),
        const SizedBox(width: 12),
        Expanded(
          child: Text(line?.of(context) ?? text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
