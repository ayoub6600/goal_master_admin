import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/format_time.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_booking_cubit/add_booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/employee_cubit/employee_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/choose_payment.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/event_card.dart';
import 'package:goal_master_admin/features/home/data/model/booking_slots_response.dart';
import 'package:goal_master_admin/features/home/presentation/manager/page_view_new_booking_cubit/page_view_new_booking_cubit.dart';
import 'package:goal_master_admin/features/home/presentation/view/widgets/employee_selection_new.dart';

import '../../../../../core/components/button_app.dart';

class BookingItem extends StatelessWidget {
  const BookingItem({super.key, required this.booking});
  final BookingSlot booking;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xfff5f7fa),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        color: Color(0xfff5f7fa),
        child: Row(
          children: [
            WidthSpace(8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "${booking.serviceTitle}" "( ${booking.club} )",
                    style: AppTextStyles.font16Bold,
                  ),
                  HeightSpace(8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.watch_later_outlined,
                              color: AppColors.primary,
                            ),
                            WidthSpace(8.w),
                            Text(
                              "${formatTime(booking.startTime)} - ${formatTime(booking.endTime)}",
                              textDirection: TextDirection.ltr,
                              style: AppTextStyles.font14Bold.copyWith(
                                color: AppColors.fontColor,
                              ),
                            ),
                          ]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            Assets.imagesPngImageCalendar,
                            color: AppColors.primary,
                          ),
                          WidthSpace(8.w),
                          Text(
                            "${booking.date}",
                            style: AppTextStyles.font14Bold.copyWith(
                              color: AppColors.fontColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  HeightSpace(16.h),
                  ButtonApp(
                      text: "حجز",
                      onTap: () {
                        push(RoutesKeys.kAddNewBooking, context,
                            extra: booking);
                      })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddNewBooking extends StatefulWidget {
  const AddNewBooking({super.key, required this.booking});
  final BookingSlot booking;

  @override
  State<AddNewBooking> createState() => _AddNewBookingState();
}

class _AddNewBookingState extends State<AddNewBooking> {
  final PageController _controller = PageController();
  @override
  void initState() {
    context.read<EmployeeCubit>().listEmployee(widget.booking.clubId);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pageViewCubit = context.read<PageViewNewBookingCubit>();

    return Stack(
      children: [
        PageWrapper(
          title: "إضافة الحجز",
          allowBack: false,
          child: BlocBuilder<PageViewNewBookingCubit, PageViewNewBookingState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        EmployeeSelectionNew(controller: _controller),
                        ChoosePayment(controller: _controller),
                      ],
                    ),
                  ),
                  if (state.currentPage > 0)
                    EventCard(
                      date: widget.booking.date,
                      startTime: widget.booking.startTime,
                      endTime: widget.booking.endTime,
                      categoryName: widget.booking.categoryName,
                      serviceTitle: widget.booking.serviceTitle,
                    ),
                  if (state.currentPage > 0)
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: ButtonApp(
                              backGround: AppColors.grey,
                              text: "رجوع",
                              onTap: () {
                                pageViewCubit.previousPage();
                                _controller.previousPage(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.ease,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 8.w),

                          //  if (state.currentPage == 2)
                          BlocConsumer<AddBookingCubit, AddBookingState>(
                            listener: (context, state) {
                              if (state is AddBookingSuccess) {
                                showCustomSuccessToast("تم اضافة الحجز بنجاح");
                                pushReplacement(RoutesKeys.kHome, context);
                              } else if (state is AddBookingFailure) {
                                showCustomFailureToast(state.massage);
                              }
                            },
                            builder: (context, state) {
                              return Expanded(
                                child: ButtonApp(
                                  text: "تأكيد الحجز",
                                  onTap: () {
                                    print(
                                        "employeeId ${pageViewCubit.state.employeeId} serviceId ${widget.booking.serviceId} zoneId ${pageViewCubit.state.zoneId} clubId ${widget.booking.clubId} date ${widget.booking.date} startTime ${widget.booking.startTime} endTime ${widget.booking.endTime}");
                                    // context.read<AddBookingCubit>().addBooking(

                                    //       customerId: 0,
                                    //       employeeId:
                                    //           pageViewCubit.state.employeeId ??
                                    //               0,
                                    //       serviceId: widget.booking.serviceId,
                                    //       date: widget.booking.date,
                                    //       startTime: widget.booking.startTime,
                                    //       endTime: widget.booking.endTime,
                                    //     );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        BlocBuilder<AddBookingCubit, AddBookingState>(
          builder: (context, state) {
            if (state is AddBookingLoading) {
              return Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
