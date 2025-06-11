import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_booking_cubit/add_booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/calendar_cubit/calendar_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/page_view_cubit/page_view_cubit_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/category_selection.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/choose_payment.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/club_selection.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/employee_selection.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/event_card.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/service_selection.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/time_slot_section.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/zone_selection.dart';

import 'package:intl/intl.dart';
import 'widgets/custom_calder.dart';

class AddBookingView extends StatefulWidget {
  const AddBookingView({super.key});

  @override
  State<AddBookingView> createState() => _AddBookingViewState();
}

class _AddBookingViewState extends State<AddBookingView> {
  final PageController _controller = PageController();
  bool _isMonthly = false;

  @override
  Widget build(BuildContext context) {
    final pageViewCubit = context.read<PageViewCubit>();

    return Stack(
      children: [
        PageWrapper(
          title: "إضافة الحجز",
          allowBack: false,
          child: BlocBuilder<PageViewCubit, PageViewState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        ZoneSelection(controller: _controller),
                        ClubSelection(controller: _controller),
                        CategorySelection(controller: _controller),
                        ServiceSelection(controller: _controller),
                        EmployeeSelection(controller: _controller),
                        CustomCalder(controller: _controller),
                        TimeSlotSection(controller: _controller),
                        ChoosePayment(controller: _controller),
                      ],
                    ),
                  ),

                  /// سويتش تحديد إن كان الحجز شهريًا
                  if (state.currentPage == 7)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "هل الحجز شهري؟",
                            style: TextStyle(fontSize: 16),
                          ),
                          Switch(
                            value: _isMonthly,
                            onChanged: (val) {
                              setState(() {
                                _isMonthly = val;
                              });
                              context.read<AddBookingCubit>().setIsMonthly(val);
                            },
                          ),
                        ],
                      ),
                    ),

                  if (state.currentPage == 7)
                    EventCard(
                      date: formatDateString(context
                          .read<CalendarCubit>()
                          .state
                          .selectedTimeEnd
                          .toString()),
                      startTime: formatTimeString(context
                          .read<CalendarCubit>()
                          .state
                          .selectedTime
                          .toString()),
                      endTime: formatTimeString(context
                          .read<CalendarCubit>()
                          .state
                          .selectedTimeEnd
                          .toString()),
                      club: pageViewCubit.state.clubTitle.toString(),
                      categoryName:
                          pageViewCubit.state.categoryTitle.toString(),
                      serviceTitle: pageViewCubit.state.serviceTitle.toString(),
                      address: pageViewCubit.state.zoneTitle.toString(),
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
                          if (state.currentPage == 7)
                            BlocConsumer<AddBookingCubit, AddBookingState>(
                              listener: (context, state) {
                                if (state is AddBookingSuccess) {
                                  showCustomSuccessToast(
                                      "تم اضافة الحجز بنجاح");
                                  pushReplacement(
                                    RoutesKeys.kHome,
                                    context,
                                  );
                                } else if (state is AddBookingFailure) {
                                  showCustomFailureToast(state.massage);
                                }
                              },
                              builder: (context, state) {
                                return Expanded(
                                  child: ButtonApp(
                                    text: "تأكيد الحجز",
                                    onTap: () {
                                      context
                                          .read<AddBookingCubit>()
                                          .addBooking(
                                            employeeId: pageViewCubit
                                                    .state.employeeId ??
                                                0,
                                            serviceId:
                                                pageViewCubit.state.serviceId ??
                                                    0,
                                            zoneId:
                                                pageViewCubit.state.zoneId ?? 0,
                                            clubId:
                                                pageViewCubit.state.clubId ?? 0,
                                            date: context
                                                .read<CalendarCubit>()
                                                .state
                                                .focusedDay
                                                .toString(),
                                            startTime: context
                                                .read<CalendarCubit>()
                                                .state
                                                .selectedTime,
                                            endTime: context
                                                .read<CalendarCubit>()
                                                .state
                                                .selectedTimeEnd!,
                                          );
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
            return SizedBox.shrink();
          },
        ),
      ],
    );
  }

  String formatDateString(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  String formatTimeString(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }
}
