import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/main.dart';
import 'package:wt_core/wt_core.dart';

class DiskSource implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

class Clock implements TimeSource {
  Clock(this.utc);
  DateTime utc;
  @override
  DateTime nowUtc() => utc;
  @override
  Duration utcOffset() => const Duration(hours: 7);
}

/// Golden screens for every panel, TH + EN (T-042 AC). Text renders in the
/// test font (boxes); these guard layout, not wording.
void main() {
  late GameContent content;
  setUpAll(
      () async => content = await ContentRepository(DiskSource()).loadAll());

  Future<ProviderContainer> boot(WidgetTester tester, String lang,
      {Clock? clock}) async {
    final c = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
      if (clock != null) timeSourceProvider.overrideWithValue(clock),
    ]);
    addTearDown(c.dispose);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: WhiskerTalesApp(avatarRules: content.avatar, lang: lang)));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump(const Duration(milliseconds: 300));
    return c;
  }

  for (final lang in ['th', 'en']) {
    testWidgets('every page ($lang)', (tester) async {
      await boot(tester, lang);
      final app = find.byType(WhiskerTalesApp);
      await expectLater(app, matchesGoldenFile('goldens/$lang/home.png'));
      // menu, left to right; home is in the middle
      final tabs = ['character', 'dungeon', 'home', 'events', 'shop'];
      for (var i = 0; i < tabs.length; i++) {
        if (i == 2) continue;
        await tester.tap(find.bySemanticsLabel(RegExp('.')).at(0),
            warnIfMissed: false);
        final labels = find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.selected != null);
        await tester.tap(labels.at(i));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await expectLater(
            app, matchesGoldenFile('goldens/$lang/${tabs[i]}.png'));
        if (tabs[i] == 'character') {
          await tester.tap(find.text(lang == 'en' ? 'Pets' : 'เพื่อนสัตว์'));
          for (var k = 0; k < 4; k++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          expect(tester.takeException(), isNull);
          await expectLater(app, matchesGoldenFile('goldens/$lang/pets.png'));
        }
      }
      // back home, open the knit sheet
      final labels = find.byWidgetPredicate((w) =>
          w is Semantics &&
          w.properties.button == true &&
          w.properties.selected != null);
      await tester.tap(labels.at(2));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byWidgetPredicate((w) =>
          w is Semantics &&
          w.properties.button == true &&
          w.properties.label != null &&
          (w.properties.label == 'ถักของ' || w.properties.label == 'Knit')));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsOneWidget);
      await expectLater(app, matchesGoldenFile('goldens/$lang/knit.png'));
    });
  }

  testWidgets('welcome back after time away (th)', (tester) async {
    final clock = Clock(DateTime.utc(2026, 10, 20, 2));
    final c = ProviderContainer(
        overrides: [timeSourceProvider.overrideWithValue(clock)]);
    c.read(gameClockProvider).markSeen();
    c.dispose();
    clock.utc = clock.utc.add(const Duration(hours: 3));
    final game = await boot(tester, 'th', clock: clock);
    game.read(gameClockProvider).restore(ClockState(
        lastSeenUtc: DateTime.utc(2026, 10, 20, 2),
        maxSeenUtc: DateTime.utc(2026, 10, 20, 2),
        dateKey: '2026-10-20'));
    await tester.pumpWidget(UncontrolledProviderScope(
        container: game,
        child: WhiskerTalesApp(avatarRules: content.avatar, key: UniqueKey())));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(Dialog), findsOneWidget);
    await expectLater(find.byType(WhiskerTalesApp),
        matchesGoldenFile('goldens/th/welcome_back.png'));
  });
}
