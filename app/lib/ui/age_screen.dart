import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../l10n/strings.dart';
import 'game_icon.dart';
import 'palette.dart';

/// Neutral age screen (GDD v0.4 §14, T-040, D-026): every age looks the
/// same, nothing is picked for the player, and it cannot be skipped the
/// first time. Big numbers (with dots to count for the youngest) so a child
/// who cannot read yet can still answer; a ✓ / ✗ check catches a mis-tap.
/// Only the band (under 13 / 13+) is kept, never the age.
///
/// With [pass] (a grown-up came through the parental gate) it changes an
/// earlier answer and can be closed.
class AgeScreen extends ConsumerWidget {
  const AgeScreen({super.key, required this.onDone, this.pass});

  final VoidCallback onDone;
  final GatePass? pass;

  static const ages = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];

  Future<void> _pick(BuildContext context, WidgetRef ref, int age) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Palette.paper,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Palette.ink, width: 3)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            IconText('🎂 ${_label(age)}',
                style:
                    const TextStyle(fontSize: 48, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(children: [
              for (final (yes, mark, fill) in [
                (false, '✗', Palette.paper),
                (true, '✓', Palette.lime),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(yes),
                      child: Container(
                        height: 64,
                        alignment: Alignment.center,
                        decoration: inkBox(fill: fill, radius: 16),
                        child: IconText(mark,
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final gate = ref.read(ageGateProvider);
    final band = AgeGate.bandFor(age);
    if (pass == null) {
      gate.setBand(band);
    } else if (!gate.changeBand(band, pass: pass)) {
      return; // the grown-up's pass ran out: nothing changes
    }
    onDone();
  }

  static String _label(int age) => age >= 18 ? '18+' : '$age';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    return PopScope(
      canPop: pass != null, // the first time it cannot be skipped
      child: Scaffold(
        backgroundColor: Palette.paper,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (pass != null)
                Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                        onPressed: onDone,
                        icon: const GameIcon('cross', size: 28))),
              const SizedBox(height: 12),
              const IconText('🎂', style: TextStyle(fontSize: 72)),
              IconText(s.askAge,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    for (final age in ages)
                      Semantics(
                        button: true,
                        label: _label(age),
                        child: GestureDetector(
                          onTap: () => _pick(context, ref, age),
                          child: Container(
                            decoration: inkBox(radius: 16),
                            padding: const EdgeInsets.all(4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconText(_label(age),
                                        style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w800)),
                                    // dots to count for the youngest
                                    if (age <= 6)
                                      IconText('●' * age,
                                          style: const TextStyle(
                                              fontSize: 9,
                                              color: Palette.inkSoft)),
                                  ]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
