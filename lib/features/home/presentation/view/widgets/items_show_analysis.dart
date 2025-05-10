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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: AppTextStyles.font16Medium),
          const SizedBox(height: 12),
          CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 8.0,
            percent: percent.clamp(0.0, 1.0),
            center: Text(count.toString()),
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
