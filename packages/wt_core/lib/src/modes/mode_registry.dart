import '../core/contracts/game_mode.dart';

/// Holds the registered run-based modes (MODE_PLUGIN_SPEC §2, §4). The
/// adventure menu is built from [modes]; core never names a mode.
class ModeRegistry implements IModeRegistry {
  final Map<String, GameMode> _byId = {};

  /// Throws [StateError] when [mode] reuses an id: ids are save namespaces.
  @override
  void register(GameMode mode) {
    if (mode.id != mode.manifest.id) {
      throw StateError(
          'mode "${mode.id}": manifest id is "${mode.manifest.id}"');
    }
    if (_byId.containsKey(mode.id)) {
      throw StateError('mode "${mode.id}" is already registered');
    }
    _byId[mode.id] = mode;
  }

  @override
  List<GameMode> get modes {
    final all = _byId.values.toList()
      ..sort((a, b) {
        final byOrder = a.manifest.order.compareTo(b.manifest.order);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
    return List.unmodifiable(all);
  }

  /// Modes the menu may show: `enabled: false` ones stay dormant (§4).
  List<GameMode> get enabledModes =>
      List.unmodifiable(modes.where((m) => m.manifest.enabled));

  @override
  GameMode? byId(String id) => _byId[id];
}

/// What an [UnlockRule] is checked against.
class ModeUnlockContext {
  const ModeUnlockContext({
    this.flags = const {},
    this.fishTotal = 0,
    this.bossCleared = _never,
  });

  /// `profile.flags` of the save.
  final Set<String> flags;

  /// Goldfish the player holds.
  final int fishTotal;

  /// True once the boss with this id has been beaten in the main loop.
  final bool Function(String bossId) bossCleared;

  static bool _never(String _) => false;
}

/// True when [rule] is met; a mode without a rule is always open.
bool isModeUnlocked(UnlockRule? rule, ModeUnlockContext ctx) {
  if (rule == null) return true;
  return switch (rule.type) {
    UnlockType.flag => ctx.flags.contains(rule.value),
    UnlockType.fishTotal => ctx.fishTotal >= (rule.value as num).toInt(),
    UnlockType.bossCleared => ctx.bossCleared(rule.value as String),
  };
}

/// The `modes.<id>` part of the save (MODE_PLUGIN_SPEC §5). Core never reads
/// a mode's data: it keeps the JSON as it was until the mode asks for its
/// state, and keeps the JSON of modes that are not registered (a mode that
/// was switched off must not lose its progress). Order of load and register
/// does not matter.
class ModeSaves {
  ModeSaves(this._registry);

  final IModeRegistry _registry;
  final Map<String, Map<String, dynamic>> _raw = {};
  final Map<String, ModeSaveState> _decoded = {};

  /// Replaces everything with the saved `modes` section.
  void restore(Object? json) {
    _raw.clear();
    _decoded.clear();
    if (json is! Map) return;
    for (final e in json.entries) {
      if (e.key is String && e.value is Map<String, dynamic>) {
        _raw[e.key as String] = e.value as Map<String, dynamic>;
      }
    }
  }

  /// The mode's state. A save the mode cannot read starts that mode fresh
  /// and never touches the other modes or the main game.
  ModeSaveState stateOf(GameMode mode) {
    final cached = _decoded[mode.id];
    if (cached != null) return cached;
    ModeSaveState state;
    try {
      state = mode.decodeSave(_raw[mode.id] ?? const {});
    } on Object {
      state = mode.decodeSave(const {});
    }
    return _decoded[mode.id] = state;
  }

  void update(GameMode mode, ModeSaveState state) {
    _decoded[mode.id] = state;
  }

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{..._raw};
    for (final e in _decoded.entries) {
      final mode = _registry.byId(e.key);
      if (mode != null) out[e.key] = mode.encodeSave(e.value);
    }
    return out;
  }
}
