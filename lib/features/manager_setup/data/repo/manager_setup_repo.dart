import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';

abstract class ManagerSetupRepo {
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
}
