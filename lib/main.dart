// Cropsy prototype entry point.
//
// Boots the on-device garden repository (SQLite in the documents dir), then
// gates on onboarding: first run shows the setup flow; once a garden exists the
// tabbed app takes over. Offline is the default state (PRD §4).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config.dart';
import 'analytics/analytics.dart';
import 'db/connection.dart';
import 'design/brutal.dart';
import 'design/colors.dart';
import 'design/motion.dart';
import 'design/theme_mode.dart';
import 'l10n/app_lang.dart';
import 'l10n/region.dart';
import 'l10n/strings.dart';
import 'features/app_shell.dart';
import 'features/garden/garden_repository.dart';
import 'features/garden/log_node_flow.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'timing/dates.dart' show parseIso, toIso;
import 'timing/engine.dart' show nextStart;
import 'features/paywall/paywall_screen.dart';
import 'features/repository_scope.dart';
import 'notifications/lifecycle.dart';
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
  await SentryFlutter.init((options) {
    options.dsn = sentryDsn;
    options.environment = kReleaseMode ? 'production' : 'development';
    // A crash reporter, not an analytics SDK: no screenshots of someone's
    // garden, no IP address, no request bodies. (The view hierarchy and
    // session replay are off by default and stay off.)
    options.sendDefaultPii = false;
    options.attachScreenshot = false;
  }, appRunner: _boot);
}

Future<void> _boot() async {
  final repo = await GardenRepository.create(db: openAppDatabase());
  await AuthService.init();
  await Reminders.init(onTap: _openFromNotification);
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
  final theme = AppTheme(initial: AppTheme.parse(await repo.meta(AppTheme.metaKey)));
  // Dates are read, not parsed: month and weekday names have to speak the
  // reader's language too.
  await initializeDateFormatting();
  final profile = await repo.profile();
  final lang = AppLang(profile?.lang ?? deviceLang());
  AppRegion.apply(lang: lang.code, country: repo.effectiveCountry);
  // Haptics and reduced motion are read at paint time, with no context and no
  // await to spare, so they are pulled out of the profile once, here.
  AccessPrefs.load(jsonDecode(profile?.preferences ?? '{}') as Map<String, dynamic>);

  // Reminders follow the data: any change re-plans the week's notifications.
  Timer? debounce;
  repo.addListener(() {
    debounce?.cancel();
    debounce = Timer(const Duration(seconds: 2), () async {
      await Reminders.schedule(await repo.thisWeek(), today: repo.today, lang: lang.code);
    });
  });
  _coldStart = (int.tryParse(await repo.meta(Lifecycle.appOpensKey) ?? '') ?? 0) + 1;
  await repo.setMeta(Lifecycle.appOpensKey, '$_coldStart');
  // Read before runApp so its paywall is pushed before the app shell's first
  // frame, where the app-open paywall checks whether one already opened.
  final launched = await Reminders.launchPayload();
  runApp(CropsyApp(repository: repo, auth: auth, purchases: purchases, theme: theme, lang: lang));

  // A notification that cold-started the app is answered once there is a
  // navigator to answer it with.
  WidgetsBinding.instance.addPostFrameCallback((_) => _openFromNotification(launched));

  // Seasonal nudges for free gardeners, re-aimed on launch, on resume and
  // whenever the plan changes (buying clears them).
  Future<void> nudges() => Lifecycle.syncSeasonal(premium: purchases.premium, lang: lang.code);
  unawaited(nudges());
  purchases.addListener(nudges);
  AppLifecycleListener(onResume: nudges);
}

/// This cold start's number, counted in meta; see [Lifecycle.appOpenPaywall].
int _coldStart = 0;

/// A paywall already opened this start, so the app-open one stays away.
bool _paywallOpened = false;

void _openFromNotification(String? payload) {
  final trigger = switch (payload) {
    Lifecycle.paywallPayload => PaywallTrigger.homeCard,
    Lifecycle.secondChancePayload => PaywallTrigger.secondChance,
    _ => null,
  };
  if (trigger == null) return;
  _pushPaywall(trigger);
}

void _pushPaywall(PaywallTrigger trigger) {
  _paywallOpened = true;
  CropsyApp.navigator.currentState?.push(MaterialPageRoute(
    builder: (_) => PaywallScreen(trigger: trigger),
    fullscreenDialog: true,
  ));
}

