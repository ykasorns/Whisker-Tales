/// How a hatch is paid for (GDD v0.4 §6.2).
enum HatchSource { egg, ad, fish }

enum PetRarity { common, rare, legend }

class HatchResult {
  const HatchResult({
    required this.petId,
    required this.rarity,
    required this.isNew,
    required this.stars,
    this.cookies = 0,
    this.wasPity = false,
  });

  final String petId;
  final PetRarity rarity;
  final bool isNew;

  /// Stars after this hatch (1–max).
  final int stars;

  /// Treats given instead of a star when the pet was already at max stars.
  final int cookies;

  /// The legend guarantee fired.
  final bool wasPity;
}

/// Save v3 `pets` block (GAME_CONTRACT §4.6); `fish_pulls` lives in `daily`.
class PetsState {
  const PetsState({
    this.owned = const {},
    this.deployed = const [],
    this.pity = 0,
  });

  /// Pet id → stars.
  final Map<String, int> owned;
  final List<String> deployed;

  /// Hatches since the last legend.
  final int pity;

  Map<String, dynamic> toJson() => {
        'owned': {
          for (final e in owned.entries) e.key: {'stars': e.value, 'level': 1}
        },
        'deployed': deployed,
        'pity': pity,
      };

  factory PetsState.fromJson(Map<String, dynamic> j) {
    final owned = j['owned'], deployed = j['deployed'], pity = j['pity'];
    if (owned is! Map<String, dynamic> || deployed is! List || pity is! int) {
      throw const FormatException('pets: needs owned, deployed and pity');
    }
    return PetsState(
      owned: {
        for (final e in owned.entries)
          e.key: (e.value is Map && (e.value as Map)['stars'] is int)
              ? (e.value as Map)['stars'] as int
              : throw FormatException('pets: ${e.key}.stars must be an int'),
      },
      deployed: [
        for (final d in deployed)
          d is String
              ? d
              : throw const FormatException('pets: deployed must be ids'),
      ],
      pity: pity,
    );
  }
}

/// Pets and egg hatching. Owner: `pets` (T-038). GDD v0.4 §6.
abstract class IPets {
  /// Returns null when the source is unavailable (no eggs, ad quota or fish
  /// quota used up, ad not completed, not enough goldfish).
  Future<HatchResult?> hatch(HatchSource source);

  /// Goldfish price of the next fish hatch today (×1.5 per hatch).
  int get nextFishCost;

  /// Fish hatches left today (resets on DayRollover only).
  int get fishHatchesLeftToday;

  /// Rarity percentages shown before every hatch; same table as the roll.
  Map<PetRarity, double> get rates;

  void deploy(int slot, String petId);
}
