// Cropsy prototype entry point.
//
// Boots the on-device garden repository (SQLite in the documents dir), then
// gates on onboarding: first run shows the setup flow; once a garden exists the
// tabbed app takes over. Offline is the default state (PRD §4).

import 'package:flutter/material.dart';

import 'db/connection.dart';
import 'design/colors.dart';
import 'features/app_shell.dart';
import 'features/garden/garden_repository.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/repository_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await GardenRepository.create(db: openAppDatabase());
  runApp(CropsyApp(repository: repo));
}

class CropsyApp extends StatelessWidget {
  const CropsyApp({super.key, required this.repository});
  final GardenRepository repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryScope(
      repository: repository,
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
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _entered = false;

  @override
  Widget build(BuildContext context) {
    if (_entered) return const AppShell();
    return OnboardingScreen(onDone: () => setState(() => _entered = true));
  }
}
