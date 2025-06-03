import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/home/data/model/banner_model.dart';
import 'package:goal_master_admin/features/home/data/model/booking_slots_response.dart';
import 'package:goal_master_admin/features/home/data/model/dash_board_response.dart';
import 'package:goal_master_admin/features/home/data/repo/analysis_repo.dart';

class AnalysisRepoImp extends AnalysisRepo {
  final ApiConsumer consumer;
  AnalysisRepoImp(this.consumer);
  @override
  Future<Either<Failure, DashboardResponse>> getAnalysis() {
    return consumer.handleRequest(
      () => consumer.get(EndPoints.analysis),
      (data) => DashboardResponse.fromJson(data),
    );
  }

  @override
  Future<Either<Failure, BookingSlotsResponse>> filterBooking(
    String bookingStart,
    String bookingEnd,
    String branch,
    String startTime,
    String endTime,
    String categoryId,
    int page,
  ) {
    return consumer.handleRequest(
      () => consumer.post(EndPoints.fillterNewBooking(page), data: {
        if (branch?.isNotEmpty ?? false) 'branch': branch,
        if (startTime?.isNotEmpty ?? false) 'start_time': startTime,
        if (endTime?.isNotEmpty ?? false) 'end_time': endTime,
        'booking_start': bookingStart,
        'booking_end': bookingEnd,
        if (categoryId?.isNotEmpty ?? false) 'category_id': categoryId,
      }),
      (data) => BookingSlotsResponse.fromJson(data),
    );
  }

  @override
  Future<Either<Failure, List<Slide>>> getBanner() {
    return consumer.handleRequest(
      () => consumer.get(EndPoints.banner),
      (data) => SlideData.fromJson({'data': data["data"]}).data,
    );
  }
}
