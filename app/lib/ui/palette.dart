import 'package:flutter/material.dart';

/// Colored-pencil storybook palette (ART_PROMPT_BIBLE; same as the web
/// prototype).
abstract final class Palette {
  static const ink = Color(0xFF33291F);
  static const inkSoft = Color(0xFF6B5D4E);
  static const paper = Color(0xFFFFFBF2);
  static const sheet = Color(0xFFF5EFE3);
  static const storyPaper = Color(0xFFF2E2C5);
  static const storyEdge = Color(0xFFB78755);
  static const parchment = Color(0xFFFFF2D2);
  static const parchmentDeep = Color(0xFFF3D79E);
  static const wood = Color(0xFF8A552D);
  static const woodDark = Color(0xFF57351F);
  static const mochi = Color(0xFFF6A83C);
  static const coral = Color(0xFFEE6352);
  static const sun = Color(0xFFF9D64E);
  static const lime = Color(0xFF8CC152);
  static const teal = Color(0xFF3FA7B8);
  static const plum = Color(0xFF7A5E8C);
  static const grades = [
    Color(0xFFB9AE9C),
    Color(0xFF8CC152),
    Color(0xFF3FA7B8),
    Color(0xFF7A5E8C),
    Color(0xFFF9D64E),
    Color(0xFFEE6352),
  ];
}

BorderRadius _paperCorners(double radius) => BorderRadius.only(
      topLeft: Radius.circular(radius * .58),
      topRight: Radius.circular(radius),
      bottomRight: Radius.circular(radius * .62),
      bottomLeft: Radius.circular(radius * .88),
    );

/// A tappable paper surface separated by colour and a soft shadow. The
/// [accent] colour appears as a tint and shadow; no edge is
/// drawn (D-045).
BoxDecoration inkBox(
    {Color fill = Palette.paper,
    double radius = 14,
    Color accent = Palette.ink,
    double elevation = 2.5}) {
  final top = Color.lerp(fill, Colors.white, 0.22)!;
  final bottom = Color.lerp(fill, accent, 0.16)!;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [top, fill, bottom],
      stops: const [0, 0.58, 1],
    ),
    borderRadius: _paperCorners(radius),
    boxShadow: [
      BoxShadow(
        color: accent.withValues(alpha: 0.22),
        blurRadius: 1.5 + elevation,
        offset: Offset(1, 2 + elevation * 0.55),
      ),
    ],
  );
}

/// Quiet paper shared by the home controls and the Cat collection pages.
class StorybookPaper extends StatelessWidget {
  const StorybookPaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Palette.storyPaper,
          image: DecorationImage(
            image: AssetImage('assets/game/ui/ui_storybook_paper.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: child,
      );
}

/// A painted 9-slice surface from the UI kit (D-069): the corners and edges
/// keep their size, only the middle stretches. [slice] is in source pixels,
/// [scale] sets how large the corners are drawn.
BoxDecoration _kitSlice(String name, Rect slice, double scale, {Color? tint}) =>
    BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/game/kit/$name.png'),
        scale: scale,
        centerSlice: slice,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
        colorFilter:
            tint == null ? null : ColorFilter.mode(tint, BlendMode.modulate),
      ),
    );

BoxDecoration _kitCard(Color tint, double radius) => radius <= 10
    ? _kitSlice('ui_panel_tile', const Rect.fromLTRB(32, 32, 96, 96), 4,
        tint: tint)
    : _kitSlice('ui_panel_card', const Rect.fromLTRB(56, 56, 200, 200), 4,
        tint: tint);

/// Painted paper panel. [fill] tints the cream paper (pink, mint, lilac …
/// as before); [accent] is no longer needed (the painted edge carries it) but
/// stays so callers keep compiling. Small [radius] picks the small tile.
BoxDecoration storybookCard({
  Color fill = Palette.parchment,
  Color accent = Palette.storyEdge,
  double radius = 14,
}) =>
    _kitCard(fill, radius);

/// The kit button whose colour is closest to [fill]: lime/teal → green,
/// sun/orange/cream-yellow → yellow, coral → coral, plum → purple, a muted or
/// pale colour → a painted paper tile (a quiet choice, not a loud action).
String? _kitButtonFor(Color fill) {
  final h = HSLColor.fromColor(fill);
  if (h.saturation < .22 || h.lightness > .93) return null;
  final deg = h.hue;
  if (deg >= 65 && deg < 200) return 'ui_btn_green';
  if (deg >= 255 && deg < 320) return 'ui_btn_purple';
  if (deg < 18 || deg >= 340) return 'ui_btn_coral';
  return 'ui_btn_yellow';
}

