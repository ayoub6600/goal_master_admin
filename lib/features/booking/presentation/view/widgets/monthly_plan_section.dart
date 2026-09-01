import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/booking/data/model/series_preview.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/monthly_series_cubit/monthly_series_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/change_appointment_sheet.dart';

/// The four appointments a recurring booking will create, shown before it is.
///
/// The manager used to get a switch and a generic refusal after pressing
/// confirm — with no way to tell which week was taken, and no way to fix it
/// without abandoning the whole booking. Every week is on screen here, a taken
/// one can be moved in place, and confirm stays disabled until nothing is left
/// to fix.
///
/// A moved appointment REPLACES the one it stands in for. Four appointments
/// before a move, four after — never four plus an extra.
class MonthlyPlanSection extends StatelessWidget {
  const MonthlyPlanSection({super.key, required this.serviceId});

  final int serviceId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonthlySeriesCubit, MonthlySeriesState>(
      builder: (context, state) {
        if (!state.enabled) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 12.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.inactive4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الحجز الشهري',
                  style: AppTextStyles.font16Bold
                      .copyWith(color: AppColors.uiBlack)),
              SizedBox(height: 2.h),
              Text('نفس الموعد أسبوعياً لمدة 4 أسابيع',
                  style: AppTextStyles.font12Regular
                      .copyWith(color: AppColors.fontColor)),
              SizedBox(height: 14.h),
              _body(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, MonthlySeriesState state) {
    if (state.error != null) {
      return _Banner(
        tone: AppColors.errorRed,
        icon: Icons.error_outline,
        text: state.error!,
        action: 'إعادة المحاولة',
        onAction: () => context.read<MonthlySeriesCubit>().reload(),
      );
    }

    final preview = state.preview;

    if (preview == null || (state.isLoading && preview.dates.isEmpty)) {
      return const _PlanSkeleton();
    }

    if (preview.isImpossible) {
      return _Banner(
        tone: AppColors.errorRed,
        icon: Icons.event_busy_outlined,
        text: 'لا يمكن تكرار هذا الموعد أسبوعياً. اختر وقتاً أو تاريخاً آخر.',
      );
    }

    return Opacity(
      // Dimmed while the server re-checks, so the manager can see the plan
      // they chose without being able to act on a stale one.
      opacity: state.isLoading ? 0.55 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _status(state, preview),
          SizedBox(height: 12.h),
          // Every requested week, including a taken one. Hiding the taken
          // week was the dead end: the summary counted it, the button stayed
          // disabled, and the row that could have cleared it was not on
          // screen.
          ...preview.positions
              .asMap()
              .entries
              .map((e) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: _AppointmentRow(
                      position: e.key + 1,
                      date: e.value,
                      onChange: state.isLoading
                          ? null
                          : () => _openChangeSheet(context, e.value),
                      onUndo: state.isLoading
                          ? null
                          : () => context
                              .read<MonthlySeriesCubit>()
                              .clearReplacement(e.value),
                    ),
                  )),
          SizedBox(height: 6.h),
          _total(preview),
        ],
      ),
    );
  }

  /// One line telling the manager whether anything needs doing.
  Widget _status(MonthlySeriesState state, SeriesPreview preview) {
    final unresolved = state.unresolvedCount;

    if (unresolved == 0) {
      return _Banner(
        tone: AppColors.success,
        icon: Icons.check_circle_outline,
        text: 'جميع المواعيد متاحة',
      );
    }

    return _Banner(
      tone: AppColors.errorRed,
      icon: Icons.warning_amber_rounded,
      // Arabic counts differently at one and two, and reading «1 موعد» in a
      // venue office is worse than reading nothing.
      text: switch (unresolved) {
        1 => 'يوجد موعد واحد يحتاج إلى تعديل',
        2 => 'يوجد موعدان يحتاجان إلى تعديل',
        _ => 'يوجد $unresolved مواعيد تحتاج إلى تعديل',
      },
    );
  }

  Widget _total(SeriesPreview preview) {
    final count = preview.plannedOccurrences.length;
    final total = preview.displayTotal;

    // Only worth saying "× 66" when every appointment really is 66. After a
    // move into a differently priced band it would be a lie, so the breakdown
    // simply disappears and the total stands on its own.
    final prices = preview.plannedOccurrences
        .map((d) => d.chosenReplacement?.price ?? d.price)
        .toSet();
    final uniform = prices.length == 1 && prices.first > 0;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.inactive3,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                uniform
                    ? '$count مواعيد × ${prices.first.toStringAsFixed(0)} د.ل'
                    : '$count مواعيد',
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.fontColor),
              ),
              if (!uniform && total > 0)
                Text('أسعار مختلفة',
                    style: AppTextStyles.font12Regular
                        .copyWith(color: AppColors.fontColor)),
            ],
          ),
          Divider(color: AppColors.inactive4, height: 18.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي',
                  style: AppTextStyles.font16Bold
                      .copyWith(color: AppColors.uiBlack)),
              Text('${total.toStringAsFixed(0)} د.ل',
                  style: AppTextStyles.font18Bold
                      .copyWith(color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openChangeSheet(BuildContext context, PreviewDate date) async {
    final cubit = context.read<MonthlySeriesCubit>();

    final chosen = await showChangeAppointmentSheet(context, date: date);

    if (chosen == null) return;
    await cubit.chooseReplacement(date, chosen);
  }
}

/// One position in the series.
class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({
    required this.position,
    required this.date,
    this.onChange,
    this.onUndo,
  });

  final int position;
  final PreviewDate date;
  final VoidCallback? onChange;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final moved = date.isReplaced;
    final blocked = !date.available && !moved;

    final Color tone = blocked
        ? AppColors.errorRed
        : moved
            ? AppColors.primary
            : AppColors.success;

    final start = date.effectiveStartAt;
    final end = date.effectiveEndAt;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: blocked
            ? AppColors.dangerLight1
            : moved
                ? AppColors.primaryBlueLight2
                : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: blocked ? AppColors.errorRed : AppColors.inactive4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                blocked
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                size: 20.w,
                color: tone,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الموعد $position',
                        style: AppTextStyles.font12Regular
                            .copyWith(color: AppColors.fontColor)),
                    SizedBox(height: 2.h),
                    Text(
                      start == null
                          ? arabicDayAndDate(date.date)
                          : arabicDayAndDateOf(start),
                      style: AppTextStyles.font16Bold
                          .copyWith(color: AppColors.uiBlack),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      start != null && end != null
                          ? arabicRange(start, end)
                          : '${date.startTime} – ${date.endTime}',
                      style: AppTextStyles.font14Regular
                          .copyWith(color: AppColors.fontColor),
                    ),
                    if (blocked) ...[
                      SizedBox(height: 4.h),
                      Text('هذا الموعد محجوز',
                          style: AppTextStyles.font14Bold
                              .copyWith(color: AppColors.errorRed)),
                    ],
                    if (moved && date.chosenReplacement != null) ...[
                      SizedBox(height: 4.h),
                      // Subtle, not alarming: this is a solved problem, and
                      // it is still one appointment, not a second one.
                      Text(
                        'بديل عن ${_originalLabel()}',
                        style: AppTextStyles.font12Regular
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
              if (moved && onUndo != null)
                IconButton(
                  tooltip: 'تراجع',
                  onPressed: onUndo,
                  icon: Icon(Icons.undo, size: 18.w, color: AppColors.fontColor),
                ),
            ],
          ),
          if (blocked) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: date.canReplace ? onChange : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(0, 44.h),
                  elevation: 0,
                  backgroundColor: AppColors.errorRed,
                  disabledBackgroundColor: AppColors.inactive4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: Text(
                  date.canReplace
                      ? 'تغيير هذا الموعد'
                      : 'لا توجد مواعيد بديلة',
                  style:
                      AppTextStyles.font14Bold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _originalLabel() {
    final choice = date.chosenReplacement;
    if (choice == null) return '';

    // Same day, different hour — the common case. Naming the date again would
    // read as a different appointment.
    if (choice.date == date.date) {
      final start = date.startAt;
      return start != null ? arabicSlotClock(start) : date.startTime;
    }

    return arabicDayAndDate(date.date);
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.tone,
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  final Color tone;
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.w, color: tone),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(text,
                style: AppTextStyles.font14Bold.copyWith(color: tone)),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!,
                  style: AppTextStyles.font14Bold.copyWith(color: tone)),
            ),
        ],
      ),
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 72.h,
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: AppColors.inactive3,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
