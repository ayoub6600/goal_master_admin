import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/home/data/model/dash_board_response.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ItemsHomeViewList extends StatelessWidget {
  const ItemsHomeViewList(
      {super.key, required this.title, required this.bookingInfo});
  final String title;
  final BookingInfo bookingInfo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                "إجمالي ${bookingInfo.statusText}",
                style: AppTextStyles.font16Medium.copyWith(
                  color: AppColors.primary,
                ),
              ),
              HeightSpace(30),
              Row(
                children: [
                  CircleAvatar(
                    radius: 5, // Half of the dot's diameter
                    backgroundColor: AppColors.primary, // Dot color
                  ),
                  WidthSpace(20),
                  Text(
                    "العدد",
                    style: AppTextStyles.font16Medium.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  WidthSpace(20),
                  Text(
                    bookingInfo.serviceCount.toString(),
                    style: AppTextStyles.font16Medium.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
          CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 8.0,
            percent: 0.3,
            center: new Text("100%"),
            progressColor: Color(0xffff9378),
          ),
        ],
      ),
    );
  }
}
