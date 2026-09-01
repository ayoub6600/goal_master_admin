import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo.dart';
import 'package:goal_master_admin/features/booking/data/repo/booking_repo_imp.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/%20booking_details_cubit/booking_details_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/%20booking_details_cubit/booking_details_state.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/cancel_booking_cubit/cancel_booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_deposit_cubit/booking_deposit_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/attendance_actions_sheet.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/deposit_booking_button.dart';
import 'package:goal_master_admin/features/monthly_booking/data/model/monthly_booking_response.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/monthly_booking_cubit/monthly_booking_cubit.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_booking_body.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_card.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_sheet.dart';

/// What can be done to a whole recurring booking.
///
/// Only actions the server already supports appear here. Every label names its
/// own scope, because the one question this screen must never leave open is
/// whether something applies to a single session or to the whole month.
void showSeriesActions({
  required BuildContext context,
  required MonthlySeriesGroup group,
  required DateTime now,
}) {
  final cubit = context.read<MonthlyBookingCubit>();

  baseBottomSheet(
    title: 'حجز شهري #${group.reference}',
    context: context,
    hideNavBar: false,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionTile(
          icon: Icons.list_alt_rounded,
          label: 'عرض تفاصيل السلسلة',
          subtitle: 'العميل والملعب وكل المواعيد',
          onTap: () {
            Navigator.pop(context);
            baseBottomSheet(
              title: 'تفاصيل الحجز الشهري',
              context: context,
              hideNavBar: false,
              child: MonthlySeriesSheet(group: group, now: now),
            );
          },
        ),
        if (group.seriesId > 0)
          ActionTile(
            icon: Icons.open_in_new_rounded,
            label: 'فتح شاشة الحجز الشهري',
            subtitle: 'العرض الكامل من الخادم، مع أي قرار معلّق',
            onTap: () {
              Navigator.pop(context);
              openFullSeriesScreen(context, group.seriesId);
            },
          ),
        // A row that predates the series model has no series to call off, so
        // it keeps the endpoint it always used: the same call, the same
        // effect, now named after what it actually does and styled as the
        // destructive action it always was.
        if (group.isActive && group.seriesId == 0)
          ActionTile(
            icon: Icons.event_busy_rounded,
            label: 'إنهاء الحجز الشهري',
            subtitle: 'إيقاف التكرار وإلغاء المواعيد من تاريخ تختاره',
            destructive: true,
            onTap: () {
              Navigator.pop(context);
              confirmEndSeries(
                context: context,
                group: group,
                now: now,
                onConfirm: () async {
                  final next = group.nextOccurrence(now) ?? group.occurrences.first;
                  final from = MonthlySeriesGroup.occurrenceDate(next);
                  if (from == null) return;

                  final result = await cubit.bookingRepo.updateMonthlyBooking(
                    id: group.occurrences.first.id.toString(),
                    serviceDate: '${from.year}-'
                        '${from.month.toString().padLeft(2, '0')}-'
                        '${from.day.toString().padLeft(2, '0')}',
                  );
                  result.fold(
                    (failure) => showCustomFailureToast(failure.errMessage),
                    (_) {
                      showCustomSuccessToast('تم إنهاء الحجز الشهري.');
                      cubit.refresh();
                    },
                  );
                },
              );
            },
          ),
        if (group.isActive && group.seriesId > 0)
          ActionTile(
            icon: Icons.event_busy_rounded,
            label: 'إنهاء الحجز الشهري',
            subtitle: 'إلغاء المواعيد المتبقية — السلسلة بالكامل',
            destructive: true,
            onTap: () {
              Navigator.pop(context);
              confirmEndSeries(
                context: context,
                group: group,
                now: now,
                onConfirm: () async {
                  final result =
                      await cubit.bookingRepo.cancelSeries(seriesId: group.seriesId);
                  result.fold(
                    (failure) => showCustomFailureToast(failure.errMessage),
                    (message) {
                      showCustomSuccessToast(message);
                      cubit.refresh();
                    },
                  );
                },
              );
            },
          ),
      ],
    ),
  );
}

/// What can be done to ONE session.
///
/// The banner at the top is not decoration: every action below it stops at
/// this session, and a manager who reads "cancel" on a monthly booking will
/// otherwise reasonably assume it takes the rest of the month with it.
void showOccurrenceActions({
  required BuildContext context,
  required MonthlySeriesGroup group,
  required MonthlyBookingResponse occurrence,
  required bool isUpcoming,
  VoidCallback? onReschedule,
}) {
  final listCubit = context.read<MonthlyBookingCubit>();
  final date = MonthlySeriesGroup.occurrenceDate(occurrence);

  baseBottomSheet(
    title: date == null
        ? 'موعد واحد'
        : '${arabicDayAndDateOf(date)} ${date.year}',
    context: context,
    hideNavBar: false,
    child: buildOccurrenceActions(
      group: group,
      occurrence: occurrence,
      bookingRepo: getIt<BookingRepoImp>(),
      onChanged: listCubit.refresh,
      isUpcoming: isUpcoming,
      onReschedule: onReschedule,
    ),
  );
}

