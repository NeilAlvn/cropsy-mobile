/// Home — the catalogue browse (GrowIt-shaped): region header, search + Add
/// plant, a mock premium banner, and "What to grow in [month]" with filter chips
/// and a photo-card grid. Our differentiator: the recommendations come from the
/// real frost-relative engine for the user's region.
library;

import 'package:flutter/material.dart';
import '../../l10n/mascot_lines.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';
import '../../design/icons.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/crop_image.dart';
import '../../design/feedback_row.dart';
import '../../design/glass.dart';
import '../../design/mascot.dart';
import '../../design/motion.dart';
import '../../design/typography.dart';
import '../../design/widgets.dart';
import '../../timing/dates.dart';
import '../../timing/replan.dart';
import '../../timing/streak.dart';
import '../../timing/types.dart';
import '../../timing/weather_adjust.dart';
import '../garden/garden_repository.dart';
import '../garden/plant_detail_screen.dart';
import '../grow/crop_detail_screen.dart';
import '../location/location_sheet.dart';
import '../paywall/paywall_screen.dart';
import '../profile/profile_screen.dart';
import '../repository_scope.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _month;
  String _filter = 'all';
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Default the month to "today" — read here, not in initState, since it
    // depends on the inherited RepositoryScope.
    _month ??= parseIso(RepositoryScope.of(context).today).month;
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final List<Crop> crops = _query.isNotEmpty
        ? (repo.crops
            .where((c) =>
                c.names.en.toLowerCase().contains(_query.toLowerCase()) ||
                c.names.nl.toLowerCase().contains(_query.toLowerCase()))
            .toList()
          ..sort((a, b) => a.names.en.compareTo(b.names.en)))
        : repo.whatToGrowIn(_month!, filter: _filter);

    return SafeArea(
      top: false,
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HomeBand(
              region: repo.regionName,
              onSearch: (q) => setState(() => _query = q),
            ),
          ),
          SliverToBoxAdapter(
            child: ArriveIn(
              index: 0,
              child: _LifetimeCard(onTap: () => _openPaywall(context)),
            ),
          ),
          if (_query.isEmpty) ...[
            const SliverToBoxAdapter(child: ArriveIn(index: 1, child: _StreakCard())),
            const SliverToBoxAdapter(child: ArriveIn(index: 2, child: _TodaysCare())),
            const SliverToBoxAdapter(child: ArriveIn(index: 3, child: _UpcomingHarvest())),
            SliverToBoxAdapter(
              child: ArriveIn(
                index: 4,
                child: _MonthChecklist(month: _month!, onMonth: _pickMonth),
              ),
            ),
          ],
          if (_query.isEmpty)
            SliverToBoxAdapter(
              child: _WhatToGrowHeader(
                month: _month!,
                filter: _filter,
                onMonth: _pickMonth,
                onFilter: (f) => setState(() => _filter = f),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(Str.results(crops.length).of(context),
                    style: AppText.kicker(context)),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => PhotoCard(
                  crop: crops[i],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CropDetailScreen(crop: crops[i]))),
                ),
                childCount: crops.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPaywall(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen(), fullscreenDialog: true),
      );

  Future<void> _pickMonth() async {
    final picked = await showAppSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('What to grow in…', style: AppText.title(context)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 8),
                itemCount: 12,
                itemBuilder: (context, i) {
                  final m = i + 1;
                  return ListTile(
                    title: Text(_months[i], style: AppText.body(context)),
                    trailing: m == _month
                        ? Icon(PhosphorIcons.check, color: AppColors.sprout)
                        : null,
                    onTap: () => Navigator.pop(context, m),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _month = picked);
  }
}

/// The home header band. Base 3.5 lets one primary surface run the atmosphere
/// as a band carrying chrome only: the wordmark, the region, the profile and
/// the search field. Content begins below it, on the canvas. Nothing scored may
/// sit on the band, and nothing here is.
class _HomeBand extends StatelessWidget {
  const _HomeBand({required this.region, required this.onSearch});

