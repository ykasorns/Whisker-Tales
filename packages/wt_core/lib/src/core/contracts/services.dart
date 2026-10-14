import 'rewards.dart';

/// Permanent currencies, owl shop and feature unlocks (GDD v0.4 §10).
/// No API here may add yarn, eggs or goldfish from a purchase (D-002).
/// Owner: `meta_progression` (T-021).
abstract class IMetaProgression {
  int balance(Currency currency);
  bool canAfford(String unlockId);
  bool unlock(String unlockId);
}

/// Versioned local save (GAME_CONTRACT §4.6 Save v3). Owner: T-022.
abstract class ISaveService {
  Future<Map<String, dynamic>> load();
  Future<void> save(Map<String, dynamic> json);

  /// Upgrades [json] from [from] to [to]; every version bump ships a
  /// migration and a test.
  Map<String, dynamic> migrate(Map<String, dynamic> json, int from, int to);
}

/// BGM/SFX (GDD v0.3 §11). Owner: T-024.
abstract class IAudioService {
  Future<void> playBgm(String id);
  Future<void> playSfx(String id);
  void setBgmEnabled(bool enabled);
  void setSfxEnabled(bool enabled);
}

/// Store purchases (GDD v0.4 §10: cosmetics + Supporter Pack, D-003). Every call sits
/// behind [IParentalGate]. Owner: T-025.
abstract class IIapService {
  Future<bool> purchase(String sku);
  Future<void> restorePurchases();
  bool owns(String sku);
}

/// Challenge young children cannot pass, new every time (GDD v0.3 §12.2).
abstract class IParentalGate {
  Future<bool> challenge();
}
