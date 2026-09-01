import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/features/booking/data/model/operational_slot.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/monthly_booking_cubit/monthly_booking_cubit.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/reschedule_occurrence_sheet.dart';

/// Opens the reschedule sheet with the real repositories behind it.
///
/// Kept apart from the sheet itself so the sheet can be pumped in a test
/// against fakes — the sheet decides nothing, it only shows what the server
/// says and sends back what the manager picked.
void openReschedule({
  required BuildContext context,
  required MonthlySeriesGroup group,
  required MonthlyBookingResponse occurrence,
  required DateTime now,
}) {
  final listCubit = context.read<MonthlyBookingCubit>();
  final bookingRepo = getIt<BookingRepoImp>();

  baseBottomSheet(
    title: 'تعديل هذا الموعد',
    context: context,
    hideNavBar: false,
    child: RescheduleOccurrenceSheet(
      group: group,
      occurrence: occurrence,
      now: now,
      loadSlots: (operationalDate) async {
        final result = await bookingRepo.listNightSlots(
          branchId: occurrence.branchId,
          serviceId: occurrence.serviceId,
          operationalDate: operationalDate,
        );

        return result.fold(
          (failure) => throw Exception(failure.errMessage),
          (night) => night.slots,
        );
      },
      onConfirm: (start, end) async {
        String two(int v) => v.toString().padLeft(2, '0');

        final result = await listCubit.bookingRepo.rescheduleOccurrence(
          bookingId: occurrence.bookingId,
          branchId: occurrence.branchId,
          customerId: occurrence.customerId,
          employeeId: occurrence.employeeId,
          serviceId: occurrence.serviceId,
          paymentTypeId: occurrence.paymentTypeId,
          status: occurrence.bookingStatus,
          // Replayed unchanged — moving a time is not a payment.
          paidAmount: occurrence.occurrencePaidAmount > 0
              ? occurrence.occurrencePaidAmount
              : occurrence.paidAmount,
          serviceDate:
              '${start.year}-${two(start.month)}-${two(start.day)}',
          serviceTime:
              '${two(start.hour)}:${two(start.minute)}-'
              '${two(end.hour)}:${two(end.minute)}',
          remarks: occurrence.bookingRemarks,
        );

        return result.fold(
          (failure) => failure.errMessage,
          (_) {
            showCustomSuccessToast('تم تعديل الموعد.');
            listCubit.refresh();
            return null;
          },
        );
      },
    ),
  );
}

/// Re-exported so callers do not need the slot model directly.
typedef SlotLoader = Future<List<OperationalSlot>> Function(String date);
