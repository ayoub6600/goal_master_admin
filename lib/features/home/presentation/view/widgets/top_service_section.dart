import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/features/home/data/model/dash_board_response.dart';

class TopServiceSection extends StatelessWidget {
  final List<TopService> topServices;

  const TopServiceSection({
    super.key,
    required this.topServices,
  });

  @override
  Widget build(BuildContext context) {
    if (topServices.isEmpty) {
      return const Text("لا توجد خدمات حالياً");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "الأنشطة الأكثر طلبًا",
            style: AppTextStyles.font18Bold.copyWith(color: AppColors.black),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            scrollDirection: Axis.horizontal,
            itemCount: topServices.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final service = topServices[index];
              return Card(
                color: Colors.grey[200],
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child:
                            Icon(Icons.sports_soccer, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              service.title,
                              style: AppTextStyles.font20Bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${service.serviceCount} حجز",
                              style: AppTextStyles.font18Bold
                                  .copyWith(color: AppColors.dark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
