import 'package:flutter/material.dart';
import 'package:goal_master_admin/features/home/presentation/manager/analysis_cubit/analysis_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/home_view_body.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeViewBody();
  }
}

class AnalysisView extends StatelessWidget {
  const AnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalysisCubit, AnalysisState>(
      builder: (context, state) {
        if (state is AnalysisLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is AnalysisError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is AnalysisLoaded) {
          final data = state.analysis.data;
          final todayBookings = data?.bookingStatus?.todayBooking ?? [];
          final topServices = data?.topService ?? [];
          final paidBy = data?.incomAndOtherStatistics?.todayPaidBy ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('📅 Today\'s Bookings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...todayBookings.map((e) => ListTile(
                    title: Text(e.statusText ?? ''),
                    trailing: Text(e.serviceCount.toString()),
                  )),
              const SizedBox(height: 16),
              const Text('🔥 Top Services',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...topServices.map((e) => ListTile(
                    title: Text(e.title ?? ''),
                    trailing: Text('Count: ${e.serviceCount}'),
                  )),
              const SizedBox(height: 16),
              const Text('💰 Payments by Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ...paidBy.map((e) => ListTile(
                    title: Text(e.paymentBy ?? ''),
                    trailing: Text('${e.paidAmount} ر.س'),
                  )),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
