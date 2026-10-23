import '../core/clock/game_clock.dart';
import '../core/contracts/ads.dart';
import '../core/contracts/age_gate.dart';
import 'ad_network.dart';

/// What a placement does for Supporter Pack owners (D-003).
enum NoAdsBehavior { show, hide, grant }

class PlacementRule {
  const PlacementRule({
    required this.id,
    required this.enabled,
    required this.perDay,
    required this.noAds,
    this.params = const {},
  });

  /// The placement's own numbers (e.g. `fish_minutes_of_income`).
  final Map<String, num> params;
  final String id;
  final bool enabled;
  final int perDay;
  final NoAdsBehavior noAds;
}

/// `ads` from idle_balance_v1.json (D-003, D-008).
class AdRules {
  const AdRules({required this.dailyCapTotal, required this.placements});

  final int dailyCapTotal;
  final Map<String, PlacementRule> placements;

  /// `grant` (reward without an ad) is refused unless the placement carries
  /// `"grant_allowed": true` — a DECISIONS entry must allow it first.
  factory AdRules.fromJson(Map<String, dynamic> balance) {
    final ads = balance['ads'];
    if (ads is! Map<String, dynamic>) {
      throw const FormatException('balance: "ads" must be an object');
    }
    final total = ads['daily_cap_total'];
    final raw = ads['placements'];
    if (total is! int || total < 0 || raw is! Map<String, dynamic>) {
      throw const FormatException('ads: needs daily_cap_total and placements');
    }
    final placements = <String, PlacementRule>{};
    for (final e in raw.entries) {
      final p = e.value;
      if (p is! Map<String, dynamic>) {
        throw FormatException('ads.${e.key}: must be an object');
      }
      final enabled = p['enabled'], perDay = p['per_day'];
      final behavior = NoAdsBehavior.values
          .where((b) => b.name == (p['no_ads_behavior'] ?? 'show'));
      if (enabled is! bool ||
          perDay is! int ||
          perDay < 0 ||
          behavior.isEmpty) {
        throw FormatException(
            'ads.${e.key}: needs enabled, per_day and no_ads_behavior show|hide|grant');
      }
      if (behavior.first == NoAdsBehavior.grant && p['grant_allowed'] != true) {
        throw FormatException(
            'ads.${e.key}: no_ads_behavior "grant" needs a DECISIONS entry (grant_allowed)');
      }
      placements[e.key] = PlacementRule(
          id: e.key,
          enabled: enabled,
          perDay: perDay,
          noAds: behavior.first,
          params: Map.unmodifiable({
            for (final p2 in p.entries)
              if (p2.value is num && p2.key != 'per_day')
                p2.key: p2.value as num,
          }));
    }
    return AdRules(
        dailyCapTotal: total, placements: Map.unmodifiable(placements));
  }
}

/// Save v3 `daily` ad counters (GAME_CONTRACT §4.6).
class AdDailyState {
  const AdDailyState({
    required this.dateKey,
    this.used = const {},
    this.total = 0,
  });
  final String dateKey;
  final Map<String, int> used;
  final int total;

  Map<String, dynamic> toJson() =>
      {'date_key': dateKey, 'ads_used': used, 'ads_total': total};

  factory AdDailyState.fromJson(Map<String, dynamic> j) {
    final key = j['date_key'], used = j['ads_used'], total = j['ads_total'];
    if (key is! String ||
        used is! Map<String, dynamic> ||
        used.values.any((v) => v is! int || v < 0) ||
        total is! int ||
        total < 0) {
      throw const FormatException('daily: needs date_key, ads_used, ads_total');
    }
    return AdDailyState(
        dateKey: key, used: used.cast<String, int>(), total: total);
  }
}

/// The only place ads are shown and counted (GDD v0.4 §14, D-003): rewarded
/// only; per-placement and total daily caps; counters reset only when the
/// game clock's date key moves forward (a clock turned back never resets);
/// under-13 / unset → child-directed + non-personalized on every request.
class AdService implements IAdService {
  AdService({
    required this.rules,
    required this.network,
    required this.clock,
    required this.ageBand,
    required this.hasNoAds,
  }) : _dateKey = clock.dateKey;

  final AdRules rules;
  final AdNetwork network;
  final GameClock clock;
  final AgeBand Function() ageBand;

  /// Supporter Pack entitlement (`no_ads`, T-025).
  final bool Function() hasNoAds;

  String _dateKey;
  final _used = <String, int>{};
  int _total = 0;
  bool _showing = false;
  DateTime? _endedAt;

  /// An ad is on screen, or one closed within [within]. Watching an ad
  /// sends the app to the background for a moment; coming back from it is
  /// not "time away" (no welcome-back screen for it).
  bool showingOrJustShown({Duration within = const Duration(seconds: 5)}) =>
      _showing ||
      (_endedAt != null && clock.effectiveNow.difference(_endedAt!) <= within);

  void _rollIfNewDay() {
    final today = clock.dateKey;
    if (today.compareTo(_dateKey) > 0) {
      _dateKey = today;
      _used.clear();
      _total = 0;
    }
  }

  PlacementRule? _rule(String id) => rules.placements[id];

  @override
  int remainingToday(String placementId) {
    _rollIfNewDay();
    final r = _rule(placementId);
    if (r == null || !r.enabled) return 0;
    if (hasNoAds() && r.noAds == NoAdsBehavior.hide) return 0;
    final own = r.perDay - (_used[placementId] ?? 0);
    final all = rules.dailyCapTotal - _total;
    final left = own < all ? own : all;
    return left < 0 ? 0 : left;
  }

  @override
  bool canShow(String placementId) => remainingToday(placementId) > 0;

  /// Shows a rewarded ad. Only [AdOutcome.rewarded] counts toward the caps
  /// and may grant the reward.
  @override
  Future<AdOutcome> show(String placementId) async {
    if (!canShow(placementId) || _showing) {
      return _showing ? AdOutcome.failed : AdOutcome.capped;
    }
    final kid = ageBand() != AgeBand.over13;
    _showing = true;
    final AdNetworkResult result;
    try {
      result = await network.showRewarded(AdRequest(
        placementId: placementId,
        childDirected: kid,
        // No consent flow exists yet, so 13+ stays non-personalized too (D-014).
        nonPersonalized: true,
      ));
    } finally {
      _showing = false;
      _endedAt = clock.effectiveNow;
    }
    switch (result) {
      case AdNetworkResult.completed:
        _rollIfNewDay();
        _used[placementId] = (_used[placementId] ?? 0) + 1;
        _total++;
        return AdOutcome.rewarded;
      case AdNetworkResult.skipped:
        return AdOutcome.skipped;
      case AdNetworkResult.failed:
        return AdOutcome.failed;
    }
  }

  AdDailyState snapshot() {
    _rollIfNewDay();
    return AdDailyState(
        dateKey: _dateKey, used: Map.unmodifiable(_used), total: _total);
  }

  /// Loads saved counters; an older date key than the clock's is dropped.
  void restore(AdDailyState s) {
    _dateKey = s.dateKey;
    _used
      ..clear()
      ..addAll(s.used);
    _total = s.total;
    _rollIfNewDay();
  }
}
