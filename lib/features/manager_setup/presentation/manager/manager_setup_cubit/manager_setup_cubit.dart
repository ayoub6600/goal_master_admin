import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/data/repo/manager_setup_repo.dart';

part 'manager_setup_state.dart';

class ManagerServiceMediaChange {
  const ManagerServiceMediaChange({
    required this.existingServiceId,
    required this.title,
    required this.newImages,
    required this.removedExistingImageIds,
  });

  final int? existingServiceId;
  final String title;
  final List<File> newImages;
  final Set<int> removedExistingImageIds;
}

class ManagerSetupCubit extends Cubit<ManagerSetupState> {
  ManagerSetupCubit(this._repo) : super(ManagerSetupInitial());

  final ManagerSetupRepo _repo;

  ManagerSetupBootstrapResponse? bootstrapResponse;

  /// Returns null on success, or an error message on failure.
  Future<String?> updatePhysicalResourceDetails({
    required int resourceId,
    required String name,
    required String resourceType,
  }) async {
    emit(ManagerSetupSubmitting(bootstrapResponse));

    final result = await _repo.updatePhysicalResourceDetails(
      resourceId: resourceId,
      name: name,
      resourceType: resourceType,
    );

    return result.fold(
      (failure) async {
        emit(
          ManagerSetupFailure(
            failure.errMessage,
            bootstrap: bootstrapResponse,
          ),
        );
        return failure.errMessage;
      },
      (_) async {
        await loadBootstrap();

        if (state is ManagerSetupFailure) {
          return (state as ManagerSetupFailure).message;
        }

        return null;
      },
    );
  }

  /// Creates one independent physical field and reloads the fields list.
  /// Returns null on success, or an error message on failure.
  Future<String?> createPhysicalField({
    required String name,
    required String resourceType,
    required List<Map<String, dynamic>> sports,
  }) async {
    emit(ManagerSetupSubmitting(bootstrapResponse));

    final result = await _repo.createPhysicalField(
      name: name,
      resourceType: resourceType,
      sports: sports,
    );

    return result.fold<Future<String?>>(
      (failure) async {
        emit(
          ManagerSetupFailure(
            failure.errMessage,
            bootstrap: bootstrapResponse,
          ),
        );
        return failure.errMessage;
      },
      (_) async {
        await loadBootstrap();

        final currentState = state;
        if (currentState is ManagerSetupFailure) {
          return currentState.message;
        }

        return null;
      },
    );
  }

  /// Adds a brand new sport to an ALREADY EXISTING field. Returns null on
  /// success, or an error message on failure.
  Future<String?> addSportToField({
    required int resourceId,
    required int categoryTypeId,
    required double price,
  }) async {
    emit(ManagerSetupSubmitting(bootstrapResponse));

    final result = await _repo.addSportToField(
      resourceId: resourceId,
      categoryTypeId: categoryTypeId,
      price: price,
    );

    return result.fold<Future<String?>>(
      (failure) async {
        emit(
          ManagerSetupFailure(
            failure.errMessage,
            bootstrap: bootstrapResponse,
          ),
        );
        return failure.errMessage;
      },
      (_) async {
        await loadBootstrap();

        final currentState = state;
        if (currentState is ManagerSetupFailure) {
          return currentState.message;
        }

        return null;
      },
    );
  }

  /// Updates one sport's price only. Returns null on success, or an error
  /// message on failure.
  Future<String?> updateSportPrice({
    required int resourceId,
    required int serviceId,
    required double price,
  }) async {
    emit(ManagerSetupSubmitting(bootstrapResponse));

    final result = await _repo.updateSportPrice(
      resourceId: resourceId,
      serviceId: serviceId,
      price: price,
    );

    return result.fold<Future<String?>>(
      (failure) async {
        emit(
          ManagerSetupFailure(
            failure.errMessage,
            bootstrap: bootstrapResponse,
          ),
        );
        return failure.errMessage;
      },
      (_) async {
        await loadBootstrap();

        final currentState = state;
        if (currentState is ManagerSetupFailure) {
          return currentState.message;
        }

        return null;
      },
    );
  }

  /// Uploads images for ONE sport and reloads so the gallery reflects the
  /// server's actual state. Returns null on success, or an error message.
  Future<String?> uploadSportImages({
    required int serviceId,
    required List<File> images,
  }) async {
    final result = await _repo.uploadServiceImages(
      serviceId: serviceId,
      images: images,
    );

    return result.fold<Future<String?>>(
      (failure) async => failure.errMessage,
      (_) async {
        await loadBootstrap();
        return null;
      },
    );
  }

