import '../core/clock/game_clock.dart';
import '../core/contracts/idle_loop.dart';
import '../core/contracts/offline_reward.dart';
import '../core/contracts/rewards.dart';
import '../core/contracts/wallet.dart';

/// `offline` + `research.offline_node_*` + `player.offline_rate_vs_online`
/// from idle_balance_v1.json (GDD v0.4 §8, D-002 Q3).
class OfflineRules {
  const OfflineRules({
    required this.baseCapMin,
    required this.minPerLevel,
    required this.maxLevel,
    required this.ratePct,
  });

  final int baseCapMin;
  final int minPerLevel;
  final int maxLevel;

  /// Offline waves per minute as % of online (100 = same).
  final int ratePct;

  /// 8 h + 10 min per `offline_cap` research level (capped at max level).
  Duration capFor(int researchLevel) {
    final lv = researchLevel < 0
        ? 0
        : (researchLevel > maxLevel ? maxLevel : researchLevel);
    return Duration(minutes: baseCapMin + minPerLevel * lv);
  }

  factory OfflineRules.fromBalance(Map<String, dynamic> b) {
    int i(String section, String key) {
      final m = b[section];
      final v =
          m is Map<String, dynamic> ? (m[key] ?? m['ASSUMPTION_$key']) : null;
      if (v is! int) {
        throw FormatException('balance: "$section.$key" must be an integer');
      }
      return v;
    }

    final rate =
        (b['player'] as Map<String, dynamic>?)?['offline_rate_vs_online'];
    if (rate is! num || rate < 0) {
      throw const FormatException(
          'balance: "player.offline_rate_vs_online" must be ≥ 0');
    }
    return OfflineRules(
      baseCapMin: i('offline', 'base_cap_min'),
      minPerLevel: i('research', 'offline_node_min_per_level'),
      maxLevel: i('research', 'offline_node_max_level'),
      ratePct: (rate * 100).round(),
    );
  }
}

/// Offline rewards (GDD v0.4 §8): `clamp(now − last_seen, 0, cap)` of
/// farming the current page, paid with the same [IIncomeModel] as online
/// play. No ×2 button in the MVP (Q7). The speed button never applies.
///
/// Clock rules (GAME_CONTRACT §4.6): a clock turned back (`now < max_seen`)
/// pays nothing; claiming moves `last_seen` to now, and a cloud merge keeps
/// the later `last_seen`, so a window can never be paid twice.
class OfflineReward implements IOfflineReward {
  OfflineReward({
    required this.rules,
    required this.income,
    required this.clock,
    required this.wallet,
    required this.farmPage,
    this.grantExp,
  });

  final OfflineRules rules;
  final IIncomeModel income;
  final GameClock clock;
  final IWallet wallet;

  /// Page the cat was farming when the player left.
  final int Function() farmPage;

  /// Gives cat EXP (cat_class), injected so this module does not import it.
  final void Function(int exp)? grantExp;

  OfflineRewardResult? _pending;

  /// What is waiting to be claimed (null = nothing computed yet).
  OfflineRewardResult? get pending => _pending;

  @override
  OfflineRewardResult compute({
    required DateTime lastSeenUtc,
    required DateTime effectiveNowUtc,
    required Duration cap,
  }) {
    final away = effectiveNowUtc.difference(lastSeenUtc);
    final capMin = cap.inMinutes;
    var minutes = away.isNegative ? 0 : away.inMinutes;
    if (minutes > capMin) minutes = capMin;
    final waves =
        (minutes * income.wavesPerMinute * rules.ratePct / 100).floor();
    final page = farmPage();
    return OfflineRewardResult(
      creditedMinutes: minutes,
      cappedAtMinutes: capMin,
      reward: waves == 0 ? RewardBundle.empty : income.forWaves(page, waves),
      waves: waves,
      exp: waves == 0 ? 0 : income.expForWaves(page, waves),
    );
  }

  /// On app open / resume: works out the window from [clock] and keeps it
  /// pending until [claim]. A turned-back clock gives nothing.
  OfflineRewardResult checkIn({int offlineResearchLevel = 0}) {
    final cap = rules.capFor(offlineResearchLevel);
    final rolledBack = clock.now().isBefore(clock.maxSeenUtc);
    final result = rolledBack
        ? OfflineRewardResult(
            creditedMinutes: 0,
            cappedAtMinutes: cap.inMinutes,
            reward: RewardBundle.empty)
        : compute(
            lastSeenUtc: clock.lastSeenUtc,
            effectiveNowUtc: clock.effectiveNow,
            cap: cap);
    _pending = result;
    return result;
  }

  /// Pays the pending window into the wallet (and EXP to the cat), then
  /// marks the player as seen now so it cannot be paid again.
  @override
  RewardBundle claim() {
    final p = _pending;
    _pending = null;
    clock.markSeen();
    if (p == null || (p.reward.isEmpty && p.exp == 0)) {
      return RewardBundle.empty;
    }
    wallet.add(p.reward);
    if (p.exp > 0) grantExp?.call(p.exp);
    return p.reward;
  }
}