  final String region;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    // The band is light, so the status bar runs dark.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // The reference's light lime ground, fading into canvas (base 3.5).
          colors: [AppColors.skyTop, AppColors.skyMid, AppColors.canvas],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Cropsy', style: AppText.kicker(context, color: AppColors.accentDeep)),
                    const _Greeting(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // The mascot greets from the band, the way the reference puts its
              // character beside the hello (PRD §6: it is the voice of the app).
              const Mascot(MascotPose.wave, size: 84),
              const SizedBox(width: 4),
              const _ProfileButton(),
            ],
          ),
          const SizedBox(height: 4),
          _RegionChip(region: region),
          const SizedBox(height: 16),
          _SearchField(onChanged: onSearch),
        ],
      ),
      ),
    );
  }
}

/// "Hey, `name`" if we know it, the plain hello if we do not.
class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<ProfileRow?>(
      future: repo.profile(),
      builder: (context, snap) {
        final name = snap.data?.displayName;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                (name == null ? Str.greeting : Str.greetingNamed(name)).of(context),
                style: AppText.title(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(Str.greetingSub.of(context), style: AppText.caption(context)),
          ],
        );
      },
    );
  }
}

/// A glass pill on the atmosphere, which is the one place base 3.5 allows one.
class _RegionChip extends StatelessWidget {
  const _RegionChip({required this.region});

  final String region;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => showLocationPicker(context),
          child: GlassSurface(
            blur: 12,
            // Low saturation here: on the accent band the boost turns the pill
            // hotter than the ground it sits on.
            saturation: 1.05,
            tint: AppColors.surface,
            tintOpacity: 0.6,
            shadowed: false,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 36,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.mapPin, size: 18, color: AppColors.accent),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(region,
                        style: AppText.label(context, color: AppColors.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                  Icon(PhosphorIcons.caretDown, size: 18, color: AppColors.inkMuted),
                ],
              ),
            ),
          ),
        ),
      );
}

/// The gardener's avatar, and the way into the profile.
class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return Semantics(
      button: true,
      label: Str.profile.of(context),
      child: GestureDetector(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
        child: FutureBuilder<ProfileRow?>(
          future: repo.profile(),
          builder: (context, snap) => ProfileAvatar(
            name: snap.data?.displayName ?? 'Gardener',
            size: 40,
          ),
        ),
      ),
    );
  }
}

/// Base 8.10: pill, 48 tall, tile fill. It sits at the foot of the band, where
/// the gradient has already faded to canvas.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        onChanged: onChanged,
        style: AppText.body(context),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintText: Str.searchCrops.of(context),
          hintStyle: AppText.body(context, color: AppColors.inkPlaceholder),
          prefixIcon: Icon(PhosphorIcons.magnifyingGlass, size: 20, color: AppColors.inkMuted),
          filled: true,
          fillColor: AppColors.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Neo.radiusPill),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Neo.radiusPill),
            borderSide: BorderSide(color: AppColors.accent, width: 2),
          ),
        ),
      ),
    );
  }
}

