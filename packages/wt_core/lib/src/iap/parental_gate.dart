import 'dart:math' as math;

import '../core/clock/game_clock.dart';

/// A grown-up question: [a] × [b] written in words, never digits, so a
/// child who cannot read long number words yet cannot pass (GDD v0.4 §14).
class GateQuestion {
  const GateQuestion(this.a, this.b);
  final int a, b;
  int get answer => a * b;

  /// "ยี่สิบเจ็ด คูณ หก" / "twenty-seven times six".
  String words(String lang) => lang == 'en'
      ? '${englishNumber(a)} times ${englishNumber(b)}'
      : '${thaiNumber(a)} คูณ ${thaiNumber(b)}';
}

/// Proof that a grown-up just answered the gate. Only [ParentalGate] makes
/// one, and it runs out after [ParentalGate.passFor].
class GatePass {
  GatePass._(this.gate, this.expiresUtc);
  final ParentalGate gate;
  final DateTime expiresUtc;
}

/// Parental gate (T-025, D-023): every opening asks a new question; a wrong
/// answer gives no pass and the next try is a new question (no guessing the
/// same one). Purchases and restore need a live [GatePass].
class ParentalGate {
  ParentalGate({
    required this.clock,
    int Function(int max)? random,
    this.passFor = const Duration(minutes: 10),
  }) : _random = random ?? math.Random.secure().nextInt;

  final GameClock clock;
  final int Function(int max) _random;

  /// Long enough for the store's own payment screens.
  final Duration passFor;

  /// a in 13…49 (no multiples of 10), b in 3…9.
  GateQuestion next() {
    var a = 0;
    while (a % 10 == 0) {
      a = 13 + _random(37);
    }
    return GateQuestion(a, 3 + _random(7));
  }

  /// A pass when [value] is right, else null.
  GatePass? answer(GateQuestion q, int? value) => value == q.answer
      ? GatePass._(this, clock.effectiveNow.add(passFor))
      : null;

  /// [pass] came from this gate and has not run out.
  bool isValid(GatePass? pass) =>
      pass != null &&
      identical(pass.gate, this) &&
      clock.effectiveNow.isBefore(pass.expiresUtc);
}

const _thaiDigits = [
  'ศูนย์',
  'หนึ่ง',
  'สอง',
  'สาม',
  'สี่',
  'ห้า',
  'หก',
  'เจ็ด',
  'แปด',
  'เก้า'
];

/// Thai words for 0…999: 21 = ยี่สิบเอ็ด, 11 = สิบเอ็ด, 120 = หนึ่งร้อยยี่สิบ.
String thaiNumber(int n) {
  if (n < 0 || n > 999) throw RangeError.range(n, 0, 999, 'n');
  if (n == 0) return _thaiDigits[0];
  final h = n ~/ 100, t = n ~/ 10 % 10, u = n % 10;
  final b = StringBuffer();
  if (h > 0) b.write('${_thaiDigits[h]}ร้อย');
  if (t == 1) {
    b.write('สิบ');
  } else if (t == 2) {
    b.write('ยี่สิบ');
  } else if (t > 2) {
    b.write('${_thaiDigits[t]}สิบ');
  }
  if (u == 1 && (t > 0 || h > 0)) {
    b.write('เอ็ด');
  } else if (u > 0) {
    b.write(_thaiDigits[u]);
  }
  return b.toString();
}

const _enOnes = [
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', //
  'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen',
  'sixteen', 'seventeen', 'eighteen', 'nineteen'
];
const _enTens = [
  '', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', //
  'eighty', 'ninety'
];

/// English words for 0…999: 47 = forty-seven, 305 = three hundred five.
String englishNumber(int n) {
  if (n < 0 || n > 999) throw RangeError.range(n, 0, 999, 'n');
  if (n < 20) return _enOnes[n];
  if (n < 100) {
    final u = n % 10;
    return u == 0 ? _enTens[n ~/ 10] : '${_enTens[n ~/ 10]}-${_enOnes[u]}';
  }
  final rest = n % 100;
  final h = '${_enOnes[n ~/ 100]} hundred';
  return rest == 0 ? h : '$h ${englishNumber(rest)}';
}
