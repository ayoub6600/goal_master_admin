import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/format_time.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_booking_cubit/add_booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/employee_cubit/employee_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/event_card.dart';
import 'package:goal_master_admin/features/home/data/model/booking_slots_response.dart';
import 'package:goal_master_admin/features/home/presentation/manager/page_view_new_booking_cubit/page_view_new_booking_cubit.dart';

import '../../../../../core/components/button_app.dart';

class BookingItem extends StatelessWidget {
  const BookingItem({super.key, required this.booking});
  final BookingSlot booking;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xfff5f7fa),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        color: Color(0xfff5f7fa),
        child: Row(
          children: [
            WidthSpace(8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "${booking.serviceTitle}" "( ${booking.club} )",
                    style: AppTextStyles.font16Bold,
                  ),
                  HeightSpace(8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.watch_later_outlined,
                              color: AppColors.primary,
                            ),
                            WidthSpace(8.w),
                            Text(
                              "${formatTime(booking.startTime)} - ${formatTime(booking.endTime)}",
                              textDirection: TextDirection.ltr,
                              style: AppTextStyles.font14Bold.copyWith(
                                color: AppColors.fontColor,
                              ),
                            ),
                          ]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            Assets.imagesPngImageCalendar,
                            color: AppColors.primary,
                          ),
                          WidthSpace(8.w),
                          Text(
                            "${booking.date}",
                            style: AppTextStyles.font14Bold.copyWith(
                              color: AppColors.fontColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  HeightSpace(16.h),
                  // Into the one booking flow.
                  //
                  // This used to open a second, partial implementation:
                  // «اختر الحجز» followed by a payment page, whose «تأكيد
                  // الحجز» button was commented out and only printed to the
                  // console. A manager could walk the whole thing and create
                  // nothing. It also still exposed the band picker that the
                  // unified flow exists to remove.
                  ButtonApp(
                      text: "حجز",
                      onTap: () {
                        push(RoutesKeys.kAddBooking, context);
                      })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
