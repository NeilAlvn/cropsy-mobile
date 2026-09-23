// Cropsy prototype entry point.
//
// Boots the on-device garden repository (SQLite in the documents dir), then
// gates on onboarding: first run shows the setup flow; once a garden exists the
// tabbed app takes over. Offline is the default state (PRD §4).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config.dart';
import 'analytics/analytics.dart';
import 'db/connection.dart';
import 'design/brutal.dart';
import 'design/colors.dart';
import 'design/motion.dart';
import 'design/theme_mode.dart';
import 'l10n/app_lang.dart';
import 'features/app_shell.dart';
import 'features/garden/garden_repository.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/repository_scope.dart';
import 'notifications/reminders.dart';
import 'purchases/purchase_service.dart';
import 'sync/auth_service.dart';

/// Boot, wrapped in crash reporting when a DSN is configured (PRD §5.9).
///
/// Sentry starts before the app does so a failure during boot — a corrupt
/// database, a missing migration — is reported like any other crash. With no
/// DSN the app runs exactly as before and nothing leaves the device.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (sentryDsn.isEmpty) return _boot();
  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.environment = kReleaseMode ? 'production' : 'development';
      // A crash reporter, not an analytics SDK: no screenshots of someone's
      // garden, no IP address, no request bodies. (The view hierarchy and
      // session replay are off by default and stay off.)
      options.sendDefaultPii = false;
      options.attachScreenshot = false;
    },
    appRunner: _boot,
  );
}

Future<void> _boot() async {
  final repo = await GardenRepository.create(db: openAppDatabase());
  await AuthService.init();
  await Reminders.init();
  final auth = AuthService(repo);
  final purchases = PurchaseService();
  await purchases.init();
  // No-op unless the person opted in; see analytics/analytics.dart.
  await Analytics.init(await repo.meta(Analytics.metaKey));
  // Purchases and analytics follow the account: log the RevenueCat user and
  // the PostHog person in/out with Supabase.
  auth.addListener(() {
    final uid = auth.user?.id;
    if (uid != null) {
      purchases.logIn(uid);
      Analytics.identify(uid);
    } else {
      purchases.logOut();
      Analytics.signedOut();
    }
  });
  final theme = AppTheme(
    initial: AppTheme.parse(await repo.meta(AppTheme.metaKey)),
  );
  // Dates are read, not parsed: month and weekday names have to speak the
  // reader's language too.
  await initializeDateFormatting();
  final profile = await repo.profile();
  final lang = AppLang(profile?.lang ?? 'nl');
  Intl.defaultLocale = lang.code;
  // Haptics and reduced motion are read at paint time, with no context and no
  // await to spare, so they are pulled out of the profile once, here.
  AccessPrefs.load(
    jsonDecode(profile?.preferences ?? '{}') as Map<String, dynamic>,
  );

  // Reminders follow the data: any change re-plans the week's notifications.
  Timer? debounce;
  repo.addListener(() {
    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 2), () async {
      await Reminders.schedule(
        await repo.thisWeek(),
        today: repo.today,
        dutch: lang.isDutch,
      );
    });
  });
  runApp(CropsyApp(
    repository: repo,
    auth: auth,
    purchases: purchases,
    theme: theme,
    lang: lang,
  ));
}

class CropsyApp extends StatelessWidget {
  const CropsyApp({
    super.key,
    required this.repository,
    required this.theme,
    required this.lang,
    this.auth,
    this.purchases,
  });

  final GardenRepository repository;
  final AppTheme theme;
  final AppLang lang;
  final AuthService? auth;
  final PurchaseService? purchases;

  /// One per app, so the navigator outlives the scheme it was built under.
  static final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return RepositoryScope(
      repository: repository,
      child: AuthScope(
        auth: auth,
        child: PurchaseScope(
          purchases: purchases,
          child: AppLangScope(
            notifier: lang,
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
                // did, so a scheme change has to rebuild the app rather than
                // notify it. Keying the app on the scheme does that.
                key: ValueKey(palette.brightness),
                // That key would also throw away the navigation stack, which is
                // how changing the theme from a pushed screen used to dump you
                // back on Home. A global key re-parents the navigator into the
                // new tree instead: the routes survive, and being reactivated
                // is a dependency change, so each one rebuilds its page in the
                // scheme that just won.
                navigatorKey: _navigator,
                title: 'Cropsy',
                debugShowCheckedModeBanner: false,
                themeMode: theme.materialMode,
                theme: _themeData(Brightness.light),
                darkTheme: _themeData(Brightness.dark),
                home: _Root(),
              ),
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
      true => AppShell(),
      false => OnboardingScreen(onDone: () => setState(() => _hasGarden = true)),
    };
  }
}
