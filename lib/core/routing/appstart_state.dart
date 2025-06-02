import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';

enum AppStartStatus {
  checking, // في البداية
  onboarding, // أول مرة يفتح
  unauthenticated, // مش مسجل دخول
  authenticated, // داخل التطبيق
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
    await Future.delayed(const Duration(milliseconds: 500));
    final onboardingSeen = SharedPreferenceUtil.getBool(PrefKey.onboardingSeen);
    final loggedIn = SharedPreferenceUtil.getString(PrefKey.login) == 'true';

    if (!onboardingSeen) {
      emit(AppStartState(AppStartStatus.onboarding));
    } else if (!loggedIn) {
      emit(AppStartState(AppStartStatus.unauthenticated));
    } else {
      emit(AppStartState(AppStartStatus.authenticated));
    }
  }
}
