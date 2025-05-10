import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/profail/data/model/allowed_amount_response.dart';
import 'package:goal_master_admin/features/profail/presentation/view/customer_view.dart';
import 'package:goal_master_admin/features/profail/presentation/view/widgets/allowed_amount_dialog.dart';

class AllowedAmountCard extends StatelessWidget {
  final AllowedAmountData item;

  const AllowedAmountCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final booking = item.booking;
    final customer = booking.customer;
    final service = booking.service;
    final branch = booking.branch;

    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AllowedAmountDialog(item: item),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blueAccent,
              child: Text(
                customer.fullName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.fullName, style: AppTextStyles.font18Bold),
                  HeightSpace(10),
                  GestureDetector(
                    onTap: () => launchPhoneCall(customer.phoneNo),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.black54,
                        ),
                        WidthSpace(8),
                        Text(customer.phoneNo,
                            style: AppTextStyles.font14SemiBold),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "💰 ${item.allowedAmount} ر.س",
                        style: AppTextStyles.font14SemiBold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
