/// Settings (PRD 8.2, Phase 1 slice): account (magic link / password), sync
/// status, export my data, delete account. Membership, help, contact, language
/// switch follow in Phase 2/3. Never a rate prompt.
library;

import 'dart:convert';
import '../../l10n/strings.dart';
import '../../timing/types.dart';

import 'package:flutter/material.dart';
import '../../design/icons.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';

import '../../db/database.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/theme_mode.dart';
import '../../l10n/app_lang.dart';
import '../../design/typography.dart';
import '../../purchases/purchase_service.dart';
import '../../sync/auth_service.dart';
import '../../sync/sync_engine.dart';
import '../paywall/paywall_screen.dart';
import '../garden/garden_repository.dart';
import '../repository_scope.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _status;
  bool _busy = false;

  Future<void> _run(Future<void> Function() f, {String? done}) async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await f();
      setState(() => _status = done);
    } catch (e) {
      setState(() => _status = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final auth = AuthScope.maybeOf(context);
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: AppColors.paper,
        iconTheme: IconThemeData(color: AppColors.ink),
        title: Text(Str.settings.of(context), style: AppText.heading(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          SectionHeader(Str.account.of(context)),
          if (auth == null)
            Text(Str.syncUnavailable.of(context), style: AppText.bodyMuted(context))
          else if (auth.signedIn)
            _signedIn(context, auth, repo)
          else
            _signIn(context, auth),
          if (_status != null) ...[
            const SizedBox(height: 10),
            Text(_status!, style: AppText.caption(context, color: AppColors.sprout)),
          ],
          const SizedBox(height: 24),
          SectionHeader(Str.membership.of(context)),
          Builder(builder: (context) {
            final p = PurchaseScope.maybeOf(context);
            final plan = p?.plan ?? Plan.free;
            return AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                    switch (plan) {
                      Plan.free => Str.planFree,
                      Plan.lifetime => Str.planLifetime,
                      Plan.yearly => Str.planYearly,
                    }.of(context),
                    style: AppText.label(context)),
                Text(
                  switch (plan) {
                    Plan.free => Str.freeTierBlurb.of(context),
                    Plan.lifetime => Str.lifetimeNothingToCancel.of(context),
                    Plan.yearly => 'Renews yearly. Manage or cancel in the App Store / Play Store.',
                  },
                  style: AppText.caption(context),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  if (plan == Plan.free)
                    Expanded(
                      child: SecondaryButton(
                        label: Str.seePlans.of(context),
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen(), fullscreenDialog: true)),
                      ),
                    ),
                  if (plan == Plan.yearly)
                    Expanded(
                      child: SecondaryButton(
                        label: Str.managePlan.of(context),
                        onPressed: () => launchUrl(Uri.parse('https://apps.apple.com/account/subscriptions'), mode: LaunchMode.externalApplication),
                      ),
                    ),
                  if (p?.configured == true) ...[
                    const SizedBox(width: 8),
                    Expanded(child: SecondaryButton(label: Str.restore.of(context), onPressed: () => _run(() async => p!.restore(), done: Str.checkedWithStore.of(context)))),
                  ],
                ]),
              ]),
            );
          }),
          const SizedBox(height: 24),
          SectionHeader(Str.yourData.of(context)),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(PhosphorIcons.downloadSimple, color: AppColors.sprout),
              title: Text(Str.exportData.of(context), style: AppText.label(context)),
              subtitle: Text(Str.exportBlurb.of(context), style: AppText.caption(context)),
              onTap: () => _run(() async {
                await Clipboard.setData(ClipboardData(text: await _export(repo)));
              }, done: Str.copied.of(context)),
            ),
          ),
          SizedBox(height: 24),
          SectionHeader(Str.appearance.of(context)),
          Builder(builder: (context) {
            final theme = AppThemeScope.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<AppThemeChoice>(
                  segments: [
                    ButtonSegment(
                        value: AppThemeChoice.system,
                        label: Text(Str.themeSystem.of(context))),
                    ButtonSegment(
                        value: AppThemeChoice.light,
                        label: Text(Str.themeLight.of(context))),
                    ButtonSegment(
                        value: AppThemeChoice.dark,
                        label: Text(Str.themeDark.of(context))),
                  ],
                  selected: {theme.choice},
                  onSelectionChanged: (v) async {
                    theme.choice = v.first;
                    await repo.setMeta(AppTheme.metaKey, AppTheme.wire(v.first));
                  },
                ),
                const SizedBox(height: 4),
                Text(Str.themeFollows.of(context), style: AppText.caption(context)),
              ],
            );
          }),
          const SizedBox(height: 24),
          SectionHeader(Str.language.of(context)),
          FutureBuilder<ProfileRow?>(
            future: repo.profile(),
            builder: (context, snap) {
              final lang = snap.data?.lang ?? 'nl';
              return SegmentedButton<String>(
                segments: const [ButtonSegment(value: 'nl', label: Text('Nederlands')), ButtonSegment(value: 'en', label: Text('English'))],
                selected: {lang},
                onSelectionChanged: (v) async {
                  AppLangScope.of(context).code = v.first;
                  await repo.saveProfile(lang: v.first);
                  if (context.mounted) setState(() {});
                },
              );
            },
          ),
          const SizedBox(height: 4),
          Text(Str.langNote.of(context), style: AppText.caption(context)),
          const SizedBox(height: 24),
          SectionHeader(Str.help.of(context)),
          for (final (q, a) in _faq)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(q.of(context), style: AppText.label(context)),
                iconColor: AppColors.sprout,
                collapsedIconColor: AppColors.muted,
                children: [Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(bottom: 10), child: Text(a.of(context), style: AppText.bodyMuted(context))))],
              ),
            ),
          SizedBox(height: 12),
          for (final (label, icon, path) in [
            ('Contact us', PhosphorIcons.envelope, '/support'),
            ('Privacy', PhosphorIcons.lock, '/privacy'),
            ('Terms', PhosphorIcons.fileText, '/terms'),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: AppColors.sprout),
              title: Text(label, style: AppText.label(context)),
              trailing: Icon(PhosphorIcons.arrowSquareOut, size: 16, color: AppColors.muted),
              onTap: () => launchUrl(Uri.parse('$websiteUrl$path'), mode: LaunchMode.externalApplication),
            ),
          const SizedBox(height: 24),
          SectionHeader('About'),
          Text(Str.cropDataVersion(repo.cropVersion).of(context), style: AppText.caption(context)),
          Text(Str.frostDates(repo.regionName, repo.frostSource).of(context), style: AppText.caption(context)),
        ],
      ),
    );
  }

  Widget _signIn(BuildContext context, AuthService auth) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Str.signInBlurb.of(context), style: AppText.bodyMuted(context)),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: AppText.body(context),
            decoration: InputDecoration(labelText: Str.email.of(context)),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: Str.sendLink.of(context),
            onPressed: _busy
                ? null
                : () => _run(() => auth.sendMagicLink(_email.text.trim()),
                    done: Str.checkYourMail.of(context)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            obscureText: true,
            style: AppText.body(context),
            decoration: InputDecoration(labelText: Str.passwordOptional.of(context)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: SecondaryButton(
                label: Str.signIn.of(context),
                onPressed: _busy ? null : () => _run(() => auth.signInWithPassword(_email.text.trim(), _password.text)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SecondaryButton(
                label: Str.createAccount.of(context),
                onPressed: _busy
                    ? null
                    : () => _run(() => auth.signUp(_email.text.trim(), _password.text),
                        done: Str.accountCreated.of(context)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _signedIn(BuildContext context, AuthService auth, GardenRepository repo) {
    final last = auth.lastSyncAt;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(auth.user?.email ?? Str.signedIn.of(context), style: AppText.label(context)),
          const SizedBox(height: 4),
          Text(
            auth.syncing
                ? Str.syncing.of(context)
                : last == null
                    ? Str.notSyncedYet.of(context)
                    : Str.lastSync(
                            '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}')
                        .of(context) +
                        (auth.lastReport?.ok == false
                            ? Str.someTablesFailed.of(context)
                            : ''),
            style: AppText.caption(context),
          ),
          if (auth.lastReport?.ok == false)
            for (final e in auth.lastReport!.errors.entries)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${e.key}: ${e.value}', style: AppText.caption(context, color: AppColors.warn), maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
          // What actually moved, per table. Without this a sync that silently
          // pushed nothing looks exactly like one that worked.
          if (auth.lastReport != null && !auth.syncing) ...[
            const SizedBox(height: 8),
            Text(_movement(auth.lastReport!, context), style: AppText.caption(context)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PrimaryButton(label: Str.syncNow.of(context), onPressed: auth.syncing ? null : () => _run(() async => auth.syncNow()))),
            const SizedBox(width: 8),
            Expanded(child: SecondaryButton(label: Str.signOut.of(context), onPressed: () => _run(auth.signOut))),
          ]),
          const SizedBox(height: 16),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warn),
            onPressed: _busy ? null : () => _deleteAccount(auth, repo),
            child: Text(Str.deleteAccount.of(context)),
          ),
        ],
      ),
    );
  }

  /// "12 rows up, 4 down" per table, or that nothing needed to move.
  String _movement(SyncReport report, BuildContext context) {
    final parts = <String>[];
    for (final table in {...report.pushed.keys, ...report.pulled.keys}) {
      final up = report.pushed[table] ?? 0;
      final down = report.pulled[table] ?? 0;
      if (up == 0 && down == 0) continue;
      parts.add('$table ${up > 0 ? '↑$up' : ''}${up > 0 && down > 0 ? ' ' : ''}${down > 0 ? '↓$down' : ''}');
    }
    return parts.isEmpty ? Str.alreadyInStep.of(context) : parts.join(' · ');
  }

  Future<void> _deleteAccount(AuthService auth, GardenRepository repo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(Str.deleteAccountAsk.of(context), style: AppText.title(context)),
        content: Text(Str.deleteAccountBody.of(context),
            style: AppText.bodyMuted(context)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(Str.cancel.of(context))),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warn),
            onPressed: () => Navigator.pop(context, true),
            child: Text(Str.delete.of(context)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    // Read the line before the await, so the dialog's context is not used after it.
    final done = Str.deleted.of(context);
    await _run(() async {
      final deleted = await auth.deleteAccount();
      if (!deleted) throw StateError('Could not delete the account. Try again later.');
    }, done: done);
  }

  Future<String> _export(GardenRepository repo) async {
    final db = repo.db;
    return const JsonEncoder.withIndent('  ').convert({
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'profile': (await repo.profile())?.toJson(),
      'gardens': [for (final r in await db.select(db.gardens).get()) r.toJson()],
      'garden_plants': [for (final r in await db.select(db.gardenPlants).get()) r.toJson()],
      'tasks': [for (final r in await db.select(db.tasks).get()) r.toJson()],
      'journal_entries': [for (final r in await db.select(db.journalEntries).get()) r.toJson()],
      'harvests': [for (final r in await db.select(db.harvests).get()) r.toJson()],
    });
  }
}

