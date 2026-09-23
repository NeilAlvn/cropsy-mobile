/// Appearance — which scheme the app paints in, and which language it speaks.
///
/// Two rows, two sheets. A segmented control would show both choices at once,
/// but it also shows them on the profile page, and this page is a list of what
/// the app can do, not a control panel. The row carries the live answer on the
/// right so the sheet only has to be opened to *change* something.
///
/// The theme stays in `app_meta` and the language on the profile, deliberately:
/// the scheme describes this device — a phone signed in later should not
/// inherit someone else's dark mode — while the language describes the person.
library;

import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/icons.dart';
import '../../design/motion.dart';
import '../../design/theme_mode.dart';
import '../../design/typography.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../timing/types.dart';
import '../repository_scope.dart';
import 'settings_rows.dart';

class AppearanceGroup extends StatefulWidget {
  const AppearanceGroup({super.key});

  @override
  State<AppearanceGroup> createState() => _AppearanceGroupState();
}

class _AppearanceGroupState extends State<AppearanceGroup> {
  LocalizedText _themeLabel(AppThemeChoice choice) => switch (choice) {
        AppThemeChoice.system => Str.themeSystem,
        AppThemeChoice.light => Str.themeLight,
        AppThemeChoice.dark => Str.themeDark,
      };

  Future<void> _pickTheme() async {
    final theme = AppThemeScope.of(context);
    final repo = RepositoryScope.of(context);
    final picked = await _pickOne<AppThemeChoice>(
      context: context,
      title: Str.appearance.of(context),
      note: Str.themeFollows.of(context),
      selected: theme.choice,
      options: [
        for (final c in AppThemeChoice.values) (c, _themeLabel(c).of(context)),
      ],
    );
    if (picked == null) return;
    theme.choice = picked;
    await repo.setMeta(AppTheme.metaKey, AppTheme.wire(picked));
  }

  Future<void> _pickLanguage() async {
    final lang = AppLangScope.of(context);
    final repo = RepositoryScope.of(context);
    final picked = await _pickOne<String>(
      context: context,
      title: Str.language.of(context),
      note: Str.langNote.of(context),
      selected: lang.code,
      options: const [('nl', 'Nederlands'), ('en', 'English')],
    );
    if (picked == null) return;
    lang.code = picked;
    await repo.saveProfile(lang: picked);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLangScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(Str.appearance.of(context)),
        SettingsGroup(rows: [
          SettingsRow(
            icon: PhosphorIcons.sun,
            title: Str.appearance.of(context),
            value: _themeLabel(AppThemeScope.of(context).choice).of(context),
            onTap: _pickTheme,
          ),
          SettingsRow(
            icon: PhosphorIcons.globe,
            title: Str.language.of(context),
            value: lang.isDutch ? 'Nederlands' : 'English',
            onTap: _pickLanguage,
          ),
        ]),
      ],
    );
  }
}

/// One value out of a handful, with the live one ticked and a line underneath
/// saying what the choice actually governs. Used by both rows above; if a third
/// ever needs it, it moves next to the row widgets.
Future<T?> _pickOne<T>({
  required BuildContext context,
  required String title,
  required String note,
  required T selected,
  required List<(T, String)> options,
}) =>
    showAppSheet<T>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(title, style: AppText.title(context)),
            ),
            for (final (value, label) in options)
              ListTile(
                title: Text(label, style: AppText.body(context)),
                trailing: value == selected
                    ? Icon(PhosphorIcons.check, color: AppColors.accent)
                    : null,
                onTap: () => Navigator.pop(context, value),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Text(note, style: AppText.caption(context)),
            ),
          ],
        ),
      ),
    );
