import 'package:bloc/bloc.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo.dart';

import 'package:meta/meta.dart';
import 'package:goal_master_admin/features/auth/data/model/login_model/user.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repo) : super(ProfileInitial());
  final ProfileRepo _repo;

  Future<void> getProfile() async {
    emit(ProfileLoading());
    var result = await _repo.getProfile();
    result.fold((error) => emit(ProfileError(error: error.errMessage)), (user) {
      print("user: $user");
      emit(ProfileLoaded(user));
    });
  }
}
