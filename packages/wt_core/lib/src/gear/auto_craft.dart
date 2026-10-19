import 'dart:async';

import '../core/contracts/gear_basket.dart';
import '../core/contracts/rewards.dart';
import '../core/contracts/wallet.dart';
import 'gear_basket.dart';

/// Auto-craft (GDD v0.5 §4.3): knit the weakest open slot (counting worn
/// and stashed items) every [GearRules.autoCraftIntervalMs] of play until
/// the yarn runs out. Only runs while [tick] is called — never offline.
///
/// An item is kept when it beats both the worn and the stashed item on
/// power, or is ✨ strictly better than the one it would replace; anything
/// else is recycled. Kept items go to the stash or are worn at once, by
/// [AutoCraftRule.mode].
class AutoCraft implements IAutoCraft {
  AutoCraft(this.basket, this.wallet);

  final GearBasket basket;
  final IWallet wallet;
  final _stopped = StreamController<AutoCraftStopReason>.broadcast(sync: true);
  AutoCraftRule _rule = const AutoCraftRule();
  int _sinceLastMs = 0;

  AutoCraftRule get rule => _rule;
  bool get running => _rule.on;

  @override
  Stream<AutoCraftStopReason> get stopped => _stopped.stream;

  @override
  void configure(AutoCraftRule rule) => _rule = rule;

  @override
  void start() {
    _rule = AutoCraftRule(on: true, mode: _rule.mode);
    _sinceLastMs = 0;
  }

  @override
  void stop() => stopFor(AutoCraftStopReason.stoppedByPlayer);

  void stopFor(AutoCraftStopReason reason) {
    if (!_rule.on) return;
    _rule = AutoCraftRule(on: false, mode: _rule.mode);
    _stopped.add(reason);
  }

  /// Advances online play time; crafts once per interval.
  void tick(int dtMs) {
    if (!_rule.on) return;
    _sinceLastMs += dtMs;
    final every = basket.rules.autoCraftIntervalMs;
    while (_rule.on && _sinceLastMs >= every) {
      _sinceLastMs -= every;
      craftOnce();
    }
  }

  /// One auto-craft step. Returns the result, or null when out of yarn.
  CraftResult? craftOnce() {
    if (wallet.balance(Currency.yarn) < 1) {
      stopFor(AutoCraftStopReason.outOfYarn);
      return null;
    }
    GearSlot? weakest;
    var weakestPower = 0;
    for (final s in basket.openSlots) {
      final p = _best(s);
      if (weakest == null || p < weakestPower) {
        weakest = s;
        weakestPower = p;
      }
    }
    final result = basket.craft(weakest);
    final item = result.item;
    final slot = item.slot;
    final reference = basket.stashed(slot) ?? basket.equipped(slot);
    final keep = basket.powerOfItem(item) > _best(slot) ||
        item.isStrictlyBetterThan(reference);
    if (!keep) {
      basket.recycle(item.id);
    } else if (_rule.mode == AutoCraftMode.equip) {
      final waiting = basket.stashed(slot);
      basket.equip(item.id);
      if (waiting != null) basket.recycle(waiting.id);
    } else {
      basket.stash(item.id);
    }
    return result;
  }

  int _best(GearSlot s) {
    final worn = basket.powerOfItem(basket.equipped(s));
    final kept = basket.powerOfItem(basket.stashed(s));
    return worn > kept ? worn : kept;
  }

  Future<void> dispose() => _stopped.close();
}
