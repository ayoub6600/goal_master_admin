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
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 4,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "تفاصيل الحجز",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.error),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 24),

              // Customer Info Section
              _buildSectionHeader(context, "معلومات العميل"),
              _buildInfoRow("👤", "الاسم الكامل", customer.fullName),
              _buildInfoRow("📞", "رقم الهاتف", customer.phoneNo),
              const SizedBox(height: 20),

              // Booking Details Section
              _buildSectionHeader(context, "تفاصيل الحجز"),
              _buildInfoRow(
                  "🕐",
                  "وقت البدء",
                  DateFormat('hh:mm a', 'ar')
                      .format(DateTime.parse(booking.startTime))),
              _buildInfoRow(
                  "🕔",
                  "وقت الانتهاء",
                  DateFormat('hh:mm a', 'ar')
                      .format(DateTime.parse(booking.endTime))),
              const SizedBox(height: 20),

              // Service Details Section
              _buildSectionHeader(context, "تفاصيل الخدمة"),
              _buildInfoRow("🏟", "الخدمة", service.title),
              _buildInfoRow("📂", "الفئة", service.category.name),
              _buildInfoRow("🏢", "الفرع", branch.name),
              const SizedBox(height: 20),

              // Payment Section
              _buildSectionHeader(context, "المعلومات المالية"),
              _buildInfoRow(
                  "💰", "المبلغ المسموح", "${item.allowedAmount} دينار"),
              const SizedBox(height: 20),

              // Metadata Section
              _buildSectionHeader(context, "معلومات إضافية"),
              _buildInfoRow(
                  "📅",
                  "تاريخ الإنشاء",
                  DateFormat('yyyy/MM/dd - hh:mm a', 'ar')
                      .format(DateTime.parse(item.createdAt))),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.font14Bold.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.font14Bold,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
