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
  @override
  Future<Either<Failure, bool>> createPhysicalField({
    required String name,
    required String resourceType,
    required List<Map<String, dynamic>> sports,
  }) {
    return consumer.handleRequestCustom(
      () => consumer.post(
        EndPoints.managerPhysicalResources,
        data: {
          'name': name,
          'resource_type': resourceType,
          'sports': sports,
        },
        isFormData: false,
      ),
      (response) async => true,
    );
  }

  @override
  Future<Either<Failure, bool>> updatePhysicalResourceDetails({
    required int resourceId,
    required String name,
    required String resourceType,
  }) {
    return consumer.handleRequestCustom(
      () => consumer.patch(
        EndPoints.managerPhysicalResource(resourceId),
        data: {
          'name': name,
          'resource_type': resourceType,
        },
        isFormData: false,
      ),
      (response) async => true,
    );
  }

  /// Saves hours for ONE physical field, never the whole branch.
  @override
  Future<Either<Failure, bool>> savePhysicalResourceHours({
    required int resourceId,
    required String opensAt,
    required String closesAt,
  }) {
    return consumer.handleRequestCustom(
      () => consumer.patch(
        EndPoints.managerPhysicalResource(resourceId),
        data: {
          'opens_at': opensAt,
          'closes_at': closesAt,
        },
        isFormData: false,
      ),
      (response) async => true,
    );
  }

  @override
  Future<Either<Failure, bool>> addSportToField({
    required int resourceId,
    required int categoryTypeId,
    required double price,
  }) {
    return consumer.handleRequestCustom(
      () => consumer.post(
        EndPoints.managerPhysicalResourceSports(resourceId),
        data: {
          'category_type_id': categoryTypeId,
          'price': price,
        },
        isFormData: false,
      ),
      (response) async => true,
    );
  }

  @override
  Future<Either<Failure, bool>> updateSportPrice({
    required int resourceId,
    required int serviceId,
    required double price,
  }) {
    return consumer.handleRequestCustom(
      () => consumer.patch(
        EndPoints.managerPhysicalResourceSport(resourceId, serviceId),
        data: {
          'price': price,
        },
        isFormData: false,
      ),
      (response) async => true,
    );
  }

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
  Future<Either<Failure, bool>> uploadServiceImages({
    required int serviceId,
    required List<File> images,
  }) async {
    if (images.isEmpty) {
      return const Right(true);
    }

    final multipartImages = <MultipartFile>[];

    for (final image in images) {
      multipartImages.add(
        await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
      );
    }

    return consumer.handleRequestCustom(
      () => consumer.post(
        EndPoints.managerServiceImages(serviceId),
        data: {
          'images[]': multipartImages,
        },
        isFormData: true,
      ),
      (response) async => true,
    );
  }

  @override
  Future<Either<Failure, bool>> deleteServiceImage({
    required int serviceId,
    required int mediaId,
  }) {
    return consumer.handleRequestCustom(
      () => consumer.delete(
        EndPoints.managerServiceImage(
          serviceId,
          mediaId,
        ),
      ),
      (response) async => true,
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
