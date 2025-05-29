import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        //  if (booking.status == 3)
                        Row(
                          children: [
                            DepositBookingButton(bookingDetails: booking),
                          ],
                        ),
                        HeightSpace(16.h),
                        Row(
                          children: [
                            if (booking.status != 3)
                              CancelBookingButton(
                                id: booking.id,
                              ),
                            WidthSpace(8.w),
                            UpdateBookingStatusView(
                              id: booking.id,
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
