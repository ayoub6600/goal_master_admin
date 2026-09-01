import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/features/booking/data/model/created_series.dart';
import 'package:goal_master_admin/features/booking/domain/booking_occurrence.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_booking_cubit/add_booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/calendar_cubit/calendar_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/monthly_series_cubit/monthly_series_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/page_view_cubit/page_view_cubit_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_confirmation_section.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_success_sheet.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/category_selection.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/customer_picker_section.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/night_schedule_section.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/service_selection.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/skip_and_extend_sheet.dart';

/// «إضافة الحجز».
///
/// Four visible steps, down from seven. Two went away because they were never
/// questions worth asking a manager:
///
///   «اختر الحجز» — «حجز مسائي» / «حجز بعد منتصف الليل» — was the scheduling
///   engine's inability to store a 17:00–03:00 band as one row, leaking onto
///   the person using the app. The bands still exist and still price the
///   booking; the server merges them and each slot carries its own.
///
///   The standalone calendar page, folded into the time step. A manager taking
///   a booking over the phone changes the day and the hour in one breath.
///
/// Every date and time submitted from here comes from the slot the server
/// offered. The night being browsed selects which slots to show and nothing
/// else — for an after-midnight slot the two differ by a day, and using the
/// night booked the venue 24 hours early.
class AddBookingView extends StatefulWidget {
  const AddBookingView({super.key});

  @override
  State<AddBookingView> createState() => _AddBookingViewState();
}

class _AddBookingViewState extends State<AddBookingView> {
  final PageController _controller = PageController();

  static const int _confirmPage = 3;

  /// The occurrence the manager selected, or null with a toast.
  ///
  /// Deliberately has no fallback to the browsed night: a missing slot is a
  /// bug to surface, not a date to guess.
  BookingOccurrence? _occurrence(BuildContext context) {
    final slot = context.read<CalendarCubit>().state.selectedSlot;

    if (slot == null) {
      showCustomFailureToast('يرجى اختيار وقت الحجز');
      return null;
    }

    return BookingOccurrence(
      startAt: slot.startAt,
      endAt: slot.endAt,
      // The band this slot belongs to, which is what prices it.
      employeeId: slot.employeeId,
      price: slot.price,
    );
  }

  void _submit(BuildContext context, {String? approvedPlanSignature}) {
    final occurrence = _occurrence(context);
    if (occurrence == null) return;

    final pageViewCubit = context.read<PageViewCubit>();

    final monthly = context.read<MonthlySeriesCubit>().state;

    context.read<AddBookingCubit>().addBooking(
          serviceId: pageViewCubit.state.serviceId ?? 0,
          occurrence: occurrence,
          customerId: pageViewCubit.state.customerId ?? 0,
          status: pageViewCubit.state.status,
          phone: pageViewCubit.state.phone ?? '',
          fullname: pageViewCubit.state.nameCustomer.toString(),
          approvedPlanSignature: approvedPlanSignature,
          // The weeks the manager moved. Each one MOVES a position of the
          // series; the server re-checks every one under lock, so a slot taken
          // since the preview is refused rather than booked, and the series
          // never grows past four.
          replacements: monthly.enabled ? monthly.replacementPayload : const [],
        );
  }

  /// Asks for approval, then resubmits with the signature of the exact plan
  /// that was shown — never a bare "yes", which could book unseen dates.
  ///
  /// This used to read the browsed night rather than the selected slot, so an
  /// approved plan could be submitted against a different anchor than the one
  /// the manager had just agreed to. It goes through the same [_submit] now.
  Future<void> _offerSkip(
    BuildContext context,
    AddBookingSeriesConflict state,
  ) async {
    final decision = await showSkipAndExtendSheet(
      context,
      conflicts: state.conflicts,
      proposedDates: state.proposedDates,
      skippedDates: state.skippedDates,
      targetOccurrenceCount: state.targetOccurrenceCount,
      planChanged: state.planChanged,
    );

    if (!context.mounted) return;

    switch (decision) {
      case SkipDecision.skipAndContinue:
        _submit(context, approvedPlanSignature: state.planSignature);
      case SkipDecision.chooseAnotherTime:
        // Back to the time step with everything else still filled in.
        _back(context);
      case SkipDecision.cancel:
      case null:
        break;
    }
  }

