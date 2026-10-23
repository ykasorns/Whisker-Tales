import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/l10n/strings.dart';
import 'package:whisker_tales/ui/game_icon.dart';
import 'package:whisker_tales/ui/yarn_basket.dart';
import 'package:whisker_tales/main.dart';
import 'package:whisker_tales/ui/age_screen.dart';
import 'package:whisker_tales/ui/game_shell.dart';
import 'package:wt_core/wt_core.dart';

import '_l10n.dart';

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
  setUpAll(() async {
    content = await ContentRepository(DiskSource()).loadAll();
    await IconRegistry.load(); // painted icons, as in the app (D-037)
    await BasketArt.load(); // the home basket (D-040)
  });

  Future<ProviderContainer> boot(WidgetTester tester, String lang,
      {Clock? clock, bool askAge = false, bool fixedLang = true}) async {
    final c = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
      if (clock != null) timeSourceProvider.overrideWithValue(clock),
    ]);
    addTearDown(c.dispose);
    if (!askAge) c.read(ageGateProvider).setBand(AgeBand.under13);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: WhiskerTalesApp(
              avatarRules: content.avatar, lang: fixedLang ? lang : null)));
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
          await tester.tap(find.text(lang == 'en' ? 'Library' : 'ห้องสมุด'));
          for (var k = 0; k < 4; k++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          expect(tester.takeException(), isNull);
          await expectLater(
              app, matchesGoldenFile('goldens/$lang/library.png'));
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

  for (final lang in ['th', 'en']) {
    testWidgets('first launch: the neutral age screen ($lang)', (tester) async {
      final c = await boot(tester, lang, askAge: true);
      final app = find.byType(WhiskerTalesApp);
      expect(find.byType(GameShell), findsNothing); // nothing before it
      await expectLater(app, matchesGoldenFile('goldens/$lang/age.png'));
      // the system back gesture cannot skip it
      expect(await tester.binding.handlePopRoute(), isTrue);
      expect(find.byType(AgeScreen), findsOneWidget);
      // 8 → check → ✗ keeps asking; 8 → ✓ answers
      await tester.tap(find.text('8'));
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(app, matchesGoldenFile('goldens/$lang/age_check.png'));
      await tester.tap(findLabel('✗'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.read(ageGateProvider).needsPrompt, isTrue);
      await tester.tap(find.text('8'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findLabel('✓'));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.read(ageGateProvider).band, AgeBand.under13);
      expect(find.byType(GameShell), findsOneWidget);
    });
  }

  testWidgets('the language switches while playing and is saved',
      (tester) async {
    final c = await boot(tester, 'th', fixedLang: false);
    final th = lookupAppLocalizations(const Locale('th'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(find.text(th.navShop), findsOneWidget);
    // shop → "🌐 English"
    await tester.tap(find.text(th.navShop));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(findLabel(th.switchLanguage));
    await tester.pump(const Duration(milliseconds: 300));
    expect(c.read(langProvider), 'en');
    expect(find.text(en.navShop), findsWidgets);
    expect(find.text(th.navShop), findsNothing);
    expect(c.read(gameSaverProvider).capture()['settings']['lang'], 'en');
  });

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
