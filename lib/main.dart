// Cropsy prototype entry point.
//
// Boots the on-device garden repository (SQLite in the documents dir), then
// gates on onboarding: first run shows the setup flow; once a garden exists the
// tabbed app takes over. Offline is the default state (PRD §4).

import 'dart:async';

import 'package:flutter/material.dart';

import 'db/connection.dart';
import 'design/colors.dart';
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
  runApp(CropsyApp(repository: repo, auth: auth, purchases: purchases));
}

class CropsyApp extends StatelessWidget {
  const CropsyApp({super.key, required this.repository, this.auth, this.purchases});
  final GardenRepository repository;
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
      child: MaterialApp(
        title: 'Cropsy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.paper,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.sprout,
            primary: AppColors.sprout,
            surface: AppColors.paper,
          ),
          useMaterial3: true,
          textTheme: Typography.blackMountainView.apply(bodyColor: AppColors.ink),
          // Every text field picks up the bordered neo look.
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.border, width: 2.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppColors.sprout, width: 2.5),
            ),
          ),
        ),
        home: const _Root(),
      ),
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
      null => const Scaffold(backgroundColor: AppColors.paper),
      true => const AppShell(),
      false => OnboardingScreen(onDone: () => setState(() => _hasGarden = true)),
    };
  }
}
