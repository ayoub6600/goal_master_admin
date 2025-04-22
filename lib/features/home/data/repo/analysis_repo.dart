import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/home/data/model/booking_slots_response.dart';

abstract class AnalysisRepo {
  //Future<Either<Failure, Analysis>> getAnalysis();
  Future<Either<Failure, BookingSlotsResponse>> filterBooking(
    String bookingStart,
    String bookingEnd,
    String branch,
    String startTime,
    String endTime,
    String categoryId,
    int page,
  );
}
