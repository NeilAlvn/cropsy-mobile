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

import '../../data/frost_presets.dart';
import '../../design/colors.dart';
import '../../design/typography.dart';
import '../repository_scope.dart';

/// Opens the picker and applies the chosen region. Returns the chosen region, or
/// null if dismissed.
Future<FrostRegion?> showLocationPicker(BuildContext context) async {
  final repo = RepositoryScope.of(context);
  final picked = await showModalBottomSheet<FrostRegion>(
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
    // Prototype stand-in for a GPS fix + frost lookup. In production this awaits
    // the platform location service and `GET /api/frost?lat=&lon=`.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final region = nearestRegion(demoDeviceLat, demoDeviceLon);
    Navigator.pop(context, region);
  }

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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Where do you grow?', style: AppText.title(context)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'This sets your frost dates — the backbone of every planting date.',
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
                  hintText: 'Enter your town or region',
                  hintStyle: AppText.bodyMuted(context),
                  prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.paper,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.sprout),
                  ),
                ),
              ),
            ),
            _UseLocationTile(detecting: _detecting, onTap: _detecting ? null : _detect),
            const Divider(height: 1, color: AppColors.hairline),
            Flexible(
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No match for "$_query". Try a nearby city, or pick a region.',
                        style: AppText.bodyMuted(context),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.hairline, indent: 20),
                      itemBuilder: (context, i) {
                        final r = matches[i];
                        final selected = r.name == current;
                        return ListTile(
                          leading: Icon(Icons.place_outlined,
                              color: selected ? AppColors.sprout : AppColors.muted),
                          title: Text(r.name, style: AppText.body(context)),
                          subtitle: Text(
                            r.cities.take(3).join(' · '),
                            style: AppText.caption(context),
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_circle, color: AppColors.sprout)
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
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: AppColors.sprout),
            )
          : const Icon(Icons.my_location, color: AppColors.sprout),
      title: Text(
        detecting ? 'Detecting your location…' : 'Use my current location',
        style: AppText.label(context, color: AppColors.sprout),
      ),
      subtitle: detecting
          ? null
          : Text('Snap to the nearest growing region',
              style: AppText.caption(context)),
    );
  }
}