/// PRD 2.8: shown at most once a week, dismissible, never a trial pitch.
class _LifetimeCard extends StatefulWidget {
  const _LifetimeCard({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_LifetimeCard> createState() => _LifetimeCardState();
}

class _LifetimeCardState extends State<_LifetimeCard> {
  static const _key = 'lifetime_card_dismissed_on';
  bool? _show;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_show != null) return;
    final repo = RepositoryScope.of(context);
    repo.meta(_key).then((v) {
      final hide = v != null && parseIso(repo.today).difference(parseIso(v)).inDays < 7;
      if (mounted) setState(() => _show = !hide);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_show != true) return const SizedBox.shrink();
    final repo = RepositoryScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Container(
        decoration: Neo.box(color: AppColors.ink),
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Row(
          children: [
            Icon(PhosphorIcons.medal, color: AppColors.onInk, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: widget.onTap,
                child: Text(Str.unlockLifetime.of(context),
                    style: AppText.label(context, color: AppColors.onInk)),
              ),
            ),
            IconButton(
              icon: Icon(PhosphorIcons.x, color: AppColors.onInk.withValues(alpha: 0.7), size: 20),
              onPressed: () async {
                await repo.setMeta(_key, repo.today);
                if (mounted) setState(() => _show = false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatToGrowHeader extends StatelessWidget {
  const _WhatToGrowHeader({
    required this.month,
    required this.filter,
    required this.onMonth,
    required this.onFilter,
  });
  final int month;
  final String filter;
  final VoidCallback onMonth;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onMonth,
                    child: _MonthTitle(
                        line: Str.whatToGrow(Str.month(month))),
                  ),
                ),
                const Spacer(),
                const SectionFeedbackMenu(targetKind: 'section', targetId: 'home.what_to_grow'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilterChipsRow(
            options: const [
              ('all', 'All'),
              ('indoors', 'Start indoors'),
              ('outside', 'Plant outside'),
              ('easy', 'Easy'),
            ],
            selected: filter,
            onSelect: onFilter,
          ),
        ],
      ),
    );
  }
}

/// 2.3 — Today's care: the weather card says what it changed, then today's
/// tasks with checkboxes. Nothing to do → the mascot says so.
class _TodaysCare extends StatelessWidget {
  const _TodaysCare();

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<List<ThisWeekItem>>(
      future: repo.thisWeek(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final today = snap.data!.where((i) => i.due.compareTo(repo.today) <= 0).toList();
        final open = today.where((i) => !i.completed).length;
        final skipped = today.where((i) => i.hint?.action == AdjustAction.skip).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(Str.todaysCare(open).of(context), style: AppText.title(context)),
                const Spacer(),
                const SectionFeedbackMenu(targetKind: 'section', targetId: 'home.todays_care'),
              ]),
              const SizedBox(height: 10),
              AppCard(
                child: MascotSays(
                  pose: skipped.isNotEmpty ? MascotPose.rain : (open == 0 ? MascotPose.sleeping : MascotPose.sun),
                  size: 44,
                  text: skipped.isNotEmpty
                      ? skipped.first.hint!.reason.of(context)
                      : open == 0
                          ? 'Nothing to do today. Enjoy it.'
                          : '$open thing${open == 1 ? '' : 's'} to do today.',
                ),
              ),
              const SizedBox(height: 8),
              for (final item in today.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    haptic: item.completed ? Haptics.selection : Haptics.complete,
                    onTap: () => repo.setTaskCompleted(item.taskId, !item.completed),
                    child: Row(children: [
                      Icon(item.completed ? PhosphorIcons.checkCircle : PhosphorIcons.circle,
                          color: item.completed ? AppColors.positive : AppColors.hairline),
                      const SizedBox(width: 12),
                      KindMark(item.kind, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            '${kindLine(item.kind).of(context)} · '
                            '${repo.cropBySlug(item.cropSlug)?.names.of(context) ?? item.cropName}',
                            style: AppText.label(context,
                                color: item.completed ? AppColors.inkMuted : AppColors.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (item.hint != null) WeatherHintBadge(item.hint!),
                    ]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 2.4 — Upcoming harvest: hero cards with the harvest window from the path.
class _UpcomingHarvest extends StatelessWidget {
  const _UpcomingHarvest();

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    return FutureBuilder<List<({GardenPlantRow plant, PathNode harvest})>>(
      future: repo.upcomingHarvests(),
      builder: (context, snap) {
        final rows = snap.data ?? const [];
        if (rows.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Str.upcomingHarvest(rows.length).of(context),
                  style: AppText.title(context)),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final r = rows[i];
                    final h = r.harvest;
                    final fmt = DateFormat('d MMM');
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PlantDetailScreen(plantId: r.plant.id)),
                      ),
                      child: Container(
                        width: 200,
                        decoration: Neo.box(color: AppColors.surface),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 84,
                              width: double.infinity,
                              child: CropImage(slug: r.plant.cropSlug, category: repo.cropCategory(r.plant.cropSlug)),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(repo.cropName(r.plant.cropSlug), style: AppText.label(context)),
                                  Text(
                                    '${fmt.format(parseIso(h.due))} – ${fmt.format(parseIso(h.until ?? h.due))}',
                                    style: AppText.caption(context, color: AppColors.clay),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 7.3 — streak card: days in a row with something done or skipped with a
/// reason. Two freeze days a month cover the gaps. No XP, no leagues.
class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final premium = PurchaseScope.maybeOf(context)?.premium ?? false;
    return FutureBuilder<StreakResult>(
      future: repo.streak(premium: premium),
      builder: (context, snap) {
        final s = snap.data;
        if (s == null) return const SizedBox.shrink();
        final month = repo.today.substring(0, 7);
        final freezesLeft = (2 - (s.freezesUsed[month] ?? 0)).clamp(0, 2);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: AppCard(
            child: Row(children: [
              Mascot(s.count == 0 ? MascotPose.idle : s.todayOpen ? MascotPose.pointing : MascotPose.celebrating, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (s.count == 0
                              ? Str.startStreak
                              : Str.streakDays(s.count))
                          .of(context),
                      style: AppText.label(context),
                    ),
                    Text(
                      s.count == 0
                          ? MascotLines.streakStart.of(context)
                          : (premium
                                  ? const LocalizedText(
                                      nl: 'Onbeperkt vriesdagen.',
                                      en: 'Unlimited freeze days.')
                                  : LocalizedText(
                                      nl: 'Nog $freezesLeft '
                                          '${freezesLeft == 1 ? 'vriesdag' : 'vriesdagen'} deze maand.',
                                      en: '$freezesLeft freeze '
                                          'day${freezesLeft == 1 ? '' : 's'} left this month.'))
                              .of(context),
                      style: AppText.caption(context),
                    ),
                  ],
                ),
              ),
              // Base 7: no emoji as icons. The count carries the streak.
              const SizedBox(width: 12),
              Text('${s.count}',
                  style: AppText.title(context,
                          color: s.count == 0 ? AppColors.inkPlaceholder : AppColors.accent)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
          ),
        );
      },
    );
  }
}


/// PRD 2.5: "Checklist for [month]" — seasonal items from the content
/// snapshot. Hidden until the month has content.
class _MonthChecklist extends StatelessWidget {
  const _MonthChecklist({required this.month, required this.onMonth});
  final int month;
  final VoidCallback onMonth;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final items = repo.content.checklistFor(month);
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: onMonth,
                child: _MonthTitle(line: Str.checklistFor(Str.month(month))),
              ),
            ),
            const Spacer(),
            SectionFeedbackMenu(targetKind: 'checklist', targetId: 'month-$month'),
          ]),
          if (items.any((i) => i.draft)) const Padding(padding: EdgeInsets.only(bottom: 6), child: DraftBadge()),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                onTap: it.link == null
                    ? null
                    : () {
                        final crop = repo.cropBySlug(it.link!);
                        if (crop != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => CropDetailScreen(crop: crop)));
                      },
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(it.title.of(context), style: AppText.label(context)),
                      const SizedBox(height: 2),
                      Text(it.body.of(context), style: AppText.caption(context)),
                    ]),
                  ),
                  if (it.link != null) Icon(PhosphorIcons.caretRight, color: AppColors.muted),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}


/// A section title that ends in the month picker. One text flow, so a long
/// month wraps instead of eating the words before it.
class _MonthTitle extends StatelessWidget {
  const _MonthTitle({required this.line});

  /// The whole heading, month included: Dutch and English put the month in
  /// different places, so the sentence is composed in the string table.
  final LocalizedText line;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          text: line.of(context),
          style: AppText.heading(context),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(PhosphorIcons.caretDown,
                  size: 22, color: AppColors.accent),
            ),
          ],
        ),
      );
}
