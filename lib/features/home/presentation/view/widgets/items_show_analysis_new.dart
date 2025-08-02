import 'package:flutter/material.dart';

class ItemsShowAnalysisNew extends StatelessWidget {
  final String title;
  final num count;
  final Color color;
  final double percent;

  const ItemsShowAnalysisNew({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    this.percent = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 120),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
