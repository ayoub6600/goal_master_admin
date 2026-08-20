import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/page_wrapper.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';

class ManagerBookingPeriodsBody extends StatefulWidget {
  const ManagerBookingPeriodsBody({super.key});

  @override
  State<ManagerBookingPeriodsBody> createState() =>
      _ManagerBookingPeriodsBodyState();
}

class _ManagerBookingPeriodsBodyState extends State<ManagerBookingPeriodsBody> {
  final _eveningStart = TextEditingController(text: '17:00:00');
  // 24:00:00 (not 23:00) so the last hour before midnight (23:00-00:00)
  // belongs to the evening channel instead of falling in a gap between it
  // and the after-midnight channel.
  final _eveningEnd = TextEditingController(text: '24:00:00');
  final _nightStart = TextEditingController(text: '00:00:00');
  final _nightEnd = TextEditingController(text: '03:00:00');

  bool _eveningEnabled = true;
  bool _nightEnabled = false;
  bool _didPrefill = false;
  final Set<int> _eveningServiceIds = <int>{};
  final Set<int> _nightServiceIds = <int>{};

  @override
  void dispose() {
    _eveningStart.dispose();
    _eveningEnd.dispose();
    _nightStart.dispose();
    _nightEnd.dispose();
    super.dispose();
  }

  void _prefill(ManagerSetupBootstrapResponse? bootstrap) {
    if (_didPrefill || bootstrap == null) return;

    _eveningServiceIds.clear();
    _nightServiceIds.clear();

    for (final service in bootstrap.data.catalog.services) {
      if (service.supportsEvening) {
        _eveningServiceIds.add(service.id);
      }
      if (service.supportsAfterMidnight) {
        _nightServiceIds.add(service.id);
      }
    }

    for (final employee in bootstrap.data.catalog.employees) {
      if (employee.employeeId.contains('EVENING')) {
        _eveningEnabled = employee.status != 0;
        if (employee.startTime.isNotEmpty) {
          _eveningStart.text = employee.startTime;
        }
        if (employee.endTime.isNotEmpty) {
          _eveningEnd.text = employee.endTime;
        }
      }
      if (employee.employeeId.contains('AFTER-MIDNIGHT')) {
        _nightEnabled = employee.status != 0;
        if (employee.startTime.isNotEmpty) {
          _nightStart.text = employee.startTime;
        }
        if (employee.endTime.isNotEmpty) {
          _nightEnd.text = employee.endTime;
        }
      }
    }

    _didPrefill = true;
  }

  void _submit() {
    if (_eveningEnabled && _eveningServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اختر خدمة واحدة على الأقل للحجز المسائي.')),
      );
      return;
    }
    if (_nightEnabled && _nightServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('اختر خدمة واحدة على الأقل لحجز بعد منتصف الليل.')),
      );
      return;
    }

    context.read<ManagerSetupCubit>().saveBookingPeriods(
      periods: [
        {
          'key': 'evening',
          'enabled': _eveningEnabled,
          'start_time': _eveningStart.text.trim(),
          'end_time': _eveningEnd.text.trim(),
        },
        {
          'key': 'after_midnight',
          'enabled': _nightEnabled,
          'start_time': _nightStart.text.trim(),
          'end_time': _nightEnd.text.trim(),
        },
      ],
      serviceIdsByPeriod: {
        'evening': _eveningServiceIds.toList(),
        'after_midnight': _nightServiceIds.toList(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManagerSetupCubit, ManagerSetupState>(
      listener: (context, state) {
        if (state is ManagerSetupFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
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
        final isSubmitting = state is ManagerSetupSubmitting;

        return PageWrapper(
          title: 'فترات الحجز',
          child: bootstrap == null && state is ManagerSetupLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoCard(),
                      HeightSpace(18.h),
                      _periodCard(
                        title: 'حجز مسائي',
                        hint:
                            'هذه الفترة مخصصة للحجوزات التي تبدأ وتنتهي قبل منتصف الليل.',
                        enabled: _eveningEnabled,
                        onToggle: (value) =>
                            setState(() => _eveningEnabled = value),
                        startController: _eveningStart,
                        endController: _eveningEnd,
                        services: bootstrap?.data.catalog.services ?? const [],
                        selectedServiceIds: _eveningServiceIds,
                        onToggleService: (serviceId) {
                          setState(() {
                            if (_eveningServiceIds.contains(serviceId)) {
                              _eveningServiceIds.remove(serviceId);
                            } else {
                              _eveningServiceIds.add(serviceId);
                            }
                          });
                        },
                      ),
                      HeightSpace(18.h),
                      _periodCard(
                        title: 'حجز بعد منتصف الليل',
                        hint:
                            'فعّل هذه الفترة إذا كان الملعب يعمل بعد الساعة 12 ليلاً.',
                        enabled: _nightEnabled,
                        onToggle: (value) =>
                            setState(() => _nightEnabled = value),
                        startController: _nightStart,
                        endController: _nightEnd,
                        services: bootstrap?.data.catalog.services ?? const [],
                        selectedServiceIds: _nightServiceIds,
                        onToggleService: (serviceId) {
                          setState(() {
                            if (_nightServiceIds.contains(serviceId)) {
                              _nightServiceIds.remove(serviceId);
                            } else {
                              _nightServiceIds.add(serviceId);
                            }
                          });
                        },
                      ),
                      HeightSpace(18.h),
                      ButtonApp(
                        text:
                            isSubmitting ? 'جارٍ الحفظ...' : 'حفظ فترات الحجز',
                        onTap: isSubmitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xffF7FBF6),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        'هنا تتحكم في قنوات الحجز الزمنية نفسها. كل فترة لها ساعاتها الخاصة، وبعد ذلك تربط الخدمات بها في مرحلة مستقلة.',
        style: AppTextStyles.font14Medium.copyWith(height: 1.6),
      ),
    );
  }

  Widget _periodCard({
    required String title,
    required String hint,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required TextEditingController startController,
    required TextEditingController endController,
    required List<SetupServiceItem> services,
    required Set<int> selectedServiceIds,
    required ValueChanged<int> onToggleService,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.font18Bold)),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
          HeightSpace(8.h),
          Text(
            hint,
            style: AppTextStyles.font14Regular.copyWith(
              color: const Color(0xff6D7580),
              height: 1.5,
            ),
          ),
          HeightSpace(14.h),
          _timeField(startController, 'وقت البداية'),
          HeightSpace(12.h),
          _timeField(endController, 'وقت النهاية'),
          HeightSpace(14.h),
          Text(
            'الخدمات المرتبطة بهذه الفترة',
            style: AppTextStyles.font16Bold,
          ),
          HeightSpace(10.h),
          if (services.isEmpty)
            Text(
              'أضف خدمة أو ملعب أولاً، ثم ارجع لربطها بهذه الفترة.',
              style: AppTextStyles.font14Regular.copyWith(
                color: const Color(0xff6D7580),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: services.map((service) {
                final isSelected = selectedServiceIds.contains(service.id);
                return FilterChip(
                  label: Text(service.title),
                  selected: isSelected,
                  onSelected: (_) => onToggleService(service.id),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _timeField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'مثال: 17:00:00',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }
}
