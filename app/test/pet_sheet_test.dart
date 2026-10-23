import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/l10n/strings.dart';
import 'package:whisker_tales/ui/pets_tab.dart';
import 'package:wt_core/wt_core.dart';

import '_l10n.dart';

class DiskSource implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

/// D-039: tap a pet → its stats, bonus, skill and cooldown, and a deploy
/// toggle that respects the open battle slots.
void main() {
  late GameContent content;
  setUpAll(
      () async => content = await ContentRepository(DiskSource()).loadAll());

  Future<ProviderContainer> open(WidgetTester tester, PetsState state) async {
    final c = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
    ]);
    addTearDown(c.dispose);
    c.read(petsProvider)!.restore(state);
    final def = content.pets.byId('hedgehog')!;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: localized(Scaffold(body: PetSheet(def: def))),
    ));
    return c;
  }

  final en = lookupAppLocalizations(const Locale('en'));

  testWidgets('shows attack, passive, skill with its cooldown, stars',
      (tester) async {
    await open(
        tester, const PetsState(owned: {'hedgehog': 3}, deployed: [], pity: 0));
    final hedgehog = content.pets.byId('hedgehog')!;
    expect(find.text(hedgehog.nameEn), findsOneWidget);
    expect(find.textContaining(hedgehog.passive!.textEn), findsOneWidget);
    expect(find.textContaining(hedgehog.skill!.nameEn), findsOneWidget);
    expect(find.textContaining(hedgehog.skill!.textEn), findsOneWidget);
    expect(
        find.textContaining(
            en.petCooldown(hedgehog.skill!.spec.cooldownMs ~/ 1000)),
        findsOneWidget);
    expect(find.textContaining('★★★'), findsOneWidget);
    expect(find.text(en.rarityRare), findsOneWidget);
  });

  testWidgets('sending to battle and resting; a full field blocks it',
      (tester) async {
    final c = await open(
        tester,
        const PetsState(
            owned: {'hedgehog': 1, 'mouse': 1}, deployed: [], pity: 0));
    final pets = c.read(petsProvider)!;
    expect(pets.deployed, isEmpty);
    await tester.tap(find.text(en.sendToBattle));
    await tester.pump();
    expect(pets.deployed, ['hedgehog']);
    expect(find.text(en.restPet), findsOneWidget);
    await tester.tap(find.text(en.restPet));
    await tester.pump();
    expect(pets.deployed, isEmpty);
    // one slot at the start: another pet fills it, so this one cannot go
    pets.deploy(0, 'mouse');
    tester.element(find.byType(PetSheet)).markNeedsBuild();
    await tester.pump();
    expect(find.text(en.slotsFull), findsOneWidget);
    await tester.tap(find.text(en.sendToBattle), warnIfMissed: false);
    await tester.pump();
    expect(pets.deployed, ['mouse']);
    expect(pets.deploySlots, 1);
  });
}
