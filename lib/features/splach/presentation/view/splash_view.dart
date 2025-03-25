import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goal_master_admin/core/components/keys_values.dart'
    show PrefKey;
import 'package:goal_master_admin/core/components/preference_utility.dart'
    show SharedPreferenceUtil;
import 'package:goal_master_admin/core/routing/route_utils.dart'
    show pushReplacement;
import 'package:goal_master_admin/core/routing/routes_keys.dart'
    show RoutesKeys;
import 'package:goal_master_admin/core/styles/assets.dart' show Assets;

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  void initState() {
    //  if (SharedPreferenceUtil.getString(PrefKey.currentLanguageCode) == '') {
    //   SharedPreferenceUtil.putString(PrefKey.currentLanguageCode, 'ar');
    // }
    Future.delayed(Duration(seconds: 1)).then((value) {
      var result = SharedPreferenceUtil.getString(PrefKey.login);
      if (result.isEmpty) {
        print("----->$result");
        pushReplacement(RoutesKeys.kOnboarding, context);
      } else if (result == 'true') {
        print("----->$result");
        pushReplacement(RoutesKeys.kLogin, context);
      } else {
        print("----->$result");
        pushReplacement(RoutesKeys.kHome, context);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SvgPicture.asset(
          Assets.imagesSvgImageSplash,
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
