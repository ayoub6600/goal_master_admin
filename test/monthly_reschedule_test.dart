import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/booking/data/model/operational_slot.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/reschedule_occurrence_sheet.dart';

import 'support/monthly_fixtures.dart';

/// Moving one session of a recurring booking.
///
/// The scope is the whole risk here. A manager who thinks they are changing
/// next Sunday, and in fact changes every Sunday, has broken a customer's
/// month — so the sheet says which it is before it offers a control, and again
/// in the summary before anything is sent.
void main() {
  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          locale: const Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        ),
      );

  MonthlySeriesGroup series() => MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-09-06'),
        occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-13'),
        occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-20'),
        occurrence(id: 4, seriesId: 7, seq: 4, date: '2026-09-27'),
      ]).single;

  OperationalSlot slot(String date, int hour, {bool free = true}) =>
      OperationalSlot(
        employeeId: 1,
        date: date,
        startTime: '$hour:00:00',
        endTime: '${hour + 1}:00:00',
        startAt: DateTime.parse('$date ${hour.toString().padLeft(2, '0')}:00:00'),
        endAt: DateTime.parse(
            '$date ${(hour + 1).toString().padLeft(2, '0')}:00:00'),
        isAvailable: free,
        crossesMidnight: false,
      );

  Future<void> pump(
    WidgetTester tester, {
    required MonthlySeriesGroup group,
    required Future<String?> Function(DateTime, DateTime) onConfirm,
    List<OperationalSlot>? slots,
    Object? loadError,
  }) async {
    await tester.pumpWidget(host(RescheduleOccurrenceSheet(
      group: group,
      occurrence: group.occurrences[1], // 13 September, the second session
      now: DateTime(2026, 9, 8),
      loadSlots: (date) async {
        if (loadError != null) throw loadError;
        return slots ??
            [slot(date, 20), slot(date, 21), slot(date, 22, free: false)];
      },
      onConfirm: onConfirm,
    )));
    await tester.pumpAndSettle();
  }

  group('the scope is stated before anything can be changed', () {
    testWidgets('the banner names this session and what stays put',
        (tester) async {
      await pump(tester, group: series(), onConfirm: (_, __) async => null);

      expect(
        find.textContaining('أنت تعدّل هذا الموعد فقط'),
        findsOneWidget,
      );
      expect(
        find.textContaining('بقية مواعيد الحجز الشهري #7 لن تتغير'),
        findsOneWidget,
      );
    });

    testWidgets('it opens on the session own date, already selected',
        (tester) async {
      await pump(tester, group: series(), onConfirm: (_, __) async => null);

      // The session is on the 13th; the strip covers the 8th to the 20th, so
      // opening at the start would show nothing selected and hide the date
      // being edited.
      final chip = find.ancestor(
        of: find.text('13'),
        matching: find.byType(Container),
      );
      expect(chip, findsWidgets);

      // The slots loaded for the session's own date, not for the first day
      // of the range.
      expect(find.textContaining('13 سبتمبر 2026'), findsWidgets);
    });

    testWidgets('the current date, time and pitch are shown', (tester) async {
      await pump(tester, group: series(), onConfirm: (_, __) async => null);

      // Twice on purpose: the block at the top, and the chip that marks the
      // slot the session already occupies.
      expect(find.text('الموعد الحالي'), findsNWidgets(2));
      expect(find.textContaining('13 سبتمبر 2026'), findsWidgets);
      expect(find.textContaining('ملاعب الجدار'), findsOneWidget);
    });
  });

  group('choosing a new slot', () {
    testWidgets('only free slots are offered', (tester) async {
      await pump(tester, group: series(), onConfirm: (_, __) async => null);

      // 22:00 came back taken.
      expect(find.text('⁦10:00 – 11:00⁩'), findsNothing);
      expect(find.text('⁦9:00 – 10:00⁩'), findsOneWidget);
      // The session's own slot is listed too, marked as what it is.
      expect(find.text('⁦8:00 – 9:00⁩'), findsNWidgets(2));
    });

    testWidgets('nothing is sent until a slot is picked', (tester) async {
      var calls = 0;
      await pump(
        tester,
        group: series(),
        onConfirm: (_, __) async {
          calls++;
          return null;
        },
      );

      await tester.tap(find.text('تأكيد التعديل'));
      await tester.pumpAndSettle();

      expect(calls, 0);
      // No summary before a choice exists.
      expect(find.text('سيصبح'), findsNothing);
    });

    testWidgets('picking one shows the before and after, and the scope again',
        (tester) async {
      await pump(tester, group: series(), onConfirm: (_, __) async => null);

      await tester.tap(find.text('⁦9:00 – 10:00⁩'));
      await tester.pumpAndSettle();

      expect(find.text('سيصبح'), findsOneWidget);
      expect(
        find.text(
          'سيتم تعديل هذا الموعد فقط، ولن تتغير بقية مواعيد الحجز الشهري.',
        ),
        findsOneWidget,
      );
    });
  });

  group('picking the slot it already has is not a change', () {
    // The current slot is listed on purpose — leaving it out would make the
    // session's own time look unavailable. But choosing it must not be dressed
    // up as an edit.

    testWidgets('it is named in the list before it is tapped', (tester) async {
      await pump(tester, group: series(), onConfirm: (_, __) async => null);

      // The block at the top plus the chip label.
      expect(find.text('الموعد الحالي'), findsNWidgets(2));
    });

    testWidgets('no before-and-after summary is shown', (tester) async {
      await pump(tester, group: series(), onConfirm: (_, __) async => null);

      await tester.tap(find.text('⁦8:00 – 9:00⁩').last);
      await tester.pumpAndSettle();

      // «الموعد الحالي 8:00 – 9:00 ← سيصبح 8:00 – 9:00» is nonsense.
      expect(find.text('سيصبح'), findsNothing);
      expect(
        find.text('هذا هو الموعد الحالي بالفعل. اختر وقتًا أو تاريخًا آخر لتغييره.'),
        findsOneWidget,
      );
    });

    testWidgets('confirming is refused, and nothing is sent', (tester) async {
      var calls = 0;
      await pump(
        tester,
        group: series(),
        onConfirm: (_, __) async {
          calls++;
          return null;
        },
      );

      await tester.tap(find.text('⁦8:00 – 9:00⁩').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد التعديل'));
      await tester.pumpAndSettle();

      expect(calls, 0, reason: 'an edit that changes nothing was sent');
    });

    testWidgets('picking a different slot afterwards works normally',
        (tester) async {
      DateTime? sent;
      await pump(
        tester,
        group: series(),
        onConfirm: (start, __) async {
          sent = start;
          return null;
        },
      );

      await tester.tap(find.text('⁦8:00 – 9:00⁩').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('⁦9:00 – 10:00⁩'));
      await tester.pumpAndSettle();

      expect(find.text('سيصبح'), findsOneWidget);

      await tester.tap(find.text('تأكيد التعديل'));
      await tester.pumpAndSettle();

      expect(sent, DateTime(2026, 9, 13, 21));
    });
  });

  group('confirming', () {
    testWidgets('sends exactly the slot that was chosen', (tester) async {
      DateTime? sentStart;
      DateTime? sentEnd;

      await pump(
        tester,
        group: series(),
        onConfirm: (start, end) async {
          sentStart = start;
          sentEnd = end;
          return null;
        },
      );

      await tester.tap(find.text('⁦9:00 – 10:00⁩'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد التعديل'));
      await tester.pumpAndSettle();

      // The session's own date, at the picked hour — not the series pattern.
      expect(sentStart, DateTime(2026, 9, 13, 21));
      expect(sentEnd, DateTime(2026, 9, 13, 22));
    });

    testWidgets('a refusal keeps the sheet open and changes nothing',
        (tester) async {
      await pump(
        tester,
        group: series(),
        onConfirm: (_, __) async => 'هذا الوقت محجوز بالفعل.',
      );

      await tester.tap(find.text('⁦9:00 – 10:00⁩'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد التعديل'));
      await tester.pumpAndSettle();

      expect(find.text('هذا الوقت محجوز بالفعل.'), findsOneWidget);
      // Still on the sheet, with the choice intact.
      expect(find.text('تأكيد التعديل'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('degrading', () {
    testWidgets('a day with nothing free says so', (tester) async {
      await pump(
        tester,
        group: series(),
        slots: const [],
        onConfirm: (_, __) async => null,
      );

      expect(
        find.text('لا توجد مواعيد متاحة في هذا اليوم. جرّب تاريخًا آخر.'),
        findsOneWidget,
      );
    });

    testWidgets('a failed load offers a retry rather than an empty sheet',
        (tester) async {
      await pump(
        tester,
        group: series(),
        loadError: Exception('network'),
        onConfirm: (_, __) async => null,
      );

      expect(find.text('تعذّر تحميل المواعيد المتاحة.'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });

  testWidgets('it lays out on a small phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(tester, group: series(), onConfirm: (_, __) async => null);
    await tester.tap(find.text('⁦9:00 – 10:00⁩'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
