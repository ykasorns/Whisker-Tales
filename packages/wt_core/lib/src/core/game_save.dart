import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ads.dart';
import '../idle/idle.dart';
import '../save/save.dart';
import 'clock/game_clock.dart';
import 'contracts/cat_class.dart';
import 'contracts/gear_basket.dart';
import 'contracts/pets.dart';
import 'contracts/research.dart';
import 'contracts/rewards.dart';
import 'contracts/wardrobe.dart';
import 'providers.dart';
import 'wallet/memory_wallet.dart';

/// Puts every module's state into one Save v3 document and back
/// (GAME_CONTRACT §4.6, T-022). Part of the wiring layer, like
/// `providers.dart`: modules only expose `toJson`/`restore`; this is the one
/// place that knows them all. Sections no module owns yet are carried
/// through unchanged.
class GameSaver {
  GameSaver(this._ref);

  final Ref _ref;
  Map<String, dynamic> _carry = {};

  static const version = 3;

  /// `profile.flags` as saved (story unlocks and the like).
  Set<String> get profileFlags => {
        if (_section('profile', const {})['flags'] case final List l)
          ...l.whereType<String>(),
      };

  Map<String, dynamic> _section(String k, Map<String, dynamic> fallback) {
    final v = _carry[k];
    return v is Map<String, dynamic> ? v : fallback;
  }

  /// The whole game as a Save v3 document. Marks the player as seen now,
  /// unless [asSeen] is false (a look at the save before the game starts,
  /// e.g. comparing with the cloud: the offline window must stay open).
  Map<String, dynamic> capture({bool asSeen = true}) {
    final clock = _ref.read(gameClockProvider);
    if (asSeen) {
      // A "welcome back" window still on screen is paid now: marking the
      // player seen would otherwise move last_seen past it, and leaving the
      // app (pause → save) or killing it would lose the reward.
      final offline = _ref.read(offlineRewardProvider);
      if (offline.pending != null) offline.claim();
      clock.markSeen();
    }
    final wallet = _ref.read(walletProvider);
    final loop = _ref.read(idleLoopProvider);
    final ads = _ref.read(adServiceProvider);
    final daily = <String, dynamic>{
      ..._section('daily', const {'fish_pulls': 0}),
      if (ads is AdService)
        ...ads.snapshot().toJson()
      else
        'date_key': clock.dateKey,
      if (_ref.read(petsProvider) case final pets?)
        'fish_pulls': pets.fishPullsToday,
    };
    final clockJson = clock.snapshot().toJson()..remove('date_key');
    final ent = _section('entitlements', const {'no_ads': false});
    final iap = _ref.read(iapServiceProvider);
    return {
      'save_version': version,
      'profile': {
        ..._section('profile', const {'flags': [], 'unlocked_cosmetics': []}),
        for (final c in Currency.values) c.name: wallet.balance(c),
        // the cloud tie-break after pages (GAME_CONTRACT §4.6)
        'power': _ref
            .read(powerScoreProvider)
            .of(_ref.read(catSpecProvider)().stats),
      },
      'idle': {
        'cleared_page': loop.state.clearedPage,
        'book': loop.state.book,
        'road_rng': _ref.read(roadEventsProvider).rngState,
      },
      'gear': {
        ..._ref.read(gearBasketProvider).toJson(),
        'auto_craft': _ref.read(autoCraftProvider).rule.toJson(),
      },
      'cat': _ref.read(catClassProvider).snapshot().toJson(),
      'wardrobe': _ref.read(wardrobeProvider).snapshot().toJson(),
      'pets': switch (_ref.read(petsProvider)) {
        final pets? => {...pets.snapshot().toJson(), 'rng': pets.rngState},
        null =>
          _section('pets', const {'owned': {}, 'deployed': [], 'pity': 0}),
      },
      'research': _ref.read(researchProvider)?.snapshot().toJson() ??
          _section('research', const {'levels': {}, 'task': null}),
      'daily': daily,
      'clock': clockJson,
      'age': {'band': _ref.read(ageGateProvider).toJsonBand()},
      // what was bought decides no_ads; a carried flag never sticks on
      'entitlements': {...ent, ...?iap?.toJson()},
      'modes': _ref.read(modeSavesProvider).toJson(),
      'settings': {
        ..._section('settings',
            const {'lang': 'th', 'bgm': true, 'sfx': true, 'speed': 1}),
        'lang': _ref.read(langProvider),
        'bgm': _ref.read(audioServiceProvider).bgmEnabled,
        'sfx': _ref.read(audioServiceProvider).sfxEnabled,
        if (_ref.read(researchProvider) case final r?)
          'notify_research': r.notifyDone,
      },
      'updated_at': clock.effectiveNow.toIso8601String(),
    };
  }