  Future<void> _onSuccess(BuildContext context, CreatedSeries? series) async {
    final occurrence = context.read<CalendarCubit>().state.selectedSlot;
    final pageViewCubit = context.read<PageViewCubit>();
    final addBooking = context.read<AddBookingCubit>();

    if (occurrence == null) {
      pushReplacement(RoutesKeys.kHome, context);
      return;
    }

    final action = await showBookingSuccessSheet(
      context,
      customerName: pageViewCubit.state.nameCustomer ?? '',
      customerPhone: pageViewCubit.state.phone ?? '',
      serviceTitle: pageViewCubit.state.serviceTitle ?? '',
      occurrence: BookingOccurrence(
        startAt: occurrence.startAt,
        endAt: occurrence.endAt,
        employeeId: occurrence.employeeId,
        price: occurrence.price,
      ),
      isMonthly: addBooking.isMonthly,
      // The server's own account of a recurring booking. When present the
      // sheet describes it, rather than the one appointment that was selected.
      series: series,
    );

    if (!context.mounted) return;

    switch (action) {
      case BookingSuccessAction.addAnother:
        // Same venue, same manager, next booking — the common case during a
        // busy evening. A fresh route rather than a reset, so no state from
        // the finished booking can survive into the next one.
        pushReplacement(RoutesKeys.kAddBooking, context);
      case BookingSuccessAction.backToBookings:
      case null:
        pushReplacement(RoutesKeys.kHome, context);
    }
  }

  void _back(BuildContext context) {
    context.read<PageViewCubit>().previousPage();
    _controller.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageWrapper(
          title: 'إضافة الحجز',
          allowBack: true,
          child: BlocBuilder<PageViewCubit, PageViewState>(
            builder: (context, state) {
              return Column(
                children: [
                  _StepIndicator(current: state.currentPage),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        CategorySelection(controller: _controller),
                        ServiceSelection(controller: _controller),
                        // «اختر الحجز» used to sit here. It is gone, not
                        // hidden: the server merges the bands and returns one
                        // night, and each slot still carries the band that
                        // prices it.
                        NightScheduleSection(controller: _controller),
                        CustomerPickerSection(controller: _controller),
                        BookingConfirmationSection(controller: _controller),
                      ],
                    ),
                  ),
                  if (state.currentPage > 0) _footer(context, state),
                ],
              );
            },
          ),
        ),
        BlocBuilder<AddBookingCubit, AddBookingState>(
          builder: (context, state) {
            if (state is! AddBookingLoading) return const SizedBox.shrink();

            return ColoredBox(
              color: Colors.black.withValues(alpha: 0.45),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ],
    );
  }

  Widget _footer(BuildContext context, PageViewState state) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: Row(
          children: [
            Expanded(
              flex: state.currentPage == _confirmPage + 1 ? 1 : 2,
              child: ButtonApp(
                backGround: AppColors.inactive2,
                textColor: AppColors.uiBlack,
                text: 'رجوع',
                onTap: () => _back(context),
              ),
            ),
            if (state.currentPage == _confirmPage + 1) ...[
              SizedBox(width: 10.w),
              Expanded(
                flex: 2,
                child: BlocConsumer<AddBookingCubit, AddBookingState>(
                  listener: (context, state) async {
                    if (state is AddBookingSuccess) {
                      await _onSuccess(context, state.series);
                    } else if (state is AddBookingSeriesConflict) {
                      // A recurring booking clashed. Nothing was booked; if a
                      // workable plan is on offer the manager decides.
                      // Otherwise it is a plain refusal.
                      if (state.canSkipAndExtend) {
                        await _offerSkip(context, state);
                      } else {
                        showCustomFailureToast(state.message);
                      }
                    } else if (state is AddBookingFailure) {
                      showCustomFailureToast(state.massage);
                    }
                  },
                  builder: (context, state) {
                    return BlocBuilder<MonthlySeriesCubit, MonthlySeriesState>(
                      builder: (context, monthly) {
                        // A recurring booking cannot be confirmed while a week
                        // is still taken. Blocking here is the point: the old
                        // flow let the manager press confirm and learn from a
                        // refusal, with no way to fix it in place.
                        final blocked =
                            monthly.enabled && !monthly.canConfirm;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (blocked && monthly.unresolvedCount > 0) ...[
                              Text(
                                'يرجى تعديل المواعيد المحجوزة أولاً',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.errorRed,
                                ),
                              ),
                              SizedBox(height: 6.h),
                            ],
                            ButtonApp(
                              text: monthly.enabled
                                  ? 'تأكيد الحجز الشهري'
                                  : 'تأكيد الحجز',
                              // ButtonApp has no disabled state of its own, so
                              // the grey is what says "not yet".
                              backGround: blocked ? AppColors.inactive4 : null,
                              onTap: (blocked || state is AddBookingLoading)
                                  ? null
                                  : () => _submit(context),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Where the manager is, in four steps.
///
/// Worth the strip of pixels: the flow no longer has page titles doing this
/// job, and a manager interrupted mid-booking needs to see where they were.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  static const _labels = ['التصنيف', 'الخدمة', 'الوقت', 'العميل', 'التأكيد'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: List.generate(_labels.length, (index) {
          final done = index <= current;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: index == _labels.length - 1 ? 0 : 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: done ? AppColors.primary : AppColors.inactive4,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    _labels[index],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: done ? FontWeight.w700 : FontWeight.w400,
                      color: done ? AppColors.primary : AppColors.fontColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
