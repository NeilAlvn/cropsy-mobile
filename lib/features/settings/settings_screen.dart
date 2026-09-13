/// Settings (PRD 8.2, Phase 1 slice): account (magic link / password), sync
/// status, export my data, delete account. Membership, help, contact, language
/// switch follow in Phase 2/3. Never a rate prompt.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../sync/auth_service.dart';
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
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Text('Settings', style: AppText.heading(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          SectionHeader('Account'),
          if (auth == null)
            Text('Sync is not available in this build.', style: AppText.bodyMuted(context))
          else if (auth.signedIn)
            _signedIn(context, auth, repo)
          else
            _signIn(context, auth),
          if (_status != null) ...[
            const SizedBox(height: 10),
            Text(_status!, style: AppText.caption(context, color: AppColors.sprout)),
          ],
          const SizedBox(height: 24),
          SectionHeader('Your data'),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.download_outlined, color: AppColors.sprout),
              title: Text('Export my data (JSON)', style: AppText.label(context)),
              subtitle: Text('Copies everything to the clipboard.', style: AppText.caption(context)),
              onTap: () => _run(() async {
                await Clipboard.setData(ClipboardData(text: await _export(repo)));
              }, done: 'Copied to clipboard.'),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader('About'),
          Text('Cropsy · crop data ${repo.cropVersion}', style: AppText.caption(context)),
          Text('Frost dates: ${repo.regionName} (${repo.frostSource})', style: AppText.caption(context)),
        ],
      ),
    );
  }

  Widget _signIn(BuildContext context, AuthService auth) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign in to back up and sync your garden. Everything keeps working offline without it.',
              style: AppText.bodyMuted(context)),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            style: AppText.body(context),
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Send me a sign-in link',
            onPressed: _busy
                ? null
                : () => _run(() => auth.sendMagicLink(_email.text.trim()),
                    done: 'Check your mail — the link signs you in.'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            obscureText: true,
            style: AppText.body(context),
            decoration: const InputDecoration(labelText: 'Password (optional)'),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: SecondaryButton(
                label: 'Sign in',
                onPressed: _busy ? null : () => _run(() => auth.signInWithPassword(_email.text.trim(), _password.text)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SecondaryButton(
                label: 'Create account',
                onPressed: _busy
                    ? null
                    : () => _run(() => auth.signUp(_email.text.trim(), _password.text),
                        done: 'Account created — confirm via the mail we sent.'),
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
          Text(auth.user?.email ?? 'Signed in', style: AppText.label(context)),
          const SizedBox(height: 4),
          Text(
            auth.syncing
                ? 'Syncing…'
                : last == null
                    ? 'Not synced yet.'
                    : 'Last sync ${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}'
                        '${auth.lastReport?.ok == false ? ' · some tables failed' : ''}',
            style: AppText.caption(context),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PrimaryButton(label: 'Sync now', onPressed: auth.syncing ? null : () => _run(() async => auth.syncNow()))),
            const SizedBox(width: 8),
            Expanded(child: SecondaryButton(label: 'Sign out', onPressed: () => _run(auth.signOut))),
          ]),
          const SizedBox(height: 16),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warn),
            onPressed: _busy ? null : () => _deleteAccount(auth, repo),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(AuthService auth, GardenRepository repo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete account?', style: AppText.title(context)),
        content: Text('Removes your account and every synced garden, plant and log. This cannot be undone.',
            style: AppText.bodyMuted(context)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warn),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final deleted = await auth.deleteAccount();
      if (!deleted) throw StateError('Could not delete the account. Try again later.');
    }, done: 'Account deleted. Your local data stays on this phone.');
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
