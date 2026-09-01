import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/core/utils/money.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_card.dart';

/// Bidi is checked by measuring where the glyphs actually land, not by reading
/// a screenshot. In an Arabic paragraph the dash and spaces around a time range
/// are direction-neutral, so the two clock times can be laid out either way
/// round — and «6:00 – 5:00» is still a plausible-looking range, which is what
/// makes the failure dangerous rather than obvious.
double _leftEdgeOf(String needle, String full, TextDirection direction) {
  final painter = TextPainter(
    text: TextSpan(
      text: full,
      style: const TextStyle(fontSize: 14),
    ),
    textDirection: direction,
  )..layout();

  final start = full.indexOf(needle);
  expect(start, isNonNegative, reason: '"$needle" is not in "$full"');

  final boxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + needle.length),
  );
  expect(boxes, isNotEmpty);

  return boxes.map((b) => b.left).reduce((a, b) => a < b ? a : b);
}

void main() {
  group('a time range keeps its start on the left', () {
    test('inside an Arabic paragraph', () {
      final range = SlotTime.rangeText((17, 0), (18, 0));

      final startX = _leftEdgeOf('5:00', range, TextDirection.rtl);
      final endX = _leftEdgeOf('6:00', range, TextDirection.rtl);

      expect(
        startX,
        lessThan(endX),
        reason: 'a 5–6pm booking is being drawn as «6:00 – 5:00»',
      );
    });

    test('and inside a Latin one', () {
      final range = SlotTime.rangeText((17, 0), (18, 0));

      expect(
        _leftEdgeOf('5:00', range, TextDirection.ltr),
        lessThan(_leftEdgeOf('6:00', range, TextDirection.ltr)),
      );
    });

    test('for a late slot, where both ends are two digits', () {
      final range = SlotTime.rangeText((22, 0), (23, 0));

      expect(
        _leftEdgeOf('10:00', range, TextDirection.rtl),
        lessThan(_leftEdgeOf('11:00', range, TextDirection.rtl)),
      );
    });

    test('for a night that crosses midnight', () {
      final range = SlotTime.rangeText((23, 0), (0, 0));

      expect(
        _leftEdgeOf('11:00', range, TextDirection.rtl),
        lessThan(_leftEdgeOf('12:00', range, TextDirection.rtl)),
      );
    });

    test('the unisolated string is what would have gone wrong', () {
      // Proves the isolate is doing the work, not the font or the platform:
      // the same text without it reorders under RTL.
      const bare = '5:00 – 6:00';
      final isolated = SlotTime.rangeText((17, 0), (18, 0));

      expect(isolated.contains(bare), isTrue);
      expect(isolated.length, bare.length + 2);
      expect(isolated.codeUnitAt(0), 0x2066);
      expect(isolated.codeUnitAt(isolated.length - 1), 0x2069);
    });
  });

  group('an amount keeps its digits with its currency', () {
    test('the number is drawn to the left of «د.ل»', () {
      const amount = '264 د.ل';

      // Arabic script runs right to left, so the currency word sits to the
      // left of the digits. What must never happen is the digits splitting
      // away from the amount they belong to.
      final digitsX = _leftEdgeOf('264', amount, TextDirection.rtl);
      final currencyX = _leftEdgeOf('د.ل', amount, TextDirection.rtl);

      expect(currencyX, lessThan(digitsX));
    });

    test('a whole amount carries no decimals into the currency label', () {
      // Checked on the number alone: «د.ل» has a full stop of its own.
      for (final value in [66.0, 264.0, 0.0, 1000.0]) {
        expect(formatAmount(value), isNot(contains('.')));
        expect(formatMoney(value), endsWith(' د.ل'));
      }

      expect(formatAmount(66.5), '66.50');
      expect(formatMoney(66.5), '66.50 د.ل');
    });
  });
}
