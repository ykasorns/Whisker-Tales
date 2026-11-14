import 'package:flutter/material.dart';

import 'kit_specs.g.dart';

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

/// A painted stretch surface from the UI kit (D-069): the corners and edges
/// keep their size, only the middle stretches. Sizes and slices come from
/// `kit_specs.g.dart` (measured by `tools/sync_sprites.py`); Flutter wants
/// the slice in logical units, i.e. picture pixels / [scale]. A box must be
/// at least as large as the piece's fixed borders.
BoxDecoration kitDecoration(String name, {Color? tint, double scale = 4}) {
  final k = kitSpecs[name]!;
  return BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/game/kit/$name.png'),
      scale: scale,
      centerSlice: Rect.fromLTRB(
          k.left / scale, k.top / scale, k.right / scale, k.bottom / scale),
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      colorFilter:
          tint == null ? null : ColorFilter.mode(tint, BlendMode.modulate),
    ),
  );
}

// A see-through tint would make the whole painted panel see-through
// (modulate multiplies alpha too), so it is flattened onto white first.
BoxDecoration _kitCard(Color tint, double radius) =>
    kitDecoration(radius <= 10 ? 'ui_panel_tile' : 'ui_panel_card',
        tint: Color.alphaBlend(tint, Colors.white));

/// Shrinks its one-line child until it fits the width it is given, instead
/// of letting the end of a label wrap out of sight ("+101.5K", "Runs left
/// today: 3"). Never enlarges.
class FitLine extends StatelessWidget {
  const FitLine(
      {super.key, required this.child, this.alignment = Alignment.center});
  final Widget child;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

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
    return kitDecoration('ui_btn_disabled');
  }
  final name = _kitButtonFor(fill);
  if (name == null) return _kitCard(fill, radius);
  return kitDecoration(name);
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

/// A painted progress bar, 15 dp tall (the art at 4×, never scaled up or
/// down; only the middle stretches sideways).
class KitBar extends StatelessWidget {
  const KitBar({super.key, required this.value, this.fill = 'teal'});

  final double value;

  /// `green`, `teal`, `coral` or `sun`.
  final String fill;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final track = kitSpecs['ui_bar_track']!;
    final bar = kitSpecs['ui_bar_fill_$fill']!;
    final h = track.h / 4, fh = bar.h / 4, pad = (h - fh) / 2;
    // narrower than its two round ends, a fill cannot be drawn
    final least = (bar.left + bar.w - bar.right) / 4 + 1;
    return SizedBox(
      height: h,
      child: LayoutBuilder(builder: (_, c) {
        final w = (c.maxWidth - 2 * pad) * v;
        return Stack(children: [
          Positioned.fill(
              child: DecoratedBox(decoration: kitDecoration('ui_bar_track'))),
          if (v > 0)
            Positioned(
                left: pad,
                top: pad,
                width: w < least ? least : w,
                height: fh,
                child: DecoratedBox(
                    decoration: kitDecoration('ui_bar_fill_$fill'))),
        ]);
      }),
    );
  }
}

/// Pop-up panel (welcome back, confirmations): honey rim, flat cream paper.
BoxDecoration kitDialogDecoration() => kitDecoration('ui_panel_dialog');

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
        if (child != null)
          Padding(padding: const EdgeInsets.all(7), child: child),
        if (grade != null)
          Image.asset('assets/game/kit/ui_rim_g${grade!.clamp(0, 5)}.png',
              fit: BoxFit.fill, filterQuality: FilterQuality.medium),
      ]);
}

/// A short message at the bottom of the screen on the painted toast plate
/// (instead of Material's black bar).
SnackBar kitToast(Widget content,
        {Duration duration = const Duration(seconds: 4)}) =>
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: kitDecoration('ui_toast_plate'),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
              color: Palette.ink, fontSize: 14, fontWeight: FontWeight.w800),
          child: content,
        ),
      ),
    );

/// The painted bottom sheet: cream paper with a honey rim and a grabber.
/// Use with `showModalBottomSheet(backgroundColor: Colors.transparent)`.
class KitSheet extends StatelessWidget {
  const KitSheet({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: kitDecoration('ui_panel_sheet'),
        padding: const EdgeInsets.only(top: 9),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/game/kit/ui_sheet_grabber.png',
              width: 44, filterQuality: FilterQuality.medium),
          Flexible(child: child),
        ]),
      );
}

/// A yes/no question on the painted dialog panel. Returns true on [confirm].
Future<bool?> showKitConfirm(
  BuildContext context, {
  required Widget title,
  Widget? body,
  required Widget cancel,
  required Widget confirm,
}) =>
    showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Container(
          decoration: kitDialogDecoration(),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Palette.ink),
              child: title,
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              DefaultTextStyle.merge(
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Palette.inkSoft),
                child: body,
              ),
            ],
            const SizedBox(height: 16),
            Row(children: [
              for (final (i, w) in [cancel, confirm].indexed) ...[
                if (i == 1) const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    key: Key(i == 1 ? 'kit-confirm' : 'kit-cancel'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(ctx, i == 1),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: i == 1
                          ? storybookButton(fill: Palette.sun)
                          : storybookCard(fill: Palette.paper, radius: 8),
                      child: FitLine(
                        child: DefaultTextStyle.merge(
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: i == 1 ? Palette.ink : Palette.inkSoft),
                          child: w,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );

/// A row of painted stitches, as wide as it is given (tiles sideways).
class KitDivider extends StatelessWidget {
  const KitDivider({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/game/kit/ui_divider_stitch.png'),
              scale: 4,
              repeat: ImageRepeat.repeatX,
              alignment: Alignment.center,
              fit: BoxFit.none,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      );
}
