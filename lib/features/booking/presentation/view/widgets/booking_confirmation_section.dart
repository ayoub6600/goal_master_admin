import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goal_master_admin/core/components/keys_values.dart';
import 'package:goal_master_admin/core/components/preference_utility.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/utils/arabic_dates.dart';
import 'package:goal_master_admin/features/booking/domain/booking_occurrence.dart';
import 'package:goal_master_admin/features/booking/domain/booking_payment.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_booking_cubit/add_booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/calendar_cubit/calendar_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/calendar_cubit/calendar_state.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/monthly_series_cubit/monthly_series_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/page_view_cubit/page_view_cubit_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/monthly_plan_section.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/profile_cubit/profile_cubit.dart';

/// «تأكيد الحجز» — everything the manager needs to check, on one screen.
///
/// The old final step was a form: a status dropdown on the customer page, a
/// bare "amount paid" field against a total that was never displayed, a
/// payment method that had to be tapped to make the payload valid, and a
/// summary card missing the venue, the customer and the price — showing a date
/// taken from the booking's END, which for a 23:00 booking was tomorrow.
///
/// This reads top to bottom in the order a manager checks a booking: who, what,
/// when, how much.
class BookingConfirmationSection extends StatefulWidget {
  const BookingConfirmationSection({super.key, required this.controller});

  final PageController controller;

  @override
  State<BookingConfirmationSection> createState() =>
      _BookingConfirmationSectionState();
}

