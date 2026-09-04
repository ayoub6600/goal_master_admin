import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/features/booking/data/model/manager_customer.dart';
import 'package:goal_master_admin/features/booking/data/model/operational_slot.dart';
import 'package:goal_master_admin/features/booking/data/model/created_series.dart';
import 'package:goal_master_admin/features/booking/data/model/series_preview.dart';
import 'package:goal_master_admin/features/booking/data/model/cancellation_case.dart';
import 'package:goal_master_admin/features/booking/data/model/manager_series.dart';
import 'package:dio/dio.dart';
import 'package:goal_master_admin/core/errors/exceptions.dart';
import 'package:goal_master_admin/core/components/paginated_response.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/features/home/data/model/booking_drilldown_item.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_all_list_response.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';
import 'package:goal_master_admin/features/booking/data/model/cancel_booking_response.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/data/model/category_model.dart';
import 'package:goal_master_admin/features/booking/data/model/club_responce.dart';
import 'package:goal_master_admin/features/booking/data/model/employe/employe.dart';
import 'package:goal_master_admin/features/booking/data/model/location_reponse.dart';
import 'package:goal_master_admin/features/booking/data/model/service_model.dart';
import 'package:goal_master_admin/features/booking/data/model/timeslot.dart';

class BookingRepoImp extends BookingRepo {
  final ApiConsumer apiConsumer;

  BookingRepoImp(this.apiConsumer);

