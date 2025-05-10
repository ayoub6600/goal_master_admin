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
}
