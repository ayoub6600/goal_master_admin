import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      color: Color(0xffDFF5E1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            Assets.imagesPngImageSoccerPlayer,
            width: 50.w,
            height: 50.h,
            fit: BoxFit.cover,
          ),
          WidthSpace(16.w),
          Expanded(
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                print("state: $state");
                if (state is ProfileLoading) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SharedPreferenceUtil.getString(PrefKey.fullName),
                        style: AppTextStyles.font16SemiBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      HeightSpace(8.h),
                      Text(
                        SharedPreferenceUtil.getString(PrefKey.phone),
                        style: AppTextStyles.font16SemiBold
                            .copyWith(color: Color(0xff6D7580)),
                      ),
                    ],
                  );
                } else if (state is ProfileLoaded) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.user.name ?? "No Name",
                        style: AppTextStyles.font16SemiBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      HeightSpace(8.h),
                      Text(
                        state.user.phoneNumber ?? " ",
                        style: AppTextStyles.font16SemiBold
                            .copyWith(color: Color(0xff6D7580)),
                      ),
                    ],
                  );
                } else if (state is ProfileError) {
                  return Text(
                    "Error: ${state.error}",
                    style: TextStyle(color: Colors.red),
                  );
                }
                return Text("No Data Available");
              },
            ),
          ),
        ],
      ),
    );
  }
}
