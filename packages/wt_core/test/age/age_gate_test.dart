import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

import '../save/_world.dart';

/// Neutral first-launch age screen (GDD v0.4 §14, T-040, D-026).
void main() {
  final t0 = DateTime.utc(2026, 10, 22, 3);

  ProviderContainer game() {
    final c = ProviderContainer(overrides: [
      ...world(Time(t0)),
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('asked until answered; unknown counts as a child', () {
    final c = game();
    final age = c.read(ageGateProvider);
    expect(age.band, AgeBand.unset);
    expect(age.needsPrompt, isTrue);
    expect(age.treatAsChild, isTrue);
    expect(() => age.setBand(AgeBand.unset), throwsArgumentError);
    age.setBand(AgeGate.bandFor(8));
    expect(age.band, AgeBand.under13);
    expect(age.needsPrompt, isFalse);
    expect(AgeGate.bandFor(12), AgeBand.under13);
    expect(AgeGate.bandFor(13), AgeBand.over13);
    expect(AgeGate.bandFor(40), AgeBand.over13);
  });

  test('once answered, only a grown-up past the gate changes it', () {
    final c = game();
    final age = c.read(ageGateProvider)..setBand(AgeBand.under13);
    expect(() => age.setBand(AgeBand.over13), throwsStateError);
    expect(age.changeBand(AgeBand.over13, pass: null), isFalse);
    expect(age.changeBand(AgeBand.over13, pass: 'not a pass'), isFalse);
    final gate = c.read(parentalGateProvider);
    final q = gate.next();
    final pass = gate.answer(q, q.answer);
    expect(age.changeBand(AgeBand.unset, pass: pass), isFalse);
    expect(age.changeBand(AgeBand.over13, pass: pass), isTrue);
    expect(age.band, AgeBand.over13);
  });

  test('ads follow the answer: child-directed unless 13+', () async {
    final c = game();
    final net = c.read(adNetworkProvider) as FakeAdNetwork;
    await c.read(adServiceProvider).show('pet_hatch');
    expect(net.requests.last.childDirected, isTrue); // not asked yet
    c.read(ageGateProvider).setBand(AgeBand.over13);
    await c.read(adServiceProvider).show('pet_hatch');
    expect(net.requests.last.childDirected, isFalse);
    expect(net.requests.last.nonPersonalized, isTrue);
  });

  test('saved in age.band; unknown names are asked again', () {
    final c = game();
    c.read(ageGateProvider).setBand(AgeBand.over13);
    final doc = c.read(gameSaverProvider).capture();
    expect(doc['age'], {'band': '13plus'});
    final d = game();
    d.read(gameSaverProvider).restore(doc);
    expect(d.read(ageGateProvider).band, AgeBand.over13);
    d.read(gameSaverProvider).restore(doc..['age'] = {'band': 'adult?'});
    expect(d.read(ageGateProvider).needsPrompt, isTrue);
  });

  test('an answer from either phone is kept by the cloud merge', () {
    Map<String, dynamic> save(int page, String band) => {
          'idle': {'cleared_page': page},
          'age': {'band': band},
        };
    expect(mergeSaves(save(9, 'unset'), save(2, 'under13')).doc['age'],
        {'band': 'under13'});
    expect(mergeSaves(save(9, '13plus'), save(2, 'under13')).doc['age'],
        {'band': '13plus'});
  });
}