  /// A new game: this player's knitting, hatching and road-event dice get
  /// their own start from [seed] (before, every player began on the same
  /// rolls). Fights stay seeded by page and wave, the same for everyone.
  void newWorld(int seed) {
    _ref.read(gearBasketProvider).rngState = mixSeed([seed, 1]);
    _ref.read(petsProvider)?.rngState = mixSeed([seed, 2]);
    _ref.read(roadEventsProvider).rngState = mixSeed([seed, 3]);
  }

  /// Loads a Save v3 document into every module. Throws [FormatException]
  /// (naming the section) when a part does not fit the data.
  void restore(Map<String, dynamic> doc) {
    if (doc['save_version'] != version) {
      throw FormatException(
          'save: expected v$version, got ${doc['save_version']}');
    }
    Map<String, dynamic> sec(String k) {
      final v = doc[k];
      if (v is! Map<String, dynamic>) {
        throw FormatException('save: "$k" missing');
      }
      return v;
    }

    final daily = sec('daily');
    final dateKey = daily['date_key'];
    if (dateKey is! String) {
      throw const FormatException('save: "daily.date_key" missing');
    }
    _ref
        .read(gameClockProvider)
        .restore(ClockState.fromJson(sec('clock'), dateKey));

    final profile = sec('profile');
    final wallet = _ref.read(walletProvider);
    final balances = {
      for (final c in Currency.values)
        if (profile[c.name] is int) c: profile[c.name] as int,
    };
    if (wallet is MemoryWallet) {
      wallet.setBalances(balances);
    } else {
      wallet.add(RewardBundle(balances));
    }

    _ref.read(ageGateProvider).restore(_map(doc['age'])['band']);
    _ref.read(catClassProvider).restore(CatState.fromJson(sec('cat')));
    final idle = sec('idle');
    final cleared = idle['cleared_page'];
    if (cleared is! int) {
      throw const FormatException('save: "idle.cleared_page" missing');
    }
    // dice first: restoring the loop starts a walk, where events roll
    if (idle['road_rng'] case final int rng) {
      _ref.read(roadEventsProvider).rngState = rng;
    }
    _ref.read(idleLoopProvider).restore(clearedPage: cleared);

    final gear = sec('gear');
    _ref.read(gearBasketProvider).restore(gear);
    final auto = gear['auto_craft'];
    if (auto is Map<String, dynamic>) {
      final rule = AutoCraftRule.fromJson(auto);
      final ac = _ref.read(autoCraftProvider)..configure(rule);
      if (rule.on) ac.start();
    }
    _ref
        .read(wardrobeProvider)
        .restore(WardrobeState.fromJson(sec('wardrobe')));

    final ads = _ref.read(adServiceProvider);
    if (ads is AdService) ads.restore(AdDailyState.fromJson(daily));
    if (doc['entitlements'] case final Map<String, dynamic> ent) {
      _ref.read(iapServiceProvider)?.restoreSaved(ent);
    }
    if (_ref.read(petsProvider) case final pets?) {
      final fish = daily['fish_pulls'];
      pets.restore(PetsState.fromJson(sec('pets')),
          fishPulls: fish is int ? fish : 0, dateKey: dateKey);
      if (sec('pets')['rng'] case final int rng) pets.rngState = rng;
    }
    if (_ref.read(researchProvider) case final r?) {
      r.restore(ResearchState.fromJson(sec('research')));
      final settings = doc['settings'];
      r.notifyDone = settings is! Map || settings['notify_research'] != false;
    }
    final audio = _ref.read(audioServiceProvider);
    audio.setBgmEnabled(_map(doc['settings'])['bgm'] != false);
    audio.setSfxEnabled(_map(doc['settings'])['sfx'] != false);
    if (_map(doc['settings'])['lang'] case final String lang
        when kLanguages.contains(lang)) {
      _ref.read(langProvider.notifier).state = lang;
    }
    // loading = opening the app: a day that turned since the save resets now
    _ref.read(gameClockProvider).tick();

    _ref.read(modeSavesProvider).restore(doc['modes']);

    _carry = {
      for (final k in const [
        'profile',
        'pets',
        'research',
        'daily',
        'entitlements',
        'settings'
      ])
        if (doc[k] != null) k: doc[k],
    };
  }

