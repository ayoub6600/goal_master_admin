import 'package:flutter/material.dart';

import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';

class BuildTitleRow extends StatelessWidget {
  const BuildTitleRow({
    super.key,
    required this.booking,
  });
  final BookingDetails booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          booking.branch,
          style: AppTextStyles.font20Bold.copyWith(
            color: Color(0xff204523),
          ),
        ),
        Spacer(),
        //rating widget
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            StatusContainer(
              status: booking.status,
              booking: booking,
            )
          ],
        ),
      ],
    );
  }
}

class StatusContainer extends StatelessWidget {
  final int status;
  final BookingDetails booking;

  const StatusContainer(
      {super.key, required this.status, required this.booking});

  @override
  Widget build(BuildContext context) {
    Color containerColor;

    switch (status) {
      case 0:
        containerColor = Colors.orange; // Pending

        break;
      case 1:
        containerColor = Colors.blue; // Processing

        break;
      case 2:
        containerColor = Colors.green; // Approved

        break;
      case 3:
        containerColor = Colors.red; // Cancel

        break;
      case 4:
        containerColor = Colors.grey; // Done

        break;
      default:
        containerColor = Colors.black; // Default color
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          booking.statusName,
          //  "في إنتظار قبول الطلب",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