class _BookingConfirmationSectionState
    extends State<BookingConfirmationSection> {
  /// Whether this is one appointment or a recurring one. A choice about the
  /// booking, not a technical option — which is why it sits above payment as
  /// «نوع الحجز» rather than as a switch at the bottom.
  bool _isMonthly = false;

  /// What has been collected. Independent of the booking's lifecycle status,
  /// which stays Approved throughout.
  PaymentSelection _payment = PaymentSelection.unpaid;

  /// Only meaningful while [_payment] is partial — the figure the manager
  /// types. Kept out of the other two states so switching away and back
  /// cannot resurrect a stale amount.
  final TextEditingController _partial = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cash is the only supported method, so it is already chosen. Nothing here
    // waits for a tap that has no alternative.
    context.read<AddBookingCubit>().setPaymentType(1);
    // Approved with nothing collected: what a manager taking a booking in
    // person almost always means. The lifecycle status never changes again.
    context.read<PageViewCubit>().updateStatus(
          BookingPaymentStatus.lifecycleApproved,
        );
    _syncPaidAmount();
  }

  @override
  void dispose() {
    _partial.dispose();
    super.dispose();
  }

  void _selectPayment(PaymentSelection selection) {
    setState(() {
      _payment = selection;
      // Leaving partial discards the typed figure, so it cannot be submitted
      // by a state that no longer claims it.
      if (selection != PaymentSelection.partial) _partial.clear();
    });
    _syncPaidAmount();
  }

  /// Push the amount implied by the selection and the authoritative total
  /// into the cubit.
  ///
  /// Recomputed rather than remembered: switching between the three states any
  /// number of times can never leave the previous one's figure behind.
  void _syncPaidAmount({double? total}) {
    final resolved = total ?? _currentTotal();
    final entered = double.tryParse(_partial.text.trim()) ?? 0;

    context.read<AddBookingCubit>().setPaidAmount(
          _payment.amountFor(resolved, entered: entered).toStringAsFixed(2),
        );
  }

  /// Why a typed partial amount cannot be recorded, or null when it can.
  ///
  /// Zero and the full total are not errors — they are the other two states,
  /// and the manager is told so rather than being blocked.
  String? _partialError(double total) {
    final text = _partial.text.trim();
    if (text.isEmpty) return null;

    final entered = double.tryParse(text);
    if (entered == null) return 'أدخل مبلغاً صحيحاً.';
    if (entered < 0) return 'المبلغ لا يمكن أن يكون سالباً.';
    if (total > 0 && entered > total) {
      return 'المبلغ أكبر من قيمة الحجز (${total.toStringAsFixed(0)} د.ل).';
    }
    if (entered == 0) return 'هذا يعني «غير مدفوع».';
    if (total > 0 && entered == total) return 'هذا يعني «خالص».';

    return null;
  }

  /// What is being booked, priced by the server.
  double _currentTotal() {
    if (_isMonthly) {
      return context.read<MonthlySeriesCubit>().state.preview?.displayTotal ?? 0;
    }

    final slot = context.read<CalendarCubit>().state.selectedSlot;
    return slot?.price ?? 0;
  }

  void _setBookingType(bool monthly, BookingOccurrence occurrence) {
    if (_isMonthly == monthly) return;

    setState(() => _isMonthly = monthly);

    final cubit = context.read<AddBookingCubit>();
    final plan = context.read<MonthlySeriesCubit>();

    cubit.setIsMonthly(monthly);

    if (monthly) {
      // open() clears any previous plan before loading, so a plan abandoned
      // earlier in this checkout can never be shown or submitted.
      plan.open(
        branchId: SharedPreferenceUtil.getInt(PrefKey.clubId),
        serviceId: context.read<PageViewCubit>().state.serviceId ?? 0,
        anchor: occurrence,
        customerId: context.read<PageViewCubit>().state.customerId,
      );
      // The plan is still loading, so there is no monthly total yet.
      _syncPaidAmount(total: 0);
    } else {
      plan.disable();
      _syncPaidAmount(total: occurrence.price ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageCubit = context.watch<PageViewCubit>();

    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, calendar) {
        final slot = calendar.selectedSlot;

        if (slot == null) {
          return const _MissingSlot();
        }

        final occurrence = BookingOccurrence(
          startAt: slot.startAt,
          endAt: slot.endAt,
          employeeId: slot.employeeId,
          price: slot.price,
        );

        return BlocConsumer<MonthlySeriesCubit, MonthlySeriesState>(
          // A plan that resolves to a new total — because an appointment was
          // moved into a differently priced band — must drag «خالص» with it.
          listenWhen: (a, b) => a.preview?.displayTotal != b.preview?.displayTotal,
          listener: (context, monthly) {
            if (_isMonthly) {
              _syncPaidAmount(total: monthly.preview?.displayTotal ?? 0);
            }
          },
          builder: (context, monthly) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تأكيد الحجز',
                      style: AppTextStyles.font20Bold
                          .copyWith(color: AppColors.uiBlack)),
                  SizedBox(height: 16.h),

                  _Card(title: 'العميل', child: _customer(pageCubit)),
                  SizedBox(height: 12.h),

                  // The booking-type choice comes before anything that
                  // depends on it, because it decides what the rest of the
                  // page is describing.
                  _Card(
                    title: 'نوع الحجز',
                    child: _bookingType(occurrence),
                  ),
                  SizedBox(height: 12.h),

                  // One presentation or the other, never both: a single
                  // occurrence card above a four-appointment plan reads as a
                  // fifth booking.
                  if (!_isMonthly)
                    _Card(
                      title: 'تفاصيل الحجز',
                      child: _details(pageCubit, occurrence),
                    )
                  else
                    _Card(
                      title: 'تفاصيل الحجز الشهري',
                      child: _monthlyDetails(pageCubit),
                    ),
                  SizedBox(height: 12.h),

                  _Card(
                    title: 'الدفع',
                    child: _paymentSection(occurrence, monthly),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- who ----------------

  Widget _customer(PageViewCubit pageCubit) {
    final name = pageCubit.state.nameCustomer ?? '';
    final phone = pageCubit.state.phone ?? '';

    return Row(
      children: [
        Container(
          width: 40.w,
          height: 40.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryBlueLight2,
            shape: BoxShape.circle,
          ),
          child: Text(
            name.trim().isEmpty ? '؟' : name.trim().substring(0, 1),
            style: AppTextStyles.font16Bold.copyWith(color: AppColors.primary),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font16Bold
                      .copyWith(color: AppColors.uiBlack)),
              SizedBox(height: 2.h),
              Text(phone,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.font14Regular
                      .copyWith(color: AppColors.fontColor)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- what and when ----------------

  Widget _details(PageViewCubit pageCubit, BookingOccurrence occurrence) {
    // «الملعب» is deliberately absent: the manager works one venue, and its
    // NAME is not held anywhere on the device — only its id, in
    // SharedPreferences. Showing the category instead is true; inventing a
    // venue name would not be.
    return Column(
      children: [
        if ((pageCubit.state.categoryTitle ?? '').isNotEmpty)
          _Row(
            icon: Icons.category_outlined,
            label: 'التصنيف',
            value: pageCubit.state.categoryTitle!,
          ),
        _Row(
          icon: Icons.sports_soccer,
          label: 'الخدمة',
          value: pageCubit.state.serviceTitle ?? '',
        ),
        // The date is the START's. A booking that runs to midnight belongs to
        // the night it began, and an after-midnight slot belongs to the day
        // the server put it on — never to the night being browsed.
        _Row(
          icon: Icons.calendar_today_outlined,
          label: 'التاريخ',
          value: arabicDayAndDateOf(occurrence.startAt),
        ),
        _Row(
          icon: Icons.schedule,
          label: 'الوقت',
          value: arabicRange(occurrence.startAt, occurrence.endAt),
          footnote: occurrence.crossesMidnight ? 'يمتد بعد منتصف الليل' : null,
          last: true,
        ),
      ],
    );
  }

  // ---------------- how much ----------------

  Widget _paymentSection(BookingOccurrence occurrence, MonthlySeriesState monthly) {
    final total = _isMonthly
        ? (monthly.preview?.displayTotal ?? 0)
        : (occurrence.price ?? 0);
    final occurrenceCount = monthly.preview?.plannedOccurrences.length ?? 0;
    final entered = double.tryParse(_partial.text.trim()) ?? 0;
    final paid = _payment.amountFor(total, entered: entered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('طريقة الدفع',
            style: AppTextStyles.font14SemiBold
                .copyWith(color: AppColors.fontColor)),
        SizedBox(height: 8.h),
        // One method, already selected. Wallet exists in the enum but has
        // never been supported for a manager-created booking, so it is not
        // offered here.
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.primaryBlueLight2,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.payments_outlined,
                  size: 22.w, color: AppColors.primary),
              SizedBox(width: 10.w),
              Expanded(
                child: Text('الدفع نقداً',
                    style: AppTextStyles.font16Bold
                        .copyWith(color: AppColors.uiBlack)),
              ),
              Icon(Icons.check_circle, size: 22.w, color: AppColors.primary),
            ],
          ),
        ),
        SizedBox(height: 18.h),

        Text('حالة الدفع',
            style: AppTextStyles.font14SemiBold
                .copyWith(color: AppColors.fontColor)),
        SizedBox(height: 8.h),
        // Three states, because "part of it" is what a venue actually
        // collects. This used to be a two-way «حالة الحجز» whose «خالص» wrote
        // the booking's LIFECYCLE field — saying the match had been played.
        Row(
          children: [
            for (final option in PaymentSelection.values) ...[
              Expanded(
                child: _StatusOption(
                  label: option.label,
                  selected: _payment == option,
                  onTap: () => _selectPayment(option),
                ),
              ),
              if (option != PaymentSelection.values.last) SizedBox(width: 6.w),
            ],
          ],
        ),

        if (_payment == PaymentSelection.partial) ...[
          SizedBox(height: 12.h),
          Text('المبلغ المستلم',
              style: AppTextStyles.font14SemiBold
                  .copyWith(color: AppColors.fontColor)),
          SizedBox(height: 6.h),
          TextField(
            controller: _partial,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() => _syncPaidAmount(total: total)),
            style: AppTextStyles.font16Bold,
            decoration: InputDecoration(
              hintText: '0',
              suffixText: 'د.ل',
              hintStyle: AppTextStyles.font16Regular
                  .copyWith(color: AppColors.inactiveText5),
              filled: true,
              fillColor: AppColors.inactive3,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          if (_partialError(total) != null) ...[
            SizedBox(height: 6.h),
            Text(_partialError(total)!,
                style: AppTextStyles.font12Regular
                    .copyWith(color: AppColors.errorRed)),
          ],
        ],

        SizedBox(height: 18.h),

        if (_isMonthly && occurrenceCount > 0)
          _Amount(label: '$occurrenceCount مواعيد', value: total)
        else if (!_isMonthly && total > 0)
          _Amount(label: 'قيمة الحجز', value: total),
        Divider(color: AppColors.inactive4, height: 20.h),
        _Amount(label: 'الإجمالي', value: total, emphasised: true),
        SizedBox(height: 8.h),
        // The three figures a venue reads together. Derived from the selection
        // and the server's total, so they can never disagree with each other.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('المدفوع',
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.fontColor)),
            Text('${paid.toStringAsFixed(0)} د.ل',
                style: AppTextStyles.font16Bold.copyWith(
                  color: paid > 0 ? AppColors.success : AppColors.fontColor,
                )),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('المتبقي',
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.fontColor)),
            Text('${(total - paid).clamp(0, total).toStringAsFixed(0)} د.ل',
                style: AppTextStyles.font16Bold.copyWith(
                  color: (total - paid) > 0
                      ? AppColors.uiBlack
                      : AppColors.success,
                )),
          ],
        ),
      ],
    );
  }

  // ---------------- monthly ----------------

  /// «حجز عادي» / «حجز شهري» — a booking type, presented as one.
  ///
  /// This was a switch labelled «هل الحجز شهري؟» at the bottom of the page,
  /// under the payment fields, which made a recurring booking read as an
  /// afterthought toggled on rather than a kind of booking chosen up front.
  Widget _bookingType(BookingOccurrence occurrence) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        final user = profileState is ProfileLoaded ? profileState.user : null;
        final allowed = user?.canUseMonthlyBookings ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatusOption(
                    label: 'حجز عادي',
                    selected: !_isMonthly,
                    onTap: () => _setBookingType(false, occurrence),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _StatusOption(
                    label: 'حجز شهري',
                    selected: _isMonthly,
                    // The same entitlement the backend enforces. A modified
                    // client would still be refused there.
                    onTap: allowed
                        ? () => _setBookingType(true, occurrence)
                        : null,
                  ),
                ),
              ],
            ),
            if (!allowed) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 16.w, color: AppColors.errorRed),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'الحجز الشهري غير متاح في اشتراكك الحالي',
                      style: AppTextStyles.font12Regular
                          .copyWith(color: AppColors.errorRed),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  /// The recurring booking's own detail block: what is being booked, then the
  /// four appointments. The single-occurrence card is deliberately not shown
  /// alongside it.
  Widget _monthlyDetails(PageViewCubit pageCubit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((pageCubit.state.categoryTitle ?? '').isNotEmpty)
          _Row(
            icon: Icons.category_outlined,
            label: 'التصنيف',
            value: pageCubit.state.categoryTitle!,
          ),
        _Row(
          icon: Icons.sports_soccer,
          label: 'الخدمة',
          value: pageCubit.state.serviceTitle ?? '',
          last: true,
        ),
        MonthlyPlanSection(serviceId: pageCubit.state.serviceId ?? 0),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.inactive4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.font12Bold
                  .copyWith(color: AppColors.fontColor, letterSpacing: 0.4)),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.footnote,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? footnote;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.w, color: AppColors.fontColor),
          SizedBox(width: 10.w),
          SizedBox(
            width: 62.w,
            child: Text(label,
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.fontColor)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.font16Bold
                        .copyWith(color: AppColors.uiBlack)),
                if (footnote != null) ...[
                  SizedBox(height: 2.h),
                  Text(footnote!,
                      style: AppTextStyles.font12Regular
                          .copyWith(color: AppColors.primary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final double value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final style = emphasised
        ? AppTextStyles.font18Bold.copyWith(color: AppColors.primary)
        : AppTextStyles.font16Regular.copyWith(color: AppColors.uiBlack);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: emphasised
                ? AppTextStyles.font16Bold.copyWith(color: AppColors.uiBlack)
                : AppTextStyles.font14Regular
                    .copyWith(color: AppColors.fontColor)),
        Text('${value.toStringAsFixed(0)} د.ل', style: style),
      ],
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 46.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlueLight2 : AppColors.inactive3,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: AppTextStyles.font14Bold.copyWith(
                color: selected ? AppColors.primary : AppColors.fontColor)),
      ),
    );
  }
}

class _MissingSlot extends StatelessWidget {
  const _MissingSlot();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 34.w, color: AppColors.fontColor),
            SizedBox(height: 12.h),
            Text('لم يتم اختيار وقت',
                style: AppTextStyles.font16Bold
                    .copyWith(color: AppColors.uiBlack)),
            SizedBox(height: 6.h),
            Text('ارجع خطوة واختر وقتاً من الأوقات المتاحة.',
                textAlign: TextAlign.center,
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.fontColor)),
          ],
        ),
      ),
    );
  }
}
