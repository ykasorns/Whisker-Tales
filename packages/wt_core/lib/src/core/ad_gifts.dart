import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'contracts/ads.dart';
import 'contracts/rewards.dart';
import 'providers.dart';

/// 🎁 daily gift / 🧶 yarn bundle on the Events page (D-003): one rewarded
/// ad pays N minutes of the farm page's income (`*_minutes_of_income`), the
/// gear's goldfish find included. One place for the app and the balance
/// sim (T-029).
class AdGifts {
  AdGifts(this._ref);
  final Ref _ref;

  static const gifts = {
    'daily_gift': (Currency.goldfish, 'fish_minutes_of_income'),
    'yarn_bundle': (Currency.yarn, 'yarn_minutes_of_income'),
  };

  /// What one ad of [placement] pays now (at least 1).
  RewardBundle rewardFor(String placement) {
    final (currency, key) = gifts[placement] ??
        (throw ArgumentError.value(placement, 'placement', 'not a gift'));
    final rule = _ref.read(adRulesProvider).placements[placement]!;
    final income = _ref.read(incomeModelProvider);
    final page = _ref.read(idleLoopProvider).state.farmPage;
    final waves = ((rule.params[key] ?? 0) * income.wavesPerMinute).floor();
    final amount = income.forWaves(page, waves,
        fishBp: _ref.read(findsProvider)().fishBp)[currency];
    return RewardBundle({currency: amount < 1 ? 1 : amount});
  }

  /// Shows the ad; pays only when it was watched to the end.
  Future<RewardBundle?> watch(String placement) async {
    if (await _ref.read(adServiceProvider).show(placement) !=
        AdOutcome.rewarded) {
      return null;
    }
    final r = rewardFor(placement);
    _ref.read(walletProvider).add(r);
    return r;
  }
}

/// Events-page gifts (D-003).
final adGiftsProvider = Provider<AdGifts>((ref) => AdGifts(ref));
