# حل مشكلة Hot Restart في تطبيق Goal Master Admin

## المشكلة
عند تثبيت التطبيق لأول مرة وعمل تسجيل دخول، عند الضغط على `hot restart` كان التطبيق يعود إلى شاشة الـ onboarding بدلاً من البقاء في الشاشة الرئيسية.

## سبب المشكلة
المشكلة كانت في `AppStartCubit` الذي يتم إنشاؤه مرة واحدة فقط عند بدء التطبيق، ولا يتم إعادة فحص حالة التطبيق عند حدوث `hot restart`. هذا يؤدي إلى أن التطبيق يعود إلى الحالة الافتراضية (onboarding) بدلاً من الحالة المحفوظة.

## الحل المطبق

### 1. إضافة طريقة `refreshAppState` في `AppStartCubit`
```dart
// إضافة طريقة لإعادة فحص حالة التطبيق
Future<void> refreshAppState() async {
  print('[AppStart] 🔄 Refreshing app state...');
  emit(AppStartState(AppStartStatus.checking));
  await Future.delayed(const Duration(milliseconds: 100)); // تأخير قصير لضمان حفظ البيانات
  await _checkAppStartState();
}
```

### 2. تحسين `main.dart` لاستدعاء `refreshAppState` عند hot restart
```dart
// إضافة استدعاء refreshAppState عند حدوث hot restart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (state.status == AppStartStatus.checking) {
    try {
      context.read<AppStartCubit>().refreshAppState();
    } catch (e) {
      print('Error refreshing app state: $e');
    }
  }
});
```

### 3. تحسين `login_view_body.dart` لتحديث حالة التطبيق بعد تسجيل الدخول
```dart
// ✅ تحديث حالة التطبيق
if (context.mounted) {
  try {
    final appStartCubit = BlocProvider.of<AppStartCubit>(context, listen: false);
    await appStartCubit.refreshAppState();
  } catch (e) {
    print('AppStartCubit not found in widget tree: $e');
  }
}
```

### 4. تحسين حفظ البيانات في `login_cubit.dart`
```dart
// حفظ جميع البيانات بشكل متزامن
await Future.wait<void>([
  SharedPreferenceUtil.putString(PrefKey.refreshToken, userData.token ?? "") ?? Future.value(),
  SharedPreferenceUtil.putInt(PrefKey.userId, userData.user?.id ?? 0) ?? Future.value(),
  // ... باقي البيانات
]);
```

### 5. تحسين حفظ البيانات في أزرار الـ onboarding
```dart
// حفظ البيانات بشكل متزامن
await Future.wait([
  SharedPreferenceUtil.putBool(PrefKey.onboardingSeen, true) ?? Future.value(),
  SharedPreferenceUtil.putString(PrefKey.login, "false"),
]);
```

## النتيجة
بعد تطبيق هذه التحسينات:
- ✅ عند تسجيل الدخول لأول مرة، يتم حفظ البيانات بشكل صحيح
- ✅ عند الضغط على `hot restart`، يبقى التطبيق في الشاشة الرئيسية
- ✅ يتم إعادة فحص حالة التطبيق بشكل صحيح عند الحاجة
- ✅ تحسين أداء حفظ البيانات باستخدام `Future.wait`

## الملفات المعدلة
1. `lib/core/routing/appstart_state.dart`
2. `lib/main.dart`
3. `lib/features/auth/presentation/view/widgets/login_view_body.dart`
4. `lib/features/auth/presentation/manager/login_cubit/login_cubit.dart`
5. `lib/features/onbording/presentation/view/widgets/button_onbording.dart`
6. `lib/features/onbording/presentation/view/widgets/onboarding_next_page_button.dart` 