/// Onboarding just ended. Remembers when, and gives a free gardener who
/// walked past the paywall one reminder two days later. Once per install: a
/// reinstall or a second onboarding (sign-out) does not earn another.
Future<void> _afterOnboarding(GardenRepository repo, PurchaseService? purchases, String lang) async {
  final now = DateTime.now();
  await repo.setMeta('onboarded_at', now.toIso8601String());
  if ((purchases?.premium ?? false) || await repo.meta(Lifecycle.secondChanceKey) != null) return;
  await repo.setMeta(Lifecycle.secondChanceKey, now.toIso8601String());
  final fire = Lifecycle.secondChanceTime(now);
  final next = Lifecycle.stepAfter(await repo.seasonTasks(), fire);
  var step = next == null ? null : Str.stepOnCrop(nodeKindLine(next.kind), repo.cropNames(next.cropSlug));
  var days = next?.days ?? 0;
  if (next == null) {
    // Out of season nothing grows yet: name the first start to come, when it
    // is close enough to act on. Further off, the generic line says it better.
    final day = toIso(fire);
    final soon = [
      for (final p in await repo.planningPlants())
        if (repo.cropBySlug(p.cropSlug) case final c?)
          if (nextStart(c, repo.frost, day) case final s? when !s.open)
            (slug: p.cropSlug, s: s, days: parseIso(s.start).difference(parseIso(day)).inDays),
    ].where((x) => x.days <= 30).toList()
      ..sort((a, b) => a.days.compareTo(b.days));
    if (soon.isNotEmpty) {
      step = Str.stepOnCrop(startLine(soon.first.s.method), repo.cropNames(soon.first.slug));
      days = soon.first.days;
    }
  }
  final body = Str.secondChanceBody(step, days, trial: (purchases?.trialDaysOffered ?? 0) > 0);
  await Lifecycle.scheduleSecondChance(now, body, lang: lang);
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
  static final navigator = GlobalKey<NavigatorState>();

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
                builder: (context, palette, _) => ListenableBuilder(
                  listenable: lang,
                  builder: (context, _) => MaterialApp(
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
                    navigatorKey: navigator,
                    title: 'Cropsy',
                    debugShowCheckedModeBanner: false,
                    themeMode: theme.materialMode,
                    theme: _themeData(Brightness.light),
                    darkTheme: _themeData(Brightness.dark),
                    locale: Locale(lang.code),
                    supportedLocales: [for (final (code, _) in pickerLanguages) Locale(code)],
                    localizationsDelegates: GlobalMaterialLocalizations.delegates,
                    home: _Root(),
                  ),
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

  /// Onboarding has created the garden and is showing the plan it built.
  ///
  /// Without this the gate would fire the moment that garden lands and swap
  /// onboarding for the app mid-flow, so the payoff screen and the paywall
  /// after it never appear. From here on onboarding owns its own exit.
  bool _onboardingFinishing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs on every repository change too: after a sign-in sync pulls a
    // garden, onboarding gives way to the app without a restart.
    if (_hasGarden != true && !_onboardingFinishing) {
      RepositoryScope.of(context).hasGarden().then((v) {
        if (mounted && v != _hasGarden && !_onboardingFinishing) {
          final onboarding = _hasGarden == false;
          setState(() => _hasGarden = v);
          if (v) WidgetsBinding.instance.addPostFrameCallback((_) => _appOpenPaywall(onboarding));
        }
      });
    }
  }

  /// [onboarding]: it was on screen this start, and a garden synced in under
  /// it; that start has had its paywall.
  void _appOpenPaywall(bool onboarding) {
    if (!mounted) return;
    final show = Lifecycle.appOpenPaywall(
      coldStart: _coldStart,
      premium: PurchaseScope.maybeOf(context)?.premium ?? false,
      onboarding: onboarding,
      paywallOpened: _paywallOpened,
    );
    if (show) _pushPaywall(PaywallTrigger.appOpen);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_hasGarden) {
      null => Scaffold(backgroundColor: AppColors.canvas),
      true => AppShell(),
      false => OnboardingScreen(
        onBuildingPlan: () => _onboardingFinishing = true,
        onDone: () {
          unawaited(_afterOnboarding(RepositoryScope.of(context), PurchaseScope.maybeOf(context),
              AppLangScope.of(context).code));
          setState(() {
            _onboardingFinishing = false;
            _hasGarden = true;
          });
        },
      ),
    };
  }
}
