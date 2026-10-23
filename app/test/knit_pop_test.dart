import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/ui/home_page.dart';

/// 2026-10-23 phone test: a kept piece used to stay on screen for good.
void main() {
  for (final kept in [true, false]) {
    testWidgets(
        'knit pop ${kept ? "kept" : "recycled"} fades out and reports done',
        (tester) async {
      var done = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Center(
                  child: KnitPop(
                      art: 'gear/sword_1',
                      kept: kept,
                      onDone: () => done++)))));
      await tester.pump(const Duration(milliseconds: 500));
      expect(done, 0);
      double opacity() => tester
          .widget<Opacity>(find
              .descendant(
                  of: find.byType(KnitPop), matching: find.byType(Opacity))
              .first)
          .opacity;
      expect(opacity(), greaterThan(0.5)); // still visible mid-way
      await tester.pump(const Duration(milliseconds: 800));
      expect(done, 1);
      expect(opacity(), lessThan(0.01)); // nothing left behind
    });
  }
}
