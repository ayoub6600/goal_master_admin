import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/home/data/model/booking_drilldown_item.dart';

enum BookingDrilldownKind { paidOnline, paidCash, due }

class BookingDrilldownView extends StatefulWidget {
  final String title;
  final BookingDrilldownKind kind;

  const BookingDrilldownView({
    super.key,
    required this.title,
    required this.kind,
  });

  @override
  State<BookingDrilldownView> createState() => _BookingDrilldownViewState();
}

class _BookingDrilldownViewState extends State<BookingDrilldownView> {
  late Future<Either<Failure, List<BookingDrilldownItem>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<Either<Failure, List<BookingDrilldownItem>>> _fetch() {
    final repo = getIt<BookingRepoImp>();
    switch (widget.kind) {
      case BookingDrilldownKind.paidOnline:
        return repo.getPaidBookings('online');
      case BookingDrilldownKind.paidCash:
        return repo.getPaidBookings('cash');
      case BookingDrilldownKind.due:
        return repo.getDueBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: widget.title,
      allowBack: true,
      child: FutureBuilder<Either<Failure, List<BookingDrilldownItem>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final result = snapshot.data;
          if (result == null) {
            return const Center(child: Text('حدث خطأ غير متوقع'));
          }

          return result.fold(
            (failure) => Center(child: Text(failure.errMessage)),
            (items) {
              if (items.isEmpty) {
                return const Center(child: Text('لا توجد بيانات لعرضها'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _BookingDrilldownCard(
                      item: item, showDue: widget.kind == BookingDrilldownKind.due);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingDrilldownCard extends StatelessWidget {
  final BookingDrilldownItem item;
  final bool showDue;

  const _BookingDrilldownCard({required this.item, required this.showDue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.customerName.isEmpty ? 'بدون اسم' : item.customerName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('#${item.id}', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          if (item.customerPhone.isNotEmpty)
            Text(item.customerPhone, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text('${item.serviceTitle} — ${item.branchName}',
              style: TextStyle(color: Colors.grey.shade700)),
          Text('${item.date} ${item.startTime}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 8),
          if (showDue)
            Text(
              'المستحق: ${item.dueAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFFBA4A00)),
            )
          else
            Text(
              'المدفوع: ${item.paidAmount.toStringAsFixed(2)} / ${item.serviceAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF367C82)),
            ),
        ],
      ),
    );
  }
}
