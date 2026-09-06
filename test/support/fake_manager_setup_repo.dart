import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/data/repo/manager_setup_repo.dart';

/// A stand-in for the setup API.
///
/// `saveBookingPeriods` records the payload rather than sending it, so a test
/// can assert that the two stored windows a night splits into are exactly what
/// leaves the screen.
class FakeManagerSetupRepo implements ManagerSetupRepo {
  List<Map<String, dynamic>>? lastPeriods;
  Map<String, List<int>>? lastServiceIds;
  int saveCalls = 0;

  @override
  Future<Either<Failure, ManagerSetupBootstrapResponse>> getBootstrap() async =>
      Right(bootstrapFixture());

  /// A venue that already exists: one pitch, hours of 5pm–3am, a pin on the
  /// map — the state a manager opening «بيانات الملعب» is actually in.
  static ManagerSetupBootstrapResponse bootstrapFixture() =>
      ManagerSetupBootstrapResponse.fromJson({
        'data': {
          'setup': {
            'has_branch_profile': true,
            'branch': _branchJson,
          },
          'wallet': const <String, dynamic>{},
          'zones': [
            {'id': 3, 'name': 'مصراتة'},
          ],
          'category_types': const <dynamic>[],
          'catalog': {
            'services': [
              {
                'id': 1,
                'title': 'سداسي 1',
                'price': 66,
                'supports_evening': true,
                'supports_after_midnight': true,
              },
              // Deliberately evening-only: the case a merged service list
              // would silently widen into the small hours.
              {
                'id': 2,
                'title': 'سباعي 1',
                'price': 90,
                'supports_evening': true,
                'supports_after_midnight': false,
              },
            ],
            'employees': [
              {
                'id': 9,
                // Matches ManagerCatalogSetupService::employeeCode() on the
                // backend — the short form, not the old 'GM-BRANCH-{id}-
                // EVENING' that overflowed sch_employees.employee_id
                // (varchar 20) and was fixed by shortening it. This fixture
                // drifting from the real format is exactly how that fix's
                // three Flutter-side `.contains('EVENING')` call sites broke
                // silently — see SetupEmployeeItem.isEveningChannel.
                'employee_id': 'GM12-EVE',
                'full_name': 'حجز مسائي',
                'status': 1,
                'start_time': '17:00:00',
                'end_time': '24:00:00',
              },
              {
                'id': 10,
                'employee_id': 'GM12-AFT',
                'full_name': 'حجز بعد منتصف الليل',
                'status': 2,
                'start_time': '00:00:00',
                'end_time': '03:00:00',
              },
            ],
          },
        },
      });

  static ExistingBranch branchFixture() =>
      ExistingBranch.fromJson(Map<String, dynamic>.from(_branchJson));

  static const _branchJson = <String, dynamic>{
    'id': 12,
    'name': 'ملاعب الجدار',
    'phone': '0916776600',
    'email': 'wall@goalmaster.local',
    'zone_id': 3,
    'zone_name': 'مصراتة',
    'address': 'مصراتة - شارع طرابلس',
    'lat': '32.377000',
    'long': '15.092000',
    'image': '',
  };

  @override
  Future<Either<Failure, CreateFirstVenueResponse>> saveBranchSetup({
    required String branchName,
    required int zoneId,
    required String phone,
    required String email,
    required String address,
    String? lat,
    String? long,
    File? image,
  }) async =>
      Left(Failure(errMessage: 'not used in this test'));

  @override
  Future<Either<Failure, SaveManagerBookingPeriodsResponse>> saveBookingPeriods({
    required List<Map<String, dynamic>> periods,
    required Map<String, List<int>> serviceIdsByPeriod,
  }) async {
    saveCalls++;
    lastPeriods = periods;
    lastServiceIds = serviceIdsByPeriod;

    return Left(Failure(errMessage: 'recorded'));
  }

  @override
  Future<Either<Failure, SaveManagerCatalogResponse>> saveCatalogSetup({
    required int categoryTypeId,
    required List<Map<String, dynamic>> services,
  }) async =>
      Left(Failure(errMessage: 'not used in this test'));
}