  /// Deletes ONE image from a sport's gallery and reloads. Returns null on
  /// success, or an error message.
  Future<String?> deleteSportImage({
    required int serviceId,
    required int mediaId,
  }) async {
    final result = await _repo.deleteServiceImage(
      serviceId: serviceId,
      mediaId: mediaId,
    );

    return result.fold<Future<String?>>(
      (failure) async => failure.errMessage,
      (_) async {
        await loadBootstrap();
        return null;
      },
    );
  }

  Future<void> loadBootstrap() async {
    emit(ManagerSetupLoading());

    final result = await _repo.getBootstrap();
    result.fold(
      (failure) => emit(ManagerSetupFailure(failure.errMessage)),
      (response) {
        bootstrapResponse = response;
        emit(ManagerSetupLoaded(response));
      },
    );
  }

  Future<void> saveBranchSetup({
    required String branchName,
    required int zoneId,
    required String phone,
    required String email,
    required String address,
    String? lat,
    String? long,
    File? image,
  }) async {
    emit(ManagerSetupSubmitting(bootstrapResponse));

    final result = await _repo.saveBranchSetup(
      branchName: branchName,
      zoneId: zoneId,
      phone: phone,
      email: email,
      address: address,
      lat: lat,
      long: long,
      image: image,
    );

    await result.fold(
      (failure) async => emit(
        ManagerSetupFailure(
          failure.errMessage,
          bootstrap: bootstrapResponse,
        ),
      ),
      (response) async {
        await SharedPreferenceUtil.putInt(PrefKey.zoneId, response.user.zoneId);
        await SharedPreferenceUtil.putInt(PrefKey.clubId, response.user.clubId);
        await loadBootstrap();
        emit(
          ManagerSetupSuccess(
            response: response,
            bootstrap: bootstrapResponse,
          ),
        );
      },
    );
  }

  Future<void> saveCatalogSetup({
    required int categoryTypeId,
    required List<Map<String, dynamic>> services,
    List<ManagerServiceMediaChange> mediaChanges = const [],
  }) async {
    emit(ManagerSetupSubmitting(bootstrapResponse));

    final result = await _repo.saveCatalogSetup(
      categoryTypeId: categoryTypeId,
      services: services,
    );

    await result.fold(
      (failure) async => emit(
        ManagerSetupFailure(
          failure.errMessage,
          bootstrap: bootstrapResponse,
        ),
      ),
      (response) async {
        String? mediaError;

        for (final change in mediaChanges) {
          SavedManagerService? savedService;

          for (final service in response.services) {
            if (service.title.trim() == change.title.trim()) {
              savedService = service;
              break;
            }
          }

          final savedServiceId = savedService?.id ?? change.existingServiceId;

          if (savedServiceId == null) {
            mediaError =
                'تم حفظ الملعب ولكن تعذر تحديده لرفع الصور. حاول مرة أخرى.';
            break;
          }

          // Existing images selected for removal must be deleted from the
          // service that originally owns them.
          if (change.existingServiceId != null &&
              change.removedExistingImageIds.isNotEmpty) {
            for (final mediaId in change.removedExistingImageIds) {
              final deleteResult = await _repo.deleteServiceImage(
                serviceId: change.existingServiceId!,
                mediaId: mediaId,
              );

              deleteResult.fold(
                (failure) {
                  mediaError = failure.errMessage;
                },
                (_) {},
              );

              if (mediaError != null) break;
            }
          }

          if (mediaError != null) break;

          if (change.newImages.isNotEmpty) {
            final uploadResult = await _repo.uploadServiceImages(
              serviceId: savedServiceId,
              images: change.newImages,
            );

            uploadResult.fold(
              (failure) {
                mediaError = failure.errMessage;
              },
              (_) {},
            );
          }

          if (mediaError != null) break;
        }

        if (mediaError != null) {
          await loadBootstrap();

          emit(
            ManagerSetupFailure(
              'تم حفظ بيانات الملاعب، لكن حدث خطأ أثناء حفظ الصور: $mediaError',
              bootstrap: bootstrapResponse,
            ),
          );
          return;
        }

        await loadBootstrap();

        emit(
          ManagerCatalogSetupSuccess(
            response: response,
            bootstrap: bootstrapResponse,
          ),
        );
      },
    );
  }

  Future<void> saveBookingPeriods({
    required List<Map<String, dynamic>> periods,
    required Map<String, List<int>> serviceIdsByPeriod,
  }) async {
    emit(ManagerSetupSubmitting(bootstrapResponse));

    final result = await _repo.saveBookingPeriods(
      periods: periods,
      serviceIdsByPeriod: serviceIdsByPeriod,
    );

    await result.fold(
      (failure) async => emit(
        ManagerSetupFailure(
          failure.errMessage,
          bootstrap: bootstrapResponse,
        ),
      ),
      (response) async {
        await loadBootstrap();
        emit(
          ManagerBookingPeriodsSuccess(
            response: response,
            bootstrap: bootstrapResponse,
          ),
        );
      },
    );
  }
}
