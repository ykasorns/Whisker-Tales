import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/ui/library_tab.dart';
import 'package:wt_core/wt_core.dart';

import '_l10n.dart';

class DiskSource implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

/// Owl library (T-041, D-022): each running desk has its own 📺 button, so
/// the player picks which task the ad cuts.
void main() {
  late GameContent content;
  setUpAll(
      () async => content = await ContentRepository(DiskSource()).loadAll());

  testWidgets('every running desk has its own ad button; it cuts that desk',
      (tester) async {
    final c = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
    ]);
    addTearDown(c.dispose);
    final research = c.read(researchProvider)!
      ..restore(const ResearchState(
          levels: {'sharp_claws': 14, 'offline_cap': 3, 'queue_2': 1}));
    (c.read(walletProvider) as MemoryWallet)
        .add(RewardBundle({Currency.goldfish: 1000000}));
    expect(research.start('sharp_claws'), isTrue); // 4 h
    expect(research.start('offline_cap'), isTrue); // a few minutes
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: localized(const Scaffold(body: LibraryTab())),
    ));
    final buttons = find.textContaining('📺');
    expect(buttons, findsNWidgets(2));
    // second desk = the short one: its 30-min cut finishes it
    await tester.tap(buttons.at(1));
    await tester.pump();
    await tester.pump();
    expect(research.levelOf('offline_cap'), 4);
    expect(research.levelOf('sharp_claws'), 14);
    expect(research.tasks.single.nodeId, 'sharp_claws');
  });
}
