import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/booking/data/model/operational_slot.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/calendar_cubit/calendar_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/calendar_cubit/calendar_state.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/page_view_cubit/page_view_cubit_cubit.dart';

/// Date and time on one screen.
///
/// A manager taking a booking over the phone changes the day and the hour in
/// the same breath — «الجمعة؟ لا، السبت الساعة تسعة» — so splitting them
/// across two pages cost a page transition on almost every booking. They are
/// one step now.
///
/// Two things this screen deliberately does not do:
///
///   It never asks which time band. «حجز مسائي / بعد منتصف الليل» was the
///   scheduling engine's inability to store a 17:00–03:00 band leaking onto
///   the person using the app. The server merges the bands; each slot still
///   carries the one it belongs to, which is what prices it.
///
///   It never works out a date. The night comes from the strip, and every slot
///   arrives carrying its own calendar day — which for an after-midnight slot
///   is the day AFTER the night being browsed. Nothing here adds or subtracts
///   a day from anything.
class NightScheduleSection extends StatefulWidget {
  const NightScheduleSection({super.key, required this.controller});

  final PageController controller;

  @override
  State<NightScheduleSection> createState() => _NightScheduleSectionState();
}

class _NightScheduleSectionState extends State<NightScheduleSection> {
  /// The night already in progress, when the server says it is still bookable.
  /// Never derived from the device clock.
  PreviousNightContext _previousNight = PreviousNightContext.inactive;
  bool _bootstrapped = false;

  int get _branchId => SharedPreferenceUtil.getInt(PrefKey.clubId);
  int get _serviceId => context.read<PageViewCubit>().state.serviceId ?? 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final calendar = context.read<CalendarCubit>();

    final previous = await calendar.loadPreviousNight(
      branchId: _branchId,
      serviceId: _serviceId,
    );

    if (!mounted) return;
    setState(() => _previousNight = previous);

    _loadNight(calendar.state.selectedDay);
  }

  void _loadNight(DateTime night) {
    final calendar = context.read<CalendarCubit>();
    calendar.updateSelectedDay(night, night);
    calendar.listNightSlots(branchId: _branchId, serviceId: _serviceId);
  }

  Future<void> _openFullCalendar() async {
    final calendar = context.read<CalendarCubit>();

    // The earliest night the manager may browse. When the server is offering
    // the night in progress, that night is reachable here too — otherwise the
    // strip would offer a date the calendar refused.
    final earliest = _previousNight.active &&
            _previousNight.operationalDate != null
        ? DateTime.parse(_previousNight.operationalDate!)
        : DateUtils.dateOnly(DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: calendar.state.selectedDay.isBefore(earliest)
          ? earliest
          : calendar.state.selectedDay,
      firstDate: earliest,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );

    if (picked != null) _loadNight(picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('التاريخ'),
              SizedBox(height: 10.h),
              _dateStrip(state),
              SizedBox(height: 22.h),
              _SectionLabel('الأوقات المتاحة'),
              SizedBox(height: 10.h),
              _times(state),
            ],
          ),
        );
      },
    );
  }

  // ---------------- date ----------------

  Widget _dateStrip(CalendarState state) {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = List.generate(14, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 78.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL: today sits on the right, the future runs left.
        children: [
          if (_previousNight.active && _previousNight.operationalDate != null)
            _tonightCard(state),
          ...days.asMap().entries.map((e) => _dayCard(
                state,
                date: e.value,
                label: switch (e.key) {
                  0 => 'اليوم',
                  1 => 'غدًا',
                  _ => arabicWeekdayOf(e.value),
                },
              )),
          _calendarCard(),
        ],
      ),
    );
  }

  /// «الليلة» — the night already running, offered as its own card.
  ///
  /// Visually distinct on purpose: it is not "yesterday", it is tonight
  /// continuing past midnight. A manager at 00:30 who reads it as a past date
  /// will not tap it, and the 01:00 slot about to be played in their own venue
  /// would stay unbookable.
  ///
  /// The date is the SERVER's, verbatim.
  Widget _tonightCard(CalendarState state) {
    final date = DateTime.parse(_previousNight.operationalDate!);
    final selected = DateUtils.isSameDay(state.selectedDay, date);

    return _card(
      selected: selected,
      accent: true,
      onTap: () => _loadNight(date),
      top: 'الليلة',
      bottom: arabicShortDateOf(date),
      footnote: '${_previousNight.remainingSlotsCount} متاح',
    );
  }

  Widget _dayCard(
    CalendarState state, {
    required DateTime date,
    required String label,
  }) {
    return _card(
      selected: DateUtils.isSameDay(state.selectedDay, date),
      onTap: () => _loadNight(date),
      top: label,
      bottom: arabicShortDateOf(date),
    );
  }

  Widget _calendarCard() {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: _openFullCalendar,
        child: Container(
          width: 62.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.inactive4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month_outlined,
                  size: 22.w, color: AppColors.primary),
              SizedBox(height: 4.h),
              Text('تاريخ آخر',
                  style: AppTextStyles.font12Bold
                      .copyWith(color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required bool selected,
    required VoidCallback onTap,
    required String top,
    required String bottom,
    String? footnote,
    bool accent = false,
  }) {
    final Color background = selected
        ? AppColors.primary
        : accent
            ? AppColors.primaryBlueLight2
            : Colors.white;
    final Color foreground = selected
        ? Colors.white
        : accent
            ? AppColors.primary
            : AppColors.uiBlack;

    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 76.w,
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : accent
                      ? AppColors.primaryBlueLight
                      : AppColors.inactive4,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(top,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font12Bold.copyWith(color: foreground)),
              SizedBox(height: 3.h),
              Text(bottom,
                  maxLines: 1,
                  style:
                      AppTextStyles.font14Bold.copyWith(color: foreground)),
              if (footnote != null) ...[
                SizedBox(height: 2.h),
                Text(footnote,
                    maxLines: 1,
                    style: AppTextStyles.font12Regular.copyWith(
                        color: foreground.withValues(alpha: 0.75))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- times ----------------

  Widget _times(CalendarState state) {
    if (state is TimeLoading) return const _SlotSkeleton();

    if (state is TimeFailure) {
      return _Message(
        icon: Icons.error_outline,
        color: AppColors.errorRed,
        title: 'تعذّر تحميل الأوقات',
        body: state.message,
      );
    }

    if (state is! TimeSuccess) return const SizedBox.shrink();

    final night = state.night;

    if (night.slots.isEmpty) {
      return const _Message(
        icon: Icons.nightlight_outlined,
        title: 'لا توجد أوقات في هذه الليلة',
        body: 'جرّب تاريخًا آخر من الشريط بالأعلى.',
      );
    }

    final evening = night.evening;
    final afterMidnight = night.afterMidnight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (evening.isNotEmpty) ...[
          _BandHeading(
            'مساء ${arabicWeekdayOf(DateTime.parse(night.operationalDate))}',
          ),
          SizedBox(height: 8.h),
          _grid(evening, state.selectedSlot),
        ],
        if (afterMidnight.isNotEmpty) ...[
          SizedBox(height: 18.h),
          // Presentation only. The manager is not choosing a band here — they
          // are being told where midnight falls in a list they can already see
          // in full.
          const _MidnightDivider(),
          SizedBox(height: 12.h),
          _grid(afterMidnight, state.selectedSlot),
        ],
      ],
    );
  }

  Widget _grid(List<OperationalSlot> slots, OperationalSlot? selected) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: slots
          .map((slot) => _SlotChip(
                slot: slot,
                // Identity by start instant: two slots can share a clock
                // across a night boundary, but never an instant.
                selected: selected != null &&
                    selected.startAt.isAtSameMomentAs(slot.startAt),
                onTap: () => _select(slot),
              ))
          .toList(),
    );
  }

  void _select(OperationalSlot slot) {
    if (!slot.isAvailable) return;

    // The band the fee is keyed on, travelling with the slot that owns it.
    context.read<PageViewCubit>().setEmployeeId(slot.employeeId);
    context.read<CalendarCubit>().selectSlot(slot);

    context.read<PageViewCubit>().nextPage();
    widget.controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.ease,
    );
  }
}

