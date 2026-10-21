import 'dart:convert';

import 'package:hive/hive.dart';

/// Key–value storage the save slots live in. [HiveSaveStore] on device,
/// [MemorySaveStore] in tests.
abstract class SaveStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class MemorySaveStore implements SaveStore {
  final data = <String, String>{};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

/// Hive box of strings (GAME_CONTRACT §5 approved dependency).
class HiveSaveStore implements SaveStore {
  HiveSaveStore(this.box);
  final Box<String> box;

  @override
  Future<String?> read(String key) async => box.get(key);

  @override
  Future<void> write(String key, String value) async {
    await box.put(key, value);
    await box.flush();
  }
}

/// One readable save slot: generation, slot index, stored document.
typedef SavedSlot = ({int gen, int slot, Map<String, dynamic> doc});

/// [SaveService.readSlots] result.
typedef SaveSlots = ({List<SavedSlot> slots, bool damaged});

/// Upgrades a save document one version (`from` → `from + 1`).
typedef SaveMigration = Map<String, dynamic> Function(Map<String, dynamic>);

class SaveLoadResult {
  const SaveLoadResult(this.document,
      {this.migratedFrom, this.recovered = false});

  /// Save v[current] document, or null for a new game.
  final Map<String, dynamic>? document;

  /// Version the file had before migrating (null = already current).
  final int? migratedFrom;

  /// The newest slot was damaged and the other one was used.
  final bool recovered;
}

/// Local save (T-022, GAME_CONTRACT §4.6 Save v3). Two slots, written in
/// turn, each with a generation number and a checksum: the slot being
/// written is never the one holding the last good save, so killing the app
/// mid-write leaves the previous save intact. Loading picks the newest slot
/// whose checksum matches.
class SaveService {
  SaveService(this.store,
      {this.currentVersion = 3, Map<int, SaveMigration> migrations = const {}})
      : _migrations = Map.unmodifiable(migrations);

  final SaveStore store;
  final int currentVersion;
  final Map<int, SaveMigration> _migrations;

  static const _slots = ['save_a', 'save_b'];
  int _generation = 0;
  int _lastSlot = -1;

  /// The newest readable save, migrated (no document = new game).
  Future<SaveLoadResult> load() async {
    final read = await readSlots();
    if (read.slots.isEmpty) {
      return SaveLoadResult(null, recovered: read.damaged);
    }
    final best = read.slots.first;
    resumeAfter(read, best);
    final from = best.doc['save_version'];
    return SaveLoadResult(upgrade(best.doc),
        migratedFrom: from == currentVersion ? null : from as int,
        recovered: read.damaged);
  }

  /// Every slot whose checksum holds, newest first, as stored (not yet
  /// migrated). [damaged]: some slot failed its checksum.
  Future<SaveSlots> readSlots() async {
    final slots = <SavedSlot>[];
    var damaged = false;
    for (var i = 0; i < _slots.length; i++) {
      final raw = await store.read(_slots[i]);
      if (raw == null) continue;
      final env = _open(raw);
      if (env == null) {
        damaged = true;
        continue;
      }
      slots.add((gen: env.gen, slot: i, doc: env.doc));
    }
    slots.sort((a, b) => b.gen.compareTo(a.gen));
    return (slots: slots, damaged: damaged);
  }

  /// [doc] migrated to [currentVersion]. Throws [FormatException] when it
  /// has no version, is newer than this app or a migration is missing.
  Map<String, dynamic> upgrade(Map<String, dynamic> doc) {
    final from = doc['save_version'];
    if (from is! int) {
      throw const FormatException('save: "save_version" missing');
    }
    return from == currentVersion ? doc : migrate(doc, from, currentVersion);
  }

  /// The next [save] continues after every slot in [read] (so it is the
  /// newest) and never overwrites [loaded], the save the game runs on. With
  /// [loaded] null (new game) slot A is written first.
  void resumeAfter(SaveSlots read, SavedSlot? loaded) {
    _generation = read.slots.fold(0, (g, s) => s.gen > g ? s.gen : g);
    _lastSlot = loaded?.slot ?? -1;
  }

  /// Copies both slots aside as `broken_save_a/b` before a save that does
  /// not load gets overwritten. The first broken save is kept: a later
  /// failure never replaces it.
  Future<void> keepBroken() async {
    for (final k in _slots) {
      final raw = await store.read(k);
      if (raw != null && await store.read('broken_$k') == null) {
        await store.write('broken_$k', raw);
      }
    }
  }

  /// Writes [document] to the slot not holding the last good save.
  Future<void> save(Map<String, dynamic> document) async {
    if (document['save_version'] != currentVersion) {
      throw ArgumentError('save_version must be $currentVersion');
    }
    final gen = _generation + 1;
    final slot = _lastSlot == 0 ? 1 : 0;
    final body = jsonEncode(document);
    final envelope =
        jsonEncode({'gen': gen, 'sum': _checksum(body), 'body': body});
    await store.write(_slots[slot], envelope);
    _generation = gen;
    _lastSlot = slot;
  }

  /// Runs migrations `from → from+1 → … → to`. Every version step needs a
  /// registered migration (GAME_CONTRACT §4.4: bump = migration + test).
  Map<String, dynamic> migrate(Map<String, dynamic> doc, int from, int to) {
    if (from > to) {
      throw FormatException('save v$from is newer than this app (v$to)');
    }
    var d = doc;
    for (var v = from; v < to; v++) {
      final m = _migrations[v] ??
          (throw FormatException('save: no migration from v$v to v${v + 1}'));
      d = m(d);
      d['save_version'] = v + 1;
    }
    return d;
  }

  ({int gen, Map<String, dynamic> doc})? _open(String raw) {
    try {
      final env = jsonDecode(raw);
      if (env is! Map<String, dynamic>) return null;
      final gen = env['gen'], sum = env['sum'], body = env['body'];
      if (gen is! int || sum is! int || body is! String) return null;
      if (_checksum(body) != sum) return null;
      final doc = jsonDecode(body);
      return doc is Map<String, dynamic> ? (gen: gen, doc: doc) : null;
    } on FormatException {
      return null;
    }
  }

  /// FNV-1a over UTF-8 bytes.
  static int _checksum(String s) {
    var h = 0x811C9DC5;
    for (final b in utf8.encode(s)) {
      h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }
}
