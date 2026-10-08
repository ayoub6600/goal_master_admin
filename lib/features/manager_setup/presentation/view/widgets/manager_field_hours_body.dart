import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';

import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/data/repo/manager_setup_repo_imp.dart';
import 'package:goal_master_admin/features/manager_setup/domain/opening_hours.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';

/// Step 1: select the real field.
/// Step 2: edit only that field's opening/closing hours.
class ManagerFieldHoursBody extends StatefulWidget {
  const ManagerFieldHoursBody({super.key});

  @override
  State<ManagerFieldHoursBody> createState() => _ManagerFieldHoursBodyState();
}

class _ManagerFieldHoursBodyState extends State<ManagerFieldHoursBody> {
  int? _selectedResourceId;
  bool _saving = false;

  OpeningHours _hours = const OpeningHours(
    opensAt: TimeOfDay(hour: 16, minute: 0),
    closesAt: TimeOfDay(hour: 3, minute: 0),
  );

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final parts = raw.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _apiTime(TimeOfDay value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _select(
    SetupPhysicalResource resource,
    ManagerSetupBootstrapResponse bootstrap,
  ) {
    // Existing venues may not have per-field hours configured yet.
    // Display their previous operational hours as the initial suggestion.
    String? eveningStart;
    String? eveningEnd;
    String? nightEnd;
    bool nightEnabled = false;

    for (final employee in bootstrap.data.catalog.employees) {
      if (employee.isEveningChannel) {
        eveningStart = employee.startTime;
        eveningEnd = employee.endTime;
      }

      if (employee.isAfterMidnightChannel) {
        nightEnd = employee.endTime;
        nightEnabled = employee.status != 0;
      }
    }

    final fallback = OpeningHours.fromBands(
      eveningStart: eveningStart,
      eveningEnd: eveningEnd,
      afterMidnightEnd: nightEnd,
      afterMidnightEnabled: nightEnabled,
    );

    setState(() {
      _selectedResourceId = resource.id;
      _hours = OpeningHours(
        opensAt: _parseTime(resource.opensAt) ?? fallback.opensAt,
        closesAt: _parseTime(resource.closesAt) ?? fallback.closesAt,
      );
    });
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

    if (picked == null || !mounted) return;

    setState(() {
      _hours = OpeningHours(
        opensAt: opening ? picked : _hours.opensAt,
        closesAt: opening ? _hours.closesAt : picked,
      );
    });
  }

  Future<void> _save() async {
    final id = _selectedResourceId;
    if (id == null || _saving) return;

    final problem = _hours.problem;
    if (problem != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(problem)),
      );
      return;
    }

    setState(() => _saving = true);

    final result = await getIt<ManagerSetupRepoImp>().savePhysicalResourceHours(
      resourceId: id,
      opensAt: _apiTime(_hours.opensAt),
      closesAt: _apiTime(_hours.closesAt),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.errMessage)),
        );
      },
      (_) {
        showCustomSuccessToast('تم حفظ ساعات الملعب بنجاح');
        setState(() => _selectedResourceId = null);
        context.read<ManagerSetupCubit>().loadBootstrap();
      },
    );

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  Widget _card({
    required String title,
    required Widget child,
    String? subtitle,
  }) {
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
          Text(
            title,
            style: AppTextStyles.font16Bold,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 5.h),
            Text(
              subtitle,
              style: AppTextStyles.font12Regular,
            ),
          ],
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }

  Widget _fieldList(
    ManagerSetupBootstrapResponse bootstrap,
  ) {
    final resources = bootstrap.data.catalog.physicalResources;

    if (resources.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: const Text('ما عندكش ملاعب مضافة حتى الآن.'),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 32.h),
      children: [
        Text(
          'اختار الملعب اللي تبي تحدد ساعات تشغيله',
          style: AppTextStyles.font16Bold,
        ),
        SizedBox(height: 15.h),
        for (final resource in resources) ...[
          Card(
            color: AppColors.white,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15.w,
                vertical: 8.h,
              ),
              leading: Icon(
                resource.isMulti
                    ? Icons.sports_basketball_outlined
                    : Icons.sports_soccer_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                resource.name,
                style: AppTextStyles.font16Bold,
              ),
              subtitle: Text(
                '${resource.isMulti ? 'مالتي' : 'عادي'}'
                '\n'
                '${resource.opensAt == null || resource.closesAt == null ? 'ساعات خاصة غير محددة بعد' : 'من ${resource.opensAt} إلى ${resource.closesAt}'}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _select(resource, bootstrap),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }

  Widget _timeTile({
    required String title,
    required TimeOfDay value,
    required VoidCallback onTap,
    String? note,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.access_time_outlined,
        color: AppColors.primary,
      ),
      title: Text(title),
      subtitle: note == null ? null : Text(note),
      trailing: Text(
        arabicClock(value),
        style: AppTextStyles.font14Regular,
      ),
      onTap: onTap,
    );
  }

  Widget _hoursEditor(SetupPhysicalResource resource) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _saving
                ? null
                : () => setState(() => _selectedResourceId = null),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('رجوع لقائمة الملاعب'),
          ),
          SizedBox(height: 10.h),
          Text(
            'ساعات تشغيل ${resource.name}',
            style: AppTextStyles.font16Bold,
          ),
          SizedBox(height: 14.h),
          _card(
            title: 'متى يفتح ملعبك؟',
            subtitle: 'التوقيت خاص بهذا الملعب فقط.',
            child: Column(
              children: [
                _timeTile(
                  title: 'يفتح',
                  value: _hours.opensAt,
                  onTap: () => _pick(opening: true),
                ),
                const Divider(),
                _timeTile(
                  title: 'يغلق',
                  value: _hours.closesAt,
                  note: _hours.crossesMidnight ? 'اليوم التالي' : null,
                  onTap: () => _pick(opening: false),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          _card(
            title: _hours.problem == null
                ? 'الملعب مفتوح ${arabicDuration(_hours.durationMinutes)}'
                : 'راجع ساعات التشغيل',
            child: Text(
              _hours.problem ??
                  'من ${arabicClock(_hours.opensAt)} '
                      'إلى ${arabicClock(_hours.closesAt)}'
                      '${_hours.crossesMidnight ? ' من اليوم التالي' : ''}',
              style: AppTextStyles.font14Regular,
            ),
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving || !_hours.isValid ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: 15.h),
              ),
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('حفظ ساعات الملعب'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManagerSetupCubit, ManagerSetupState>(
      builder: (context, state) {
        final bootstrap = context.read<ManagerSetupCubit>().bootstrapResponse;

        SetupPhysicalResource? selected;

        if (bootstrap != null && _selectedResourceId != null) {
          for (final resource in bootstrap.data.catalog.physicalResources) {
            if (resource.id == _selectedResourceId) {
              selected = resource;
              break;
            }
          }
        }

        return PageWrapper(
          title:
              selected == null ? 'فترات الحجز' : 'ساعات تشغيل ${selected.name}',
          child: bootstrap == null
              ? Center(
                  child: TextButton(
                    onPressed: () =>
                        context.read<ManagerSetupCubit>().loadBootstrap(),
                    child: const Text('جارٍ التحميل... اضغط لإعادة المحاولة'),
                  ),
                )
              : selected == null
                  ? _fieldList(bootstrap)
                  : _hoursEditor(selected),
        );
      },
    );
  }
}
