import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/features/booking/data/model/manager_series.dart';
import 'package:goal_master_admin/core/components/paginated_response.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_all_list_response.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';
import 'package:goal_master_admin/features/booking/data/model/cancel_booking_response.dart';
import 'package:goal_master_admin/features/booking/data/model/category_model.dart';
import 'package:goal_master_admin/features/booking/data/model/club_responce.dart';
import 'package:goal_master_admin/features/booking/data/model/employe/employe.dart';
import 'package:goal_master_admin/features/booking/data/model/location_reponse.dart';
import 'package:goal_master_admin/features/booking/data/model/service_model.dart';
import 'package:goal_master_admin/features/booking/data/model/timeslot.dart';
import 'package:goal_master_admin/features/booking/data/model/manager_customer.dart';
import 'package:goal_master_admin/features/booking/data/model/operational_slot.dart';
import 'package:goal_master_admin/features/booking/data/model/created_series.dart';
import 'package:goal_master_admin/features/booking/data/model/series_preview.dart';

abstract class BookingRepo {
  Future<Either<Failure, PaginatedResponse<BookingItemResponce>>> getBooking(
    int page,
    String? startDate,
    String? endDate,
    String? branchId,
    String? employeeId,
    String? customerId,
    String? serviceStatus,
    String? bookingId,
  );

  Future<Either<Failure, BookingDetails>> getBookingInfo(
    int id,
  );
  Future<Either<Failure, CancelBookingResponse>> cancelBooking(
    int id,
  );
  Future<Either<Failure, String>> updateStatusBooking(
    int id,
    String status,
  );
  Future<Either<Failure, BookingDetails>> depositBookingPayment(
    int id,
    String due,
    String status,
    String extraInput,
  );
  Future<Either<Failure, List<Location>>> listZone();
  Future<Either<Failure, List<ClubResponce>>> listClub(
    int zoneId,
  );
  //category
  Future<Either<Failure, List<CategoryModel>>> listCategory(
      {required int branchId});
  //service
  Future<Either<Failure, List<Service>>> listService(
    int categoryId,
    int branchId,
  );
  //customer-create
  Future<Either<Failure, String>> addCustomer({
    required String fullName,
    required String phone,
  });

  //employee
  Future<Either<Failure, List<Employee>>> listEmployee({required int branchId});
  //timeslot
  Future<Either<Failure, List<TimeslotModel>>> listTimeslot({
    required int branchId,
    required int employeeId,
    required int serviceId,
    required String date,
  });

  /// One operational night's slots, bands merged server-side. No employeeId:
  /// the band travels back on each slot instead of being chosen up front.
  Future<Either<Failure, OperationalNight>> listNightSlots({
    required int branchId,
    required int serviceId,
    required String operationalDate,
  });

  /// Whether the night already in progress still has bookable slots. The
  /// server decides, and supplies the date.
  Future<Either<Failure, PreviousNightContext>> previousNightContext({
    required int branchId,
    required int serviceId,
  });

  /// The four appointments a recurring booking would create, and which are
  /// taken. Same endpoint and engine the customer app uses.
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
    bool strictPositions,
    List<Map<String, dynamic>> replacements,
  });

  /// One page of the manager's customer book: alias-aware, searchable across
  /// alias/platform name/phone, and reachable before a first booking.
  Future<Either<Failure, ManagerCustomerPage>> managerCustomers({
    String? search,
    int page,
  });

  Future<Either<Failure, BookingCreated>> addBooking({
    required int branchId,
    required int employeeId,
    required int serviceId,
    required int paymentType,
    required String date,
    required String startTime,
    required String endTime,
    String? startAt,
    String? endAt,
    required String fullName,
    required String phone,
    required String state,
    required int isMonthly,
    String review,
    required int customerId,
    String paidAmount,
    String status,

    /// The manager's explicit approval of a plan that skips a taken week.
    /// Without the matching signature the backend refuses to skip anything —
    /// force booking waives policy, never approval.
    String? approvedPlanSignature,
    List<Map<String, dynamic>> replacements,
  });

  /// The venue's view of one recurring booking, with every session.
  Future<Either<Failure, ManagerSeries>> getManagerSeries(int seriesId);

  /// Accepts or refuses a whole recurring booking. All sessions move
  /// together — that is what the customer asked for.
  Future<Either<Failure, String>> decideManagerSeries({
    required int seriesId,
    required int status,
  });
}


/// What the server created, and what to tell the manager about it.
///
/// [series] is present only for a recurring booking, and is the server's own
/// account of it — occurrence list and total included — so the success screen
/// never has to infer either.
class BookingCreated {
  const BookingCreated({required this.message, this.series});

  final String message;
  final CreatedSeries? series;
}
