/// How a hatch is paid for (GDD v0.4 §6.2).
enum HatchSource { egg, ad, fish }

enum PetRarity { common, rare, legend }

class HatchResult {
  const HatchResult({
    required this.petId,
    required this.rarity,
    required this.isNew,
    required this.stars,
  });

  final String petId;
  final PetRarity rarity;
  final bool isNew;
  final int stars;
}

/// Pets and egg hatching. Owner: `pets` (T-038). GDD v0.4 §6.
abstract class IPets {
  /// Returns null when the source is unavailable (no eggs, ad quota or fish
  /// quota used up, ad not completed).
  Future<HatchResult?> hatch(HatchSource source);

  /// Goldfish price of the next fish hatch today (×1.5 per hatch).
  int get nextFishCost;

  /// Fish hatches left today (resets on DayRollover only).
  int get fishHatchesLeftToday;

  /// Rarity percentages shown before every hatch; same table as the roll.
  Map<PetRarity, double> get rates;

  void deploy(int slot, String petId);
}
