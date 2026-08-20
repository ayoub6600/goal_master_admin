import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';

class ManagerWalletPaymentMethodsSheet extends StatelessWidget {
  const ManagerWalletPaymentMethodsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ButtonApp(
            text: 'البطاقة المصرفية (أونلاين)',
            backGround: AppColors.primary,
            textColor: Colors.white,
            onTap: () => Navigator.pop(context, 'visa'),
          ),
          HeightSpace(12.h),
          ButtonApp(
            text: 'شحن بالكرت',
            backGround: Colors.white,
            textColor: AppColors.primary,
            onTap: () => Navigator.pop(context, 'card'),
          ),
        ],
      ),
    );
  }
}
