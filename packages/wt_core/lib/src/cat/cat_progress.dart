import 'dart:async';

import '../core/contracts/cat_class.dart';
import 'cat_rules.dart';

/// Cat level + EXP (GDD v0.5 §3.1).
class CatProgress implements ICatProgress {
  CatProgress(this.rules);

  final CatRules rules;
  final _levelUps = StreamController<CatLevelUp>.broadcast(sync: true);
  int _level = 1;
  int _exp = 0;

  @override
  int get level => _level;

  @override
  int get exp => _exp;

  @override
  int get expToNext => rules.expToNext(_level);

  @override
  Stream<CatLevelUp> get levelUps => _levelUps.stream;

  /// No level cap; one call may raise several levels.
  @override
  int gainExp(int amount) {
    if (amount < 0) throw ArgumentError.value(amount, 'amount', 'must be >= 0');
    final from = _level;
    var exp = _exp + amount;
    while (exp >= rules.expToNext(_level)) {
      exp -= rules.expToNext(_level);
      _level++;
    }
    _exp = exp;
    if (_level > from) _levelUps.add(CatLevelUp(from: from, to: _level));
    return _level - from;
  }

  /// Loads the save's level and EXP; throws [FormatException] if invalid.
  void restore(CatState s) {
    if (s.level < 1) {
      throw FormatException('cat: level ${s.level} out of range');
    }
    if (s.exp < 0 || s.exp >= rules.expToNext(s.level)) {
      throw FormatException('cat: exp ${s.exp} invalid at level ${s.level}');
    }
    _level = s.level;
    _exp = s.exp;
  }

  Future<void> dispose() => _levelUps.close();
}
