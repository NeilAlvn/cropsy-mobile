/// Help — the answers, and the three ways out to a human.
///
/// The questions used to be accordions at the bottom of a 584-line settings
/// screen, which is the same as not having them. They get a screen of their
/// own now, one row away from the profile, and the three links keep their
/// locale prefix so the site does not answer in the wrong language.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/icons.dart';
import '../../design/typography.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../timing/types.dart';
import 'settings_rows.dart';

class HelpGroup extends StatelessWidget {
  const HelpGroup({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(Str.helpAndSupport.of(context)),
          SettingsGroup(rows: [
            SettingsRow(
              icon: PhosphorIcons.info,
              title: Str.faq.of(context),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FaqScreen()),
              ),
            ),
            for (final (label, icon, path) in const [
              (Str.contactUs, PhosphorIcons.envelope, '/support'),
              (Str.privacy, PhosphorIcons.lock, '/privacy'),
              (Str.terms, PhosphorIcons.fileText, '/terms'),
            ])
              SettingsRow(
                icon: icon,
                title: label.of(context),
                trailing: PhosphorIcons.arrowSquareOut,
                // Locale-prefixed: the site serves /nl/... and /en/..., and a
                // bare path only 307s to Dutch.
                onTap: () => launchUrl(
                  Uri.parse(
                      '$websiteUrl/${AppLangScope.of(context).code}$path'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ]),
        ],
      );
}

/// The six questions, expanded one at a time.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: AppColors.canvas,
          iconTheme: IconThemeData(color: AppColors.ink),
          title: Text(Str.faq.of(context), style: AppText.subheading(context)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            for (final (q, a) in faq)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(q.of(context), style: AppText.label(context)),
                  iconColor: AppColors.accent,
                  collapsedIconColor: AppColors.inkMuted,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(a.of(context), style: AppText.bodyMuted(context)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

/// The help content. Chrome, not crop data, so it lives here rather than in the
/// snapshot, and it carries both languages like everything else the user reads.
const faq = <(LocalizedText, LocalizedText)>[
  (
    LocalizedText(
      nl: 'Waar komen de plantdata vandaan?',
      en: 'Where do the planting dates come from?',
    ),
    LocalizedText(
      nl: 'Uit de vorstdatums voor jouw locatie (KNMI / Open-Meteo '
          'klimaatnormalen, afgerond op ~1 km), gecombineerd met teeltregels '
          'die tegen minstens twee Nederlandse zaaikalenders zijn gelegd.',
      en: 'From the frost dates for your location (KNMI / Open-Meteo climate '
          'normals, rounded to ~1 km) combined with crop rules cross-checked '
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
      nl: 'Profiel → Account → Account verwijderen. Dat wist je account '
          'en elke gesynchroniseerde rij; lokale gegevens blijven op deze '
          'telefoon tot je de app verwijdert.',
      en: 'Profile → Account → Delete account. It removes your account and '
          'every synced row; local data stays on this phone until you delete '
          'the app.',
    ),
  ),
];
