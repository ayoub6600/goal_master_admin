import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/employee_cubit/employee_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_list.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_view_body_bottom_sheet.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo_imp.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/customer_cubit/customer_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookingViewBody extends StatelessWidget {
  const BookingViewBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeightSpace(16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "قائمة الحجوزات",
                      style: AppTextStyles.font24Bold.copyWith(
                        color: AppColors.fontColor,
                      ),
                    ),
                    HeightSpace(4.h),
                    Text(
                      "يمكنك هنا استعراض جميع الحجوزات",
                      style: AppTextStyles.font16Medium.copyWith(
                        color: AppColors.fontColor,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  final parentContext = context; // ده اللي فيه BlocProvider

                  baseBottomSheet(
                      title: "بحث",
                      context: context,
                      hideNavBar: false,
                      child: MultiBlocProvider(
                        providers: [
                          BlocProvider(
                            create: (context) =>
                                EmployeeCubit(getIt<BookingRepoImp>())
                                  ..listEmployee(12),
                          ),
                          BlocProvider(
                            create: (context) => CustomerCubit(
                              bookingRepo: getIt<ProfileRepoImp>(),
                            )..loadFirstPageManually(),
                          ),
                        ],
                        child: BookingViewBodyBottomSheet(
                          cubitContext: parentContext,
                        ),
                      ));
                },
                child: Image.asset(
                  Assets.imagesPngImageFiltter,
                ),
              ),
            ],
          ),
        ),
        HeightSpace(16.h),
        Expanded(child: BookingList()),
      ],
    );
  }
}