// ---------------- pieces ----------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.font18Bold.copyWith(color: AppColors.uiBlack));
  }
}

class _BandHeading extends StatelessWidget {
  const _BandHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTextStyles.font14SemiBold
            .copyWith(color: AppColors.fontColor));
  }
}

class _MidnightDivider extends StatelessWidget {
  const _MidnightDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.bedtime_outlined, size: 16.w, color: AppColors.primary),
        SizedBox(width: 6.w),
        Text('بعد منتصف الليل',
            style:
                AppTextStyles.font14SemiBold.copyWith(color: AppColors.primary)),
        SizedBox(width: 10.w),
        Expanded(child: Divider(color: AppColors.inactive4, height: 1)),
      ],
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final OperationalSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taken = !slot.isAvailable;

    final Color background = selected
        ? AppColors.primary
        : taken
            ? AppColors.inactive3
            : Colors.white;
    final Color border = selected
        ? AppColors.primary
        : taken
            ? AppColors.inactive4
            : AppColors.primaryBlueLight;
    final Color foreground = selected
        ? Colors.white
        : taken
            ? AppColors.inactiveText5
            : AppColors.uiBlack;

    return Semantics(
      button: true,
      enabled: !taken,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: taken ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: BoxConstraints(minWidth: 92.w, minHeight: 48.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: border, width: selected ? 2 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                arabicSlotClock(slot.startAt),
                style: AppTextStyles.font16Bold.copyWith(
                  color: foreground,
                  decoration:
                      taken ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
              if (taken)
                Text('محجوز',
                    style: AppTextStyles.font12Regular
                        .copyWith(color: AppColors.inactiveText5))
              else if (slot.price != null)
                Text('${slot.price!.toStringAsFixed(0)} د.ل',
                    style: AppTextStyles.font12Regular.copyWith(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.fontColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotSkeleton extends StatelessWidget {
  const _SlotSkeleton();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: List.generate(
        8,
        (_) => Container(
          width: 92.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: AppColors.inactive3,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AppColors.fontColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.inactive3,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30.w, color: tone),
          SizedBox(height: 10.h),
          Text(title,
              textAlign: TextAlign.center,
              style: AppTextStyles.font16Bold.copyWith(color: tone)),
          SizedBox(height: 4.h),
          Text(body,
              textAlign: TextAlign.center,
              style: AppTextStyles.font14Regular
                  .copyWith(color: AppColors.fontColor)),
        ],
      ),
    );
  }
}
