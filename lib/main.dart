// Cropsy prototype entry point.
//
// Boots the on-device garden repository (SQLite in the documents dir), then
// gates on onboarding: first run shows the setup flow; once a garden exists the
// tabbed app takes over. Offline is the default state (PRD §4).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'db/connection.dart';
import 'design/brutal.dart';
import 'design/colors.dart';
import 'design/theme_mode.dart';
import 'features/app_shell.dart';
import 'features/garden/garden_repository.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/repository_scope.dart';
import 'notifications/reminders.dart';
import 'purchases/purchase_service.dart';
import 'sync/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await GardenRepository.create(db: openAppDatabase());
  await AuthService.init();
  await Reminders.init();
  final auth = AuthService(repo);
  final purchases = PurchaseService();
  await purchases.init();
  // Purchases follow the account: log the RevenueCat user in/out with Supabase.
  auth.addListener(() {
    final uid = auth.user?.id;
    if (uid != null) {
      purchases.logIn(uid);
    } else {
      purchases.logOut();
    }
  });
  // Reminders follow the data: any change re-plans the week's notifications.
  Timer? debounce;
  repo.addListener(() {
    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 2), () async {
      await Reminders.schedule(await repo.thisWeek(), today: repo.today);
    });
  });
  final theme = AppTheme(
    initial: AppTheme.parse(await repo.meta(AppTheme.metaKey)),
  );
  runApp(CropsyApp(
    repository: repo,
    auth: auth,
    purchases: purchases,
    theme: theme,
  ));
}

class CropsyApp extends StatelessWidget {
  const CropsyApp({
    super.key,
    required this.repository,
    required this.theme,
    this.auth,
    this.purchases,
  });

  final GardenRepository repository;
  final AppTheme theme;
  final AuthService? auth;
  final PurchaseService? purchases;

  @override
  Widget build(BuildContext context) {
    return RepositoryScope(
      repository: repository,
      child: AuthScope(
        auth: auth,
        child: PurchaseScope(
          purchases: purchases,
          child: AppThemeScope(
            notifier: theme,
            // The colour tokens are getters over the live scheme, so a scheme
            // change is answered by rebuilding the app, not by threading a
            // palette through every widget.
            child: ValueListenableBuilder<AppPalette>(
              valueListenable: AppColors.scheme,
              builder: (context, palette, _) => MaterialApp(
                // Colour tokens are read during build, and a const widget that
                // was already built will not rebuild just because its ancestor
                // did. Keying the app on the scheme rebuilds everything once,
                // which is the honest cost of tokens that are not inherited.
                key: ValueKey(palette.brightness),
                title: 'Cropsy',
                debugShowCheckedModeBanner: false,
                themeMode: theme.materialMode,
                theme: _themeData(Brightness.light),
                darkTheme: _themeData(Brightness.dark),
                home: const _Root(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One builder, both schemes: the tokens already know which scheme is live,
  /// so this only has to hand Material the same values.
  ThemeData _themeData(Brightness brightness) {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        surface: AppColors.canvas,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        brightness == Brightness.dark ? ThemeData.dark().textTheme : null,
      ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      // Base 8.11: 56 tall, tile radius, hairline ring, 2 accent on focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Neo.radiusTile),
          borderSide: BorderSide(color: AppColors.hairline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Neo.radiusTile),
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool? _hasGarden;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs on every repository change too: after a sign-in sync pulls a
    // garden, onboarding gives way to the app without a restart.
    if (_hasGarden != true) {
      RepositoryScope.of(context).hasGarden().then((v) {
        if (mounted && v != _hasGarden) setState(() => _hasGarden = v);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_hasGarden) {
      null => Scaffold(backgroundColor: AppColors.paper),
      true => const AppShell(),
      false => OnboardingScreen(onDone: () => setState(() => _hasGarden = true)),
    };
  }
}
