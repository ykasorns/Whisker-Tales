import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

/// Reads the repo, with optional edits to one file's JSON.
class RepoSource implements ContentSource {
  RepoSource({this.edit = const {}, this.missing = const {}});
  final Map<String, void Function(Map<String, dynamic>)> edit;
  final Set<String> missing;

  @override
  Future<String> read(String path) async {
    if (missing.contains(path)) throw const FileSystemException('not found');
    final raw = File('../../$path').readAsStringSync();
    final fix = edit[path];
    if (fix == null) return raw;
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    fix(doc);
    return jsonEncode(doc);
  }
}

void main() {
  Future<ContentError> fails(RepoSource s) async {
    try {
      await ContentRepository(s).loadAll();
    } on ContentError catch (e) {
      return e;
    }
    fail('expected a ContentError');
  }

  test('loads every file and the game runs on it', () async {
    final content = await ContentRepository(RepoSource()).loadAll();
    expect(content.skills.byClass, hasLength(4));
    expect(content.cat.classes, hasLength(5));
    expect(content.gear.slots, hasLength(8));
    final c = ProviderContainer(overrides: content.overrides);
    addTearDown(c.dispose);
    final loop = c.read(idleLoopProvider);
    for (var i = 0; i < 600; i++) {
      loop.tick(100);
    }
    expect(c.read(walletProvider).balance(Currency.goldfish), greaterThan(0));
    expect(c.read(offlineRewardProvider).rules.baseCapMin, 480);
  });

  test('ASSUMPTION_ values load like plain ones', () async {
    final content = await ContentRepository(RepoSource()).loadAll();
    expect(content.combat.stunMs, 1000); // ASSUMPTION_stun_ms
    expect(content.idle.starterYarn, 10); // ASSUMPTION_starter_yarn
  });

  test('broken JSON names the file', () async {
    final e = await fails(RepoSource(missing: {'design/data/wardrobe.json'}));
    expect(e.file, 'design/data/wardrobe.json');
  });

  test('a wrong schema_version is a clear error', () async {
    final e = await fails(RepoSource(edit: {
      'design/data/skills.json': (d) => d['schema_version'] = 2,
    }));
    expect(e.file, 'design/data/skills.json');
    expect(e.message, contains('schema_version is 2'));
  });

  test('a bad or missing field names the file and the field', () async {
    var e = await fails(RepoSource(edit: {
      ContentRepository.balancePath: (d) =>
          (d['combat'] as Map).remove('def_floor_pct'),
    }));
    expect(e.file, ContentRepository.balancePath);
    expect(e.message, contains('def_floor_pct'));
    e = await fails(RepoSource(edit: {
      'design/data/skills.json': (d) => ((d['skills'] as List).first
          as Map)['buffs_target'] = ['no_such_buff'],
    }));
    expect(e.file, 'design/data/skills.json');
    expect(e.message, contains('no_such_buff'));
    e = await fails(RepoSource(edit: {
      'design/data/gear_slots.json': (d) => (d['slots'] as Map).remove('bell'),
    }));
    expect(e.file, 'design/data/gear_slots.json');
    expect(e.message, contains('bell'));
  });

  test('cross-file references are checked', () async {
    var e = await fails(RepoSource(edit: {
      'design/data/skills.json': (d) =>
          ((d['skills'] as List).first as Map)['class'] = 'pirate',
    }));
    expect(e.message, contains('pirate'));
    e = await fails(RepoSource(edit: {
      'design/data/wardrobe.json': (d) =>
          (d['weapon_art'] as Map).remove('mage'),
    }));
    expect(e.message, contains('mage'));
    e = await fails(RepoSource(edit: {
      ContentRepository.balancePath: (d) =>
          ((d['ads'] as Map)['placements'] as Map).remove('road_event'),
    }));
    expect(e.message, contains('road_event'));
  });
}
