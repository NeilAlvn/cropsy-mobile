/// Which language the app speaks.
///
/// Six codes, English as the fallback. The choice lives on the profile so it
/// syncs with the account; this holds the live value and tells the widgets
/// that read it when it changes.
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

const appLanguageCodes = ['en', 'nl', 'de', 'fr', 'sv', 'pt'];

/// `de-AT` → `de`, `pt_PT` → `pt`, anything unknown → `en`.
String normalizeLang(String? code) {
  final c = code?.split(RegExp('[-_]')).first.toLowerCase();
  return appLanguageCodes.contains(c) ? c! : 'en';
}

/// The phone's language, snapped onto the six codes.
String deviceLang() => normalizeLang(ui.PlatformDispatcher.instance.locale.languageCode);

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
