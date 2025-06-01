import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_date_picker.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/monthly_booking_cubit/monthly_booking_cubit.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/udate_monthly_booking_cubit/udate_monthly_booking_cubit.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/udate_monthly_booking_cubit/udate_monthly_booking_state.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/time_formatter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:intl/intl.dart';

class MonthlyBookingItems extends StatelessWidget {
  const MonthlyBookingItems({super.key, required this.booking});
  final MonthlyBookingResponse booking;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[200],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان + ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الفرع: ${booking.branchName}',
                    style: AppTextStyles.font16Regular),
                Text('ID: ${booking.id}',
                    style: AppTextStyles.font20Regular
                        .copyWith(color: AppColors.black)),
              ],
            ),
            const SizedBox(height: 12),

            // معلومات العميل مع صورة
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            Assets.imagesPngImageProfailIcon,
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'العميل: ${booking.customer.fullName}',
                                style: AppTextStyles.font20Regular,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // التواريخ والأوقات
            Row(
              children: [
                Image.asset(
                  Assets.imagesPngImageCalendar,
                  height: 16,
                  width: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(
                        '${booking.date} | ${booking.startTime} - ${booking.endTime}',
                        style: AppTextStyles.font14Regular)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Image.asset(
                  Assets.imagesPngImageClock,
                  height: 16,
                  width: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TimeFormatter(
                      startTime: booking.startTime, endTime: booking.endTime),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // المبالغ
            Row(
              children: [
                Image.asset(
                  Assets.imagesPngImageEmptyWalletTime,
                  height: 16,
                  width: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'الإجمالي: ${booking.totalAmount} - المدفوع: ${booking.paidAmount} \nالباقي: ${booking.dueAmount} د.ل',
                    style: AppTextStyles.font14Regular,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // كود الخصم
            if (booking.couponCode != null && booking.couponCode!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.discount, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                      'كود الخصم: ${booking.couponCode} | ${booking.couponDiscount} د.ل'),
                ],
              ),
            const SizedBox(height: 8),

            // الحجز الشهري وتفعيله
            Row(
              children: [
                Expanded(
                  child: Chip(
                    label: Text(booking.isMonthly == 1 ? 'شهري' : 'غير شهري'),
                    backgroundColor: booking.isMonthly == 1
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Chip(
                    label: Text(
                        booking.isMonthlyActive == 1 ? 'مفعل' : 'غير مفعل'),
                    backgroundColor: booking.isMonthlyActive == 1
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BlocConsumer<UpdateMonthlyBooking, UpdateMonthlyBookingState>(
              listener: (context, state) {
                if (state is UpdateMonthlyBookingSuccess) {
                  showCustomSuccessToast(state.message);
                } else if (state is UpdateMonthlyBookingFailure) {
                  showCustomFailureToast(state.error);
                }
              },
              builder: (context, state) {
                return ButtonApp(
                  text: "تفعيل الحجز",
                  onTap: () {
                    DateTime? pickedDate;
                    final dateController = TextEditingController();

                    baseBottomSheet(
                      title: "تحديد تاريخ جديد",
                      context: context,
                      hideNavBar: false,
                      child: Column(
                        children: [
                          CustomDatePicker(
                            initialDate: pickedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 3650)),
                            onDatePicked: (value) {
                              if (value != null) {
                                pickedDate = value;
                                dateController.text = DateFormat('yyyy-MM-dd')
                                    .format(pickedDate!);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          ButtonApp(
                            text: state is UpdateMonthlyBookingLoading
                                ? "الرجاء الانتظار"
                                : "تأكيد التفعيل",
                            onTap: () {
                              if (pickedDate == null) {
                                showCustomFailureToast(
                                    "يرجى اختيار التاريخ أولًا");
                                return;
                              }

                              final formattedDate =
                                  DateFormat('yyyy-MM-dd').format(pickedDate!);

                              context
                                  .read<UpdateMonthlyBooking>()
                                  .updateMonthlyBooking(
                                    id: booking.id.toString(),
                                    serviceDate: formattedDate,
                                  );

                              Navigator.pop(context); // إغلاق الشيت بعد التحديث
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
