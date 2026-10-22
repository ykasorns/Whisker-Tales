import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

/// Dev-only numbers on screen (T-029): `flutter run --dart-define=WT_DEBUG=true`.
/// A compile-time constant, false in release builds — the overlay and its
/// code are not in the release app at all.
const kDebugTelemetry = bool.fromEnvironment('WT_DEBUG') && !kReleaseMode;

/// Page clear times, offline minutes credited, ads per placement, cat level
/// and power — the same numbers the headless player reports (D-027).
class DebugTelemetryOverlay extends ConsumerStatefulWidget {
  const DebugTelemetryOverlay({super.key, required this.tick});

  /// Changes a few times a second.
  final int tick;

  /// The last welcome-back window, set by the offline sheet.
  static int lastOfflineMinutes = 0;

  @override
  ConsumerState<DebugTelemetryOverlay> createState() =>
      _DebugTelemetryOverlayState();
}

class _DebugTelemetryOverlayState extends ConsumerState<DebugTelemetryOverlay> {
  final _clears = <int, Duration>{};
  final _started = DateTime.now();
  StreamSubscription<IdleEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(idleLoopProvider).events.listen((e) {
      if (e is BossResult && e.won) {
        _clears[e.page] = DateTime.now().difference(_started);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = ref.read(catProgressProvider);
    final power =
        ref.read(powerScoreProvider).of(ref.read(catSpecProvider)().stats);
    final ads = ref.read(adServiceProvider);
    final daily = ads is AdService ? ads.snapshot().used : const {};
    final last = _clears.entries.toList()..sort((a, b) => b.key - a.key);
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.all(6),
        color: const Color(0xAA000000),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 10, color: Colors.white),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('WT-TELEMETRY (dev)'),
                Text('Lv ${cat.level} · power $power'),
                Text('offline credited: '
                    '${DebugTelemetryOverlay.lastOfflineMinutes} min'),
                Text('ads today: $daily'),
                for (final e in last.take(4))
                  Text('p${e.key} cleared at ${e.value.inMinutes} min'),
              ]),
        ),
      ),
    );
  }
}
