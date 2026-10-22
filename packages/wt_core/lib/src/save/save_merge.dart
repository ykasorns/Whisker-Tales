/// Which side of a merge was kept as the game.
enum MergeWinner { local, cloud }

/// Merges two Save v3 documents from two devices (GAME_CONTRACT §4.6,
/// T-023, D-025). The game itself comes whole from the side with more
/// progress — `idle.cleared_page`, then `profile.power`, then `updated_at`;
/// a full tie keeps [local]. A few fields take both sides into account so
/// switching devices can never earn or reset anything twice:
/// - `clock.max_seen_utc` and `clock.last_seen_utc`: the later of the two
///   (an offline window paid on one device is not paid again on the other);
/// - `daily`: the later `date_key`; on the same day the larger count of each
///   quota (ads per placement, ads in total, goldfish hatches);
/// - `entitlements`: what was bought on either device.
({Map<String, dynamic> doc, MergeWinner winner}) mergeSaves(
    Map<String, dynamic> local, Map<String, dynamic> cloud) {
  final winner =
      _compare(local, cloud) >= 0 ? MergeWinner.local : MergeWinner.cloud;
  final keep = winner == MergeWinner.local ? local : cloud;
  final doc = _copy(keep);

  final lc = _map(local['clock']), cc = _map(cloud['clock']);
  doc['clock'] = {
    ..._map(keep['clock']),
    for (final k in const ['last_seen_utc', 'max_seen_utc'])
      if (_later(lc[k], cc[k]) case final t?) k: t,
  };

  doc['daily'] = _mergeDaily(_map(local['daily']), _map(cloud['daily']));

  final le = _map(local['entitlements']), ce = _map(cloud['entitlements']);
  doc['entitlements'] = {
    ..._map(keep['entitlements']),
    'no_ads': le['no_ads'] == true || ce['no_ads'] == true,
    'skus': ({..._strings(le['skus']), ..._strings(ce['skus'])}.toList()
      ..sort()),
  };
  return (doc: doc, winner: winner);
}

/// > 0: [a] has more progress.
int _compare(Map<String, dynamic> a, Map<String, dynamic> b) {
  int page(Map<String, dynamic> d) => _int(_map(d['idle'])['cleared_page']);
  int power(Map<String, dynamic> d) => _int(_map(d['profile'])['power']);
  final byPage = page(a).compareTo(page(b));
  if (byPage != 0) return byPage;
  final byPower = power(a).compareTo(power(b));
  if (byPower != 0) return byPower;
  final ta = DateTime.tryParse('${a['updated_at']}');
  final tb = DateTime.tryParse('${b['updated_at']}');
  if (ta == null || tb == null) return ta == null ? (tb == null ? 0 : -1) : 1;
  return ta.compareTo(tb);
}

Map<String, dynamic> _mergeDaily(
    Map<String, dynamic> a, Map<String, dynamic> b) {
  final ka = '${a['date_key'] ?? ''}', kb = '${b['date_key'] ?? ''}';
  final byDay = ka.compareTo(kb);
  if (byDay > 0) return _copy(a);
  if (byDay < 0) return _copy(b);
  final ua = _map(a['ads_used']), ub = _map(b['ads_used']);
  return {
    ..._copy(a),
    'ads_used': {
      for (final k in {...ua.keys, ...ub.keys}) k: _max(ua[k], ub[k]),
    },
    'ads_total': _max(a['ads_total'], b['ads_total']),
    'fish_pulls': _max(a['fish_pulls'], b['fish_pulls']),
  };
}

String? _later(Object? a, Object? b) {
  final ta = DateTime.tryParse('$a'), tb = DateTime.tryParse('$b');
  if (ta == null) return tb == null ? null : '$b';
  if (tb == null) return '$a';
  return ta.isAfter(tb) ? '$a' : '$b';
}

int _int(Object? v) => v is int ? v : 0;
int _max(Object? a, Object? b) => _int(a) > _int(b) ? _int(a) : _int(b);

Map<String, dynamic> _map(Object? v) =>
    v is Map<String, dynamic> ? v : const {};

List<String> _strings(Object? v) =>
    v is List ? v.whereType<String>().toList() : const [];

/// Deep copy through plain JSON values.
Map<String, dynamic> _copy(Map<String, dynamic> m) =>
    {for (final e in m.entries) e.key: _copyValue(e.value)};

Object? _copyValue(Object? v) => switch (v) {
      Map<String, dynamic>() => _copy(v),
      List() => [for (final x in v) _copyValue(x)],
      _ => v,
    };
