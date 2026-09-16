/// The mascot's 12 pose slots (PRD §6) — a terracotta pot with a seedling, one
/// image per pose under assets/mascot. Screens build against this API, so a
/// later swap to Rive/Lottie touches only this file.
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
    // The art is drawn on the canvas grey, so it sits in a circle of the same
    // value and reads as one shape rather than a pasted square.
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: AppColors.tile,
        child: Image.asset(
          'assets/mascot/${_asset[pose]}.jpg',
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
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
