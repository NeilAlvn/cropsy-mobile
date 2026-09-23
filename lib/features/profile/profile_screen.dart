/// Profile — who the gardener is, what their season looks like, and everything
/// the app can be told about itself.
///
/// Base 8.9 detail header, base 8.18 stat figures, base 8.7 grouped rows.
///
/// This used to be two groups and a row called "Settings & Sync", behind which
/// sat the theme switch, the language switch, the FAQ and account deletion —
/// all present, none findable. So the settings came out to meet the gardener:
/// each group builds itself from its own file under features/settings, and the
/// only thing left behind a push is the sign-in form, because that one really
/// is a page of typing.
library;

import 'package:flutter/material.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';
import '../../design/icons.dart';

import '../../db/database.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../timing/streak.dart';
import '../garden/garden_repository.dart';
import '../repository_scope.dart';
import '../settings/accessibility_group.dart';
import '../settings/account_group.dart';
import '../settings/appearance_group.dart';
import '../settings/garden_group.dart';
import '../settings/help_group.dart';
import '../settings/notifications_group.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<_ProfileData>? _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _data ??= _load();
  }

  Future<_ProfileData> _load() async {
    final repo = RepositoryScope.of(context);
    final premium = PurchaseScope.maybeOf(context)?.premium ?? false;
    final profile = await repo.profile();
    final plants = await repo.plants();
    final streak = await repo.streak(premium: premium);
    final tally = await repo.seasonTally();
    return _ProfileData(
      displayName: profile?.displayName,
      plants: plants,
      streak: streak,
      harvestEuros: tally.euros,
      premium: premium,
    );
  }

  void _reload() {
    if (mounted) setState(() => _data = _load());
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final auth = AuthScope.maybeOf(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: AppColors.canvas,
        iconTheme: IconThemeData(color: AppColors.ink),
        title: Text(Str.profile.of(context), style: AppText.subheading(context)),
        centerTitle: true,
      ),
      body: FutureBuilder<_ProfileData>(
        future: _data,
        builder: (context, snap) {
          final d = snap.data;
          if (d == null) {
            return Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final growing = d.plants.where((p) => p.plantedOn != null).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _Identity(
                name: d.displayName ?? Str.gardener.of(context),
                email: auth?.user?.email,
                premium: d.premium,
                onEditName: () => _editName(repo, d.displayName),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _Stat(figure: '${d.streak.count}', label: Str.dayStreak.of(context))),
                  const SizedBox(width: 12),
                  Expanded(child: _Stat(figure: '$growing', label: Str.growingNow.of(context))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(
                      figure: '€${d.harvestEuros.round()}',
                      label: Str.harvested.of(context),
                    ),
                  ),
                ],
              ),
              // The order is the order someone looks for things in: their own
              // garden first, then how the app looks and speaks, then what it
              // sends, then what it can tone down, then the account, then help.
              const SizedBox(height: 16),
              GardenGroup(onChanged: _reload),
              const SizedBox(height: 16),
              const AppearanceGroup(),
              const SizedBox(height: 16),
              const NotificationsGroup(),
              const SizedBox(height: 16),
              const AccessibilityGroup(),
              const SizedBox(height: 16),
              AccountGroup(onChanged: _reload),
              const SizedBox(height: 16),
              const HelpGroup(),
              // Which crop data and which frost dates this plan was built from.
              // Two lines nobody needs until the day a date looks wrong.
              const SizedBox(height: 24),
              Text(Str.cropDataVersion(repo.cropVersion).of(context),
                  style: AppText.caption(context)),
              Text(Str.frostDates(repo.regionName, repo.frostSource).of(context),
                  style: AppText.caption(context)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editName(GardenRepository repo, String? current) async {
    final controller = TextEditingController(text: current ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Neo.radius)),
        title: Text(Str.yourName.of(context), style: AppText.heading(context)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppText.body(context),
          decoration: InputDecoration(hintText: Str.gardener.of(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(Str.cancel.of(context), style: AppText.label(context, color: AppColors.ink)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(Str.save.of(context), style: AppText.label(context, color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (name == null) return;
    await repo.saveProfile(displayName: name.isEmpty ? null : name);
    _reload();
  }
}

class _ProfileData {
  const _ProfileData({
    required this.displayName,
    required this.plants,
    required this.streak,
    required this.harvestEuros,
    required this.premium,
  });

  final String? displayName;
  final List<GardenPlantRow> plants;
  final StreakResult streak;
  final double harvestEuros;
  final bool premium;
}

/// Avatar, name, and what the account is. One card, base 8.5.
class _Identity extends StatelessWidget {
  const _Identity({
    required this.name,
    required this.email,
    required this.premium,
    required this.onEditName,
  });

  final String name;
  final String? email;
  final bool premium;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onEditName,
        child: Row(
          children: [
            ProfileAvatar(name: name, size: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.heading(context)),
                  const SizedBox(height: 2),
                  Text(
                    email ?? Str.onThisDeviceOnly.of(context),
                    style: AppText.caption(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (premium)
              Pill(
                label: Str.planLifetime.of(context),
                icon: PhosphorIcons.medal,
                color: AppColors.onAccentSoft,
                bg: AppColors.accentSoft,
              ),
          ],
        ),
      );
}

/// Base 8.18: a figure with its label under it. No ring, no bar: these are
/// counts, not scores, so nothing here carries a band.
class _Stat extends StatelessWidget {
  const _Stat({required this.figure, required this.label});

  final String figure;
  final String label;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(
              figure,
              style: AppText.title(context).copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(label,
                style: AppText.caption(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

/// The gardener's initial on an accent-soft circle. Used in the profile and in
/// the home header, so both read as the same person.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.name, this.size = 36});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'G' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        shape: BoxShape.circle,
        // A white ring, so the avatar reads on the home band's lime as well as
        // on a white card.
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Text(
        initial,
        style: AppText.subheading(context, color: AppColors.onAccentSoft)
            .copyWith(fontSize: size * 0.42),
      ),
    );
  }
}
