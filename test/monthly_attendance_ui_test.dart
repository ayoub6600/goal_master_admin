import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/attendance_actions_sheet.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_sheet.dart';

import 'support/monthly_fixtures.dart';

/// Four weeks, four possible endings — shown against the week each belongs to.
///
/// The result of a recurring booking is not one answer for the month. A
/// session played, a customer who did not turn up, a flooded pitch and a week
/// that has not happened yet can all be true of one monthly booking at once,
/// and the screen has to say which is which.
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

  testWidgets('each week carries its own result', (tester) async {
    final group = MonthlySeriesGroup.from([
      occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30', attendance: 'attended'),
      occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-06', attendance: 'no_show'),
      occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-13', attendance: 'venue_issue'),
      occurrence(id: 4, seriesId: 7, seq: 4, date: '2026-09-20'),
    ]).single;

    await tester.pumpWidget(host(
      MonthlySeriesSheet(group: group, now: DateTime(2026, 9, 16)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('تم اللعب'), findsOneWidget);
    expect(find.text('لم يحضر'), findsOneWidget);
    expect(find.text('مشكلة من الملعب'), findsOneWidget);
    // The fourth has not happened and claims nothing.
    expect(find.text('لم يُحدد'), findsNothing);
  });

  testWidgets('a finished week with no result is marked as awaiting one',
      (tester) async {
    final group = MonthlySeriesGroup.from([
      occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30', canReport: true),
      occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-20'),
    ]).single;

    await tester.pumpWidget(host(
      MonthlySeriesSheet(group: group, now: DateTime(2026, 9, 1)),
    ));
    await tester.pumpAndSettle();

    // Exactly one — the future week is not asking for a result.
    expect(find.text('بانتظار النتيجة'), findsOneWidget);
  });

  testWidgets('a replacement week awaiting a result keeps its date readable',
      (tester) async {
    // Two badges plus a date on one row truncated the date to
    // «الإثنين 24 أغسط…» — losing the one field a manager scans for. They
    // wrap now instead of competing for the line.
    final group = MonthlySeriesGroup.from([
      occurrence(
        id: 1,
        seriesId: 7,
        seq: 1,
        date: '2026-08-24',
        replacement: true,
        canReport: true,
        startTime: '2026-08-24 22:00:00',
        endTime: '2026-08-24 23:00:00',
      ),
    ]).single;

    await tester.pumpWidget(host(
      MonthlySeriesSheet(group: group, now: DateTime(2026, 9, 1)),
    ));
    await tester.pumpAndSettle();

    // Both facts are legible at once, and the date is not ellipsized.
    expect(find.text('موعد بديل'), findsOneWidget);
    expect(find.text('بانتظار النتيجة'), findsOneWidget);

    final dateText = find.text('الإثنين 24 أغسطس 2026');
    expect(dateText, findsOneWidget);
    expect(tester.widget<Text>(dateText).overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });

  testWidgets('it survives a narrow phone with both badges', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final group = MonthlySeriesGroup.from([
      occurrence(
        id: 1, seriesId: 7, seq: 1, date: '2026-08-24',
        replacement: true, attendance: 'venue_issue',
      ),
    ]).single;

    await tester.pumpWidget(host(
      MonthlySeriesSheet(group: group, now: DateTime(2026, 9, 1)),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('مشكلة من الملعب'), findsOneWidget);
  });

  testWidgets('the shared result sheet names the week it applies to',
      (tester) async {
    // The sheet is shared with the ordinary bookings screen, where it asks
    // about «هذا الحجز». Inside a monthly booking that reads as the whole
    // month, so the week is named and the rest ruled out.
    await tester.pumpWidget(host(
      const AttendanceActionsSheet(
        bookingId: 900001,
        scopeNote: 'هذا التقرير يخص موعد الإثنين 10 أغسطس 2026 فقط، ولن يؤثر '
            'على بقية مواعيد الحجز الشهري #7.',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('يخص موعد الإثنين 10 أغسطس 2026 فقط'),
        findsOneWidget);
    expect(find.textContaining('لن يؤثر على بقية مواعيد الحجز الشهري'),
        findsOneWidget);

    // Still the same three results, not a second flow.
    expect(find.textContaining('تم اللعب'), findsOneWidget);
    expect(find.textContaining('الزبون لم يحضر'), findsOneWidget);
    expect(find.textContaining('تعذّر اللعب بسبب الملعب'), findsOneWidget);
  });

  testWidgets('an ordinary booking gets no scope line', (tester) async {
    // Nothing changes for the bookings screen: one card, one booking, no
    // ambiguity to resolve.
    await tester.pumpWidget(host(
      const AttendanceActionsSheet(bookingId: 900001),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('بقية مواعيد الحجز الشهري'), findsNothing);
    expect(find.text('ما نتيجة هذا الحجز؟'), findsOneWidget);
  });

  test('eligibility is read from the server, never worked out on the device',
      () {
    // A week that has ended but which the server says is not reportable — an
    // already-settled one, say — must not be offered.
    final ended = occurrence(
      id: 1, seriesId: 7, seq: 1, date: '2026-08-30', canReport: false,
    );
    expect(ended.canReportAttendance, isFalse);

    final reportable = occurrence(
      id: 2, seriesId: 7, seq: 2, date: '2026-08-30', canReport: true,
    );
    expect(reportable.canReportAttendance, isTrue);

    // A recorded result replaces the action rather than sitting beside it.
    final done = occurrence(
      id: 3, seriesId: 7, seq: 3, date: '2026-08-30', attendance: 'attended',
    );
    expect(done.hasReportedResult, isTrue);
    expect(done.attendanceLabel, 'تم اللعب');
    expect(ended.hasReportedResult, isFalse);
  });

  test('an older server that sends nothing offers no action', () {
    // Withholding the button is a nuisance; offering it on a guess invites a
    // report the backend will refuse.
    final row = MonthlyBookingResponseFixture.withoutAttendanceFields();

    expect(row.canReportAttendance, isFalse);
    expect(row.hasReportedResult, isFalse);
  });
}
