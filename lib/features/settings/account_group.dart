/// Account — signing in, taking the data out, and ending the account.
///
/// The forms behind "sign in and sync" are the only thing left in
/// [SettingsScreen]; everything that used to sit under them is a row on the
/// profile now. Deleting stays gated behind being signed in on purpose: a
/// device-only garden has no account to delete, and wiping the phone's own rows
/// is not what the button says it does, so the row explains itself instead of
/// pretending.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/icons.dart';
import '../../design/typography.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../sync/auth_service.dart';
import '../garden/garden_repository.dart';
import '../repository_scope.dart';
import 'settings_rows.dart';
import 'settings_screen.dart';

class AccountGroup extends StatefulWidget {
  const AccountGroup({super.key, this.onChanged});

  /// A sign-in pulls a garden down, so the page above reloads on return.
  final VoidCallback? onChanged;

  @override
  State<AccountGroup> createState() => _AccountGroupState();
}

class _AccountGroupState extends State<AccountGroup> {
  Future<void> _export(GardenRepository repo) async {
    final copied = Str.copied.of(context);
    await Clipboard.setData(ClipboardData(text: await _exportJson(repo)));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(copied)));
  }

  /// Everything the account holds, as one readable JSON blob on the clipboard.
  Future<String> _exportJson(GardenRepository repo) async {
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

  Future<void> _delete(AuthService auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(Str.deleteAccountAsk.of(context), style: AppText.title(context)),
        content: Text(Str.deleteAccountBody.of(context), style: AppText.bodyMuted(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(Str.cancel.of(context)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.critical),
            onPressed: () => Navigator.pop(context, true),
            child: Text(Str.delete.of(context)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    // Both lines are read before the await: the dialog's context is gone by the
    // time the answer comes back.
    final done = Str.deleted.of(context);
    final failed = Str.couldNotDeleteAccount.of(context);
    final deleted = await auth.deleteAccount();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(deleted ? done : failed)));
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final auth = AuthScope.maybeOf(context);
    final signedIn = auth?.signedIn ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(Str.account.of(context)),
        SettingsGroup(rows: [
          SettingsRow(
            icon: PhosphorIcons.gear,
            title: (signedIn ? Str.settingsAndSync : Str.signInToSync).of(context),
            value: auth?.user?.email ?? Str.onThisDevice.of(context),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsScreen()))
                .then((_) {
              if (mounted) setState(() {});
              widget.onChanged?.call();
            }),
          ),
          SettingsRow(
            icon: PhosphorIcons.downloadSimple,
            title: Str.exportData.of(context),
            onTap: () => _export(repo),
          ),
          SettingsRow(
            icon: PhosphorIcons.trash,
            title: Str.deleteAccount.of(context),
            danger: signedIn,
            // Nothing to delete without an account, and the value says which
            // half of that is true.
            value: signedIn ? null : Str.notSignedIn.of(context),
            onTap: signedIn && auth != null ? () => _delete(auth) : null,
          ),
        ]),
      ],
    );
  }
}
