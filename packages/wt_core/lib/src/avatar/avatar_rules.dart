/// `design/art/mochi_sprites.json` (D-024): the frames every class sheet
/// has, the classes with an outfit, and where the feet sit.
/// A shot that flies from a class to its target on a normal attack
/// (the archer's arrow, D-038). Sizes are in scene heights.
class ProjectileSpec {
  const ProjectileSpec({
    required this.icon,
    required this.flightMs,
    required this.muzzleX,
    required this.muzzleY,
    required this.length,
  });
  final String icon;
  final int flightMs;
  final double muzzleX, muzzleY, length;
}

class AvatarRules {
  const AvatarRules({
    required this.frames,
    required this.classes,
    required this.groundPadPx,
    this.projectiles = const {},
  });

  /// Class id → its projectile; classes without one hit up close.
  final Map<String, ProjectileSpec> projectiles;

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
    final classes = ids('classes');
    final shots = <String, ProjectileSpec>{};
    final raw = json['projectiles'];
    if (raw is Map<String, dynamic>) {
      for (final e in raw.entries) {
        final m = e.value;
        if (!classes.contains(e.key) || m is! Map<String, dynamic>) {
          throw bad('projectiles.${e.key}: unknown class or not an object');
        }
        num n(String k) {
          final v = m[k];
          if (v is! num) throw bad('projectiles.${e.key}.$k must be a number');
          return v;
        }

        final icon = m['icon'];
        if (icon is! String || n('flight_ms') <= 0 || n('length') <= 0) {
          throw bad(
              'projectiles.${e.key}: needs icon, flight_ms > 0, length > 0');
        }
        shots[e.key] = ProjectileSpec(
            icon: icon,
            flightMs: n('flight_ms').toInt(),
            muzzleX: n('muzzle_x').toDouble(),
            muzzleY: n('muzzle_y').toDouble(),
            length: n('length').toDouble());
      }
    }
    return AvatarRules(
        frames: frames,
        classes: classes,
        groundPadPx: pad.toDouble(),
        projectiles: Map.unmodifiable(shots));
  }
}
