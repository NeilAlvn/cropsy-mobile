/// Which language the app speaks.
///
/// Dutch first, English second (PRD §4). The choice lives on the profile, so it
/// syncs with the account; this holds the live value and tells the widgets that
/// read it when it changes.
library;

import 'package:flutter/widgets.dart';

import '../timing/types.dart';

class AppLang extends ChangeNotifier {
  AppLang([String code = 'nl']) : _code = code;

  String _code;
  String get code => _code;
  bool get isDutch => _code == 'nl';

  set code(String value) {
    if (value == _code) return;
    _code = value;
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
  String of(BuildContext context) => AppLangScope.of(context).isDutch ? nl : en;
}
