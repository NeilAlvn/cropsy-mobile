/// Meldingen — the two things the app may send outward on the gardener's
/// behalf: the seasonal mail, and the anonymous usage it reports about itself.
///
/// Both are consent, so both are off until they are not, and both say what they
/// mean in the row rather than in a sheet nobody opens. Seasonal mail rides on
/// the account — the address is the account's — so without a sign-in the switch
/// is there but unpressable, with the reason under it.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../analytics/analytics.dart';
import '../../design/components.dart';
import '../../design/icons.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../repository_scope.dart';
import 'settings_rows.dart';

class NotificationsGroup extends StatefulWidget {
  const NotificationsGroup({super.key});

  @override
  State<NotificationsGroup> createState() => _NotificationsGroupState();
}

class _NotificationsGroupState extends State<NotificationsGroup> {
  Future<({bool mail, bool analytics})>? _consent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _consent ??= _load();
  }

  Future<({bool mail, bool analytics})> _load() async {
    final repo = RepositoryScope.of(context);
    final profile = await repo.profile();
    final prefs = profile == null
        ? const <String, dynamic>{}
        : jsonDecode(profile.preferences) as Map<String, dynamic>;
    return (
      mail: prefs['mail_optin'] != null,
      analytics: await repo.meta(Analytics.metaKey) == 'yes',
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final signedIn = AuthScope.maybeOf(context)?.signedIn ?? false;
    return FutureBuilder<({bool mail, bool analytics})>(
      future: _consent,
      builder: (context, snap) {
        final consent = snap.data ?? (mail: false, analytics: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(Str.reminders.of(context)),
            SettingsGroup(rows: [
              SettingsSwitchRow(
                icon: PhosphorIcons.envelopeSimple,
                title: Str.seasonMailTitle.of(context),
                blurb: (signedIn
                        ? Str.seasonMailBlurb
                        : Str.seasonMailNeedsAccount)
                    .of(context),
                value: consent.mail && signedIn,
                onChanged: signedIn
                    ? (want) async {
                        await repo.saveProfile(preferences: {
                          'mail_optin': want
                              ? DateTime.now().toUtc().toIso8601String()
                              : null,
                        });
                        if (mounted) setState(() => _consent = _load());
                      }
                    : null,
              ),
              SettingsSwitchRow(
                icon: PhosphorIcons.chartBar,
                title: Str.analyticsTitle.of(context),
                blurb: Str.analyticsBlurb.of(context),
                value: consent.analytics,
                onChanged: (on) async {
                  await repo.setMeta(Analytics.metaKey, on ? 'yes' : 'no');
                  await Analytics.setConsent(on);
                  if (mounted) setState(() => _consent = _load());
                },
              ),
            ]),
          ],
        );
      },
    );
  }
}
