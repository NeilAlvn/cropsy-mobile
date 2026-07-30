/// Cropsy type system: Bricolage Grotesque (display) + DM Sans (body/UI).
/// A characterful grotesque for headings — clearly not Farmsy's Fraunces serif.
///
/// Loaded via google_fonts (fetched + cached at runtime for the prototype;
/// bundle the .ttf files before store submission to remove the network fetch).
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

abstract final class AppText {
  static TextStyle display(BuildContext context, {Color? color}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: 32,
        height: 1.04,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: color ?? AppColors.ink,
      );

  static TextStyle title(BuildContext context, {Color? color}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: 22,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: color ?? AppColors.ink,
      );

  static TextStyle heading(BuildContext context, {Color? color}) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: color ?? AppColors.ink,
      );

  static TextStyle kicker(BuildContext context, {Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color ?? AppColors.sprout,
      );

  static TextStyle body(BuildContext context, {Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.ink,
      );

  static TextStyle bodyMuted(BuildContext context) =>
      body(context, color: AppColors.muted);

  static TextStyle label(BuildContext context, {Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.ink,
      );

  static TextStyle caption(BuildContext context, {Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.muted,
      );

  static TextStyle button(BuildContext context, {Color? color}) =>
      GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        color: color ?? Colors.white,
      );
}