/// The body of the occurrence sheet, with the cubits it depends on.
///
/// Separated from `showOccurrenceActions` so a test can pump the real widget
/// tree against a fake repository. It exists because the first version of this
/// sheet shipped without providing BookingDepositCubit — the analyzer cannot
/// see a missing provider, and nothing was rendering the tree until a manager
/// tapped an occurrence and got a red screen.
Widget buildOccurrenceActions({
  required MonthlySeriesGroup group,
  required MonthlyBookingResponse occurrence,
  required BookingRepo bookingRepo,
  required VoidCallback onChanged,
  bool isUpcoming = true,
  VoidCallback? onReschedule,
}) {
  return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              BookingDetailsCubit(bookingRepo, occurrence.bookingId)
                ..getBookingInfo(),
        ),
        BlocProvider(
          create: (_) => CancelBookingCubit(bookingRepo),
        ),
        // DepositBookingButton is itself a BlocConsumer<BookingDepositCubit>:
        // the provider it creates internally is only for the sheet it opens,
        // so the cubit has to exist ABOVE it. The bookings screen supplies it
        // from its route; this sheet has to supply its own.
        BlocProvider(
          create: (_) => BookingDepositCubit(
            occurrence.bookingId,
            bookingRepo: bookingRepo,
          ),
        ),
      ],
      child: _OccurrenceActions(
        group: group,
        occurrence: occurrence,
        onChanged: onChanged,
        isUpcoming: isUpcoming,
        onReschedule: onReschedule,
      ),
  );
}

class _OccurrenceActions extends StatelessWidget {
  const _OccurrenceActions({
    required this.group,
    required this.occurrence,
    required this.onChanged,
    required this.isUpcoming,
    this.onReschedule,
  });

  final MonthlySeriesGroup group;
  final MonthlyBookingResponse occurrence;
  final VoidCallback onChanged;

  /// Whether this session is still ahead of the venue.
  final bool isUpcoming;

