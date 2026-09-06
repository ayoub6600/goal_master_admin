import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/domain/opening_hours.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';

/// «متى يفتح ملعبك؟» — one question, asked the way an owner thinks.
///
/// This screen used to present the venue's night as two configurable channels
/// called «حجز مسائي» and «حجز بعد منتصف الليل», each with raw `17:00:00` and
/// `24:00:00` text fields and its own switch. Those are not concepts a pitch
/// owner has; they are how the booking engine stores a night, because it
/// recognises an after-midnight session by finding a band whose window lies
/// wholly in the small hours.
///
/// That storage is still exactly what gets saved — nothing about the engine,
/// the bands or the existing bookings changes. The manager is simply no longer
/// asked to think in it: they say when they open and when they close, and the
/// split happens on the way out.
class ManagerBookingPeriodsBody extends StatefulWidget {
  const ManagerBookingPeriodsBody({super.key, this.onSave, this.initialHours});

  /// Injected by tests to capture the payload without a network call.
  final void Function(
    List<Map<String, dynamic>> periods,
    Map<String, List<int>> serviceIdsByPeriod,
  )? onSave;

  /// Injected by tests to start from a chosen night.
  final OpeningHours? initialHours;

  @override
  State<ManagerBookingPeriodsBody> createState() =>
      _ManagerBookingPeriodsBodyState();
}

class _ManagerBookingPeriodsBodyState extends State<ManagerBookingPeriodsBody> {
  late OpeningHours _hours = widget.initialHours ??
      const OpeningHours(
    opensAt: TimeOfDay(hour: 17, minute: 0),
    closesAt: TimeOfDay(hour: 0, minute: 0),
  );

  /// The pitches bookable during the night, as one question — the manager was
  /// previously asked the same thing twice, once per band.
  final Set<int> _serviceIds = <int>{};

  /// What each band offered when the screen loaded.
  ///
  /// The server deactivates any pitch missing from the list it is sent, and
  /// activates every pitch that is in it — per band. Sending one merged list
  /// to both bands would therefore quietly widen a pitch that was only
  /// available in the evening into the small hours as well, purely because
  /// somebody opened this screen and saved.
  ///
  /// So the existing split is remembered and preserved: an untouched pitch
  /// keeps the bands it already had, and only what the manager actually
  /// changed changes.
  final Set<int> _wasEvening = <int>{};
  final Set<int> _wasAfterMidnight = <int>{};

  bool _didPrefill = false;

  void _prefill(ManagerSetupBootstrapResponse? bootstrap) {
    if (_didPrefill || bootstrap == null) return;
    final keepInjectedHours = widget.initialHours != null;

    for (final service in bootstrap.data.catalog.services) {
      if (service.supportsEvening) _wasEvening.add(service.id);
      if (service.supportsAfterMidnight) _wasAfterMidnight.add(service.id);
      if (service.supportsEvening || service.supportsAfterMidnight) {
        _serviceIds.add(service.id);
      }
    }

    String? eveningStart, eveningEnd, nightEnd;
    var nightEnabled = false;

    for (final employee in bootstrap.data.catalog.employees) {
      if (employee.isEveningChannel) {
        eveningStart = employee.startTime;
        eveningEnd = employee.endTime;
      }
      if (employee.isAfterMidnightChannel) {
        nightEnabled = employee.status != 0;
        nightEnd = employee.endTime;
      }
    }

    if (!keepInjectedHours) {
      _hours = OpeningHours.fromBands(
        eveningStart: eveningStart,
        eveningEnd: eveningEnd,
        afterMidnightEnd: nightEnd,
        afterMidnightEnabled: nightEnabled,
      );
    }

    _didPrefill = true;
  }

