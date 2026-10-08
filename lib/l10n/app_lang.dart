/// Which language the app speaks.
///
/// Six codes planned, [shippedLanguages] live, English as the fallback. The
/// choice lives on the profile so it syncs with the account; this holds the
/// live value and tells the widgets that read it when it changes.
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../timing/types.dart';

/// Picker order: English first, then the launch market, then the rest.
const appLanguages = <(String, String)>[
  ('en', 'English'),
  ('nl', 'Nederlands'),
  ('de', 'Deutsch'),
  ('fr', 'Français'),
  ('sv', 'Svenska'),
  ('pt', 'Português'),
];

/// Languages whose interface strings are complete. Waves append one code.
const shippedLanguages = ['en', 'nl', 'de'];

/// What the picker and MaterialApp offer: [appLanguages] that have shipped.
final pickerLanguages = [for (final l in appLanguages) if (shippedLanguages.contains(l.$1)) l];

String _snap(String? code, Iterable<String> codes) {
  final c = code?.split(RegExp('[-_]')).first.toLowerCase();
  return codes.contains(c) ? c! : 'en';
}

/// What the app speaks: `de-AT` → `de`; anything not shipped yet → `en`.
String normalizeLang(String? code) => _snap(code, shippedLanguages);

/// What the reader wants, on the six planned codes: `fr-FR` → `fr` even
/// before French ships. This is what the profile stores, so the reader moves
/// to their language the day its wave lands; [normalizeLang] gates the read.
String plannedLang(String? code) => _snap(code, [for (final (c, _) in appLanguages) c]);

/// The phone's language, snapped onto the shipped codes.
String deviceLang() => normalizeLang(ui.PlatformDispatcher.instance.locale.languageCode);

/// The phone's language on the planned codes, for the stored profile.
String deviceLangPlanned() => plannedLang(ui.PlatformDispatcher.instance.locale.languageCode);

String languageName(String code) =>
    appLanguages.firstWhere((l) => l.$1 == code, orElse: () => appLanguages.first).$2;

class AppLang extends ChangeNotifier {
  AppLang([String code = 'en']) : _code = normalizeLang(code);

  String _code;
  String get code => _code;

  set code(String value) {
    final v = normalizeLang(value);
    if (v == _code) return;
    _code = v;
    // Every DateFormat in the app is built without an explicit locale, so this
    // is the one switch that makes dates follow the language.
    Intl.defaultLocale = v;
    notifyListeners();
  }
}

class AppLangScope extends InheritedNotifier<AppLang> {
  const AppLangScope({super.key, required AppLang super.notifier, required super.child});

  static AppLang of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLangScope>()?.notifier ?? AppLang();
}

extension Spoken on LocalizedText {
  /// The side of this text the reader actually wants.
  String of(BuildContext context) => pick(AppLangScope.of(context).code);
}
