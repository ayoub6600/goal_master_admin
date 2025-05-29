// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:goal_master_admin/core/components/keys_values.dart';
// import 'package:goal_master_admin/core/components/preference_utility.dart';

// enum AppStartStatus { splash, onboarding, unauthenticated, authenticated }

// class AppStartState {
//   final AppStartStatus status;

//   AppStartState(this.status);
// }

// class AppStartCubit extends Cubit<AppStartState> {
//   AppStartCubit() : super(AppStartState(AppStartStatus.splash)) {
//     _checkAppStartState();
//   }

//   Future<void> _checkAppStartState() async {
//     await Future.delayed(const Duration(milliseconds: 500)); // simulate delay

//     final onboardingSeen = SharedPreferenceUtil.getBool(PrefKey.onboardingSeen);
//     final loggedIn = SharedPreferenceUtil.getString(PrefKey.login) == 'true';

//     if (!onboardingSeen) {
//       emit(AppStartState(AppStartStatus.onboarding));
//     } else if (!loggedIn) {
//       emit(AppStartState(AppStartStatus.unauthenticated));
//     } else {
//       emit(AppStartState(AppStartStatus.authenticated));
//     }
//   }
// }
