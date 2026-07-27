// Pre-UX shell entry point.
//
// The product UI is deliberately NOT built yet — Luuk is still deciding the
// design, and the agreement is basics-only until there's a greenlit direction.
// This screen is a developer harness, not product UX: it loads the bundled crop
// snapshot and runs the offline base-schedule engine so we can see the
// design-independent core working end-to-end on a real device. Replace it with
// the real "This week" screen (spec F2) once the UX lands.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'timing/crop_snapshot.dart';
import 'timing/engine.dart';
import 'timing/types.dart';

void main() => runApp(const CropsyApp());

class CropsyApp extends StatelessWidget {
  const CropsyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cropsy (shell)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F5E3A)),
        useMaterial3: true,
      ),
      home: const _ShellHarness(),
    );
  }
}

/// Bundled national default so the base schedule runs before any location is
/// set (API contract §3: offline with no cache falls back to an NL default).
const _nlDefaultFrost =
    FrostProfile(lastFrost: '2026-04-15', firstFrost: '2026-11-01');

class _ShellHarness extends StatefulWidget {
  const _ShellHarness();

  @override
  State<_ShellHarness> createState() => _ShellHarnessState();
}

class _ShellHarnessState extends State<_ShellHarness> {
  CropSnapshot? _snapshot;
  List<ScheduledWindow> _thisWeek = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/crops-snapshot.json');
      final snapshot = CropSnapshot.parse(raw);
      final all = scheduleGarden(snapshot.crops, _nlDefaultFrost);
      final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      setState(() {
        _snapshot = snapshot;
        _thisWeek = windowsActiveInRange(all, today);
      });
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Cropsy — shell')),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load snapshot:\n$_error',
                    textAlign: TextAlign.center),
              )
            : snapshot == null
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('Offline core wired',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('crop snapshot ${snapshot.version}'),
                        Text('${snapshot.crops.length} crops bundled'),
                        Text('${_thisWeek.length} windows active this week '
                            '(NL default frost)'),
                        const SizedBox(height: 16),
                        const Text(
                          'Product UI intentionally not built yet — '
                          'waiting on the design direction.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
