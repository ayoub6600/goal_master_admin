import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';

import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/%20booking_details_cubit/booking_details_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/%20booking_details_cubit/booking_details_state.dart';

import 'package:goal_master_admin/features/booking/presentation/view/widgets/build_details_section.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/build_header_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/cancel_booking_button.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/deposit_booking_button.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/update_booking_status_view.dart';

class BookingItemsDetails extends StatelessWidget {
  const BookingItemsDetails({super.key});

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
