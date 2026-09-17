/// Location picker — lets the grower set the place their whole schedule is
/// computed from. Three ways in, matching how people actually think about it:
///   • "Use my current location" — detect and snap to the nearest region.
///   • Type a town — "Rotterdam", "Antwerp" — and match it to a region.
///   • Pick a region from the list.
///
/// Whatever they choose calls [GardenRepository.setRegion], which re-points the
/// frost profile every planting date and reminder is derived from. In production
/// the detected/typed coordinate would hit `GET /api/frost?lat=&lon=`; here it
/// resolves offline against the bundled presets.
library;

import 'package:flutter/material.dart';
import '../../l10n/mascot_lines.dart';
import '../../l10n/strings.dart';
import '../../l10n/app_lang.dart';
import '../../design/icons.dart';
import '../../design/motion.dart';

import '../../data/frost_presets.dart';
import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../repository_scope.dart';
import 'frost_lookup.dart';

/// Opens the picker and applies the chosen region. Returns the chosen region, or
/// null if dismissed.
Future<FrostRegion?> showLocationPicker(BuildContext context) async {
  final repo = RepositoryScope.of(context);
  final picked = await showAppSheet<FrostRegion>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _LocationSheet(),
  );
  if (picked != null) await repo.setRegion(picked);
  return picked;
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  String _query = '';
  bool _detecting = false;

  Future<void> _detect() async {
    setState(() => _detecting = true);
    final repo = RepositoryScope.of(context);
    // Read before the await: the context is gone by the time this lands.
    final here = Str.yourLocation.of(context);
    // GPS → GET /api/frost. Offline or denied: snap to the nearest preset.
    final hit = await frostForDevice();
    if (!mounted) return;
    if (hit != null) {
      await repo.setLocation(name: here, profile: hit.profile, lat: hit.lat, lon: hit.lon);
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _detecting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Str.noLocation.of(context))),
    );
  }

  Future<void> _postcode(String pc) async {
    setState(() => _detecting = true);
    final repo = RepositoryScope.of(context);
    final hit = await frostForPostcode(pc);
    if (!mounted) return;
    if (hit != null) {
      await repo.setLocation(name: pc.toUpperCase(), profile: hit.profile, lat: hit.lat, lon: hit.lon, postcode: pc);
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _detecting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Str.postcodeNotFound.of(context))),
    );
  }

  static final _pcPattern = RegExp(r'^[1-9]\d{3}\s?[A-Za-z]{2}$');

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final current = repo.regionName;
    final matches =
        frostRegions.where((r) => r.matches(_query)).toList(growable: false);
    // Leave room for the keyboard when the search field is focused.
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.78;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(Str.whereDoYouGrow.of(context), style: AppText.title(context)),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  MascotLines.lastFrost.of(context),
                  style: AppText.bodyMuted(context),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
              child: TextField(
                autofocus: false,
                onChanged: (q) => setState(() => _query = q),
                style: AppText.body(context),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: Str.townOrPostcode.of(context),
                  hintStyle: AppText.bodyMuted(context),
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.paper,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.border, width: Neo.borderWidth),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.sprout, width: Neo.borderWidth),
                  ),
                ),
              ),
            ),
            _UseLocationTile(detecting: _detecting, onTap: _detecting ? null : _detect),
            Divider(height: 1, color: AppColors.hairline),
            Flexible(
              child: matches.isEmpty
                  ? _pcPattern.hasMatch(_query.trim())
                      ? ListTile(
                          leading: Icon(PhosphorIcons.envelopeSimple, color: AppColors.sprout),
                          title: Text(Str.usePostcode(_query.trim().toUpperCase()).of(context), style: AppText.body(context)),
                          subtitle: Text(Str.looksUpFrost.of(context), style: AppText.caption(context)),
                          onTap: _detecting ? null : () => _postcode(_query.trim()),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            Str.noLocationMatch(_query).of(context),
                            style: AppText.bodyMuted(context),
                          ),
                        )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: AppColors.hairline, indent: 20),
                      itemBuilder: (context, i) {
                        final r = matches[i];
                        final selected = r.name == current;
                        return ListTile(
                          leading: Icon(PhosphorIcons.mapPin,
                              color: selected ? AppColors.sprout : AppColors.muted),
                          title: Text(r.name, style: AppText.body(context)),
                          subtitle: Text(
                            r.cities.take(3).join(' · '),
                            style: AppText.caption(context),
                          ),
                          trailing: selected
                              ? Icon(PhosphorIcons.checkCircle, color: AppColors.sprout)
                              : null,
                          onTap: () => Navigator.pop(context, r),
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

class _UseLocationTile extends StatelessWidget {
  const _UseLocationTile({required this.detecting, required this.onTap});
  final bool detecting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: detecting
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: AppColors.sprout),
            )
          : Icon(PhosphorIcons.crosshair, color: AppColors.sprout),
      title: Text(
        (detecting ? Str.detectingLocation : Str.useCurrentLocation)
            .of(context),
        style: AppText.label(context, color: AppColors.sprout),
      ),
      subtitle: detecting
          ? null
          : Text(Str.snapToRegion.of(context),
              style: AppText.caption(context)),
    );
  }
}
