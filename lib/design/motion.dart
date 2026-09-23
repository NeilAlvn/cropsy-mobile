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

/// The two accessibility preferences the app offers on top of the phone's own.
///
/// [ValueNotifier]s rather than the [InheritedNotifier] the theme uses, because
/// both values have to be readable where there is no [BuildContext] to look a
/// scope up from: [Haptics] is a static class whose methods are passed around as
/// bare function references (`haptic: Haptics.selection`), and [Motion.of] runs
/// in widget tests that mount a `MediaQuery` and nothing else. Same reasoning as
/// `AppColors.scheme`: a value the paint path needs, held where the paint path
/// can reach it.
///
/// Both live in `Profiles.preferences`, which already syncs, so a phone that
/// signs in keeps the person's answer. (The theme deliberately does not: that
/// one describes the device.)
///
/// Nothing listens to these by default — a toggle takes effect on the next
/// build, which is the next animation or the next buzz, not the current frame.
/// The screen that flips them rebuilds itself so its own switch is honest.
abstract final class AccessPrefs {
  static const hapticsKey = 'haptics';
  static const reduceMotionKey = 'reduce_motion';

  /// Haptics on unless the person turned them off; motion full unless they
  /// asked for less. Both defaults match what the app did before it asked.
  static final ValueNotifier<bool> haptics = ValueNotifier(true);
  static final ValueNotifier<bool> reduceMotion = ValueNotifier(false);

  /// Boot: the decoded `preferences` map from the profile row.
  static void load(Map<String, dynamic> preferences) {
    haptics.value = preferences[hapticsKey] as bool? ?? true;
    reduceMotion.value = preferences[reduceMotionKey] as bool? ?? false;
  }
}

class Motion {
  const Motion._(this.reduced);

  /// Reads the platform's reduce-motion setting, and the app's own on top of
  /// it. Screens call this instead of touching the constants, so honouring the
  /// setting is the default path.
  ///
  /// The app preference only ever adds: a phone that asks for reduced motion
  /// gets it whatever the app setting says, because the phone's answer is the
  /// one the person gave their operating system.
  factory Motion.of(BuildContext context) => Motion._(
        MediaQuery.disableAnimationsOf(context) || AccessPrefs.reduceMotion.value,
      );

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
///
/// Silent when [AccessPrefs.haptics] is off: the gate sits here rather than at
/// the call sites, because every buzz in the app already routes through these
/// three methods.
abstract final class Haptics {
  static void selection() {
    if (AccessPrefs.haptics.value) HapticFeedback.selectionClick();
  }

  static void press() {
    if (AccessPrefs.haptics.value) HapticFeedback.mediumImpact();
  }

  static void complete() {
    if (AccessPrefs.haptics.value) HapticFeedback.heavyImpact();
  }
}

/// A bottom sheet on the base's own timing: 380 ms in on the enter curve, and
/// a shorter exit (base 9). Flutter's default is 250 ms both ways, which makes
/// a sheet feel like a dialog.
///
/// Every sheet in the app goes through here, so the timing is one number in one
/// place rather than an argument each call site has to remember.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  final motion = Motion.of(context);
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    shape: shape,
    sheetAnimationStyle: AnimationStyle(
      duration: motion[Motion.sheet],
      curve: Motion.easeEnter,
      reverseDuration: motion[Motion.exit],
      reverseCurve: Motion.easeExit,
    ),
  );
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