  final VoidCallback? onReschedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScopeBanner(
          text: 'هذا الموعد فقط — لن تتأثر بقية مواعيد الحجز الشهري '
              '#${group.reference}',
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 16.r, color: AppColors.dark2),
            SizedBox(width: 7.w),
            SlotTime(occurrence: occurrence),
            const Spacer(),
            if (occurrence.isReplacement) const ReplacementBadge(),
          ],
        ),
        SizedBox(height: 14.h),

        // Payment goes through the manager's existing deposit flow, which owns
        // the arithmetic. Nothing is recalculated here.
        BlocBuilder<BookingDetailsCubit, BookingDetailsState>(
          builder: (context, state) {
            if (state is BookingDetailsSuccess) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                // The button returns an Expanded — it is built to sit in the
                // booking screen's action Row — so it needs a Flex parent
                // here too rather than a Column.
                child: Row(
                  children: [
                    DepositBookingButton(
                      bookingDetails: state.bookingDetails,
                    ),
                  ],
                ),
              );
            }
            if (state is BookingDetailsError) {
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Text(
                  'تعذّر تحميل بيانات الدفع لهذا الموعد.',
                  style: AppTextStyles.font12Regular
                      .copyWith(color: AppColors.dark2),
                ),
              );
            }
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),

        // Moving one session. Offered only where it can actually be done:
        // a cancelled session has nothing to move, and a session already
        // played cannot be rescheduled — update-booking refuses a past date
        // outright, so showing the action would be a promise the server
        // will not keep.
        if (onReschedule != null && !occurrence.isCancelled && isUpcoming)
          ActionTile(
            icon: Icons.edit_calendar_outlined,
            label: 'تعديل هذا الموعد',
            subtitle: 'تغيير تاريخ أو وقت هذا الموعد وحده',
            onTap: onReschedule,
          ),
        // The result of THIS session, through the manager app's existing
        // attendance sheet and the same `mark-attendance` endpoint an ordinary
        // booking uses. A recurring booking's sessions are ordinary bookings
        // as far as a result is concerned — one each, on their own dates — so
        // there is deliberately no monthly attendance path to maintain.
        if (occurrence.hasReportedResult)
          Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: Row(
              children: [
                Icon(Icons.fact_check_outlined,
                    size: 16.r, color: AppColors.dark2),
                SizedBox(width: 8.w),
                Text(
                  'النتيجة المسجَّلة: ${occurrence.attendanceLabel}',
                  style: AppTextStyles.font12Regular
                      .copyWith(color: AppColors.dark5),
                ),
              ],
            ),
          )
        else if (occurrence.canReportAttendance)
          ActionTile(
            icon: Icons.fact_check_outlined,
            label: 'سجّل نتيجة الحجز',
            subtitle: 'ما حدث في هذا الموعد وحده',
            onTap: () async {
              final when = MonthlySeriesGroup.occurrenceDate(occurrence);
              final reported = await AttendanceActionsSheet.show(
                context,
                occurrence.bookingId,
                payOnArrival: occurrence.payOnArrival,
                // The shared sheet asks about «هذا الحجز». Inside a monthly
                // booking that could be read as the whole month, so the week
                // is named and the rest is ruled out explicitly.
                scopeNote: when == null
                    ? 'هذا التقرير يخص هذا الموعد فقط، ولن يؤثر على بقية '
                        'مواعيد الحجز الشهري.'
                    : 'هذا التقرير يخص موعد ${arabicDayAndDateOf(when)} '
                        '${when.year} فقط، ولن يؤثر على بقية مواعيد الحجز '
                        'الشهري #${group.reference}.',
              );
              if (reported == true) {
                onChanged();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),

        if (!occurrence.isCancelled)
          BlocConsumer<CancelBookingCubit, CancelBookingState>(
            listener: (context, state) {
              if (state is CancelBookingSuccess) {
                showCustomSuccessToast(state.message);
                Navigator.pop(context);
                onChanged();
              } else if (state is CancelBookingFailure) {
                showCustomFailureToast(state.message);
              }
            },
            builder: (context, state) {
              final busy = state is CancelBookingLoading;

              return ActionTile(
                icon: Icons.event_busy_outlined,
                label: busy ? 'جارٍ الإلغاء…' : 'إلغاء هذا الموعد فقط',
                subtitle: 'بقية مواعيد الحجز الشهري تبقى كما هي',
                destructive: true,
                onTap: busy
                    ? null
                    : () => _confirmCancelOne(context, occurrence),
              );
            },
          ),
      ],
    );
  }

  void _confirmCancelOne(
    BuildContext context,
    MonthlyBookingResponse occurrence,
  ) {
    final cubit = context.read<CancelBookingCubit>();
    final date = MonthlySeriesGroup.occurrenceDate(occurrence);
    final when =
        date == null ? 'هذا الموعد' : '${arabicDayAndDateOf(date)} ${date.year}';

    baseBottomSheet(
      title: 'إلغاء هذا الموعد؟',
      context: context,
      hideNavBar: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScopeBanner(
            text: 'سيتم إلغاء موعد $when فقط. '
                'بقية مواعيد الحجز الشهري #${group.reference} لن تتأثر.',
            destructive: true,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _Button(
                  label: 'تراجع',
                  background: AppColors.inactive2,
                  foreground: AppColors.dark,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _Button(
                  label: 'إلغاء الموعد',
                  background: AppColors.errorRed,
                  foreground: AppColors.white,
                  onTap: () {
                    Navigator.pop(context);
                    cubit.cancelBooking(occurrence.bookingId);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// States, in words, which bookings an action reaches.
class ScopeBanner extends StatelessWidget {
  const ScopeBanner({
    super.key,
    required this.text,
    this.destructive = false,
  });

  final String text;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(11.r),
      decoration: BoxDecoration(
        color: destructive ? AppColors.dangerLight1 : AppColors.inactive3,
        borderRadius: BorderRadius.circular(11.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            destructive
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            size: 16.r,
            color: destructive ? AppColors.errorRed : AppColors.dark2,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.font12Regular.copyWith(
                color: destructive ? AppColors.errorRed : AppColors.dark5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in an action sheet.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.destructive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colour = destructive ? AppColors.errorRed : AppColors.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 11.h, horizontal: 2.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: destructive
                    ? AppColors.dangerLight1
                    : AppColors.primaryBlueLight2,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon,
                  size: 17.r,
                  color: destructive ? AppColors.errorRed : AppColors.primary),
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          AppTextStyles.font14SemiBold.copyWith(color: colour)),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: AppTextStyles.font12Regular
                          .copyWith(color: AppColors.dark2),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_left, size: 18.r, color: AppColors.dark2),
          ],
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(label,
              style: AppTextStyles.font14Bold.copyWith(color: foreground)),
        ),
      ),
    );
  }
}
