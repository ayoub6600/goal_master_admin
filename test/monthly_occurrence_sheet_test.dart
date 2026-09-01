import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';
import 'package:goal_master_admin/features/booking/data/model/cancel_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_actions.dart';
import 'package:oktoast/oktoast.dart';

import 'support/fake_booking_repo.dart';
import 'support/monthly_fixtures.dart';

/// The occurrence sheet reuses the manager's existing booking widgets, and
/// reusing a widget means inheriting what it expects around it.
///
/// The first version of this sheet shipped broken: `DepositBookingButton` is
/// itself a `BlocConsumer<BookingDepositCubit>`, so it needs that cubit ABOVE
/// it — the provider it creates internally only covers the sheet it opens. The
/// bookings screen supplies it from its route, this sheet did not, and the
/// analyzer cannot see a missing provider. Nothing caught it until a manager
/// tapped a session and got a red error box.
///
/// So these tests pump the real tree rather than checking types.
class _Repo extends FakeBookingRepo {
  _Repo({this.details});

  final BookingDetails? details;
  int? cancelledId;

  @override
  Future<Either<Failure, BookingDetails>> getBookingInfo(int id) async {
    if (details == null) {
      return Left(Failure(errMessage: 'not found'));
    }
    return Right(details!);
  }

  @override
  Future<Either<Failure, CancelBookingResponse>> cancelBooking(int id) async {
    cancelledId = id;
    return Right(CancelBookingResponse(status: true));
  }
}

/// A loaded booking, so `DepositBookingButton` actually renders.
///
/// This matters more than it looks: the button is only built on
/// BookingDetailsSuccess, so a test whose fake always fails never constructs
/// it — and therefore never notices that its cubit is missing. That is exactly
/// how the first version of this test suite passed against the broken sheet.
BookingDetails loadedBooking() => BookingDetails(
      id: 100003,
      cmnCustomerId: 58,
      branch: 'ملاعب الجدار',
      address: 'مصراتة',
      latitude: '0',
      longitude: '0',
      date: DateTime(2026, 9, 13),
      startTime: '20:00:00',
      endTime: '21:00:00',
      service: 'سداسي 1',
      serviceAmount: '66',
      paidAmount: '0',
      paymentStatus: 2,
      paymentName: 'غير مدفوع',
      paymentType: 'نقدي',
      status: 2,
      statusName: 'موافق عليه',
      category: 'كرة قدم',
    );

void main() {
  Widget host(Widget child) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => OKToast(
          child: MaterialApp(
            locale: const Locale('ar'),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: SingleChildScrollView(child: child)),
            ),
          ),
        ),
      );

  MonthlySeriesGroup series() => MonthlySeriesGroup.from([
        occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-08-30'),
        occurrence(id: 2, seriesId: 7, seq: 2, date: '2026-09-06'),
        occurrence(id: 3, seriesId: 7, seq: 3, date: '2026-09-13'),
        occurrence(id: 4, seriesId: 7, seq: 4, date: '2026-09-20'),
      ]).single;

  testWidgets('the sheet builds with the payment button actually rendered',
      (tester) async {
    // The regression this file exists for: DepositBookingButton is a
    // BlocConsumer<BookingDepositCubit> and needs that cubit above it. It is
    // only built once the booking details load, so the fake must SUCCEED —
    // a failing fake skips the button and hides the missing provider.
    final group = series();
    final repo = _Repo(details: loadedBooking());

    await tester.pumpWidget(host(buildOccurrenceActions(
      group: group,
      occurrence: group.occurrences[2],
      bookingRepo: repo,
      onChanged: () {},
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ايداع دفعة'), findsOneWidget);
    expect(find.text('إلغاء هذا الموعد فقط'), findsOneWidget);
  });

  testWidgets('the sheet builds when the details fail to load too',
      (tester) async {
    final group = series();
    final repo = _Repo();

    await tester.pumpWidget(host(buildOccurrenceActions(
      group: group,
      occurrence: group.occurrences[2],
      bookingRepo: repo,
      onChanged: () {},
    )));
    await tester.pumpAndSettle();

    // A missing provider throws ProviderNotFoundException while building.
    expect(tester.takeException(), isNull);
  });

  testWidgets('it states the scope before it offers any action',
      (tester) async {
    final group = series();

    await tester.pumpWidget(host(buildOccurrenceActions(
      group: group,
      occurrence: group.occurrences[2],
      bookingRepo: _Repo(),
      onChanged: () {},
    )));
    await tester.pumpAndSettle();

    // The banner and the action label both say it, which is the point.
    expect(find.textContaining('هذا الموعد فقط'), findsNWidgets(2));
    expect(find.textContaining('لن تتأثر بقية مواعيد الحجز الشهري #7'),
        findsOneWidget);
    expect(find.text('إلغاء هذا الموعد فقط'), findsOneWidget);
    // The series-wide wording must not appear on a single-session sheet.
    expect(find.text('إنهاء الحجز الشهري'), findsNothing);
  });

  testWidgets('a failed details load degrades instead of blocking the sheet',
      (tester) async {
    final group = series();

    await tester.pumpWidget(host(buildOccurrenceActions(
      group: group,
      occurrence: group.occurrences[2],
      bookingRepo: _Repo(),
      onChanged: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('تعذّر تحميل بيانات الدفع لهذا الموعد.'), findsOneWidget);
    // Cancelling does not depend on the payment details loading.
    expect(find.text('إلغاء هذا الموعد فقط'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling asks first, names the one date, and targets the '
      'session row', (tester) async {
    final group = series();
    final repo = _Repo();

    await tester.pumpWidget(host(buildOccurrenceActions(
      group: group,
      occurrence: group.occurrences[2],
      bookingRepo: repo,
      onChanged: () {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إلغاء هذا الموعد فقط'));
    await tester.pumpAndSettle();

    expect(find.textContaining('سيتم إلغاء موعد'), findsOneWidget);
    expect(find.textContaining('13 سبتمبر 2026'), findsOneWidget);
    expect(find.textContaining('لن تتأثر'), findsWidgets);
    // Still nothing sent.
    expect(repo.cancelledId, isNull);

    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();
    expect(repo.cancelledId, isNull);
  });

  testWidgets('confirming cancels that booking row, not the series id',
      (tester) async {
    final group = series();
    final repo = _Repo();

    await tester.pumpWidget(host(buildOccurrenceActions(
      group: group,
      occurrence: group.occurrences[2],
      bookingRepo: repo,
      onChanged: () {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إلغاء هذا الموعد فقط'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء الموعد'));
    await tester.pumpAndSettle();

    // The session's own sch_service_bookings id — never 7, the series.
    expect(repo.cancelledId, group.occurrences[2].bookingId);
    expect(repo.cancelledId, isNot(7));

    // Let the success toast expire so the tree disposes cleanly.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('an already-cancelled session offers no cancel action',
      (tester) async {
    final group = MonthlySeriesGroup.from([
      occurrence(id: 1, seriesId: 7, seq: 1, date: '2026-09-20', status: 3),
    ]).single;

    await tester.pumpWidget(host(buildOccurrenceActions(
      group: group,
      occurrence: group.occurrences.first,
      bookingRepo: _Repo(),
      onChanged: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('إلغاء هذا الموعد فقط'), findsNothing);
  });
}