  @override
  Future<Either<Failure, PaginatedResponse<BookingItemResponce>>> getBooking(
    int page,
    String? startDate,
    String? endDate,
    String? branchId,
    String? employeeId,
    String? customerId,
    String? serviceStatus,
    String? bookingId,
  ) async {
    final queryParams = <String, dynamic>{
      'pageSize': 10,
      'page': page,
    };

    if (startDate != null && startDate.isNotEmpty) {
      queryParams['dateFrom'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['dateTo'] = endDate;
    }

    if (branchId != null && branchId.isNotEmpty) {
      queryParams['branchId'] = int.tryParse(branchId);
    }
    if (bookingId != null && bookingId.isNotEmpty) {
      queryParams['bookingId'] = int.tryParse(bookingId.toString());
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      queryParams['employeeId'] = int.tryParse(employeeId);
    }
    if (customerId != null && customerId.isNotEmpty) {
      queryParams['customerId'] = int.tryParse(customerId);
    }
    if (serviceStatus != null && serviceStatus.isNotEmpty) {
      queryParams['serviceStatus'] = int.tryParse(serviceStatus);
    }

    return apiConsumer.handleRequest(
      () => apiConsumer.get(
        EndPoints.bookingHistory(page),
        queryParameters: queryParams,
      ),
      (data) => PaginatedResponse<BookingItemResponce>.fromJson(
        data,
        BookingItemResponce.fromJson,
      ),
    );
  }

  @override
  Future<Either<Failure, CancelBookingResponse>> cancelBooking(int id) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.cancelBooking,
        data: {
          'id': id,
        },
      ),
      (data) => CancelBookingResponse.fromJson(data),
    );
  }

  @override
  Future<Either<Failure, List<Location>>> listZone() {
    return apiConsumer.handleRequest(
      () => apiConsumer.get(EndPoints.listZone),
      (data) {
        // تأكد من أن data['data'] هو عبارة عن List
        List<Location> locations = (data['data'] as List<dynamic>)
            .map((item) => Location.fromJson(item as Map<String, dynamic>))
            .toList();
        return locations;
      },
    );
  }

  @override
  Future<Either<Failure, List<ClubResponce>>> listClub(int zoneId) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.listClub,
        data: {
          'zone': zoneId,
        },
      ),
      (data) {
        print("data: ${data["id"]}");
        List<ClubResponce> clubs = (data['data'] as List<dynamic>)
            .map((item) => ClubResponce.fromJson(item as Map<String, dynamic>))
            .toList();
        return clubs;
      },
    );
  }

  @override
  Future<Either<Failure, List<CategoryModel>>> listCategory(
      {required int branchId}) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.listCategory,
        data: {
          'branch': branchId,
        },
      ),
      (data) {
        List<CategoryModel> categories = (data['data'] as List<dynamic>)
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
        return categories;
      },
    );
  }

  @override
  Future<Either<Failure, List<Service>>> listService(
      int categoryId, int branchId) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.listService,
        data: {
          'category': categoryId,
          'branch': branchId,
        },
      ),
      (data) {
        List<Service> services = (data['data'] as List<dynamic>)
            .map((item) => Service.fromJson(item as Map<String, dynamic>))
            .toList();
        return services;
      },
    );
  }

  @override
  Future<Either<Failure, List<Employee>>> listEmployee(
      {required int branchId}) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.listEmployee,
        data: {
          'branch': branchId,
        },
      ),
      (data) {
        List<Employee> employees = (data['data'] as List<dynamic>)
            .map((item) => Employee.fromJson(item as Map<String, dynamic>))
            .toList();
        return employees;
      },
    );
  }

  @override
  Future<Either<Failure, List<TimeslotModel>>> listTimeslot(
      {required int branchId,
      required int employeeId,
      required int serviceId,
      required String date}) {
    return apiConsumer.handleRequest(
        () => apiConsumer.post(
              EndPoints.listTimeslot,
              data: {
                'branch_id': branchId,
                'employee_id': employeeId,
                'service_id': serviceId,
                'date': date,
              },
            ), (data) {
      List<TimeslotModel> timeslots = (data['data'] as List<dynamic>)
          .map((item) => TimeslotModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return timeslots;
    });
  }

  /// One operational night, bands already merged by the server.
  ///
  /// Replaces the band-scoped `list/timeslot`, which needed an `employee_id`
  /// before it would answer and returned clocks with no calendar day attached.
  /// Note the absence of an employeeId parameter: the band is now something
  /// each slot carries back, not something the manager has to choose first.
  @override
  Future<Either<Failure, OperationalNight>> listNightSlots({
    required int branchId,
    required int serviceId,
    required String operationalDate,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.operationalAvailability,
        data: {
          'branch_id': branchId,
          'service_id': serviceId,
          'operational_date': operationalDate,
        },
      ),
      (data) =>
          OperationalNight.fromJson(data['data'] as Map<String, dynamic>),
    );
  }

  /// Whether the night already in progress is still worth offering.
  ///
  /// A manager at 00:30 on Sunday is operationally still inside Saturday's
  /// night. The server says so, and supplies the date; nothing here subtracts
  /// a day from the device clock.
  @override
  Future<Either<Failure, PreviousNightContext>> previousNightContext({
    required int branchId,
    required int serviceId,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.operationalNightContext,
        data: {
          'branch_id': branchId,
          'service_id': serviceId,
        },
      ),
      (data) => PreviousNightContext.fromJson(
        Map<String, dynamic>.from(
          data['data']?['previous_operational_night'] as Map? ?? const {},
        ),
      ),
    );
  }

  /// One page of the manager's own customer book.
  ///
  /// Alias-aware, searchable across alias, platform name and phone, and
  /// reachable before a customer's first booking — none of which the two
  /// endpoints this replaces could do together.
  @override
  Future<Either<Failure, ManagerCustomerPage>> managerCustomers({
    String? search,
    int page = 1,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.get(
        EndPoints.managerCustomers,
        queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      ),
      (data) => ManagerCustomerPage.fromJson(data as Map<String, dynamic>),
    );
  }

  /// The plan a recurring booking would create, with any moves the manager has
  /// already chosen applied.
  ///
  /// `customerId` matters: per-customer caps are only evaluated when a customer
  /// is known, so previewing without it would show a week as free that the
  /// booking itself then refuses.
  @override
  Future<Either<Failure, SeriesPreview>> previewSeries({
    required int branchId,
    required int employeeId,
    required int serviceId,
    required String date,
    required String startTime,
    required String endTime,
    String? startAt,
    String? endAt,
    int? customerId,
    bool strictPositions = false,
    List<Map<String, dynamic>> replacements = const [],
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.seriesPreview,
        data: {
          'branch_id': branchId,
          'employee_id': employeeId,
          'service_id': serviceId,
          'service_date': date,
          'start_time': startTime,
          'end_time': endTime,
          if (startAt != null && startAt.isNotEmpty) 'start_at': startAt,
          if (endAt != null && endAt.isNotEmpty) 'end_at': endAt,
          if (customerId != null && customerId > 0) 'customer_id': customerId,
          // Four agreed positions, a taken one resolved in place. Without this
          // the server drops the taken week and appends a fifth calendar week,
          // which is not a plan a venue can read out to a customer.
          if (strictPositions) 'strict_positions': 1,
          // Moves already chosen. Sent back so the preview describes the FINAL
          // schedule — the moved week in place, and no phantom extra week.
          if (replacements.isNotEmpty) 'replacements': replacements,
        },
        isFormData: false,
      ),
      (data) => SeriesPreview.fromJson(data['data'] as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, BookingCreated>> addBooking({
    required int branchId,
    required int employeeId,
    required int serviceId,
    required int paymentType,
    required String date,
    required String startTime,
    required String endTime,
    // The server's authoritative occurrence datetimes. Sent so the backend can
    // prove `service_date`/`start_time`/`end_time` describe the same moment it
    // offered, instead of trusting a bare calendar date.
    String? startAt,
    String? endAt,
    required String fullName,
    required String phone,
    required int isMonthly,
    required String state,
    String? paidAmount,
    String? status,
    String? review,
    int? customerId,
    String? approvedPlanSignature,
    List<Map<String, dynamic>> replacements = const [],
  }) async {
    // Handled outside handleRequest for a recurring booking: a series_conflict
    // refusal carries a list and an offered plan that the generic handler
    // would flatten into a single string, leaving the manager nothing to act
    // on. A normal booking keeps the shared path.
    try {
      final response = await apiConsumer.post(
        EndPoints.addBooking,
        data: {
          'branch_id': branchId,
          'employee_id': employeeId,
          'service_id': serviceId,
          'payment_type': paymentType,
          'service_date': date,
          'start_time': startTime,
          'end_time': endTime,
          if (startAt != null && startAt.isNotEmpty) 'start_at': startAt,
          if (endAt != null && endAt.isNotEmpty) 'end_at': endAt,
          'full_name': fullName,
          'phone_no': phone,
          'state': state,
          'is_monthly': isMonthly,
          'paid_amount': paidAmount ?? '',
          'status': status ?? '',
          'review': review ?? '',
          'customer_id': customerId,
          // Only present once the manager has approved a specific plan. The
          // signature pins it to the exact dates they were shown.
          if (approvedPlanSignature != null &&
              approvedPlanSignature.isNotEmpty) ...{
            'allow_skip': 1,
            'approved_plan_signature': approvedPlanSignature,
          },
          // Each entry MOVES one position of the series. The server
          // re-validates every one under lock, so a stale choice is refused
          // rather than booked, and the series length never grows.
          if (replacements.isNotEmpty) 'replacements': replacements,
          if (isMonthly == 1) 'strict_positions': 1,
        },
      );

      // The series the server actually created, kept rather than discarded.
      // The success screen used to be drawn from the request instead, which is
      // why a four-week booking reported one appointment's price as its total.
      final series = CreatedSeries.tryFrom(
        response['data'] is Map
            ? Map<String, dynamic>.from(response['data'] as Map)
            : null,
      );

      final html = response['html'];
      if (html != null && html is String && html.trim().isNotEmpty) {
        return right(BookingCreated(message: html, series: series));
      }

      final msg = response['msg'] ?? response['message'] ?? 'تم الحفظ بنجاح';
      return right(BookingCreated(
        message: '<div style="padding: 24px; font-size: 16px;">$msg</div>',
        series: series,
      ));
    } on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map<String, dynamic> &&
          (data['reason'] == 'series_conflict' ||
              data['reason'] == 'plan_changed')) {
        return left(_seriesConflict(data));
      }

      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['data'];
        if (message is String && message.isNotEmpty) {
          return left(Failure(errMessage: message));
        }
      }

      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      return left(ServerFailure(errMessage: e.toString()));
    }
  }

  /// Turns the backend's series refusal into something the manager can act on:
  /// which weeks clash, whether skipping them is on offer, and the signature
  /// that would approve it.
  SeriesConflictFailure _seriesConflict(Map<String, dynamic> data) {
    final plan = data['plan'];
    final planMap =
        plan is Map<String, dynamic> ? plan : const <String, dynamic>{};

    List<String> stringList(dynamic value) =>
        ((value as List?) ?? const []).map((e) => e.toString()).toList();

    return SeriesConflictFailure(
      errMessage:
          (data['message'] ?? data['data'] ?? 'تعذّر إنشاء الحجز الشهري')
              .toString(),
      conflicts: ((data['conflicts'] as List?) ?? const [])
          .map((e) => ConflictedDate(
                date: (e['date'] ?? '').toString(),
                startTime: (e['start_time'] ?? '').toString(),
                message: (e['message'] ?? '').toString(),
              ))
          .toList(),
      canSkipAndExtend: data['can_skip_and_extend'] == true,
      planSignature: (data['plan_signature'] ?? '').toString(),
      proposedDates: stringList(planMap['confirmed_dates']),
      skippedDates: stringList(planMap['skipped_dates']),
      targetOccurrenceCount: planMap['target_occurrence_count'] == null
          ? 4
          : int.tryParse(planMap['target_occurrence_count'].toString()) ?? 4,
      planChanged: data['reason'] == 'plan_changed',
    );
  }

  @override
  Future<Either<Failure, BookingDetails>> getBookingInfo(int id) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.getBookingInfo(id),
      ),
      (data) {
        return BookingDetails.fromJson(data['data'] as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<Either<Failure, String>> updateStatusBooking(int id, String status) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(EndPoints.updateStatusBooking,
          queryParameters: {'status': status, 'booking_id': id}),
      (data) {
        return data['message'];
      },
    );
  }

  @override
  Future<Either<Failure, BookingDetails>> depositBookingPayment(
      int id, String due, String status, String extraInput) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(EndPoints.depositBookingPayment, queryParameters: {
        'booking_id': id,
        'due': due,
        'payment_status': status,
        'extra_input': extraInput
      }),
      (data) {
        return BookingDetails.fromJson(data['data'] as Map<String, dynamic>);
      },
    );
  }

  @override
  Future<Either<Failure, String>> addCustomer(
      {required String fullName, required String phone}) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(EndPoints.addCustomer, queryParameters: {
        'full_name': fullName,
        'phone_no': phone,
      }),
      (data) {
        final customerId = data['data']?['cmn_customer_id'];
        if (customerId != null) {
          return customerId.toString();
        } else {
          throw Exception("Customer ID not found in response");
        }
      },
    );
  }

  Future<Either<Failure, List<BookingDrilldownItem>>> getPaidBookings(
      String type) {
    return apiConsumer.handleRequest(
      () => apiConsumer.get(EndPoints.getPaidBookings(type)),
      (data) {
        return (data['data'] as List<dynamic>)
            .map(
                (e) => BookingDrilldownItem.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<Either<Failure, List<BookingDrilldownItem>>> getDueBookings() {
    return apiConsumer.handleRequest(
      () => apiConsumer.get(EndPoints.getDueBookings),
      (data) {
        return (data['data'] as List<dynamic>)
            .map(
                (e) => BookingDrilldownItem.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<Either<Failure, ManagerSeries>> getManagerSeries(int seriesId) {
    return apiConsumer.handleRequest(
      () => apiConsumer.get(EndPoints.managerSeries(seriesId)),
      (data) => ManagerSeries.fromJson(data['data'] as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, String>> decideManagerSeries({
    required int seriesId,
    required int status,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.managerSeriesDecision,
        data: {'series_id': seriesId, 'status': status},
      ),
      (data) => (data['message'] ?? 'تم').toString(),
    );
  }

  /// Appeals waiting on this manager's venues.
  Future<Either<Failure, List<CancellationExceptionCase>>> pendingExceptions() {
    return apiConsumer.handleRequest(
      () => apiConsumer.get(EndPoints.pendingExceptions),
      (data) => (data['data'] as List? ?? [])
          .map((e) => CancellationExceptionCase.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// Approve or reject. A rejection must carry a reason — the customer sees
  /// it, and a refusal they cannot understand is one they will escalate.
  Future<Either<Failure, String>> decideException({
    required int exceptionId,
    required String decision,
    double? amount,
    String? reason,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.decideException,
        isFormData: false,
        data: {
          'exception_id': exceptionId,
          'decision': decision,
          if (amount != null) 'amount': amount,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      ),
      (data) => data['message']?.toString() ?? 'تم.',
    );
  }

  Future<Either<Failure, List<AwaitingAttendanceBooking>>>
      awaitingAttendance() {
    return apiConsumer.handleRequest(
      () => apiConsumer.get(EndPoints.awaitingAttendance),
      (data) => (data['data'] as List? ?? [])
          .map((e) => AwaitingAttendanceBooking.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// Records what happened at the pitch. Never cancels the booking — a
  /// no-show is a slot that was consumed, not one that was called off.
  Future<Either<Failure, String>> markAttendance({
    required int bookingId,
    required String attendanceStatus,
    String? note,
    String? venueFaultReason,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.markAttendance,
        isFormData: false,
        data: {
          'booking_id': bookingId,
          'attendance_status': attendanceStatus,
          if (note != null && note.isNotEmpty) 'note': note,
          // A code, not the Arabic label: the server counts these, and
          // counting free text is how "انقطاع الكهرباء" and "الكهرباء مقطوعة"
          // become two different problems.
          if (venueFaultReason != null) 'venue_fault_reason': venueFaultReason,
        },
      ),
      (data) => data['message']?.toString() ?? 'تم التسجيل.',
    );
  }

  /// A manager's proposed settlement for an open no-show dispute.
  ///
  /// Talk, not a verdict — this never closes the dispute or touches money.
  /// `result` is 'attended' | 'no_show' | 'disagreement'.
  Future<Either<Failure, String>> proposeNoShowResolution({
    required int bookingId,
    required String result,
    String? note,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.proposeNoShowResolution,
        isFormData: false,
        data: {
          'booking_id': bookingId,
          'result': result,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      ),
      (data) => data['message']?.toString() ?? 'تم تسجيل الاقتراح.',
    );
  }

  /// Restricts pay-on-arrival for this customer at this venue only.
  Future<Either<Failure, String>> restrictPayOnArrival({
    required int bookingId,
    int? days,
    String? reason,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.restrictCustomer,
        isFormData: false,
        data: {
          'booking_id': bookingId,
          if (days != null) 'days': days,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      ),
      (data) => data['message']?.toString() ?? 'تم التقييد.',
    );
  }

  /// Stops this venue taking NEW bookings from this customer. Never a
  /// platform ban, never touches an existing booking.
  Future<Either<Failure, String>> blockCustomerFromVenue({
    required int customerId,
    required int branchId,
    required String reasonCode,
    String? note,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.blockCustomer,
        isFormData: false,
        data: {
          'customer_id': customerId,
          'branch_id': branchId,
          'reason_code': reasonCode,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      ),
      (data) => data['message']?.toString() ?? 'تم حظر الزبون.',
    );
  }

  Future<Either<Failure, String>> unblockCustomerFromVenue({
    required int customerId,
    required int branchId,
    String? note,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.unblockCustomer,
        isFormData: false,
        data: {
          'customer_id': customerId,
          'branch_id': branchId,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      ),
      (data) => data['message']?.toString() ?? 'تم إلغاء الحظر.',
    );
  }

  /// Calls off a whole monthly booking in one action.
  ///
  /// Cancelling the sessions one at a time sent the customer a separate
  /// message for each, every one of them promising that the rest of their
  /// series was still booked. This is the path that says what actually
  /// happened, once.
  Future<Either<Failure, String>> cancelManagerSeries(int seriesId) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.cancelManagerSeries,
        isFormData: false,
        data: {'series_id': seriesId},
      ),
      (data) => data['message']?.toString() ?? 'تم إلغاء الحجز الشهري.',
    );
  }

  /// Records cash taken for a whole monthly booking.
  ///
  /// The server decides which sessions the money covers — earliest first —
  /// so the app never has to split the amount itself. It also caps an
  /// overpayment at what is actually outstanding, which is why the confirming
  /// message comes back from the response rather than being composed here
  /// from the amount that was typed.
  Future<Either<Failure, String>> depositManagerSeries({
    required int seriesId,
    required double amount,
  }) {
    return apiConsumer.handleRequest(
      () => apiConsumer.post(
        EndPoints.managerSeriesDeposit,
        isFormData: false,
        data: {'series_id': seriesId, 'amount': amount},
      ),
      (data) => data['message']?.toString() ?? 'تم تسجيل الدفعة.',
    );
  }

}