/// The help section. Chrome, not content, so it lives here rather than in the
/// snapshot, and it carries both languages like everything else the user reads.
const _faq = <(LocalizedText, LocalizedText)>[
  (
    LocalizedText(
      nl: 'Waar komen de plantdata vandaan?',
      en: 'Where do the planting dates come from?',
    ),
    LocalizedText(
      nl: 'Uit de vorstdatums voor jouw locatie (KNMI / Open-Meteo '
          'klimaatnormalen, afgerond op ~10 km), gecombineerd met teeltregels '
          'die tegen minstens twee Nederlandse zaaikalenders zijn gelegd.',
      en: 'From the frost dates for your location (KNMI / Open-Meteo climate '
          'normals, rounded to ~10 km) combined with crop rules cross-checked '
          'against at least two Dutch seed calendars.',
    ),
  ),
  (
    LocalizedText(
      nl: 'Ik loop achter. Is mijn plan verpest?',
      en: 'I fell behind. Is my plan ruined?',
    ),
    LocalizedText(
      nl: 'Nee. Log wat je echt hebt gedaan en wanneer; elke volgende stap '
          'schuift mee. Niets is ooit "te laat", het is "verzet".',
      en: 'No. Log what you actually did and when; every later step moves with '
          'it. Nothing is ever "overdue", it is "moved".',
    ),
  ),
  (
    LocalizedText(
      nl: 'Waarom is een waterbeurt verdwenen?',
      en: 'Why did a watering disappear?',
    ),
    LocalizedText(
      nl: 'Het heeft rond die dag genoeg geregend, of er is regen voorspeld. '
          'De weerregel op Home vertelt wat er veranderde.',
      en: 'It rained enough around that day, or rain is forecast. The weather '
          'line on Home says what changed.',
    ),
  ),
  (
    LocalizedText(nl: 'Werkt het offline?', en: 'Does it work offline?'),
    LocalizedText(
      nl: 'Ja. Gewassen, data, herinneringen en de tijdlijn draaien op de '
          'telefoon. Weerhints en synchroniseren hebben verbinding nodig.',
      en: 'Yes. Crops, dates, reminders and the timeline all run on the phone. '
          'Weather hints and sync need a connection.',
    ),
  ),
  (
    LocalizedText(
      nl: 'Wat zit er in de gratis versie?',
      en: 'What does the free tier include?',
    ),
    LocalizedText(
      nl: 'Eén tuin, zes groeiende planten, de volledige tijdlijn, '
          'herinneringen en elk gewas, voorgoed. Lifetime geeft meer ruimte.',
      en: 'One garden, six growing plants, the full timeline, reminders and '
          'every crop, forever. Lifetime unlocks more room.',
    ),
  ),
  (
    LocalizedText(
      nl: 'Hoe verwijder ik mijn account?',
      en: 'How do I delete my account?',
    ),
    LocalizedText(
      nl: 'Instellingen → Account → Account verwijderen. Dat wist je account '
          'en elke gesynchroniseerde rij; lokale gegevens blijven op deze '
          'telefoon tot je de app verwijdert.',
      en: 'Settings → Account → Delete account. It removes your account and '
          'every synced row; local data stays on this phone until you delete '
          'the app.',
    ),
  ),
];
