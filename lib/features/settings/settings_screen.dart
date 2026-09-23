/// Sign in and sync (PRD 8.2): the magic link, the password, what moved last
/// time, and the two account changes that need a server.
///
/// This screen used to be all of settings — six unrelated jobs, 584 lines, and
/// one row on the profile as its only way in, which is why nobody found the
/// theme switch or the FAQ. Everything that was not a form about the account
/// now lives in its own file next to this one and is reached directly from the
/// profile. What is left is the part that genuinely needs a keyboard and a
/// network. Never a rate prompt.
library;

import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../sync/auth_service.dart';
import '../../sync/sync_engine.dart';
import '../../timing/types.dart';
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
    final auth = AuthScope.maybeOf(context);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: AppColors.canvas,
        iconTheme: IconThemeData(color: AppColors.ink),
        title: Text(Str.settingsAndSync.of(context), style: AppText.subheading(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          SectionHeader(Str.account.of(context)),
          if (auth == null)
            Text(Str.syncUnavailable.of(context), style: AppText.bodyMuted(context))
          else if (auth.signedIn)
            _signedIn(context, auth)
          else
            _signIn(context, auth),
          if (_status != null) ...[
            const SizedBox(height: 10),
            Text(_status!, style: AppText.caption(context, color: AppColors.accent)),
          ],
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
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: _busy
                  ? null
                  : () => _run(() => auth.sendPasswordReset(_email.text.trim()),
                      done: Str.resetMailSent.of(context)),
              child: Text(Str.forgotPassword.of(context), style: AppText.caption(context)),
            ),
          ),
        ],
      ),
    );
  }

  /// One sheet for both "new password" and "new address": same shape, same
  /// single field, so neither needs a screen of its own.
  Future<String?> _ask(BuildContext context, LocalizedText title, LocalizedText label, {bool obscure = false}) {
    final field = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title.of(context)),
        content: TextField(
          controller: field,
          obscureText: obscure,
          autofocus: true,
          autocorrect: false,
          keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
          decoration: InputDecoration(labelText: label.of(context)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(Str.cancel.of(context))),
          TextButton(
            onPressed: () => Navigator.of(context).pop(field.text.trim()),
            child: Text(Str.save.of(context)),
          ),
        ],
      ),
    );
  }

  Widget _signedIn(BuildContext context, AuthService auth) {
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
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: SecondaryButton(
                label: Str.changePassword.of(context),
                onPressed: _busy
                    ? null
                    : () async {
                        final next = await _ask(context, Str.changePassword, Str.newPassword, obscure: true);
                        if (next == null || next.isEmpty || !context.mounted) return;
                        final done = Str.passwordChanged.of(context);
                        await _run(() => auth.changePassword(next), done: done);
                      },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SecondaryButton(
                label: Str.changeEmail.of(context),
                onPressed: _busy
                    ? null
                    : () async {
                        final next = await _ask(context, Str.changeEmail, Str.newEmail);
                        if (next == null || next.isEmpty || !context.mounted) return;
                        final done = Str.emailChangeSent.of(context);
                        await _run(() => auth.changeEmail(next), done: done);
                      },
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(Str.emailChangeBlurb.of(context), style: AppText.caption(context)),
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
}
