import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:intl/intl.dart';

import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_all_list_response.dart';

class BookingItems extends StatelessWidget {
  const BookingItems({super.key, required this.booking});
  final BookingItemResponce booking;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        push(RoutesKeys.kBookingItemsDetails, context, extra: booking.id);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(vertical: 16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.primary,
          ),
        ),
        child: Column(
          children: [
            HeightSpace(6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "# رقم الحجز : ",
                        style: AppTextStyles.font16Bold.copyWith(
                          color: AppColors.fontColor,
                        ),
                      ),
                      WidthSpace(10.w),
                      Text(
                        booking.id.toString(),
                        style: AppTextStyles.font16Bold.copyWith(
                          color: AppColors.fontColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      border:
                          Border.all(color: _getStatusColor(booking.status)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _getStatusText(booking.status),
                      style: AppTextStyles.font14Bold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            HeightSpace(10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 7.w),
                  padding:
                      EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      width: 1.5,
                      color: const Color(0xffDFF5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      WidthSpace(10.w),
                      Text(
                        booking.service,
                        style: AppTextStyles.font16Bold.copyWith(
                          color: const Color(0xff204523),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 18.h,
                    horizontal: 30.w,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffDFF5E1),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12.r),
                      bottomRight: Radius.circular(12.r),
                    ),
                    border: Border.all(
                      width: 1.5,
                      color: const Color(0xffDFF5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        booking.branch,
                        style: AppTextStyles.font16Bold.copyWith(
                          color: const Color(0xff204523),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            HeightSpace(16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Image.asset(
                    Assets.imagesPngImageProfailIcon,
                    fit: BoxFit.cover,
                  ),
                  WidthSpace(10.w),
                  Text(
                    booking.customer,
                    style: AppTextStyles.font16Bold.copyWith(
                      color: AppColors.fontColor,
                    ),
                  ),
                ],
              ),
            ),
            HeightSpace(16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Image.asset(
                          Assets.imagesPngImageClock,
                          fit: BoxFit.cover,
                        ),
                        WidthSpace(10.w),
                        Text(
                          formatTimeFromDate(booking.startTime),
                          style: AppTextStyles.font16Bold.copyWith(
                            color: AppColors.fontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Image.asset(
                          Assets.imagesPngImageCalendar,
                          fit: BoxFit.cover,
                        ),
                        WidthSpace(10.w),
                        Text(
                          formatDateFromDate(booking.date),
                          style: AppTextStyles.font16Bold.copyWith(
                            color: AppColors.fontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            HeightSpace(12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                WidthSpace(12.w),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "السعر : ${booking.serviceAmount} دينار",
                      style: AppTextStyles.font18Bold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            HeightSpace(12.h),
          ],
        ),
      ),
    );
  }

  String formatTimeFromDate(DateTime time) {
    return DateFormat.jm('ar').format(time); // "8:00 م"
  }

  String formatDateFromDate(DateTime date) {
    return DateFormat.yMMMMd('ar').format(date);
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'قيد الانتظار';
      case 1:
        return 'قيد المعالجة';
      case 2:
        return 'موافَق عليه';
      case 3:
        return 'ملغي';
      case 4:
        return 'مكتمل';
      default:
        return 'غير معروف';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.deepOrange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
