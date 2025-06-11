import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';

enum AppStartStatus {
  checking,
  onboarding,
  unauthenticated,
  authenticated,
}

class AppStartState {
  final AppStartStatus status;

  AppStartState(this.status);
}

class AppStartCubit extends Cubit<AppStartState> {
  AppStartCubit() : super(AppStartState(AppStartStatus.checking)) {
    _checkAppStartState();
  }

  Future<void> _checkAppStartState() async {
    final onboardingSeen = SharedPreferenceUtil.getBool(PrefKey.onboardingSeen);
    final loggedIn = SharedPreferenceUtil.getString(PrefKey.login) == 'true';
    final userId = SharedPreferenceUtil.getInt(PrefKey.userId);

    print('[AppStart] onboardingSeen: $onboardingSeen');
    print('[AppStart] loggedIn: $loggedIn');
    print('[AppStart] userId: $userId');

    if (!onboardingSeen) {
      print('[AppStart] 👣 Showing onboarding');
      emit(AppStartState(AppStartStatus.onboarding));
    } else if (!loggedIn || userId == null || userId == 0) {
      print('[AppStart] 🚫 Not authenticated');
      emit(AppStartState(AppStartStatus.unauthenticated));
    } else {
      print('[AppStart] ✅ Authenticated');
      emit(AppStartState(AppStartStatus.authenticated));
    }
  }
}