  /// Loads the local save into the game. Returns what happened (new game,
  /// migrated, recovered from a damaged slot).
  Future<SaveLoadResult> load() async {
    final r = await _ref.read(saveServiceProvider).load();
    final doc = r.document;
    if (doc != null) restore(doc);
    return r;
  }

  Future<void> save() => _ref.read(saveServiceProvider).save(capture());
}

/// How the game came up when the newest save could not be loaded.
enum BootFallback {
  /// The other save slot (one save older) loaded instead.
  olderSave,

  /// No save fit this build: a new game. The old save is kept aside.
  newGame,
}

class GameBoot {
  const GameBoot(this.container, {this.fallback, this.error});

  /// Holds the loaded game; use it for the app's `ProviderScope`.
  final ProviderContainer container;

  /// Null when the newest save (or no save: first launch) loaded.
  final BootFallback? fallback;

  /// Why the newest save did not load, for the log.
  final Object? error;
}

/// Starts the game from the newest save that fits this build (T-022). A save
/// that throws while loading (newer app version, data it does not know, a
/// bug) never stops the app: the older slot is tried, then a new game, each
/// in a fresh container from [make] so no half-loaded state is left. The
/// broken save is copied aside first (`broken_save_a/b`) and the next save
/// is written so it never overwrites the save the game runs on.
///
/// Every container from [make] must share one [SaveService].
///
/// A new game gets its own dice from [newWorldSeed] (random by default).
Future<GameBoot> bootGame(ProviderContainer Function() make,
    {int Function()? newWorldSeed}) async {
  var container = make();
  final saves = container.read(saveServiceProvider);
  final read = await saves.readSlots();
  Object? error;
  for (var i = 0; i < read.slots.length; i++) {
    final slot = read.slots[i];
    try {
      container.read(gameSaverProvider).restore(saves.upgrade(slot.doc));
    } on Object catch (e) {
      error ??= e;
      container.dispose();
      container = make();
      continue;
    }
    saves.resumeAfter(read, slot);
    if (i == 0) return GameBoot(container);
    await saves.keepBroken();
    return GameBoot(container, fallback: BootFallback.olderSave, error: error);
  }
  saves.resumeAfter(read, null);
  container
      .read(gameSaverProvider)
      .newWorld(newWorldSeed?.call() ?? math.Random().nextInt(1 << 32));
  if (read.slots.isEmpty) return GameBoot(container);
  await saves.keepBroken();
  return GameBoot(container, fallback: BootFallback.newGame, error: error);
}

/// Local save storage + migrations (T-022). Boot overrides this with a
/// [HiveSaveStore]; the default keeps saves in memory.
final saveServiceProvider =
    Provider<SaveService>((ref) => SaveService(MemorySaveStore()));

/// Save / load the whole game (T-022).
final gameSaverProvider = Provider<GameSaver>((ref) => GameSaver(ref));

Map<String, dynamic> _map(Object? v) =>
    v is Map<String, dynamic> ? v : const {};
