import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wt_core/wt_core.dart';

/// Writes only the first [keep] characters, then "crashes".
class CrashingStore extends MemorySaveStore {
  int? crashAfter;
  @override
  Future<void> write(String key, String value) async {
    final keep = crashAfter;
    if (keep != null) {
      data[key] = value.substring(0, keep.clamp(0, value.length));
      throw StateError('app killed mid-write');
    }
    await super.write(key, value);
  }
}

Map<String, dynamic> doc(int n) => {'save_version': 3, 'n': n};

void main() {
  test('new game: nothing to load', () async {
    final r = await SaveService(MemorySaveStore()).load();
    expect(r.document, isNull);
    expect(r.recovered, isFalse);
  });

  test('saves alternate slots and load returns the newest', () async {
    final store = MemorySaveStore();
    final s = SaveService(store);
    await s.save(doc(1));
    await s.save(doc(2));
    await s.save(doc(3));
    expect(store.data.keys.toSet(), {'save_a', 'save_b'});
    expect((await SaveService(store).load()).document, doc(3));
  });

  test('killing the app mid-write keeps the last good save', () async {
    final store = CrashingStore();
    final s = SaveService(store);
    await s.save(doc(1));
    await s.save(doc(2));
    for (final cut in [0, 5, 20, 40]) {
      store.crashAfter = cut;
      await expectLater(s.save(doc(99)), throwsStateError);
      store.crashAfter = null;
      final r = await SaveService(store).load();
      expect(r.document, doc(2), reason: 'cut at $cut');
    }
  });

  test('a damaged newest slot falls back to the other one', () async {
    final store = MemorySaveStore();
    final s = SaveService(store);
    await s.save(doc(1));
    await s.save(doc(2)); // in save_b
    store.data['save_b'] =
        store.data['save_b']!.replaceFirst(r'\"n\":2', r'\"n\":7');
    expect(store.data['save_b'], contains(r'\"n\":7')); // tampered
    final r = await SaveService(store).load();
    expect(r.document, doc(1));
    expect(r.recovered, isTrue);
  });

  test('older saves migrate step by step; gaps and newer saves fail', () async {
    final store = MemorySaveStore();
    final v1 = SaveService(store, currentVersion: 1);
    await v1.save({'save_version': 1, 'fish': 5});
    final v3 = SaveService(store, migrations: {
      1: (d) => {...d, 'goldfish': d['fish']}..remove('fish'),
      2: (d) => {
            ...d,
            'cat': {'level': 1}
          },
    });
    final r = await v3.load();
    expect(r.migratedFrom, 1);
    expect(r.document, {
      'save_version': 3,
      'goldfish': 5,
      'cat': {'level': 1}
    });
    await expectLater(SaveService(store).load(), throwsFormatException);
    final future = MemorySaveStore();
    await SaveService(future, currentVersion: 4).save({'save_version': 4});
    await expectLater(SaveService(future).load(), throwsFormatException);
  });

  test('writing a document of another version is refused', () {
    expect(() => SaveService(MemorySaveStore()).save({'save_version': 2}),
        throwsArgumentError);
  });

  test('Hive store round-trip', () async {
    final dir = await Directory.systemTemp.createTemp('wt_save');
    addTearDown(() => dir.delete(recursive: true));
    Hive.init(dir.path);
    final box = await Hive.openBox<String>('saves');
    await SaveService(HiveSaveStore(box)).save(doc(5));
    await box.close();
    final again = await Hive.openBox<String>('saves');
    expect((await SaveService(HiveSaveStore(again)).load()).document, doc(5));
    await again.close();
  });

  test('the contract Save v3 example is valid JSON with every section', () {
    final contract =
        File('../../_contract/GAME_CONTRACT.md').readAsStringSync();
    final start = contract.indexOf('"save_version": 3');
    final open = contract.lastIndexOf('{', start);
    final close = contract.indexOf('\n}\n', start) + 2;
    final v3 =
        jsonDecode(contract.substring(open, close)) as Map<String, dynamic>;
    expect(v3.keys.toSet(), {
      'save_version',
      'profile',
      'idle',
      'gear',
      'cat',
      'wardrobe',
      'pets',
      'research',
      'daily',
      'clock',
      'age',
      'entitlements',
      'modes',
      'settings',
      'updated_at',
    });
  });
}
