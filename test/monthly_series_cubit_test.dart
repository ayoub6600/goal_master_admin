import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/data/model/series_preview.dart';
import 'package:goal_master_admin/features/booking/domain/booking_occurrence.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/monthly_series_cubit/monthly_series_cubit.dart';

import 'support/fake_booking_repo.dart';

/// What the manager's switch actually does.
///
/// It used to set a flag. Now it loads the plan, and everything the manager
/// then does — moving a week, undoing it, switching back off — goes through
/// the same preview call, so the app never decides for itself which weeks are
/// free or what the total is.
void main() {
  final anchor = BookingOccurrence(
    startAt: DateTime(2026, 8, 30, 18),
    endAt: DateTime(2026, 8, 30, 19),
    employeeId: 11,
    price: 66,
  );

  late FakeBookingRepo repo;
  late MonthlySeriesCubit cubit;

  setUp(() {
    repo = FakeBookingRepo();
    cubit = MonthlySeriesCubit(repo);
  });

  Future<void> open() => cubit.open(
        branchId: 3,
        serviceId: 13,
        anchor: anchor,
        customerId: 42,
      );

  test('turning the switch on loads the plan', () async {
    repo.previewResult = Right(FakeBookingRepo.cleanPreview());

    await open();

    expect(cubit.state.enabled, isTrue);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.preview!.dates.length, 4);
    expect(repo.previewCalls, 1);
  });

  test('the preview anchors on the selected appointment, not the night', () async {
    repo.previewResult = Right(FakeBookingRepo.cleanPreview());

    await open();

    // 30 August, the appointment — even though it belongs to the operational
    // night of 29 August.
    expect(repo.lastPreviewArgs!['service_date'], '2026-08-30');
    expect(repo.lastPreviewArgs!['start_at'], '2026-08-30 18:00:00');
    expect(repo.lastPreviewArgs!['employee_id'], 11);
    // Per-customer caps only apply when the customer is known.
    expect(repo.lastPreviewArgs!['customer_id'], 42);
  });

  test('an all-available plan can be confirmed', () async {
    repo.previewResult = Right(FakeBookingRepo.cleanPreview());

    await open();

    expect(cubit.state.canConfirm, isTrue);
    expect(cubit.state.unresolvedCount, 0);
    expect(cubit.state.replacementPayload, isEmpty);
  });

  test('a taken week blocks confirmation', () async {
    repo.previewResult = Right(FakeBookingRepo.conflictPreview());

    await open();

    expect(cubit.state.canConfirm, isFalse);
    expect(cubit.state.unresolvedCount, 1);
  });

  test('choosing a replacement re-asks the server with the move applied', () async {
    repo.previewResult = Right(FakeBookingRepo.conflictPreview());
    await open();

    final blocked = cubit.state.preview!.unresolved.single;
    final option = blocked.replacementOptions!.sameDay.single;

    // The server's answer once the move is applied.
    repo.previewResult = Right(FakeBookingRepo.resolvedPreview());

    await cubit.chooseReplacement(blocked, option);

    expect(repo.previewCalls, 2);

    final sent = repo.lastPreviewArgs!['replacements'] as List;
    expect(sent.length, 1);
    expect(
      (sent.single as Map)['original_date'],
      '2026-09-06',
      reason: 'the move is keyed to the position it replaces',
    );

    expect(cubit.state.canConfirm, isTrue);
    expect(cubit.state.preview!.plannedOccurrences.length, 4);
  });

  test('the payload sent with the booking is the same set of moves', () async {
    repo.previewResult = Right(FakeBookingRepo.conflictPreview());
    await open();

    final blocked = cubit.state.preview!.unresolved.single;
    repo.previewResult = Right(FakeBookingRepo.resolvedPreview());
    await cubit.chooseReplacement(
        blocked, blocked.replacementOptions!.sameDay.single);

    expect(cubit.state.replacementPayload.length, 1);
    expect(cubit.state.replacementPayload.single['original_date'], '2026-09-06');
  });

  test('switching off drops the plan entirely', () async {
    repo.previewResult = Right(FakeBookingRepo.cleanPreview());
    await open();

    cubit.disable();

    expect(cubit.state.enabled, isFalse);
    expect(cubit.state.preview, isNull);
    expect(cubit.state.canConfirm, isFalse,
        reason: 'a switched-off plan must never be submitted');
  });

  test('a failed preview surfaces and blocks confirmation', () async {
    repo.previewResult = Left(Failure(errMessage: 'الشبكة غير متاحة'));

    await open();

    expect(cubit.state.error, 'الشبكة غير متاحة');
    expect(cubit.state.canConfirm, isFalse);
  });

  group('booking type', bookingTypeSwitching);

  test('confirmation is blocked while the plan is reloading', () async {
    repo.previewResult = Right(FakeBookingRepo.cleanPreview());
    await open();
    expect(cubit.state.canConfirm, isTrue);

    // Mid-reload the plan on screen is the previous one; confirming against it
    // could book a date the manager has already moved away from.
    repo.hold = true;
    final pending = cubit.reload();

    expect(cubit.state.isLoading, isTrue);
    expect(cubit.state.canConfirm, isFalse);

    repo.release();
    await pending;
  });
}

