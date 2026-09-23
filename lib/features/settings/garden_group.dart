/// Jouw tuin — the three facts every planting date is computed from: where the
/// garden is, what it is, and what the plan is allowed to assume about it.
///
/// Region already had a picker. Situation, size and sun were asked once during
/// onboarding and then never again, which is wrong the moment someone moves
/// house or clears another bed: the plan keeps sizing itself to a balcony the
/// gardener left behind. The sheet below asks the same three questions in the
/// same words and with the same controls as onboarding did, so it reads as the
/// app remembering rather than as a form.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../db/database.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/icons.dart';
import '../../design/motion.dart';
import '../../design/typography.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../purchases/purchase_service.dart';
import '../location/location_sheet.dart';
import '../paywall/paywall_screen.dart';
import '../repository_scope.dart';
import 'settings_rows.dart';

class GardenGroup extends StatefulWidget {
  const GardenGroup({super.key, this.onChanged});

  /// The profile's stat tiles and identity card are built from the same data,
  /// so the page above reloads when anything here lands.
  final VoidCallback? onChanged;

  @override
  State<GardenGroup> createState() => _GardenGroupState();
}

class _GardenGroupState extends State<GardenGroup> {
  Future<GardenRow?>? _garden;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _garden ??= _load();
  }

  Future<GardenRow?> _load() async {
    final gardens = await RepositoryScope.of(context).gardens();
    return gardens.isEmpty ? null : gardens.first;
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _garden = _load());
    widget.onChanged?.call();
  }

  /// What the garden row says on the right: the situation, and the size when
  /// there is one. Enough to tell at a glance whether it is still true.
  String _gardenValue(BuildContext context, GardenRow? garden) {
    if (garden == null) return '';
    final kind = gardenKindLabel(garden.kind).of(context);
    final size = garden.sizeM2;
    return size == null ? kind : '$kind · ${Str.gardenSizeM2(size).of(context)}';
  }

  Future<void> _editGarden(GardenRow garden) async {
    final saved = await showAppSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _GardenProfileSheet(garden: garden),
    );
    if (saved != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Str.gardenSaved.of(context))),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final plan = PurchaseScope.maybeOf(context)?.plan ?? Plan.free;
    return FutureBuilder<GardenRow?>(
      future: _garden,
      builder: (context, snap) {
        final garden = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(Str.yourGarden.of(context)),
            SettingsGroup(rows: [
              SettingsRow(
                icon: PhosphorIcons.mapPin,
                title: Str.region.of(context),
                value: repo.regionName,
                onTap: () async {
                  await showLocationPicker(context);
                  _reload();
                },
              ),
              SettingsRow(
                icon: PhosphorIcons.plant,
                title: Str.gardenProfile.of(context),
                value: _gardenValue(context, garden),
                onTap: garden == null ? null : () => _editGarden(garden),
              ),
              SettingsRow(
                icon: PhosphorIcons.medal,
                title: Str.membership.of(context),
                value: switch (plan) {
                  Plan.free => Str.planFree,
                  Plan.lifetime => Str.planLifetime,
                  Plan.yearly => Str.planYearly,
                }
                    .of(context),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                ),
              ),
              // Only a subscription can be managed, and only Apple can manage
              // it; lifetime has nothing to cancel and free has nothing to
              // manage, so neither gets a row that leads to a dead end.
              if (plan == Plan.yearly)
                SettingsRow(
                  icon: PhosphorIcons.arrowClockwise,
                  title: Str.managePlan.of(context),
                  trailing: PhosphorIcons.arrowSquareOut,
                  onTap: () => launchUrl(
                    Uri.parse('https://apps.apple.com/account/subscriptions'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ]),
          ],
        );
      },
    );
  }
}

/// The three onboarding questions, asked again. Same buckets, same chips, same
/// slider — a different set of controls here would read as a different app.
class _GardenProfileSheet extends StatefulWidget {
  const _GardenProfileSheet({required this.garden});

  final GardenRow garden;

  @override
  State<_GardenProfileSheet> createState() => _GardenProfileSheetState();
}

class _GardenProfileSheetState extends State<_GardenProfileSheet> {
  /// Onboarding's own buckets (§5.1): nobody measures their balcony, they
  /// recognise it.
  static const _sizes = [('< 2 m²', 1), ('2–5 m²', 4), ('5–20 m²', 12), ('> 20 m²', 30)];

  late GardenKind _kind = widget.garden.kind;
  late double _sun = (widget.garden.sunHours ?? 6).toDouble();
  late int _size = _nearestBucket(widget.garden.sizeM2);

  /// A stored size can be any number — an older build, a future editor — so the
  /// bucket shown is the one it sits closest to rather than none at all.
  static int _nearestBucket(int? m2) {
    if (m2 == null) return _sizes.first.$2;
    var best = _sizes.first.$2;
    for (final (_, value) in _sizes) {
      if ((value - m2).abs() < (best - m2).abs()) best = value;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Str.gardenProfile.of(context), style: AppText.title(context)),
            const SizedBox(height: 4),
            Text(Str.gardenProfileBlurb.of(context), style: AppText.caption(context)),
            const SizedBox(height: 20),
            Text(Str.growingSituation.of(context), style: AppText.label(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final k in GardenKind.values)
                  ChoiceChip(
                    label: Text(
                      '${gardenKindEmoji(k)}  ${gardenKindLabel(k).of(context)}',
                      style: AppText.body(context),
                    ),
                    selected: _kind == k,
                    selectedColor: AppColors.accentSoft,
                    onSelected: (_) {
                      Haptics.selection();
                      setState(() => _kind = k);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(Str.gardenSize.of(context), style: AppText.label(context)),
            Text(Str.gardenSizeHint.of(context), style: AppText.caption(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                // The bucket labels are numbers and a unit, so they read the
                // same in both languages and carry no string of their own.
                for (final (label, value) in _sizes)
                  ChoiceChip(
                    label: Text(label, style: AppText.body(context)),
                    selected: _size == value,
                    selectedColor: AppColors.accentSoft,
                    onSelected: (_) {
                      Haptics.selection();
                      setState(() => _size = value);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(Str.sunHoursLabel.of(context), style: AppText.label(context)),
            Text(Str.sunHoursHint.of(context), style: AppText.caption(context)),
            Slider(
              value: _sun,
              min: 0,
              max: 12,
              divisions: 12,
              activeColor: AppColors.accent,
              label: Str.sunHours(_sun.round()).of(context),
              onChanged: (s) => setState(() => _sun = s),
            ),
            Text(Str.sunHours(_sun.round()).of(context), style: AppText.caption(context)),
            const SizedBox(height: 20),
            PrimaryButton(
              label: Str.saveChanges.of(context),
              onPressed: () async {
                await repo.updateGarden(
                  widget.garden.id,
                  kind: _kind,
                  sizeM2: _size,
                  sunHours: _sun.round(),
                );
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
