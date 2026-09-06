import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/domain/opening_hours.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/manager/manager_setup_cubit/manager_setup_cubit.dart';
import 'package:goal_master_admin/features/venue_profile/presentation/view/widgets/venue_edit_sheet.dart';

/// The venue as its manager knows it: a name, a way to be reached, a place.
///
/// Read first. The old screen showed every value inside a text box whether or
/// not anyone was editing, which makes a profile look like a form and makes an
/// accidental keystroke look like a change. Here the values are simply read,
/// and a section is only editable once its «تعديل» is tapped.
class VenueProfileBody extends StatelessWidget {
  const VenueProfileBody({super.key, this.onEdit});

  /// Injected by tests so a section can be opened without a network stack.
  final void Function(VenueEditSection section)? onEdit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManagerSetupCubit, ManagerSetupState>(
      builder: (context, state) {
        final bootstrap = switch (state) {
          final ManagerSetupLoaded s => s.response,
          final ManagerSetupSubmitting s => s.bootstrap,
          final ManagerSetupFailure s => s.bootstrap,
          final ManagerBookingPeriodsSuccess s => s.bootstrap,
          _ => null,
        };

        if (bootstrap == null) {
          return state is ManagerSetupFailure
              ? _Message(
                  icon: Icons.cloud_off_rounded,
                  title: 'تعذّر تحميل بيانات الملعب',
                  detail: state.message,
                  onRetry: () =>
                      context.read<ManagerSetupCubit>().loadBootstrap(),
                )
              : const Center(child: CircularProgressIndicator());
        }

        final branch = bootstrap.data.setup.branch;

        if (branch == null) {
          // A manager who has not created a venue yet belongs in the wizard,
          // not in a profile of nothing.
          return _Message(
            icon: Icons.stadium_outlined,
            title: 'لم تُنشئ ملعبك بعد',
            detail: 'أكمل إعداد الملعب لتظهر بياناته هنا.',
            actionLabel: 'إعداد الملعب',
            onRetry: () => context.push(RoutesKeys.kAddFirstVenue),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Identity(branch: branch, onEdit: () => _edit(context, VenueEditSection.identity)),
              SizedBox(height: 18.h),
              _Section(
                title: 'المعلومات الأساسية',
                onEdit: () => _edit(context, VenueEditSection.identity),
                rows: [
                  ('اسم الملعب', branch.name),
                  ('المنطقة', branch.zoneName),
                ],
              ),
              SizedBox(height: 14.h),
              _Section(
                title: 'التواصل',
                onEdit: () => _edit(context, VenueEditSection.contact),
                rows: [
                  ('رقم الهاتف', branch.phone),
                  ('البريد الإلكتروني', branch.email),
                ],
              ),
              SizedBox(height: 14.h),
              _LocationSection(
                branch: branch,
                onEdit: () => _edit(context, VenueEditSection.location),
              ),
              SizedBox(height: 22.h),
              // Everything below has its own screen. Shown as a way in, with
              // the current value, rather than rebuilt here.
              _LinkRow(
                label: 'فترات الحجز',
                value: _hoursSummary(bootstrap),
                onTap: () => context.push(RoutesKeys.kManagerBookingPeriods),
              ),
              SizedBox(height: 10.h),
              _LinkRow(
                label: 'الملاعب والخدمات',
                value: _servicesSummary(bootstrap),
                onTap: () => context.push(RoutesKeys.kAddFirstVenue),
              ),
            ],
          ),
        );
      },
    );
  }

  void _edit(BuildContext context, VenueEditSection section) {
    if (onEdit != null) {
      onEdit!(section);
      return;
    }
    showVenueEditSheet(context: context, section: section);
  }

  /// The venue's night, read from the same bands the hours screen writes —
  /// never a second copy of the setting.
  static String _hoursSummary(ManagerSetupBootstrapResponse bootstrap) {
    String? eveningStart, eveningEnd, nightEnd;
    var nightEnabled = false;

    for (final e in bootstrap.data.catalog.employees) {
      if (e.isEveningChannel) {
        eveningStart = e.startTime;
        eveningEnd = e.endTime;
      }
      if (e.isAfterMidnightChannel) {
        nightEnabled = e.status != 0;
        nightEnd = e.endTime;
      }
    }

    if (eveningStart == null || eveningStart.isEmpty) return 'لم تُحدَّد بعد';

    final hours = OpeningHours.fromBands(
      eveningStart: eveningStart,
      eveningEnd: eveningEnd,
      afterMidnightEnd: nightEnd,
      afterMidnightEnabled: nightEnabled,
    );

    return '${arabicClock(hours.opensAt)} – ${arabicClock(hours.closesAt)}';
  }

  static String _servicesSummary(ManagerSetupBootstrapResponse bootstrap) {
    final count = bootstrap.data.catalog.services.length;

    return switch (count) {
      0 => 'لم تُضف ملاعب بعد',
      1 => 'ملعب واحد',
      2 => 'ملعبان',
      _ => '$count ملاعب',
    };
  }
}

