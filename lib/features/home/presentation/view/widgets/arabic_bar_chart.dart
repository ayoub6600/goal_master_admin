import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';

class ArabicBarChart extends StatelessWidget {
  const ArabicBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xfff5f7fa),
        borderRadius: BorderRadius.circular(12),
      ),
      height: MediaQuery.of(context).size.height * 0.3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 800,
            barGroups: [
              _buildBar(0, 150, Colors.green), // المدفوع عبر الإنترنت
              _buildBar(1, 350, Colors.blue), // المدفوع نقدًا
              _buildBar(2, 800, Colors.red), // المستحق
              _buildBar(3, 600, Colors.amber), // الدخل
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 100, // Label steps
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  interval: 1,
                  showTitles: true,
                  reservedSize: 80,
                  getTitlesWidget: (value, meta) {
                    List<String> labels = [
                      "إجمالي الدخل",
                      "إجمالي المستحق",
                      "إجمالي المدفوع نقدًا",
                      "إجمالي المدفوع عبر الإنترنت",
                    ];
                    return Container(
                      width: 60,
                      //    height: 80,
                      //  padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        labels[value.toInt()],
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font12Regular,
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(show: true, drawHorizontalLine: true),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 30,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
