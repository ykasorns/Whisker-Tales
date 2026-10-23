import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/ui/overlays.dart';
import 'package:wt_core/wt_core.dart';

import '_l10n.dart';

/// 2026-10-23: a "Fail" card when Mochi loses — small, self-closing, never
/// stacking, and with no ad or retry button (GDD §14, D-008).
void main() {
  late StreamController<IdleEvent> events;
  setUp(() => events = StreamController<IdleEvent>.broadcast(sync: true));
  tearDown(() => events.close());

  Future<void> open(WidgetTester tester) => tester.pumpWidget(ProviderScope(
      child: localized(
          Scaffold(body: Stack(children: [FailCard(events: events.stream)])))));

  final lostBoss = BossResult(page: 5, won: false, reward: RewardBundle.empty);

  testWidgets('a lost boss shows the card, which closes by itself',
      (tester) async {
    await open(tester);
    expect(find.byKey(const ValueKey('fail-card')).hitTestable(), findsNothing);
    events.add(lostBoss);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        find.byKey(const ValueKey('fail-card')).hitTestable(), findsOneWidget);
    // nothing to press but the card itself: no ad, no retry
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.textContaining('📺'), findsNothing);
    await tester.pump(FailCard.showFor + const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('fail-card')).hitTestable(), findsNothing);
  });

  testWidgets('a tap closes it at once', (tester) async {
    await open(tester);
    events.add(lostBoss);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('fail-card')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('fail-card')).hitTestable(), findsNothing);
  });

  testWidgets('a streak of lost waves shows one card, not one per retry',
      (tester) async {
    await open(tester);
    events.add(const WaveFailed(page: 3, waveIndex: 1));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(FailCard.showFor + const Duration(milliseconds: 400));
    events.add(const WaveFailed(page: 3, waveIndex: 1)); // the retry fails too
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('fail-card')).hitTestable(), findsNothing);
    // a win ends the streak; the next loss shows a card again
    events.add(
        WaveCleared(page: 3, waveIndex: 1, reward: RewardBundle.empty, exp: 1));
    events.add(const WaveFailed(page: 3, waveIndex: 2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        find.byKey(const ValueKey('fail-card')).hitTestable(), findsOneWidget);
    await tester.pump(FailCard.showFor + const Duration(milliseconds: 400));
  });
}
