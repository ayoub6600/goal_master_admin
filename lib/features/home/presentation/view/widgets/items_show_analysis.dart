import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ItemsShowAnalysis extends StatelessWidget {
  final String title;
  final int count;
  final double percent;
  final Color color;

  const ItemsShowAnalysis({
    super.key,
    required this.title,
    required this.count,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // حل مشكلة overflow
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              style: AppTextStyles.font16Medium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          CircularPercentIndicator(
            radius: 36.0,
            lineWidth: 6.0,
            percent: percent.clamp(0.0, 1.0),
            center: Text(
              count.toString(),
              style: AppTextStyles.font16Medium,
            ),
            progressColor: color,
            backgroundColor: Colors.grey.shade300,
            animation: true,
            animationDuration: 600,
          ),
        ],
      ),
    );
  }
}
