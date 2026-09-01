import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/core/utils/money.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_card.dart';

import 'support/monthly_fixtures.dart';

/// The card is the whole screen for most managers: they scan it and act. These
/// tests pin what it must never get wrong — a past date sold as upcoming, a
/// time range whose ends have swapped, an amount that reads like a rounding
/// error, and a badge claiming a replacement the server never recorded.
void main() {
  Widget host(Widget child, {Size size = const Size(390, 844)}) {
    return ScreenUtilInit(
      designSize: size,
      builder: (_, __) => MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
  }

  MonthlySeriesGroup fourWeekSeries({double paid = 0}) =>
      MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30', paid: paid > 0 ? 66 : 0),
        occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-06', paid: paid > 66 ? 34 : 0),
        occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-13'),
        occurrence(id: 4, seriesId: 7, seq: 4, date: '2026-09-20'),
      ]).single;

  group('what the manager reads first', () {
    testWidgets('the booking is named, and the id is only a reference',
        (tester) async {
      await tester.pumpWidget(host(MonthlySeriesCard(
        group: fourWeekSeries(),
        now: DateTime(2026, 9, 1),
      )));
      await tester.pumpAndSettle();

      expect(find.text('حجز شهري'), findsOneWidget);
      expect(find.text('#7'), findsOneWidget);
      // The old card headlined "ID: 286" in 20pt.
      expect(find.textContaining('ID:'), findsNothing);
    });

    testWidgets('customer, pitch, and the four sessions as one booking',
        (tester) async {
      await tester.pumpWidget(host(MonthlySeriesCard(
        group: fourWeekSeries(),
        now: DateTime(2026, 9, 1),
      )));
      await tester.pumpAndSettle();

      expect(find.text('ayoubbelhaj'), findsOneWidget);
      expect(find.text('ملاعب الجدار'), findsOneWidget);
      expect(find.text('4 مواعيد'), findsOneWidget);
    });
  });

  group('the next session', () {
    testWidgets('is labelled upcoming and names its position', (tester) async {
      await tester.pumpWidget(host(MonthlySeriesCard(
        group: fourWeekSeries(),
        now: DateTime(2026, 9, 8),
      )));
      await tester.pumpAndSettle();

      expect(find.text('الموعد القادم'), findsOneWidget);
      expect(find.text('الموعد 3 من 4'), findsOneWidget);
      expect(find.textContaining('13 سبتمبر 2026'), findsOneWidget);
    });

    testWidgets('a finished series says «آخر موعد», never «الموعد القادم»',
        (tester) async {
      await tester.pumpWidget(host(MonthlySeriesCard(
        group: fourWeekSeries(),
        now: DateTime(2026, 10, 5),
      )));
      await tester.pumpAndSettle();

      expect(find.text('الموعد القادم'), findsNothing);
      expect(find.text('آخر موعد'), findsOneWidget);
      expect(find.textContaining('20 سبتمبر 2026'), findsOneWidget);
    });

    testWidgets('the date is formatted, never a raw backend datetime',
        (tester) async {
      await tester.pumpWidget(host(MonthlySeriesCard(
        group: fourWeekSeries(),
        now: DateTime(2026, 9, 1),
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('2026-09-06'), findsNothing);
      expect(find.textContaining('00:00:00'), findsNothing);
      expect(find.textContaining('2026-08-30 20:00'), findsNothing);
    });
  });

  group('the time range holds its order under Arabic', () {
    testWidgets('start comes before end, laid out as one LTR run',
        (tester) async {
      await tester.pumpWidget(host(MonthlySeriesCard(
        group: fourWeekSeries(),
        now: DateTime(2026, 9, 1),
      )));
      await tester.pumpAndSettle();

      final range = find.text(SlotTime.rangeText((20, 0), (21, 0)));
      expect(range, findsOneWidget);
      // Without the isolation this renders as «9:00 – 8:00» to the reader.
      expect(tester.widget<Text>(range).textDirection, TextDirection.ltr);
      expect(find.text('مساءً'), findsWidgets);
    });

    test('the range is isolated so its ends can never swap', () {
      // Latin digits either side of a bidi-neutral dash, inside an Arabic
      // paragraph: without the isolate a 5pm–6pm booking can render as
      // «6:00 – 5:00», which still looks like a plausible range.
      final range = SlotTime.rangeText((17, 0), (18, 0));

      expect(range.startsWith('\u2066'), isTrue);
      expect(range.endsWith('\u2069'), isTrue);
      // Start before end, in the string itself.
      expect(range.indexOf('5:00'), lessThan(range.indexOf('6:00')));
      expect(range, '\u20665:00 – 6:00\u2069');
    });

    testWidgets('the clock is read out of the DATETIME, not its date half',
        (tester) async {
      expect(SlotTime.clockOf('2026-08-30 20:00:00'), (20, 0));
      expect(SlotTime.clockOf('20:00:00'), (20, 0));
      expect(SlotTime.clockOf('2026-08-30T23:30:00'), (23, 30));
      // Unreadable input must not throw; the raw value is shown instead.
      expect(SlotTime.clockOf('لا يوجد'), isNull);
      expect(SlotTime.clockOf('99:99:99'), isNull);
      expect(SlotTime.clockOf(''), isNull);
    });
  });

  group('money', () {
    testWidgets('the three figures are labelled and formatted', (tester) async {
      final group = MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30', paid: 66),
        occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-06', paid: 34),
        occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-13'),
        occurrence(id: 4, seriesId: 7, seq: 4, date: '2026-09-20'),
      ]).single;

      await tester.pumpWidget(
          host(MonthlySeriesCard(group: group, now: DateTime(2026, 9, 1))));
      await tester.pumpAndSettle();

      expect(find.text('الإجمالي'), findsOneWidget);
      expect(find.text('تم استلام'), findsOneWidget);
      expect(find.text('المتبقي'), findsOneWidget);

      expect(find.text('264 د.ل'), findsOneWidget);
      expect(find.text('100 د.ل'), findsOneWidget);
      expect(find.text('164 د.ل'), findsOneWidget);
      // The old card printed «66.0».
      expect(find.textContaining('.0 '), findsNothing);
    });

    test('whole amounts drop decimals, real ones keep two', () {
      expect(formatMoney(66), '66 د.ل');
      expect(formatMoney(66.0), '66 د.ل');
      expect(formatMoney(66.5), '66.50 د.ل');
      expect(formatMoney(0), '0 د.ل');
      expect(formatMoney(817.4000000000001), '817.40 د.ل');
    });
  });

  group('status is said in words a manager uses', () {
    testWidgets('unpaid, partly paid and settled each get their own chip',
        (tester) async {
      for (final (paid, label) in [
        (0.0, 'غير مدفوع'),
        (34.0, 'مدفوع جزئيًا'),
        (66.0, 'خالص'),
      ]) {
        final group = MonthlySeriesGroup.from([
          occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-09-20', paid: paid),
        ]).single;

        await tester.pumpWidget(
            host(MonthlySeriesCard(group: group, now: DateTime(2026, 9, 1))));
        await tester.pumpAndSettle();

        expect(find.text(label), findsOneWidget, reason: 'paid $paid');
        // Internal enum names must never reach the screen.
        expect(find.textContaining('PartialPaid'), findsNothing);
      }
    });

    testWidgets('an active booking says مفعّل, a finished one منتهي',
        (tester) async {
      await tester.pumpWidget(host(MonthlySeriesCard(
        group: fourWeekSeries(),
        now: DateTime(2026, 9, 1),
      )));
      await tester.pumpAndSettle();
      expect(find.text('مفعّل'), findsOneWidget);

      final cancelled = MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-09-20', status: 3),
      ]).single;
      await tester.pumpWidget(
          host(MonthlySeriesCard(group: cancelled, now: DateTime(2026, 9, 1))));
      await tester.pumpAndSettle();
      expect(find.text('منتهي'), findsOneWidget);
    });
  });

  group('replacements are shown, and only when recorded', () {
    testWidgets('a flagged session carries the badge', (tester) async {
      final group = MonthlySeriesGroup.from([
        occurrence(
          id: 1,
          seriesId: 7,
          seq: 1,
          date: '2026-09-20',
          replacement: true,
          startTime: '2026-08-30 22:00:00',
          endTime: '2026-08-30 23:00:00',
        ),
      ]).single;

      await tester.pumpWidget(
          host(MonthlySeriesCard(group: group, now: DateTime(2026, 9, 1))));
      await tester.pumpAndSettle();

      expect(find.text('موعد بديل'), findsOneWidget);
      // Its own hour, not the series pattern.
      expect(find.text(SlotTime.rangeText((22, 0), (23, 0))), findsOneWidget);
    });

    testWidgets('a different hour alone earns no badge', (tester) async {
      final group = MonthlySeriesGroup.from([
        occurrence(
          id: 1,
          seriesId: 7,
          seq: 1,
          date: '2026-09-20',
          startTime: '2026-08-30 22:00:00',
          endTime: '2026-08-30 23:00:00',
        ),
      ]).single;

      await tester.pumpWidget(
          host(MonthlySeriesCard(group: group, now: DateTime(2026, 9, 1))));
      await tester.pumpAndSettle();

      expect(find.text('موعد بديل'), findsNothing);
    });
  });

  group('the primary action is not the destructive one', () {
    testWidgets('the green button views, it does not cancel', (tester) async {
      await tester.pumpWidget(host(MonthlySeriesCard(
        group: fourWeekSeries(),
        now: DateTime(2026, 9, 1),
      )));
      await tester.pumpAndSettle();

      expect(find.text('عرض التفاصيل'), findsOneWidget);
      // The old card's green CTA said this, and it ended the booking.
      expect(find.text('الغاء الحجز'), findsNothing);
      expect(find.text('إنهاء الحجز الشهري'), findsNothing);
    });
  });

  group('it lays out on real phones', () {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      testWidgets('no overflow at ${size.width.toInt()}px', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(host(
          MonthlySeriesCard(
            group: MonthlySeriesGroup.from([
              occurrence(
                id: 1,
                seriesId: 7,
                seq: 1,
                date: '2026-09-20',
                // A long Arabic name and a long pitch name together.
                customer: 'عبد الرحمن بن محمد الطرابلسي الشريف',
                branch: 'ملاعب الجدار الرياضية — الملعب السداسي رقم 1',
                replacement: true,
              ),
            ]).single,
            now: DateTime(2026, 9, 1),
          ),
          size: size,
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a Latin username and Arabic text sit together', (tester) async {
      await tester.pumpWidget(host(MonthlySeriesCard(
        group: MonthlySeriesGroup.from([
          occurrence(
            id: 1,
            seriesId: 7,
            seq: 1,
            date: '2026-09-20',
            customer: 'ayoubbelhaj',
          ),
        ]).single,
        now: DateTime(2026, 9, 1),
      )));
      await tester.pumpAndSettle();

      expect(find.text('ayoubbelhaj'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
