import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/l10n/strings.dart';
import 'package:whisker_tales/ui/dungeon_adventure.dart';
import 'package:whisker_tales/ui/frames.dart';
import 'package:whisker_tales/ui/game_icon.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_mode_dungeon/wt_mode_dungeon.dart';

import '_l10n.dart';

class _DiskSource implements ContentSource {
  @override
  Future<String> read(String path) =>
      File('assets/content/$path').readAsString();
}

void main() {
  late GameContent content;
  late DungeonMode mode;

  setUpAll(() async {
    content = await ContentRepository(_DiskSource()).loadAll();
    await IconRegistry.load();
    await FrameArt.load();
    mode = DungeonMode(
      const ModeManifest(
          id: 'dungeon',
          nameTh: 'ถ้ำขนมแมว',
          nameEn: 'Treat Dungeon',
          icon: 'mode_dungeon',
          order: 2,
          enabled: true,
          minAppVersion: '1.0.0'),
      DungeonRules.fromJson(
          (await _json('design/data/dungeon.json')) as Map<String, dynamic>),
    );
  });

  Future<ProviderContainer> mount(WidgetTester tester,
      {String lang = 'en', DungeonSave? save}) async {
    final container = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
    ]);
    addTearDown(container.dispose);
    if (save != null) {
      container.read(modeSavesProvider).update(mode, save);
    }
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: localized(DungeonPage(mode: mode), lang: lang),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    return container;
  }

  /// Plays the run to its end in 100 ms frames (30 s of game time).
  Future<void> playOut(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 50)); // first ticker frame
    for (var i = 0; i < 400; i++) {
      if (find.byKey(const Key('dungeon-back')).evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('pick, drop in, 30 s later the result panel pays cookies',
      (tester) async {
    final c = await mount(tester);
    final en = lookupAppLocalizations(const Locale('en'));
    await expectLater(find.byType(DungeonPage),
        matchesGoldenFile('goldens/dungeon/ready.png'));
    expect(findLabel(en.dungeonEntries('3')), findsOneWidget);
    expect(find.byKey(const Key('dungeon-timer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('dungeon-start')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('dungeon-finish')), findsOneWidget);
    // the entry is spent the moment the run starts
    expect(
        (c.read(modeSavesProvider).stateOf(mode) as DungeonSave).runsToday, 1);

    await tester.pump(const Duration(milliseconds: 3000));
    await expectLater(find.byType(DungeonPage),
        matchesGoldenFile('goldens/dungeon/running.png'));

    await playOut(tester);
    expect(find.byKey(const Key('dungeon-back')), findsOneWidget);
    expect(tester.takeException(), isNull);
    final save = c.read(modeSavesProvider).stateOf(mode) as DungeonSave;
    expect(save.runsToday, 1);
    expect(c.read(walletProvider).balance(Currency.cookies),
        greaterThanOrEqualTo(0));
    await expectLater(find.byType(DungeonPage),
        matchesGoldenFile('goldens/dungeon/result.png'));
    // two runs left; "again" returns to the picker
    await tester.tap(find.byKey(const Key('dungeon-again')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(findLabel(en.dungeonEntries('2')), findsOneWidget);
  });

  testWidgets('no runs left: start is off and the ad offer shows',
      (tester) async {
    await mount(tester,
        save: DungeonSave(day: '2000-01-01', runsToday: 3, unlocked: 3));
    // the saved day is not today, so all three runs are back
    expect(
        findLabel(
            lookupAppLocalizations(const Locale('en')).dungeonEntries('3')),
        findsOneWidget);
  });

  testWidgets('finish now ends the run and pays what was dealt',
      (tester) async {
    final c = await mount(tester);
    await tester.tap(find.byKey(const Key('dungeon-start')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.tap(find.byKey(const Key('dungeon-finish')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('dungeon-back')), findsOneWidget);
    expect(
        (c.read(modeSavesProvider).stateOf(mode) as DungeonSave).runsToday, 1);
  });

  testWidgets('the level picker stays within the unlocked levels',
      (tester) async {
    await mount(tester, save: DungeonSave(unlocked: 3));
    expect(
        findLabel(lookupAppLocalizations(const Locale('en')).dungeonLevel('3')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('dungeon-level-up')));
    await tester.pump();
    expect(
        findLabel(lookupAppLocalizations(const Locale('en')).dungeonLevel('3')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('dungeon-level-down')));
    await tester.pump();
    expect(
        findLabel(lookupAppLocalizations(const Locale('en')).dungeonLevel('2')),
        findsOneWidget);
  });
}

Future<Object?> _json(String path) async {
  final text = await File('assets/content/$path').readAsString();
  return jsonDecode(text);
}
