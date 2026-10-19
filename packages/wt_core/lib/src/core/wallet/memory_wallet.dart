import '../contracts/rewards.dart';
import '../contracts/wallet.dart';

/// In-memory wallet for tests and the time before T-021.
class MemoryWallet implements IWallet {
  MemoryWallet([Map<Currency, int> start = const {}]) : _b = {...start};

  final Map<Currency, int> _b;

  @override
  int balance(Currency c) => _b[c] ?? 0;

  @override
  bool spend(Currency c, int amount) {
    if (amount < 0) throw ArgumentError.value(amount, 'amount');
    if (balance(c) < amount) return false;
    _b[c] = balance(c) - amount;
    return true;
  }

  @override
  void add(RewardBundle reward) {
    for (final e in reward.amounts.entries) {
      _b[e.key] = balance(e.key) + e.value;
    }
  }
}
