import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/routing/app_router.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/features/layout/presentation/manager/layout_cubit.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo_imp.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ✅ حل المشكلة
  await SharedPreferenceUtil.getInstance();
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LayoutCubit(),
        ),
        BlocProvider(
          create: (context) => ProfileCubit(
            getIt<ProfileRepoImp>(),
          )..getProfile(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        child: GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: OKToast(
            child: MaterialApp.router(
              title: "Goal Master Admin",
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
                useMaterial3: true,
                textTheme: GoogleFonts.tajawalTextTheme(),
                scaffoldBackgroundColor: Colors.white,
              ),
              debugShowCheckedModeBanner: false,
              locale: const Locale('ar'),
              supportedLocales: const [
                Locale('ar'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: AppRouter.router,
            ),
          ),
        ),
      ),
    );
  }
}
