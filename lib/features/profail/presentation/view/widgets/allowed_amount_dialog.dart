import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/profail/data/model/allowed_amount_response.dart';
import 'package:intl/intl.dart';

class AllowedAmountDialog extends StatelessWidget {
  final AllowedAmountData item;

  const AllowedAmountDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final booking = item.booking;
    final customer = booking.customer;
    final service = booking.service;
    final branch = booking.branch;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("تفاصيل الحجز",
                      style: Theme.of(context).textTheme.titleLarge),
                  GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: Colors.red,
                      )),
                ],
              ),
              const Divider(height: 20),
              Text(
                "👤 العميل: ${customer.fullName}",
                style: AppTextStyles.font14Bold,
              ),
              HeightSpace(10),
              Text(
                "📞 رقم الهاتف: ${customer.phoneNo}",
                style: AppTextStyles.font14Bold,
              ),
              HeightSpace(10),
              Text(
                "🕐 وقت البدء: ${DateFormat('hh:mm a', 'ar').format(DateTime.parse(booking.startTime))}",
                style: AppTextStyles.font14Bold,
              ),
              HeightSpace(10),
              Text(
                "🕔 وقت الانتهاء: ${DateFormat('hh:mm a', 'ar').format(DateTime.parse(booking.endTime))}",
                style: AppTextStyles.font14Bold,
              ),
              HeightSpace(10),
              Text(
                "🏟 الخدمة: ${service.title}",
                style: AppTextStyles.font14Bold,
              ),
              HeightSpace(10),
              Text(
                "📂 الفئة: ${service.category.name}",
                style: AppTextStyles.font14Bold,
              ),
              HeightSpace(10),
              Text(
                "🏢 الفرع: ${branch.name}",
                style: AppTextStyles.font14Bold,
              ),
              HeightSpace(10),
              Text(
                "💰 المبلغ المسموح: ${item.allowedAmount} دينار",
                style: AppTextStyles.font14Bold,
              ),
              HeightSpace(10),
              Text(
                "📅 تاريخ الإنشاء: ${DateFormat('yyyy/MM/dd – hh:mm a', 'ar').format(DateTime.parse(item.createdAt))}",
                style: AppTextStyles.font14Bold,
              ),
              HeightSpace(10),
            ],
          ),
        ),
      ),
    );
  }
}
