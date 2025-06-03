import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/home/presentation/manager/analysis_cubit/analysis_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/home_view_body.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/items_show_analysis.dart';

class AnalysisView extends StatelessWidget {
  const AnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalysisCubit, AnalysisState>(
      builder: (context, state) {
        if (state is AnalysisLoading) {
          return const ScimagLoading(itemCount: 4, crossAxisCount: 2);
        } else if (state is AnalysisError) {
          return Center(child: Text('حدث خطأ: ${state.message}'));
        } else if (state is AnalysisLoaded) {
          final todayBookings = state.analysis.data.bookingStatus.totalBooking;

          if (todayBookings.isEmpty) {
            return const Center(child: Text("لا توجد بيانات متاحة"));
          }

          final totalServices = todayBookings.fold<int>(
              0, (sum, item) => sum + item.serviceCount);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayBookings.length,
            padding: EdgeInsets.only(left: 6, right: 6, bottom: 40),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              final booking = todayBookings[index];
              final percent = totalServices > 0
                  ? booking.serviceCount / totalServices
                  : 0.0;
              final color = _getStatusColor(booking.status);

              return ItemsShowAnalysis(
                title: booking.statusText,
                count: booking.serviceCount,
                percent: percent,
                color: color,
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
