import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/l10n/strings.dart';
import 'package:whisker_tales/ui/pages.dart';
import 'package:wt_core/wt_core.dart';

import '_l10n.dart';

class DiskSource implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

class Rec extends SilentAudioOutput {
  final stopped = <int>[];
  final shots = <String>[];
  @override
  void stop(int channel) => stopped.add(channel);
  @override
  Future<void> oneShot(String asset, double volume) async => shots.add(asset);
}

/// T-024 AC: the 🎵 / 🔊 switches mute at once and are saved.
void main() {
  testWidgets('switching music and sounds off works at once and is saved',
      (tester) async {
    final content = await ContentRepository(DiskSource()).loadAll();
    final out = Rec();
    final saves = SaveService(MemorySaveStore());
    final c = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(saves),
      audioOutputProvider.overrideWithValue(out),
    ]);
    addTearDown(c.dispose);
    final audio = c.read(audioServiceProvider);
    await audio.playBgm('farm');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: localized(const Scaffold(body: ShopPage())),
    ));
    final en = lookupAppLocalizations(const Locale('en'));
    Finder switchOf(String label) => find.descendant(
        of: find.ancestor(of: find.text(label), matching: find.byType(Row)),
        matching: find.byType(Switch));

    await tester.tap(switchOf(en.music));
    await tester.pump();
    expect(audio.bgmEnabled, isFalse);
    expect(out.stopped, containsAll([0, 1])); // silent right away

    await tester.tap(switchOf(en.sounds));
    await tester.pump();
    await audio.playSfx('coin');
    expect(out.shots, isEmpty);

    await c.read(gameSaverProvider).save();
    final doc = (await saves.load()).document!;
    expect(doc['settings']['bgm'], isFalse);
    expect(doc['settings']['sfx'], isFalse);
  });
}
