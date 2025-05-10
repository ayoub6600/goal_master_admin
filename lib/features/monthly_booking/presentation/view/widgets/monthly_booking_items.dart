import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';

class MonthlyBookingItems extends StatelessWidget {
  const MonthlyBookingItems({super.key, required this.booking});
  final MonthlyBookingResponse booking;
  @override
  Widget build(BuildContext context) {
    return Card(
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
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('ID: ${booking.id}',
                    style: const TextStyle(color: Colors.grey)),
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
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(
                        '${booking.date} | ${booking.startTime} - ${booking.endTime}',
                        style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 8),

            // المبالغ
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'الإجمالي: ${booking.totalAmount} - المدفوع: ${booking.paidAmount} - الباقي: ${booking.dueAmount}',
                    style: const TextStyle(fontSize: 14),
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
                Chip(
                  label: Text(booking.isMonthly == 1 ? 'شهري' : 'غير شهري'),
                  backgroundColor: booking.isMonthly == 1
                      ? Colors.green.shade100
                      : Colors.grey.shade300,
                ),
                const SizedBox(width: 8),
                Chip(
                  label:
                      Text(booking.isMonthlyActive == 1 ? 'مفعل' : 'غير مفعل'),
                  backgroundColor: booking.isMonthlyActive == 1
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // زر التحديث
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  // context.read<MonthlyBookingCubit>().updateBooking(
                  //       id: booking.id.toString(),
                  //       serviceDate: booking.date,
                  //     );
                },
                icon: const Icon(Icons.update),
                label: const Text('تحديث'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
