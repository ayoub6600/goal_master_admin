import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/errors/failure.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
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

              final rows = _group(items);

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final showDue = widget.kind == BookingDrilldownKind.due;

                  // A recurring booking is ONE payment split across four
                  // sessions, so it is one row. Listing the sessions
                  // separately made a single 264 د.ل booking read as four.
                  return row.length > 1
                      ? _MonthlySeriesCard(sessions: row, showDue: showDue)
                      : _BookingDrilldownCard(
                          item: row.first, showDue: showDue);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Folds sessions of the same recurring booking together, preserving the
  /// order the server sent and the position of the first session in it.
  List<List<BookingDrilldownItem>> _group(List<BookingDrilldownItem> items) {
    final rows = <List<BookingDrilldownItem>>[];
    final seriesRow = <int, int>{};

    for (final item in items) {
      final seriesId = item.seriesId;
      if (seriesId == null) {
        rows.add([item]);
        continue;
      }

      final existing = seriesRow[seriesId];
      if (existing == null) {
        seriesRow[seriesId] = rows.length;
        rows.add([item]);
      } else {
        rows[existing].add(item);
      }
    }

    for (final row in rows) {
      if (row.length > 1) {
        row.sort((a, b) => a.seriesSequence.compareTo(b.seriesSequence));
      }
    }

    return rows;
  }
}

/// One recurring booking: a single card that opens to its sessions.
///
/// Collapsed by default because the venue's question at this level is "who
/// paid, and how much" — one answer per booking. The sessions are one tap
/// away for anyone who wants the dates.
class _MonthlySeriesCard extends StatefulWidget {
  const _MonthlySeriesCard({required this.sessions, required this.showDue});

  final List<BookingDrilldownItem> sessions;
  final bool showDue;

  @override
  State<_MonthlySeriesCard> createState() => _MonthlySeriesCardState();
}

class _MonthlySeriesCardState extends State<_MonthlySeriesCard> {
  bool _open = false;

  BookingDrilldownItem get _first => widget.sessions.first;

  double get _total => widget.showDue
      ? widget.sessions.fold(0.0, (sum, s) => sum + s.dueAmount)
      : widget.sessions.fold(0.0, (sum, s) => sum + s.paidAmount);

  double get _gross =>
      widget.sessions.fold(0.0, (sum, s) => sum + s.serviceAmount);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_repeat,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'حجز شهري',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.sessions.length} مواعيد',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                      Icon(
                        _open ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _first.customerName.isEmpty
                        ? 'بدون اسم'
                        : _first.customerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (_first.customerPhone.isNotEmpty)
                    Text(_first.customerPhone,
                        style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text('${_first.serviceTitle} — ${_first.branchName}',
                      style: TextStyle(color: Colors.grey.shade700)),
                  Text(
                    'كل ${arabicWeekday(_first.displayDate)} '
                    'الساعة ${arabicTime(_first.displayStartTime)}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  Text(
                    'من ${arabicShortDate(_first.displayDate)} '
                    'إلى ${arabicDateWithYear(widget.sessions.last.displayDate)}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.showDue
                        ? 'المستحق: ${_total.toStringAsFixed(2)}'
                        : 'المدفوع: ${_total.toStringAsFixed(2)} / '
                            '${_gross.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.showDue
                          ? const Color(0xFFBA4A00)
                          : const Color(0xFF367C82),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade300),
                  ...widget.sessions.map(
                    (session) => _SessionRow(
                      session: session,
                      showDue: widget.showDue,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.showDue});

  final BookingDrilldownItem session;
  final bool showDue;

  @override
  Widget build(BuildContext context) {
    final amount = showDue ? session.dueAmount : session.paidAmount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              '${session.seriesSequence}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabicDayAndDate(session.displayDate),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  arabicTime(session.displayStartTime),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color:
                  showDue ? const Color(0xFFBA4A00) : const Color(0xFF367C82),
            ),
          ),
          const SizedBox(width: 6),
          Text('#${session.id}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
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
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text('#${item.id}',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          if (item.customerPhone.isNotEmpty)
            Text(item.customerPhone,
                style: TextStyle(color: Colors.grey.shade700)),
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF367C82)),
            ),
        ],
      ),
    );
  }
}
