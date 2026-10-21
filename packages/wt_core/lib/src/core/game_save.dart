import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ads.dart';
import '../save/save.dart';
import 'clock/game_clock.dart';
import 'contracts/age_gate.dart';
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
/// place that knows them all. Sections no module owns yet (age, modes,
/// settings) are carried through unchanged.
class GameSaver {
  GameSaver(this._ref);

  final Ref _ref;
  Map<String, dynamic> _carry = {};

  static const version = 3;
  static const _ageNames = {
    AgeBand.unset: 'unset',
    AgeBand.under13: 'under13',
    AgeBand.over13: '13plus',
  };

  Map<String, dynamic> _section(String k, Map<String, dynamic> fallback) {
    final v = _carry[k];
    return v is Map<String, dynamic> ? v : fallback;
  }

  /// The whole game as a Save v3 document. Marks the player as seen now.
  Map<String, dynamic> capture() {
    final clock = _ref.read(gameClockProvider)..markSeen();
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
    return {
      'save_version': version,
      'profile': {
        ..._section('profile', const {'flags': [], 'unlocked_cosmetics': []}),
        for (final c in Currency.values) c.name: wallet.balance(c),
      },
      'idle': {'cleared_page': loop.state.clearedPage, 'book': loop.state.book},
      'gear': {
        ..._ref.read(gearBasketProvider).toJson(),
        'auto_craft': _ref.read(autoCraftProvider).rule.toJson(),
      },
      'cat': _ref.read(catClassProvider).snapshot().toJson(),
      'wardrobe': _ref.read(wardrobeProvider).snapshot().toJson(),
      'pets': _ref.read(petsProvider)?.snapshot().toJson() ??
          _section('pets', const {'owned': {}, 'deployed': [], 'pity': 0}),
      'research': _ref.read(researchProvider)?.snapshot().toJson() ??
          _section('research', const {'levels': {}, 'task': null}),
      'daily': daily,
      'clock': clockJson,
      'age': {
        'band': _carry['age'] is Map
            ? (_carry['age'] as Map)['band']
            : _ageNames[_ref.read(ageBandProvider)()],
      },
      'entitlements': {
        ...ent,
        'no_ads': ent['no_ads'] == true || _ref.read(noAdsProvider)(),
      },
      'modes': _section('modes', const {}),
      'settings': {
        ..._section('settings',
            const {'lang': 'th', 'bgm': true, 'sfx': true, 'speed': 1}),
        if (_ref.read(researchProvider) case final r?)
          'notify_research': r.notifyDone,
      },
      'updated_at': clock.effectiveNow.toIso8601String(),
    };
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

    _ref.read(catClassProvider).restore(CatState.fromJson(sec('cat')));
    final cleared = sec('idle')['cleared_page'];
    if (cleared is! int) {
      throw const FormatException('save: "idle.cleared_page" missing');
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
    if (_ref.read(petsProvider) case final pets?) {
      final fish = daily['fish_pulls'];
      pets.restore(PetsState.fromJson(sec('pets')),
          fishPulls: fish is int ? fish : 0, dateKey: dateKey);
    }
    if (_ref.read(researchProvider) case final r?) {
      r.restore(ResearchState.fromJson(sec('research')));
      final settings = doc['settings'];
      r.notifyDone = settings is! Map || settings['notify_research'] != false;
    }
    // loading = opening the app: a day that turned since the save resets now
    _ref.read(gameClockProvider).tick();

    _carry = {
      for (final k in const [
        'profile',
        'pets',
        'research',
        'daily',
        'age',
        'entitlements',
        'modes',
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

/// Local save storage + migrations (T-022). Boot overrides this with a
/// [HiveSaveStore]; the default keeps saves in memory.
final saveServiceProvider =
    Provider<SaveService>((ref) => SaveService(MemorySaveStore()));

/// Save / load the whole game (T-022).
final gameSaverProvider = Provider<GameSaver>((ref) => GameSaver(ref));
