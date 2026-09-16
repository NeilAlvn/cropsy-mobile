/// Which scheme the app paints in.
///
/// The palette in colors.dart is a pair of constants; this is what decides
/// which one is live. Three settings: follow the phone, or pin light or dark.
/// The choice is stored in `app_meta`, so it survives a restart without
/// needing an account.
library;

import 'package:flutter/material.dart';

import 'colors.dart';

enum AppThemeChoice { system, light, dark }

/// Holds the choice and resolves it against the platform's own brightness.
class AppTheme extends ChangeNotifier with WidgetsBindingObserver {
  AppTheme({AppThemeChoice initial = AppThemeChoice.system}) {
    _choice = initial;
    WidgetsBinding.instance.addObserver(this);
    _apply();
  }

  static const metaKey = 'theme_choice';

  late AppThemeChoice _choice;
  AppThemeChoice get choice => _choice;

  set choice(AppThemeChoice value) {
    if (value == _choice) return;
    _choice = value;
    _apply();
    notifyListeners();
  }

  /// The phone changed appearance under us, which only matters while the
  /// choice is "follow the phone".
  @override
  void didChangePlatformBrightness() {
    if (_choice == AppThemeChoice.system) _apply();
  }

  ThemeMode get materialMode => switch (_choice) {
        AppThemeChoice.system => ThemeMode.system,
        AppThemeChoice.light => ThemeMode.light,
        AppThemeChoice.dark => ThemeMode.dark,
      };

  Brightness get brightness => switch (_choice) {
        AppThemeChoice.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
        AppThemeChoice.light => Brightness.light,
        AppThemeChoice.dark => Brightness.dark,
      };

  void _apply() {
    final next =
        brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
    if (AppColors.scheme.value != next) AppColors.scheme.value = next;
  }

  static AppThemeChoice parse(String? stored) => switch (stored) {
        'light' => AppThemeChoice.light,
        'dark' => AppThemeChoice.dark,
        _ => AppThemeChoice.system,
      };

  static String wire(AppThemeChoice choice) => choice.name;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Reaches the theme from anywhere under the app root.
class AppThemeScope extends InheritedNotifier<AppTheme> {
  const AppThemeScope({super.key, required AppTheme super.notifier, required super.child});

  static AppTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeScope>()!.notifier!;
}