  Future<void> _pick({required bool opening}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: opening ? _hours.opensAt : _hours.closesAt,
      helpText: opening ? 'وقت فتح الملعب' : 'وقت إغلاق الملعب',
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() {
      _hours = OpeningHours(
        opensAt: opening ? picked : _hours.opensAt,
        closesAt: opening ? _hours.closesAt : picked,
      );
    });
  }

  void _submit() {
    final problem = _hours.problem;
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
      return;
    }

    if (_serviceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر ملعبًا واحدًا على الأقل.')),
      );
      return;
    }

    // The one thing the manager entered, translated into the two windows the
    // engine has always stored. The API contract is untouched.
    final evening = _hours.eveningWindow;
    final night = _hours.afterMidnightWindow;

    final periods = <Map<String, dynamic>>[
      {
        'key': 'evening',
        'enabled': true,
        'start_time': evening.$1,
        'end_time': evening.$2,
      },
      {
        'key': 'after_midnight',
        'enabled': night != null,
        'start_time': night?.$1 ?? '00:00:00',
        'end_time': night?.$2 ?? '03:00:00',
      },
    ];

    final services = <String, List<int>>{
      'evening': _forBand(_wasEvening),
      'after_midnight': night == null ? const <int>[] : _forBand(_wasAfterMidnight),
    };

    if (widget.onSave != null) {
      widget.onSave!(periods, services);
      return;
    }

    context.read<ManagerSetupCubit>().saveBookingPeriods(
          periods: periods,
          serviceIdsByPeriod: services,
        );
  }

  /// The pitches this band should offer after the manager's edit.
  ///
  /// Keeps what the band already had (minus anything unchecked), and adds any
  /// pitch newly checked — a new pitch has no band of its own yet, so it
  /// becomes available whenever the venue is open.
  List<int> _forBand(Set<int> had) {
    final known = {..._wasEvening, ..._wasAfterMidnight};

    return _serviceIds
        .where((id) => had.contains(id) || !known.contains(id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManagerSetupCubit, ManagerSetupState>(
      listener: (context, state) {
        if (state is ManagerSetupFailure) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is ManagerBookingPeriodsSuccess) {
          showCustomSuccessToast(state.response.message);
        }
      },
      builder: (context, state) {
        final bootstrap = switch (state) {
          final ManagerSetupLoaded s => s.response,
          final ManagerSetupSubmitting s => s.bootstrap,
          final ManagerSetupFailure s => s.bootstrap,
          final ManagerBookingPeriodsSuccess s => s.bootstrap,
          _ => null,
        };

        _prefill(bootstrap);
        final busy = state is ManagerSetupSubmitting;
        final services = bootstrap?.data.catalog.services ?? const [];

        return PageWrapper(
          title: 'فترات الحجز',
          child: bootstrap == null && state is ManagerSetupLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _hoursCard(),
                      SizedBox(height: 16.h),
                      _summaryCard(),
                      SizedBox(height: 16.h),
                      _servicesCard(services),
                      SizedBox(height: 22.h),
                      _saveButton(busy),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // ---- The one question -------------------------------------------------

  Widget _hoursCard() {
    return _Card(
      title: 'متى يفتح ملعبك؟',
      child: Column(
        children: [
          _TimeRow(
            label: 'يفتح',
            time: _hours.opensAt,
            onTap: () => _pick(opening: true),
          ),
          SizedBox(height: 10.h),
          _TimeRow(
            label: 'يغلق',
            time: _hours.closesAt,
            // Said once, where it is decided, rather than as a checkbox the
            // manager has to reason about.
            note: _hours.crossesMidnight ? 'اليوم التالي' : null,
            onTap: () => _pick(opening: false),
          ),
        ],
      ),
    );
  }

  /// What the manager just described, read back to them in one sentence.
  Widget _summaryCard() {
    final problem = _hours.problem;

    if (problem != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: AppColors.dangerLight1,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 18.r, color: AppColors.errorRed),
            SizedBox(width: 9.w),
            Expanded(
              child: Text(
                problem,
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.lightSuccess,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 18.r, color: AppColors.success),
          SizedBox(width: 9.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملعبك مفتوح ${arabicDuration(_hours.durationMinutes)} كل ليلة',
                  style: AppTextStyles.font14Bold
                      .copyWith(color: AppColors.dark),
                ),
                SizedBox(height: 3.h),
                Text(
                  'من ${arabicClock(_hours.opensAt)} '
                  'إلى ${arabicClock(_hours.closesAt)}'
                  '${_hours.crossesMidnight ? ' من اليوم التالي' : ''}',
                  style: AppTextStyles.font12Regular
                      .copyWith(color: AppColors.dark2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Which pitches ----------------------------------------------------

  Widget _servicesCard(List<dynamic> services) {
    return _Card(
      title: 'الملاعب المتاحة للحجز',
      subtitle: 'اختر الملاعب التي تُحجز خلال هذه الساعات.',
      child: services.isEmpty
          ? Text(
              'لم تُضف ملاعب بعد.',
              style:
                  AppTextStyles.font14Regular.copyWith(color: AppColors.dark2),
            )
          : Column(
              children: [
                for (final service in services)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                    value: _serviceIds.contains(service.id),
                    title: Text(
                      service.title.toString(),
                      style: AppTextStyles.font14Regular
                          .copyWith(color: AppColors.dark),
                    ),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _serviceIds.add(service.id as int);
                      } else {
                        _serviceIds.remove(service.id as int);
                      }
                    }),
                  ),
              ],
            ),
    );
  }

  Widget _saveButton(bool busy) {
    final ready = _hours.isValid && _serviceIds.isNotEmpty && !busy;

    return GestureDetector(
      onTap: ready ? _submit : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 13.h),
        decoration: BoxDecoration(
          color: ready ? AppColors.primary : AppColors.inactive4,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            busy ? 'جارٍ الحفظ…' : 'حفظ ساعات العمل',
            style: AppTextStyles.font16Bold.copyWith(
              color: ready ? AppColors.white : AppColors.dark2,
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.inactive5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.font16Bold.copyWith(color: AppColors.dark)),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(subtitle!,
                style: AppTextStyles.font12Regular
                    .copyWith(color: AppColors.dark2)),
          ],
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }
}

/// One tappable clock. Shows «٥:٠٠ م», never «17:00:00».
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.time,
    required this.onTap,
    this.note,
  });

  final String label;
  final TimeOfDay time;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: AppColors.inactive3,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.inactive4),
        ),
        child: Row(
          children: [
            Text(label,
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.dark2)),
            SizedBox(width: 12.w),
            // «منتصف الليل» beside «اليوم التالي» does not fit one line on a
            // 320px phone, so the clock and its note wrap instead of pushing
            // the row past the edge.
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    arabicClock(time),
                    style: AppTextStyles.font16Bold
                        .copyWith(color: AppColors.dark),
                  ),
                  if (note != null)
                    Text(
                      note!,
                      style: AppTextStyles.font12Regular
                          .copyWith(color: AppColors.success),
                    ),
                ],
              ),
            ),
            Icon(Icons.schedule_rounded, size: 18.r, color: AppColors.dark2),
          ],
        ),
      ),
    );
  }
}
