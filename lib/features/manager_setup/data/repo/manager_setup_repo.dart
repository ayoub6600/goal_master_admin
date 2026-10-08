import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';

abstract class ManagerSetupRepo {
  Future<Either<Failure, bool>> createPhysicalField({
    required String name,
    required String resourceType,
    required List<Map<String, dynamic>> sports,
  });

  Future<Either<Failure, bool>> updatePhysicalResourceDetails({
    required int resourceId,
    required String name,
    required String resourceType,
  });

  Future<Either<Failure, bool>> savePhysicalResourceHours({
    required int resourceId,
    required String opensAt,
    required String closesAt,
  });

  /// Creates a BRAND NEW sport under an already-existing field (e.g. adding
  /// basketball to a multi field that currently only has football).
  Future<Either<Failure, bool>> addSportToField({
    required int resourceId,
    required int categoryTypeId,
    required double price,
  });

  /// Updates ONE sport's price only — every other sport on the same field,
  /// and any already-placed booking's historical total, is untouched.
  Future<Either<Failure, bool>> updateSportPrice({
    required int resourceId,
    required int serviceId,
    required double price,
  });

  Future<Either<Failure, ManagerSetupBootstrapResponse>> getBootstrap();

  Future<Either<Failure, CreateFirstVenueResponse>> saveBranchSetup({
    required String branchName,
    required int zoneId,
    required String phone,
    required String email,
    required String address,
    String? lat,
    String? long,
    File? image,
  });

  Future<Either<Failure, SaveManagerBookingPeriodsResponse>>
      saveBookingPeriods({
    required List<Map<String, dynamic>> periods,
    required Map<String, List<int>> serviceIdsByPeriod,
  });

  Future<Either<Failure, SaveManagerCatalogResponse>> saveCatalogSetup({
    required int categoryTypeId,
    required List<Map<String, dynamic>> services,
  });

  Future<Either<Failure, bool>> uploadServiceImages({
    required int serviceId,
    required List<File> images,
  });

  Future<Either<Failure, bool>> deleteServiceImage({
    required int serviceId,
    required int mediaId,
  });
}