/// Painted action button face (D-069). Disabled buttons use the grey-beige
/// pill. Label colour is the caller's; faces are bright, so keep text dark.
BoxDecoration storybookButton({
  Color fill = Palette.sun,
  Color accent = Palette.coral,
  double radius = 12,
  bool enabled = true,
}) {
  if (!enabled) {
    return _kitSlice(
        'ui_btn_disabled', const Rect.fromLTRB(80, 70, 400, 90), 4);
  }
  final name = _kitButtonFor(fill);
  if (name == null) return _kitCard(fill, radius);
  return _kitSlice(name, const Rect.fromLTRB(80, 70, 400, 90), 4);
}

/// Painted on/off switch (D-069), 52×26 dp.
class KitSwitch extends StatelessWidget {
  const KitSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: value,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: SizedBox(
              width: 52,
              height: 26,
              child: Stack(children: [
                Positioned.fill(
                  child: Image.asset(
                      'assets/game/kit/ui_toggle_track_${value ? 'on' : 'off'}.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 140),
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset('assets/game/kit/ui_toggle_knob.png',
                        width: 22, height: 22),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

/// Compact pinned label used for currencies and small live counters.
class StoryTag extends StatelessWidget {
  const StoryTag({
    super.key,
    required this.child,
    this.color = Palette.parchment,
    this.accent = Palette.storyEdge,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final Widget child;
  final Color color;
  final Color accent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: storybookCard(fill: color, accent: accent, radius: 8),
        child: child,
      );
}

/// Indeterminate "loading" indicator: the painted yarn ball, turning.
class KitSpinner extends StatefulWidget {
  const KitSpinner({super.key, this.size = 48});
  final double size;
  @override
  State<KitSpinner> createState() => _KitSpinnerState();
}

class _KitSpinnerState extends State<KitSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _c,
        child: Image.asset('assets/game/kit/ui_spinner_yarn.png',
            width: widget.size, height: widget.size),
      );
}

/// A painted progress bar: track 16 dp, fill 12 dp (art is drawn at 4x, so
/// nothing is scaled vertically; only the middle stretches sideways).
class KitBar extends StatelessWidget {
  const KitBar({super.key, required this.value, this.fill = 'teal'});

  final double value;

  /// `green`, `teal`, `coral` or `sun`.
  final String fill;

  static BoxDecoration _strip(String name, double w) => BoxDecoration(
      image: DecorationImage(
          image: AssetImage('assets/game/kit/$name.png'),
          scale: 4,
          centerSlice: Rect.fromLTRB(w, 4, 480 - w, 5),
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium));

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return SizedBox(
      height: 16,
      child: LayoutBuilder(builder: (_, c) {
        // a fill narrower than its two round ends would squash them
        final w = c.maxWidth * v;
        return Stack(children: [
          Positioned.fill(child: DecoratedBox(decoration: _strip('ui_bar_track', 32))),
          if (w >= 12)
            Positioned(
                left: 2,
                top: 2,
                width: (c.maxWidth - 4) * v,
                height: 12,
                child: DecoratedBox(
                    decoration: _strip('ui_bar_fill_$fill', 24))),
        ]);
      }),
    );
  }
}

/// Pop-up panel (welcome back, confirmations): honey rim, flat cream paper.
BoxDecoration kitDialogDecoration() => _kitSlice(
    'ui_panel_dialog', const Rect.fromLTRB(88, 88, 296, 296), 4);

/// A painted gear/wardrobe cell, drawn at its own size. [state]: `empty`,
/// `filled`, `locked` or `selected`; [grade] (0–5) lays a coloured rim.
class KitSlot extends StatelessWidget {
  const KitSlot({super.key, required this.state, this.grade, this.child});
  final String state;
  final int? grade;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset('assets/game/kit/ui_slot_$state.png',
            fit: BoxFit.fill, filterQuality: FilterQuality.medium),
        if (child != null) Padding(padding: const EdgeInsets.all(5), child: child),
        if (grade != null)
          Image.asset('assets/game/kit/ui_rim_g${grade!.clamp(0, 5)}.png',
              fit: BoxFit.fill, filterQuality: FilterQuality.medium),
      ]);
}
