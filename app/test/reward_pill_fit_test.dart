import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/ui/palette.dart';

/// "+101.3K" once vanished from the welcome-back pill: the label wrapped to a
/// second line that the single-line pill clipped. A label in a `FitLine` must
/// shrink instead, whatever its length.
void main() {
  Future<Size> labelSize(WidgetTester t, Widget label) async {
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 130, height: 50, child: label)),
    ));
    return t.getSize(find.byType(Text));
  }

  const style = TextStyle(fontSize: 17, fontWeight: FontWeight.w900);
  const long = '🐟 +101.3K  more';

  testWidgets('without FitLine a long label overflows its pill', (t) async {
    final s = await labelSize(t, const Text(long, style: style));
    expect(s.height, greaterThan(30)); // the bug: it wraps to a 2nd line
  });

  testWidgets('FitLine keeps a long label inside the pill', (t) async {
    await t.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
          child: SizedBox(
              width: 130, height: 50, child: FitLine(child: Text(long, style: style)))),
    ));
    final box = t.getRect(find.byType(FitLine));
    final text = t.getRect(find.byType(Text));
    expect(text.height, lessThan(30)); // still one line
    expect(text.right, lessThanOrEqualTo(box.right + .5));
    expect(text.left, greaterThanOrEqualTo(box.left - .5));
  });
}
