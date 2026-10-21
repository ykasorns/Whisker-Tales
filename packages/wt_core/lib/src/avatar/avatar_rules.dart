/// `design/art/mochi_sprites.json` (D-024): the frames every class sheet
/// has, the classes with an outfit, and where the feet sit.
class AvatarRules {
  const AvatarRules({
    required this.frames,
    required this.classes,
    required this.groundPadPx,
  });

  /// Frame names, e.g. `idle`, `walk_f2`, `attack`.
  final List<String> frames;

  /// Class ids that have (or will have) an outfit sheet.
  final List<String> classes;

  /// Feet sit this many frame pixels above the bottom of each image.
  final double groundPadPx;

  factory AvatarRules.fromJson(Map<String, dynamic> json) {
    FormatException bad(String w) => FormatException('mochi_sprites: $w');
    List<String> ids(String k) {
      final v = json[k];
      if (v is! List || v.isEmpty || v.any((e) => e is! String)) {
        throw bad('"$k" must be a list of names');
      }
      return List.unmodifiable(v.cast<String>());
    }

    final pad = json['ground_pad_px'];
    if (pad is! num || pad < 0) throw bad('ground_pad_px must be ≥ 0');
    final frames = ids('frames');
    for (final f in const ['idle', 'walk_f1', 'attack']) {
      if (!frames.contains(f)) throw bad('frames needs $f');
    }
    return AvatarRules(
        frames: frames, classes: ids('classes'), groundPadPx: pad.toDouble());
  }
}
