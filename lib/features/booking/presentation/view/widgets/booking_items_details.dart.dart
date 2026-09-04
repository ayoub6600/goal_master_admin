import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/data/model/booking_details.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/%20booking_details_cubit/booking_details_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/%20booking_details_cubit/booking_details_state.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/build_details_section.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/build_header_image.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/cancel_booking_button.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/deposit_booking_button.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/reschedule_booking_sheet.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/update_booking_status_view.dart';
import 'package:goal_master_admin/features/monthly_booking/data/repo/monthly_booking_repo_imp.dart';

class BookingItemsDetails extends StatefulWidget {
  const BookingItemsDetails({super.key});

  @override
  State<BookingItemsDetails> createState() => _BookingItemsDetailsState();
}

class _BookingItemsDetailsState extends State<BookingItemsDetails> {
  /// Only a booking still ahead of it can sensibly be moved. Status alone is
  /// not enough: a played session stays "Approved" until a manager marks
  /// attendance, so [BookingDetails.hasElapsed] is what actually rules out an
  /// already-finished session.
  bool _canReschedule(BookingDetails booking) =>
      (booking.status == 1 || booking.status == 2) && !booking.hasElapsed;

  Future<void> _openReschedule(
    BuildContext context,
    BookingDetails booking,
  ) async {
    final bookingRepo = getIt<BookingRepoImp>();
    final monthlyRepo = getIt<MonthlyBookingRepoImp>();
    final start = DateTime(
      booking.date.year,
      booking.date.month,
      booking.date.day,
      int.tryParse(booking.startTime.split(':')[0]) ?? 0,
      int.tryParse(booking.startTime.split(':')[1]) ?? 0,
    );
    final endParts = booking.endTime.split(':');
    final end = DateTime(
      booking.date.year,
      booking.date.month,
      booking.date.day,
      int.tryParse(endParts[0]) ?? 0,
      int.tryParse(endParts.length > 1 ? endParts[1] : '0') ?? 0,
    );

    await RescheduleBookingSheet.show(
      context,
      currentStart: start,
      currentEnd: end,
      loadSlots: (operationalDate) async {
        final result = await bookingRepo.listNightSlots(
          branchId: booking.branchId,
          serviceId: booking.serviceId,
          operationalDate: operationalDate,
        );

        return result.fold(
          (failure) => throw Exception(failure.errMessage),
          (night) => night.slots,
        );
      },
      onConfirm: (newStart, newEnd) async {
        String two(int v) => v.toString().padLeft(2, '0');

        final result = await monthlyRepo.rescheduleOccurrence(
          bookingId: booking.id,
          branchId: booking.branchId,
          customerId: booking.cmnCustomerId,
          employeeId: booking.employeeId,
          serviceId: booking.serviceId,
          paymentTypeId: booking.paymentTypeId,
          status: booking.status,
          paidAmount: double.tryParse(booking.paidAmount) ?? 0,
          serviceDate:
              '${newStart.year}-${two(newStart.month)}-${two(newStart.day)}',
          serviceTime:
              '${two(newStart.hour)}:${two(newStart.minute)}-'
              '${two(newEnd.hour)}:${two(newEnd.minute)}',
          remarks: booking.remarks,
        );

        return result.fold(
          (failure) => failure.errMessage,
          (_) {
            showCustomSuccessToast('تم تعديل الموعد.');
            if (context.mounted) {
              context.read<BookingDetailsCubit>().getBookingInfo();
            }
            return null;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<BookingDetailsCubit, BookingDetailsState>(
          builder: (context, state) {
            if (state is BookingDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BookingDetailsError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            if (state is BookingDetailsSuccess) {
              final booking = state.bookingDetails;
              final isApprovalFlow = booking.status == 1;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const BuildHeaderImage(),
                          BuildDetailsSection(
                            booking: booking,
                            onEditTime: _canReschedule(booking)
                                ? () => _openReschedule(context, booking)
                                : null,
                            onDisputeProposed: () => context
                                .read<BookingDetailsCubit>()
                                .getBookingInfo(),
                            onCustomerBlockChanged: () => context
                                .read<BookingDetailsCubit>()
                                .getBookingInfo(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (booking.paymentType == 1) ...[
                    HeightSpace(8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Text(
                        'العميل يريد الدفع عند الوصول',
                        style: AppTextStyles.font14Regular
                            .copyWith(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                  booking.status == 4 || booking.status == 3
                      ? const Divider()
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              booking.status != 1
                                  ? Row(
                                      children: [
                                        DepositBookingButton(
                                            bookingDetails: booking),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                              HeightSpace(16.h),
                              Row(
                                children: [
                                  if (booking.status != 3)
                                    CancelBookingButton(
                                      id: booking.id,
                                      isApprovalFlow: isApprovalFlow,
                                    ),
                                  WidthSpace(8.w),
                                  UpdateBookingStatusView(
                                    id: booking.id,
                                    isApprovalFlow: isApprovalFlow,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ],
              );
            }

            return const Center(child: Text('No Data'));
          },
        ),
      ),
    );
  }
}
