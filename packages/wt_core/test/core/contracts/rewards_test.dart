import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

void main() {
  test('missing currencies read as zero and zeros are dropped', () {
    final r = RewardBundle({Currency.goldfish: 5, Currency.yarn: 0});
    expect(r[Currency.goldfish], 5);
    expect(r[Currency.yarn], 0);
    expect(r.amounts.keys, [Currency.goldfish]);
    expect(RewardBundle.empty.isEmpty, isTrue);
  });

  test('bundles add per currency', () {
    final sum = RewardBundle({Currency.goldfish: 5, Currency.eggs: 1}) +
        RewardBundle({Currency.goldfish: 2, Currency.yarn: 3});
    expect(sum, RewardBundle({Currency.goldfish: 7, Currency.eggs: 1, Currency.yarn: 3}));
  });

  test('equality ignores zero entries', () {
    expect(RewardBundle({Currency.cookies: 0}), RewardBundle.empty);
    expect(RewardBundle({Currency.cookies: 0}).hashCode, RewardBundle.empty.hashCode);
  });

  test('amounts cannot be mutated', () {
    final r = RewardBundle({Currency.goldfish: 1});
    expect(() => r.amounts[Currency.goldfish] = 99, throwsUnsupportedError);
  });
}
