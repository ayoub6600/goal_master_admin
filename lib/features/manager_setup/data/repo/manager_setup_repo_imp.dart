import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer.dart';
import 'package:goal_master_admin/core/databases/api/api_consumer_extension.dart';
import 'package:goal_master_admin/core/databases/api/end_points.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/data/repo/manager_setup_repo.dart';

class ManagerSetupRepoImp implements ManagerSetupRepo {
  final ApiConsumer consumer;

  ManagerSetupRepoImp(this.consumer);

  @override
  Future<Either<Failure, ManagerSetupBootstrapResponse>> getBootstrap() {
    return consumer.handleRequestCustom(
      () => consumer.get(EndPoints.managerSetupBootstrap),
      (response) async => ManagerSetupBootstrapResponse.fromJson(
        response as Map<String, dynamic>? ?? const {},
      ),
    );
  }

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
  }) async {
    final data = <String, dynamic>{
      'branch_name': branchName,
      'zone_id': zoneId,
      'phone': phone,
      'email': email,
      'address': address,
      'lat': lat,
      'long': long,
      if (image != null)
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
    };

    return consumer.handleRequestCustom(
      () => consumer.post(
        EndPoints.managerCreateFirstVenue,
        data: data,
        isFormData: true,
      ),
      (response) async => CreateFirstVenueResponse.fromJson(
        response as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  Future<Either<Failure, SaveManagerCatalogResponse>> saveCatalogSetup({
    required int categoryTypeId,
    required List<Map<String, dynamic>> services,
  }) {
    return consumer.handleRequestCustom(
      () => consumer.post(
        EndPoints.managerSetupCatalog,
        data: {
          'category_type_id': categoryTypeId,
          'services': services,
        },
        isFormData: false,
      ),
      (response) async => SaveManagerCatalogResponse.fromJson(
        response as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  Future<Either<Failure, SaveManagerBookingPeriodsResponse>>
      saveBookingPeriods({
    required List<Map<String, dynamic>> periods,
    required Map<String, List<int>> serviceIdsByPeriod,
  }) {
    final normalizedPeriods = periods.map((period) {
      final key = (period['key'] ?? '').toString();
      return {
        ...period,
        'service_ids': serviceIdsByPeriod[key] ?? const <int>[],
      };
    }).toList();

    return consumer.handleRequestCustom(
      () => consumer.post(
        EndPoints.managerSetupBookingPeriods,
        data: {
          'periods': normalizedPeriods,
        },
        isFormData: false,
      ),
      (response) async => SaveManagerBookingPeriodsResponse.fromJson(
        response as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
