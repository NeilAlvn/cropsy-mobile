/// The mascot's 12 pose slots (PRD §6) — a terracotta pot with a seedling,
/// rendered as a glossy 3D character, one cut-out image per pose under
/// assets/mascot. Screens build against this API, so a later swap to Rive or
/// Lottie touches only this file.
library;

import 'package:flutter/material.dart';

import '../l10n/app_lang.dart';
import '../timing/types.dart';


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

class Mascot extends StatelessWidget {
  const Mascot(this.pose, {super.key, this.size = 56});
  final MascotPose pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    // The art is a cut-out, so it stands free on whatever it is put on rather
    // than inside a tile of its own.
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/mascot/${_asset[pose]}.png',
        fit: BoxFit.contain,
        excludeFromSemantics: true,
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
          child: Text(
            line?.of(context) ?? text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