/// The logo, the name, the city — the "this is my venue" moment.
class _Identity extends StatelessWidget {
  const _Identity({required this.branch, required this.onEdit});

  final dynamic branch;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (branch.imageUrl ?? '').toString();

    return Column(
      children: [
        GestureDetector(
          onTap: onEdit,
          child: Container(
            width: 92.w,
            height: 92.w,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.inactive5, width: 2),
              image: imageUrl.isEmpty
                  ? null
                  : DecorationImage(
                      image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
            child: imageUrl.isEmpty
                ? Icon(Icons.stadium_outlined,
                    size: 38.r, color: AppColors.primary)
                : null,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          branch.name.toString(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.font20Bold.copyWith(color: AppColors.dark),
        ),
        if (branch.zoneName.toString().isNotEmpty) ...[
          SizedBox(height: 3.h),
          Text(
            branch.zoneName.toString(),
            style:
                AppTextStyles.font14Regular.copyWith(color: AppColors.dark2),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.rows,
    required this.onEdit,
  });

  final String title;
  final List<(String, String)> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: title,
      onEdit: onEdit,
      child: Column(
        children: [
          for (final (label, value) in rows) _ReadRow(label: label, value: value),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.branch, required this.onEdit});

  final dynamic branch;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final lat = (branch.lat ?? '').toString();
    final long = (branch.long ?? '').toString();
    final pinned = lat.isNotEmpty && long.isNotEmpty;

    return _Card(
      title: 'الموقع',
      onEdit: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReadRow(label: 'العنوان', value: branch.address.toString()),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(
                pinned ? Icons.place_rounded : Icons.location_off_outlined,
                size: 16.r,
                color: pinned ? AppColors.success : AppColors.dark2,
              ),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  // Coordinates are how a map stores a place, not how a person
                  // reads one. Whether the pin exists is the useful fact.
                  pinned
                      ? 'الموقع محدَّد على الخريطة'
                      : 'لم يُحدَّد الموقع على الخريطة بعد',
                  style: AppTextStyles.font12Regular.copyWith(
                    color: pinned ? AppColors.success : AppColors.dark2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.onEdit});

  final String title;
  final Widget child;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.inactive5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: AppTextStyles.font16Bold
                        .copyWith(color: AppColors.dark)),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    child: Text('تعديل',
                        style: AppTextStyles.font14SemiBold
                            .copyWith(color: AppColors.primary)),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}

class _ReadRow extends StatelessWidget {
  const _ReadRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108.w,
            child: Text(label,
                style: AppTextStyles.font12Regular
                    .copyWith(color: AppColors.dark2)),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'غير محدد' : value,
              style: AppTextStyles.font14SemiBold.copyWith(
                color: value.trim().isEmpty ? AppColors.dark2 : AppColors.dark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A way into a screen that owns this setting, showing where it currently
/// stands. Never an editor.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.inactive3,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.inactive5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.font14SemiBold
                          .copyWith(color: AppColors.dark)),
                  SizedBox(height: 2.h),
                  Text(value,
                      style: AppTextStyles.font12Regular
                          .copyWith(color: AppColors.dark2)),
                ],
              ),
            ),
            Icon(Icons.chevron_left, size: 20.r, color: AppColors.dark2),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40.r, color: AppColors.dark2),
            SizedBox(height: 14.h),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    AppTextStyles.font16Bold.copyWith(color: AppColors.dark)),
            SizedBox(height: 7.h),
            Text(detail,
                textAlign: TextAlign.center,
                style: AppTextStyles.font12Regular
                    .copyWith(color: AppColors.dark2)),
            if (onRetry != null) ...[
              SizedBox(height: 18.h),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 26.w, vertical: 11.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(actionLabel ?? 'إعادة المحاولة',
                      style: AppTextStyles.font14Bold
                          .copyWith(color: AppColors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
