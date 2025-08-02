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

  // دالة لإعادة فحص الحالة (مفيدة للاختبار)
  Future<void> recheckState() async {
    emit(AppStartState(AppStartStatus.checking));
    await _checkAppStartState();
  }

  // دالة للتحقق من البيانات المحفوظة (مفيدة للاختبار)
  static void debugPrintSavedData() {
    print('=== DEBUG: Saved Data ===');
    print(
        'onboardingSeen: ${SharedPreferenceUtil.getBool(PrefKey.onboardingSeen)}');
    print('login: ${SharedPreferenceUtil.getString(PrefKey.login)}');
    print('userId: ${SharedPreferenceUtil.getInt(PrefKey.userId)}');
    print('========================');
  }

  Future<void> _checkAppStartState() async {
    // تأكد من أن SharedPreferences جاهز
    await SharedPreferenceUtil.getInstance();

    // قراءة البيانات مع إعادة المحاولة
    bool onboardingSeen = false;
    String loggedIn = '';
    int? userId;

    try {
      onboardingSeen = SharedPreferenceUtil.getBool(PrefKey.onboardingSeen);
      loggedIn = SharedPreferenceUtil.getString(PrefKey.login);
      userId = SharedPreferenceUtil.getInt(PrefKey.userId);
    } catch (e) {
      print('[AppStart] Error reading preferences: $e');
      // في حالة الخطأ، نعتبر أن المستخدم لم يرى الـ onboarding
      onboardingSeen = false;
      loggedIn = '';
      userId = null;
    }

    print('[AppStart] onboardingSeen: $onboardingSeen');
    print('[AppStart] loggedIn: $loggedIn');
    print('[AppStart] userId: $userId');

    // تأخير بسيط للتأكد من أن البيانات محفوظة
    await Future.delayed(Duration(milliseconds: 200));

    if (!onboardingSeen) {
      print('[AppStart] 👣 Showing onboarding');
      emit(AppStartState(AppStartStatus.onboarding));
    } else if (loggedIn != 'true' || userId == null || userId == 0) {
      print('[AppStart] 🚫 Not authenticated - redirecting to login');
      emit(AppStartState(AppStartStatus.unauthenticated));
    } else {
      print('[AppStart] ✅ Authenticated - going to home');
      emit(AppStartState(AppStartStatus.authenticated));
    }
  }
}
