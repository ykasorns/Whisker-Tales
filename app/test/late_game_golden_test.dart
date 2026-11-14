import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/main.dart';
import 'package:whisker_tales/ui/frames.dart';
import 'package:whisker_tales/ui/game_icon.dart';
import 'package:whisker_tales/ui/yarn_basket.dart';
import 'package:wt_core/wt_core.dart';

class _Disk implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

class _Clock implements TimeSource {
  _Clock(this.utc);
  DateTime utc;
  @override
  DateTime nowUtc() => utc;
  @override
  Duration utcOffset() => const Duration(hours: 7);
}

/// The menu pages as a long-time player sees them (Lv 119, numbers in the
/// millions, every secondary stat, graded gear, pets, a research running).
/// The first-day goldens cannot show a label that no longer fits; these can.
void main() {
  late GameContent content;
  setUpAll(() async {
    content = await ContentRepository(_Disk()).loadAll();
    await IconRegistry.load();
    await BasketArt.load();
    await FrameArt.load();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var k = 0; k < 4; k++) {
      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)));
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<ProviderContainer> boot(WidgetTester tester, _Clock clock,
      {Duration away = Duration.zero}) async {
    final c = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
      timeSourceProvider.overrideWithValue(clock),
    ]);
    addTearDown(c.dispose);
    c.read(ageGateProvider).setBand(AgeBand.under13);
    final saver = c.read(gameSaverProvider);
    final doc = saver.capture();
    (doc['profile'] as Map<String, dynamic>)
      ..['goldfish'] = 5500000
      ..['yarn'] = 400
      ..['eggs'] = 8;
    doc['cat'] =
        const CatState(level: 119, exp: 4000, classId: 'archer', tier: 1)
            .toJson();
    (doc['idle'] as Map<String, dynamic>)['cleared_page'] = 50;
    doc['pets'] = {
      'owned': {
        'sparrow': {'stars': 5, 'level': 10},
        'mouse': {'stars': 5, 'level': 10},
        'frog': {'stars': 5, 'level': 10},
        'hedgehog': {'stars': 5, 'level': 10},
        'rabbit': {'stars': 5, 'level': 17},
        'unicorn': {'stars': 5, 'level': 24},
      },
      'deployed': ['hedgehog', 'rabbit', 'unicorn'],
      'pity': 3,
    };
    doc['research'] = {
      'levels': {
        'sharp_claws': 14,
        'fluffy_fur': 14,
        'tough_paws': 14,
        'queue_2': 1,
        'quick_paws': 6,
        'keen_eyes': 5,
        'big_pounce': 3,
      },
      'task': {
        'node': 'quick_paws',
        'ends_at_utc':
            clock.utc.add(const Duration(minutes: 50)).toIso8601String(),
      },
    };
    saver.restore(doc);
    // real knitted gear in every open slot (grades as the dice give them)
    final basket = c.read(gearBasketProvider);
    for (final slot in basket.openSlots) {
      for (var i = 0; i < 12; i++) {
        final r = basket.craft(slot);
        if (r.isStrictlyBetter || basket.equipped(slot) == null) {
          basket.equip(r.item.id);
        } else {
          basket.recycle(r.item.id);
        }
      }
    }
    if (away > Duration.zero) {
      final seen = clock.utc;
      c.read(gameClockProvider).restore(ClockState(
          lastSeenUtc: seen, maxSeenUtc: seen, dateKey: '2026-10-20'));
      clock.utc = clock.utc.add(away);
    }
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: WhiskerTalesApp(avatarRules: content.avatar, lang: 'en')));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump(const Duration(milliseconds: 300));
    return c;
  }

  Finder nav() => find.byWidgetPredicate((w) =>
      w is Semantics &&
      w.properties.button == true &&
      w.properties.selected != null);

  testWidgets('menu pages of a long-time player (en)', (tester) async {
    await boot(tester, _Clock(DateTime.utc(2026, 10, 20, 2)));
    final app = find.byType(WhiskerTalesApp);
    await tester.tap(nav().at(0));
    await settle(tester);
    await expectLater(app, matchesGoldenFile('goldens/late/cat.png'));
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await settle(tester);
    await expectLater(app, matchesGoldenFile('goldens/late/cat_lower.png'));
    await tester.tap(find.text('Collection'));
    await settle(tester);
    await expectLater(app, matchesGoldenFile('goldens/late/collection.png'));
    await tester.tap(find.text('Pets'));
    await settle(tester);
    await expectLater(app, matchesGoldenFile('goldens/late/pets.png'));
    await tester.tap(find.text('Library'));
    await settle(tester);
    await expectLater(app, matchesGoldenFile('goldens/late/library.png'));
    await tester.tap(nav().at(1));
    await settle(tester);
    await expectLater(app, matchesGoldenFile('goldens/late/adventure.png'));
    await tester.tap(nav().at(4));
    await settle(tester);
    await expectLater(app, matchesGoldenFile('goldens/late/shop.png'));
    await tester.tap(nav().at(2));
    await settle(tester);
    await expectLater(app, matchesGoldenFile('goldens/late/home.png'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome back with big numbers (en)', (tester) async {
    await boot(tester, _Clock(DateTime.utc(2026, 10, 20, 2)),
        away: const Duration(hours: 3));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(Dialog), findsOneWidget);
    await settle(tester);
    await expectLater(find.byType(WhiskerTalesApp),
        matchesGoldenFile('goldens/late/welcome_back.png'));
  });
}
