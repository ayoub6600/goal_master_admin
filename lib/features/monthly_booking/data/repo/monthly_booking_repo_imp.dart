import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo.dart';

class MonthlyBookingRepoImp extends MonthlyBookingRepo {
  final ApiConsumer consumer;

  MonthlyBookingRepoImp(this.consumer);

  @override
  Future<Either<Failure, List<MonthlyBookingResponse>>> listMonthlyBooking(
    int page,
  ) {
    return consumer.handleRequest(
      () => consumer.get(EndPoints.listMonthlyBooking(page)),
      (data) => (data['data'] as List)
          .map((e) => MonthlyBookingResponse.fromJson(e))
          .toList(),
    );
  }

  @override
  Future<Either<Failure, String>> updateMonthlyBooking(
      {required String serviceDate, required String id}) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.updateMonthlyBooking,
        isFormData: false,
        data: {'service_date': serviceDate, 'id': id},
      ),
      (data) {
        return data["message"];
      },
    );
  }
}
