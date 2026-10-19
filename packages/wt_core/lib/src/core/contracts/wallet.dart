import 'rewards.dart';

/// Player currencies (GDD v0.4 §10). The real owner is `meta_progression`
/// (T-021); until then [MemoryWallet] holds them.
abstract class IWallet {
  int balance(Currency c);

  /// Takes [amount] if there is enough; returns false and changes nothing
  /// otherwise.
  bool spend(Currency c, int amount);
  void add(RewardBundle reward);
}
