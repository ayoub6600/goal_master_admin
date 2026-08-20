import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/data/repo/manager_setup_repo.dart';

part 'manager_setup_state.dart';

class ManagerSetupCubit extends Cubit<ManagerSetupState> {
  ManagerSetupCubit(this._repo) : super(ManagerSetupInitial());

  final ManagerSetupRepo _repo;

  ManagerSetupBootstrapResponse? bootstrapResponse;

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
