/// Liquid glass, the Cropsy build of it.
///
/// Nime gets Apple's real UIGlassEffect through `expo-glass-effect`. Flutter
/// 3.47 ships no equivalent widget and no platform view for it, so this is the
/// approximation the framework can do natively: a backdrop blur composed with a
/// saturation boost (the part that makes glass read as glass rather than as
/// frosted plastic), a thin translucent tint, and a specular edge that is
/// brighter at the top-left than at the bottom-right.
///
/// ponytail: a shader package (liquid_glass_renderer) would add real refraction
/// at the edges. Swap this one widget's body for it if the flat edge ever reads
/// wrong; every caller keeps working.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'brutal.dart';
import 'colors.dart';

/// Saturation matrix. 1.0 is the source image; glass over content lifts colour.
ui.ColorFilter _saturate(double amount) {
  const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
  final sr = (1 - amount) * lumR, sg = (1 - amount) * lumG, sb = (1 - amount) * lumB;
  return ui.ColorFilter.matrix(<double>[
    sr + amount, sg, sb, 0, 0, //
    sr, sg + amount, sb, 0, 0, //
    sr, sg, sb + amount, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);
}

/// A pane of glass. Blurs and saturates whatever sits behind it, so it only
/// reads as glass when content actually scrolls underneath.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur = 24,
    this.saturation = 1.7,
    this.tint,
    this.tintOpacity = 0.55,
    this.shadowed = true,
    this.padding,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final double blur;
  final double saturation;
  final Color? tint;
  final double tintOpacity;
  final bool shadowed;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(Neo.radiusPill);
    // Reduced transparency and increased contrast both mean "stop making me
    // read through things": fall back to the solid surface (base 10).
    final opaque = MediaQuery.highContrastOf(context);
    final fill = tint ?? AppColors.surface;
    // A pane of glass catches the light of the room it stands in. The light
    // scheme's edge is a room full of it; the same white on the dark canvas
    // reads as a lit ring drawn around the pill rather than as an edge, so
    // dark keeps only the trace a dim room would actually throw.
    final dark = AppColors.isDark;
    final edge = dark ? 0.10 : 0.55;
    final sheen = dark ? (0.06, 0.01) : (0.22, 0.02);

    final pane = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: opaque ? fill : fill.withValues(alpha: tintOpacity),
        // The specular edge. Brighter where a light above-left would catch it.
        border: Border.all(color: Colors.white.withValues(alpha: edge), width: 1),
        gradient: opaque
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: sheen.$1),
                  Colors.white.withValues(alpha: sheen.$2),
                ],
              ),
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadowed ? Neo.float : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: opaque
            ? pane
            : BackdropFilter(
                // `ColorFilter` implements `ImageFilter` in dart:ui, so the
                // saturation runs on the backdrop before the blur widens it.
                filter: ui.ImageFilter.compose(
                  outer: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  inner: _saturate(saturation),
                ),
                child: pane,
              ),
      ),
    );
  }
}

/// 44 circle of glass. Back, close, share, filter — anything floating over
/// content or media (base 8.2).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 44,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          onTap: onTap,
          child: GlassSurface(
            borderRadius: BorderRadius.circular(size / 2),
            blur: 18,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: 22, color: color ?? AppColors.ink),
            ),
          ),
        ),
      );
}
