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
      // The envelope is read as tolerantly as the rows are: a missing or
      // reshaped `data` key yields an empty list, not a thrown screen.
      (data) => MonthlyBookingListResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ).data,
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
      (data) => (data is Map ? data['msg'] : null)?.toString() ?? '',
    );
  }

  @override
  Future<Either<Failure, String>> cancelSeries({required int seriesId}) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.managerSeriesCancel,
        isFormData: false,
        data: {'series_id': seriesId},
      ),
      (data) => (data is Map ? (data['message'] ?? data['msg']) : null)
              ?.toString() ??
          'تم إنهاء الحجز الشهري.',
    );
  }

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
  }) {
    return consumer.handleRequest(
      () => consumer.post(
        EndPoints.updateBooking,
        isFormData: false,
        data: {
          'id': bookingId,
          'cmn_branch_id': branchId,
          'cmn_customer_id': customerId,
          'sch_employee_id': employeeId,
          'sch_service_id': serviceId,
          // Replayed unchanged: the manager is moving a time, not repricing a
          // booking or changing who it belongs to.
          'cmn_payment_type_id': paymentTypeId,
          'status': status.toString(),
          'paid_amount': paidAmount,
          'service_date': serviceDate,
          'service_time': serviceTime,
          // Never force past a genuinely taken slot.
          'isForceBooking': false,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        },
      ),
      // update-booking answers a refusal with 200 and status:'false', so the
      // refusal has to be read out of the body rather than the status code.
      (data) {
        final map = data is Map ? data : const {};
        if (map['status'].toString() == 'false') {
          throw RescheduleRefused(
            map['data']?.toString() ?? 'هذا الموعد غير متاح.',
          );
        }
        return 'تم تعديل الموعد.';
      },
    );
  }
}

/// The server declined the new slot. Nothing was written.
class RescheduleRefused implements Exception {
  RescheduleRefused(this.reason);

  final String reason;

  @override
  String toString() => reason;
}
