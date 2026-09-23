/// Accessibility — the two things the app can dial down about itself.
///
/// Both answers live in `Profiles.preferences`, which already syncs, so someone
/// who turns the buzzing off does it once and not again on the next phone. The
/// live values sit in [AccessPrefs] because they are read where there is no
/// context to read a scope from; see the note there.
///
/// Reduced motion is additive: the switch can only ever ask for less motion
/// than the phone already asks for, never more, so a phone set to reduce motion
/// keeps its answer and the row says so.
library;

import 'package:flutter/material.dart';

import '../../design/icons.dart';
import '../../design/motion.dart';
import '../../l10n/app_lang.dart';
import '../../l10n/strings.dart';
import '../../design/components.dart';
import '../repository_scope.dart';
import 'settings_rows.dart';

class AccessibilityGroup extends StatefulWidget {
  const AccessibilityGroup({super.key});

  @override
  State<AccessibilityGroup> createState() => _AccessibilityGroupState();
}

class _AccessibilityGroupState extends State<AccessibilityGroup> {
  Future<void> _set(String key, ValueNotifier<bool> live, bool on) async {
    live.value = on;
    // Rebuild before the write: the switch should answer the finger, not the
    // database.
    setState(() {});
    await RepositoryScope.of(context).saveProfile(preferences: {key: on});
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(Str.accessibility.of(context)),
          SettingsGroup(rows: [
            SettingsSwitchRow(
              icon: PhosphorIcons.speedometer,
              title: Str.hapticsTitle.of(context),
              blurb: Str.hapticsBlurb.of(context),
              value: AccessPrefs.haptics.value,
              onChanged: (on) async {
                await _set(AccessPrefs.hapticsKey, AccessPrefs.haptics, on);
                // Turning them on demonstrates itself.
                if (on) Haptics.selection();
              },
            ),
            SettingsSwitchRow(
              icon: PhosphorIcons.slidersHorizontal,
              title: Str.reduceMotionTitle.of(context),
              blurb: Str.reduceMotionBlurb.of(context),
              // The phone's own setting wins, so the switch reads as on — and
              // stays unpressable — while the phone is asking for less motion.
              value: Motion.of(context).reduced,
              onChanged: MediaQuery.disableAnimationsOf(context)
                  ? null
                  : (on) => _set(
                        AccessPrefs.reduceMotionKey,
                        AccessPrefs.reduceMotion,
                        on,
                      ),
            ),
          ]),
        ],
      );
}
