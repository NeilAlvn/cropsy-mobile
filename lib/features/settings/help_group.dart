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
  (Str.faqDatesQ, Str.faqDatesA),
  (Str.faqBehindQ, Str.faqBehindA),
  (Str.faqWateringQ, Str.faqWateringA),
  (Str.faqOfflineQ, Str.faqOfflineA),
  (Str.faqFreeQ, Str.faqFreeA),
  (Str.faqDeleteQ, Str.faqDeleteA),
];
