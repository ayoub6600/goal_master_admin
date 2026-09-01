import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';

abstract class MonthlyBookingRepo {
  Future<Either<Failure, List<MonthlyBookingResponse>>> listMonthlyBooking(
    int page,
  );
  Future<Either<Failure, String>> updateMonthlyBooking({
    required String serviceDate,
    required String id,
  });

  /// Calls off the remaining sessions of one recurring booking.
  ///
  /// Wiring only: `manager-series-cancel` already existed on the server and
  /// routes through BookingSeriesService, the same authority the customer's
  /// own cancellation uses. Nothing about refunds or series status is decided
  /// on the device.
  Future<Either<Failure, String>> cancelSeries({required int seriesId});

  /// Moves ONE session to a new slot.
  ///
  /// Wiring only. `update-booking` is the manager's existing booking editor
  /// and owns availability, pricing and payment state; this passes the
  /// session's own values back unchanged for everything except the slot, so
  /// moving the time cannot become a change to anything else.
  ///
  /// A refused slot comes back as a Failure carrying the server's reason —
  /// nothing is written in that case.
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
  });
}
