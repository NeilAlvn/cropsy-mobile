/// The shapes every settings group is built from.
///
/// Base 8.7: one container per group, rows divided by an inset hairline. A row
/// always says what it is on the left and where it stands on the right — the
/// region it will change, the theme that is live, the switch as it sits — so
/// nobody has to open a row to find out what it does.
///
/// These live here rather than in the profile screen because the profile is now
/// only the page that stacks the groups; each group builds its own rows from
/// its own file.
library;

import 'package:flutter/material.dart';

import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/icons.dart';
import '../../design/typography.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Container(
        decoration: Neo.box(),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Divider(height: 1, thickness: 1, color: AppColors.hairline),
                ),
              rows[i],
            ],
          ],
        ),
      );
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.trailing = PhosphorIcons.caretRight,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? value;

  /// Null greys the row out and leaves the value to explain why — how the
  /// delete-account row reads before there is an account to delete.
  final VoidCallback? onTap;

  /// Caret for a row that stays in the app, arrow-out for one that leaves it.
  final IconData trailing;

  /// Destructive rows carry the critical token on the title and the icon.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final tone = !enabled
        ? AppColors.inkPlaceholder
        : danger
            ? AppColors.critical
            : AppColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Neo.radius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: tone),
            const SizedBox(width: 16),
            Text(title, style: AppText.body(context, color: tone)),
            const SizedBox(width: 12),
            // The value yields to the title and ellipsises; a long region
            // name must not push the row title into a second line.
            Expanded(
              child: Text(
                value ?? '',
                style: AppText.body(context, color: AppColors.inkMuted),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(trailing, size: 16, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// A row whose whole answer is yes or no. It flips in place: sending someone to
/// a sheet to tick one box is a step that buys nothing.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.blurb,
  });

  final IconData icon;
  final String title;
  final String? blurb;
  final bool value;

  /// Null leaves the switch off and unpressable — the seasonal mail toggle
  /// before there is an address to send to.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tone = onChanged == null ? AppColors.inkPlaceholder : AppColors.ink;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: tone),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.body(context, color: tone)),
                if (blurb != null) ...[
                  const SizedBox(height: 2),
                  Text(blurb!, style: AppText.caption(context)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
