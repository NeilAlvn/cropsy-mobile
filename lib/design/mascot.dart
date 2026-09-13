/// The mascot's 12 pose slots (PRD §6). Placeholder silhouette until the
/// house-style pass delivers Rive/Lottie; screens build against this API so
/// the swap touches only this file.
library;

import 'package:flutter/material.dart';

import 'colors.dart';

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

// Placeholder glyph per pose. Replaced by the real asset in Phase 3.
const _glyph = <MascotPose, String>{
  MascotPose.idle: '🌱',
  MascotPose.wave: '👋',
  MascotPose.thinking: '🤔',
  MascotPose.celebrating: '🎉',
  MascotPose.sleeping: '😴',
  MascotPose.watering: '💧',
  MascotPose.holdingSeedling: '🪴',
  MascotPose.shrug: '🤷',
  MascotPose.pointing: '👉',
  MascotPose.rain: '🌧️',
  MascotPose.sun: '☀️',
  MascotPose.frost: '❄️',
};

class Mascot extends StatelessWidget {
  const Mascot(this.pose, {super.key, this.size = 56});
  final MascotPose pose;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.sand, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(_glyph[pose]!, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// A line the mascot says, next to its pose. Used for empty states, plan
/// changes and the "not behind" sheet.
class MascotSays extends StatelessWidget {
  const MascotSays({super.key, required this.pose, required this.text, this.size = 56});
  final MascotPose pose;
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Mascot(pose, size: size),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }
}
