import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/monthly_booking_cubit/monthly_booking_cubit.dart';

import 'support/monthly_fixtures.dart';

/// `getMonthlyBookingList` ignores its `page` parameter and returns every row
/// on every call. The screen used to drive a paged controller against it, so a
/// venue with ten or more sessions requested "page 2", got the same rows back
/// and appended them to the list it already had.
class _Repo implements MonthlyBookingRepo {
  _Repo(this.rows);

  final List<MonthlyBookingResponse> rows;
  int listCalls = 0;
  int? cancelledSeries;
  Failure? failure;

  @override
  Future<Either<Failure, List<MonthlyBookingResponse>>> listMonthlyBooking(
      int page) async {
    listCalls++;
    if (failure != null) return Left(failure!);
    // The server's actual behaviour: the same rows whatever the page.
    return Right(rows);
  }

  @override
  Future<Either<Failure, String>> updateMonthlyBooking({
    required String serviceDate,
    required String id,
  }) async =>
      const Right('Success');

  @override
  Future<Either<Failure, String>> cancelSeries({required int seriesId}) async {
    cancelledSeries = seriesId;
    return const Right('تم إنهاء الحجز الشهري.');
  }

  Map<String, dynamic>? lastReschedule;

  @override
  Future<Either<Failure, String>> rescheduleOccurrence({
    required int bookingId,
    required int branchId,
    required int customerId,
    required int employeeId,
    required int serviceId,
    required int paymentTypeId,
    required int status,
    required double paidAmount,
    required String serviceDate,
    required String serviceTime,
    String? remarks,
  }) async {
    lastReschedule = {
      'booking_id': bookingId,
      'service_date': serviceDate,
      'service_time': serviceTime,
      'paid_amount': paidAmount,
      'cmn_customer_id': customerId,
      'status': status,
    };
    return const Right('تم تعديل الموعد.');
  }
}

void main() {
  List<MonthlyBookingResponse> twoSeries() => [
        occurrence(id: 4, seriesId: 100002, seq: 4, date: '2026-09-20'),
        occurrence(id: 3, seriesId: 100002, seq: 3, date: '2026-09-13'),
        occurrence(id: 2, seriesId: 100002, seq: 2, date: '2026-09-06'),
        occurrence(id: 1, seriesId: 100002, seq: 1, date: '2026-08-30'),
        occurrence(
          id: 8,
          seriesId: 100001,
          seq: 1,
          date: '2026-09-20',
          customer: 'مبروك',
          paid: 66,
          status: 3,
        ),
      ];

  test('the list is fetched once, not once per page', () async {
    final repo = _Repo(twoSeries());
    final cubit = MonthlyBookingCubit(bookingRepo: repo);

    await cubit.load();

    expect(repo.listCalls, 1);
    final state = cubit.state as MonthlyBookingLoaded;
    // Five sessions, two bookings — and no session counted twice.
    expect(state.groups, hasLength(2));
    expect(
      state.groups.fold<int>(0, (n, g) => n + g.totalCount),
      5,
    );
  });

  test('searching matches the whole list, by name, pitch, phone or number',
      () async {
    final cubit = MonthlyBookingCubit(bookingRepo: _Repo(twoSeries()));
    await cubit.load();

    cubit.search('مبروك');
    expect((cubit.state as MonthlyBookingLoaded).groups, hasLength(1));

    cubit.search('ayoub');
    expect((cubit.state as MonthlyBookingLoaded).groups, hasLength(1));

    cubit.search('100002');
    expect((cubit.state as MonthlyBookingLoaded).groups.single.reference,
        100002);

    cubit.search('الجدار');
    expect((cubit.state as MonthlyBookingLoaded).groups, hasLength(2));

    cubit.search('  ');
    expect((cubit.state as MonthlyBookingLoaded).groups, hasLength(2));
  });

  test('filters answer the three questions a manager asks', () async {
    final cubit = MonthlyBookingCubit(bookingRepo: _Repo(twoSeries()));
    await cubit.load();

    cubit.filterBy(SeriesFilter.active);
    expect((cubit.state as MonthlyBookingLoaded).groups, hasLength(1));

    cubit.filterBy(SeriesFilter.ended);
    final ended = (cubit.state as MonthlyBookingLoaded).groups;
    expect(ended, hasLength(1));
    expect(ended.single.isActive, isFalse);

    cubit.filterBy(SeriesFilter.owing);
    expect((cubit.state as MonthlyBookingLoaded).groups.single.remainingAmount,
        greaterThan(0));

    cubit.filterBy(SeriesFilter.all);
    expect((cubit.state as MonthlyBookingLoaded).groups, hasLength(2));
  });

  test('an empty result is told apart from an empty filter', () async {
    final cubit = MonthlyBookingCubit(bookingRepo: _Repo(twoSeries()));
    await cubit.load();

    expect((cubit.state as MonthlyBookingLoaded).isFiltered, isFalse);

    cubit.search('لا أحد بهذا الاسم');
    final state = cubit.state as MonthlyBookingLoaded;
    expect(state.groups, isEmpty);
    expect(state.isFiltered, isTrue);
    // The venue does still have monthly bookings; only the search matched none.
    expect(state.total, 2);
  });

  test('a failed load surfaces the message and can be retried', () async {
    final repo = _Repo([])..failure = Failure(errMessage: 'لا يوجد اتصال');
    final cubit = MonthlyBookingCubit(bookingRepo: repo);

    await cubit.load();
    expect((cubit.state as MonthlyBookingError).message, 'لا يوجد اتصال');

    repo.failure = null;
    repo.rows.addAll(twoSeries());
    await cubit.refresh();
    expect(cubit.state, isA<MonthlyBookingLoaded>());
  });

  test('ending a series calls the series endpoint with the series id',
      () async {
    final repo = _Repo(twoSeries());
    final cubit = MonthlyBookingCubit(bookingRepo: repo);
    await cubit.load();

    final group = (cubit.state as MonthlyBookingLoaded)
        .groups
        .firstWhere((g) => g.seriesId == 100002);
    await cubit.bookingRepo.cancelSeries(seriesId: group.seriesId);

    // Not a booking_info id, and not one call per session.
    expect(repo.cancelledSeries, 100002);
  });

  test('rescheduling targets one session and replays everything else',
      () async {
    final repo = _Repo(twoSeries());
    final cubit = MonthlyBookingCubit(bookingRepo: repo);
    await cubit.load();

    final group = (cubit.state as MonthlyBookingLoaded)
        .groups
        .firstWhere((g) => g.seriesId == 100002);
    final session = group.occurrences[1];

    await cubit.bookingRepo.rescheduleOccurrence(
      bookingId: session.bookingId,
      branchId: session.branchId,
      customerId: session.customerId,
      employeeId: session.employeeId,
      serviceId: session.serviceId,
      paymentTypeId: session.paymentTypeId,
      status: session.bookingStatus,
      paidAmount: session.paidAmount,
      serviceDate: '2026-09-13',
      serviceTime: '21:00-22:00',
    );

    // One session's booking row — never the series, never the booking_info.
    expect(repo.lastReschedule!['booking_id'], session.bookingId);
    expect(repo.lastReschedule!['booking_id'], isNot(100002));
    // Customer, status and money go back exactly as they came.
    expect(repo.lastReschedule!['cmn_customer_id'], session.customerId);
    expect(repo.lastReschedule!['status'], session.bookingStatus);
    expect(repo.lastReschedule!['paid_amount'], session.paidAmount);
  });
}