/// Switching between «حجز عادي» and «حجز شهري».
///
/// The type choice decides what the confirmation screen describes and what
/// gets submitted. Switching back to a single booking must leave nothing of
/// the plan behind — not the flag, not the moves the manager had chosen.
void bookingTypeSwitching() {
  final anchor = BookingOccurrence(
    startAt: DateTime(2026, 8, 30, 18),
    endAt: DateTime(2026, 8, 30, 19),
    employeeId: 11,
    price: 66,
  );

  late FakeBookingRepo repo;
  late MonthlySeriesCubit cubit;

  setUp(() {
    repo = FakeBookingRepo();
    cubit = MonthlySeriesCubit(repo);
  });

  Future<void> open() => cubit.open(
        branchId: 3,
        serviceId: 13,
        anchor: anchor,
        customerId: 42,
      );

  test('a single booking carries no plan and no moves', () {
    expect(cubit.state.enabled, isFalse);
    expect(cubit.state.preview, isNull);
    expect(cubit.state.replacementPayload, isEmpty);
  });

  test('switching to monthly loads a plan for the selected appointment', () async {
    repo.previewResult = Right(FakeBookingRepo.cleanPreview());

    await open();

    expect(cubit.state.enabled, isTrue);
    expect(cubit.state.preview!.plannedOccurrences.length, 4);
  });

  test('switching back to a single booking clears everything', () async {
    repo.previewResult = Right(FakeBookingRepo.conflictPreview());
    await open();

    // Resolve the clash, so there is something worth losing.
    final blocked = cubit.state.preview!.unresolved.single;
    repo.previewResult = Right(FakeBookingRepo.resolvedPreview());
    await cubit.chooseReplacement(
        blocked, blocked.replacementOptions!.sameDay.single);
    expect(cubit.state.replacementPayload, hasLength(1));

    cubit.disable();

    expect(cubit.state.enabled, isFalse);
    expect(cubit.state.preview, isNull);
    expect(
      cubit.state.replacementPayload,
      isEmpty,
      reason: 'a single booking must not carry a moved week in its payload',
    );
  });

  test('returning to monthly re-asks the server instead of reusing the plan',
      () async {
    repo.previewResult = Right(FakeBookingRepo.cleanPreview());
    await open();
    final callsAfterFirst = repo.previewCalls;

    cubit.disable();
    await open();

    expect(repo.previewCalls, greaterThan(callsAfterFirst),
        reason: 'availability may have changed while it was switched off');
    expect(cubit.state.replacementPayload, isEmpty,
        reason: 'the new plan starts without the previous plan\'s moves');
  });

  test('a stale plan is never shown while a new one loads', () async {
    repo.previewResult = Right(FakeBookingRepo.cleanPreview());
    await open();
    expect(cubit.state.preview, isNotNull);

    cubit.disable();
    repo.hold = true;
    final pending = open();

    // Mid-load: the previous plan is gone, not lingering on screen.
    expect(cubit.state.isLoading, isTrue);
    expect(cubit.state.preview, isNull);
    expect(cubit.state.canConfirm, isFalse);

    repo.release();
    await pending;
  });
}
