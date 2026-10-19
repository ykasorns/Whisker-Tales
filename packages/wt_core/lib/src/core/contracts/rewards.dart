/// Shared reward vocabulary for every module and game mode
/// (MODE_PLUGIN_SPEC §10, GDD v0.4 §10). None of these can be bought with
/// real money (D-002, D-003).
enum Currency { goldfish, yarn, eggs, cookies }

/// An immutable bag of currency amounts.
class RewardBundle {
  RewardBundle([Map<Currency, int> amounts = const {}])
      : amounts = Map.unmodifiable({
          for (final e in amounts.entries)
            if (e.value != 0) e.key: e.value,
        });

  static final empty = RewardBundle();

  /// Const empty bundle for const contexts.
  static const emptyConst = RewardBundle._const();

  const RewardBundle._const() : amounts = const {};

  final Map<Currency, int> amounts;

  int operator [](Currency c) => amounts[c] ?? 0;

  bool get isEmpty => amounts.isEmpty;

  RewardBundle operator +(RewardBundle other) => RewardBundle({
        for (final c in Currency.values) c: this[c] + other[c],
      });

  @override
  bool operator ==(Object other) =>
      other is RewardBundle &&
      Currency.values.every((c) => this[c] == other[c]);

  @override
  int get hashCode => Object.hashAll(Currency.values.map((c) => this[c]));

  @override
  String toString() => 'RewardBundle($amounts)';
}
