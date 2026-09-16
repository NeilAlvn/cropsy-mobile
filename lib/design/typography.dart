/// Cropsy type — VisionTech base section 2: one sans family, Plus Jakarta Sans,
/// at the shared scale. No display face, no second family (base 13).
///
/// Loaded via google_fonts (fetched + cached at runtime for the prototype;
/// bundle the four .ttf weights before store submission).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

abstract final class AppText {
  static TextStyle _jakarta({
    required double size,
    required double line,
    required FontWeight weight,
    required double tracking,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        height: line / size,
        fontWeight: weight,
        letterSpacing: tracking,
        color: color ?? AppColors.ink,
      );

  /// 40/44 w700. Splash, onboarding headline, hero figure. One per screen.
  static TextStyle display(BuildContext context, {Color? color}) => _jakarta(
      size: 40, line: 44, weight: FontWeight.w700, tracking: -0.8, color: color);

  /// 28/34 w700. Screen title, sheet title.
  static TextStyle title(BuildContext context, {Color? color}) => _jakarta(
      size: 28, line: 34, weight: FontWeight.w700, tracking: -0.4, color: color);

  /// 22/28 w600. Section heading, card headline, dialog title.
  static TextStyle heading(BuildContext context, {Color? color}) => _jakarta(
      size: 22, line: 28, weight: FontWeight.w600, tracking: -0.2, color: color);

  /// 17/22 w600. Row title, tile title, emphasised body.
  static TextStyle subheading(BuildContext context, {Color? color}) => _jakarta(
      size: 17, line: 22, weight: FontWeight.w600, tracking: 0, color: color);

  /// 16/24 w400. Default reading text.
  static TextStyle body(BuildContext context, {Color? color}) => _jakarta(
      size: 16, line: 24, weight: FontWeight.w400, tracking: 0, color: color);

  static TextStyle bodyMuted(BuildContext context) =>
      body(context, color: AppColors.inkMuted);

  /// 15/20 w400. Dense lists, secondary descriptions.
  static TextStyle bodySm(BuildContext context, {Color? color}) => _jakarta(
      size: 15, line: 20, weight: FontWeight.w400, tracking: 0, color: color);

  /// 15/20 w600. Emphasised dense text: inline links, row values, chip labels.
  static TextStyle label(BuildContext context, {Color? color}) => _jakarta(
      size: 15, line: 20, weight: FontWeight.w600, tracking: 0, color: color);

  /// 13/18 w400. Meta, timestamps, helper text.
  static TextStyle caption(BuildContext context, {Color? color}) => _jakarta(
      size: 13,
      line: 18,
      weight: FontWeight.w400,
      tracking: 0,
      color: color ?? AppColors.inkMuted);

  /// 12/16 w600 +0.3. Badges and tiny status labels. Sentence case.
  static TextStyle kicker(BuildContext context, {Color? color}) => _jakarta(
      size: 12,
      line: 16,
      weight: FontWeight.w600,
      tracking: 0.3,
      color: color ?? AppColors.inkMuted);

  /// Pill button label. Base 8.1: subheading, weight 600, one line.
  static TextStyle button(BuildContext context, {Color? color}) => _jakarta(
      size: 17,
      line: 22,
      weight: FontWeight.w600,
      tracking: 0,
      color: color ?? AppColors.onAccent);
}
