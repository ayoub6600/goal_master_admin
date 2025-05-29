import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/launch_phone_call.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/launch_whats_app.dart';

class ItemsUserCall extends StatelessWidget {
  const ItemsUserCall({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.mainBlue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                customer.fullName[0].toUpperCase(),
                style: AppTextStyles.font18Bold.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName,
                  style: AppTextStyles.font16Bold.copyWith(
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                HeightSpace(8.h),
                Row(
                  children: [
                    Image.asset(
                      Assets.imagesPngImageCallCalling,
                      fit: BoxFit.cover,
                    ),
                    WidthSpace(8.w),
                    GestureDetector(
                      onTap: () => launchPhoneCall(customer.phoneNo),
                      child: Text(
                        customer.phoneNo,
                        style: AppTextStyles.font16Bold.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => launchWhatsApp(customer.phoneNo),
            child: Image.asset(
              Assets.imagesPngImageSend2,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
