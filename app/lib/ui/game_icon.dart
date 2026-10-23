import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Emoji → game art (D-037). The map is `design/art/icons.json`; files are
/// `assets/game/icon/<id>.png`. A text with a mapped emoji shows the painted
/// icon instead; anything unmapped, or any file that is missing, stays the
/// plain emoji, so the game never shows a hole.
class IconRegistry {
  IconRegistry._();

  static Map<String, String> _emoji = const {};
  static Set<String> _skills = const {}, _events = const {};
  static Set<String> _classes = const {};
  static RegExp? _re;

  /// Reads `icons.json` from the bundle. Called at boot; until then (and in
  /// tests that skip it) every emoji stays text.
  static Future<void> load([AssetBundle? bundle]) async {
    final src = await (bundle ?? rootBundle)
        .loadString('assets/content/design/art/icons.json');
    setFromJson(jsonDecode(src) as Map<String, dynamic>);
  }

  static void setFromJson(Map<String, dynamic> j) {
    String plain(String e) => e.replaceAll('️', '');
    _emoji = {
      for (final e in (j['emoji'] as Map<String, dynamic>).entries)
        plain(e.key): e.value as String,
    };
    _skills = {...(j['skills'] as List).cast<String>()};
    _events = {...(j['events'] as List).cast<String>()};
    _classes = {...((j['classes'] as List?) ?? const []).cast<String>()};
    final keys = _emoji.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    _re = keys.isEmpty
        ? null
        : RegExp('(${keys.map(RegExp.escape).join('|')})️?');
  }

  static void reset() {
    _emoji = const {};
    _skills = _events = _classes = const {};
    _re = null;
  }

  /// File id for [emoji] (with or without the variation selector).
  static String? idOf(String emoji) => _emoji[emoji.replaceAll('️', '')];

  /// Art for a skill / road event by its own id, else the data's emoji.
  static String? skillArt(String id) => _skills.contains(id) ? id : null;
  static String? eventArt(String id) => _events.contains(id) ? 'ev_$id' : null;

  /// The class emblem, or null when the class has none yet.
  static String? classArt(String id) =>
      _classes.contains(id) ? 'class_$id' : null;
}

/// One painted icon, [size] square. [name] is a file id (`fish`) or an
/// emoji; [fallback] (default: the emoji / name) shows if the file is missing.
class GameIcon extends StatelessWidget {
  const GameIcon(this.name, {super.key, this.size = 20, this.fallback});

  final String name;
  final double size;
  final String? fallback;

  /// Skill art by id; the data's [emoji] when it has no art of its own.
  factory GameIcon.skill(String id, String emoji, {double size = 28}) =>
      GameIcon(IconRegistry.skillArt(id) ?? emoji, size: size, fallback: emoji);

  /// The class's round emblem (nothing at all while it has none).
  static Widget classEmblem(String id, {double size = 24}) {
    final art = IconRegistry.classArt(id);
    return art == null ? const SizedBox.shrink() : GameIcon(art, size: size);
  }

  factory GameIcon.event(String id, String emoji, {double size = 20}) =>
      GameIcon(IconRegistry.eventArt(id) ?? emoji, size: size, fallback: emoji);

  @override
  Widget build(BuildContext context) {
    final id = IconRegistry.idOf(name) ?? name;
    final text = fallback ?? name;
    final isFile = RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id);
    if (!isFile || IconRegistry._re == null) {
      return SizedBox(
          width: size,
          height: size,
          child:
              FittedBox(child: Text(text, style: TextStyle(fontSize: size))));
    }
    return Image.asset(
      'assets/game/icon/$id.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => SizedBox(
          width: size,
          height: size,
          child:
              FittedBox(child: Text(text, style: TextStyle(fontSize: size)))),
    );
  }
}

/// `Text` that draws mapped emoji as game icons, sized to the font (D-037).
/// Without a mapped emoji it is exactly a `Text`.
class IconText extends StatelessWidget {
  const IconText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final re = IconRegistry._re;
    if (re == null || !re.hasMatch(data)) {
      return Text(data,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          softWrap: softWrap);
    }
    final base = DefaultTextStyle.of(context).style.merge(style);
    final size = (base.fontSize ?? 14) * 1.3;
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in re.allMatches(data)) {
      if (m.start > at) spans.add(TextSpan(text: data.substring(at, m.start)));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GameIcon(m.group(1)!, size: size),
      ));
      at = m.end;
    }
    if (at < data.length) spans.add(TextSpan(text: data.substring(at)));
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
