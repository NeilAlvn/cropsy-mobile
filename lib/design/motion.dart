/// Motion — VisionTech base section 9.
///
/// Every animation answers "what changed" or "what did I press". Durations and
/// curves are fixed by the base; exits run shorter than enters. Under reduced
/// motion everything collapses to an instant state change, which is why screens
/// read durations through [Motion.of] rather than using the constants directly.
library;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

class Motion {
  const Motion._(this.reduced);

  /// Reads the platform's reduce-motion setting. Screens call this instead of
  /// touching the constants, so honouring the setting is the default path.
  factory Motion.of(BuildContext context) =>
      Motion._(MediaQuery.disableAnimationsOf(context));

  final bool reduced;

  static const Duration micro = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration sheet = Duration(milliseconds: 380);

  /// Exits run 30 percent shorter than enters (base 9).
  static const Duration exit = Duration(milliseconds: 175);

  static const Curve easeEnter = Cubic(0.2, 0, 0, 1);
  static const Curve easeExit = Cubic(0.4, 0, 1, 1);

  /// Press scale and release. Base 9: damping 18, stiffness 260.
  static const SpringDescription springPress =
      SpringDescription(mass: 1, stiffness: 260, damping: 18);

  /// Sheet detents and drag release. Base 9: damping 24, stiffness 200.
  static const SpringDescription springSheet =
      SpringDescription(mass: 1, stiffness: 200, damping: 24);

  /// Stagger between items arriving after load, capped at six items (base 9).
  static const Duration stagger = Duration(milliseconds: 40);
  static const int staggerCap = 6;

  Duration operator [](Duration d) => reduced ? Duration.zero : d;
}

/// Haptics, base 9. Light on selection, medium on a primary action, heavy on a
/// completion. Never on scroll or a passive update.
abstract final class Haptics {
  static void selection() => HapticFeedback.selectionClick();
  static void press() => HapticFeedback.mediumImpact();
  static void complete() => HapticFeedback.heavyImpact();
}

/// Press feedback: scale to 0.97 on a spring, and one haptic on the press.
/// Wrap anything tappable that is not already a Material control.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.haptic = Haptics.selection,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Which haptic the press fires. Pass null for controls that would make the
  /// phone buzz on every scroll-adjacent tap.
  final void Function()? haptic;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    value: 1,
    vsync: this,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _to(double target) {
    // A pointer can be released after the widget is gone (a tap that navigates
    // away, a list that rebuilds); reading MediaQuery then throws.
    if (!mounted) return;
    if (Motion.of(context).reduced) {
      _c.value = target;
      return;
    }
    _c.animateWith(
      SpringSimulation(Motion.springPress, _c.value, target, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _to(widget.scale) : null,
      onTapUp: enabled ? (_) => _to(1) : null,
      onTapCancel: enabled ? () => _to(1) : null,
      onTap: enabled
          ? () {
              widget.haptic?.call();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) =>
            Transform.scale(scale: _c.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Content that arrives after load: fade in and rise 8 points, staggered by
/// index and capped at six, so a long list does not ripple forever.
class ArriveIn extends StatelessWidget {
  const ArriveIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    if (motion.reduced) return child;
    final delay = Motion.stagger * index.clamp(0, Motion.staggerCap);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.standard + delay,
      curve: Interval(
        delay.inMilliseconds / (Motion.standard + delay).inMilliseconds,
        1,
        curve: Motion.easeEnter,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
