import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/features/monthly_booking/domain/monthly_series_group.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/manager/monthly_booking_cubit/monthly_booking_cubit.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_actions.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_card.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_sheet.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/monthly_series_skeleton.dart';
import 'package:goal_master_admin/features/monthly_booking/presentation/view/widgets/reschedule_launcher.dart';

class MonthlyBookingBody extends StatelessWidget {
  const MonthlyBookingBody({super.key, this.now});

  /// Injected by tests so "the next session" is a fixed question.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MonthlyBookingCubit, MonthlyBookingState>(
      builder: (context, state) {
        if (state is MonthlyBookingError) {
          return _ErrorState(
            message: state.message,
            onRetry: () => context.read<MonthlyBookingCubit>().refresh(),
          );
        }

        if (state is! MonthlyBookingLoaded) {
          return const MonthlySeriesSkeleton();
        }

        return Column(
          children: [
            _Toolbar(state: state),
            Expanded(
              child: state.groups.isEmpty
                  ? _EmptyState(isFiltered: state.isFiltered)
                  : RefreshIndicator(
                      onRefresh: () =>
                          context.read<MonthlyBookingCubit>().refresh(),
                      child: ListView.builder(
                        padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
                        itemCount: state.groups.length,
                        itemBuilder: (context, index) {
                          final group = state.groups[index];
                          final clock = now ?? DateTime.now();

                          return MonthlySeriesCard(
                            group: group,
                            now: clock,
                            onDetails: () => _openDetails(context, group, clock),
                            onMenu: () => showSeriesActions(
                              context: context,
                              group: group,
                              now: clock,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _openDetails(
    BuildContext context,
    MonthlySeriesGroup group,
    DateTime clock,
  ) {
    baseBottomSheet(
      title: 'تفاصيل الحجز الشهري',
      context: context,
      hideNavBar: false,
      child: MonthlySeriesSheet(
        group: group,
        now: clock,
        onOccurrenceTap: (occurrence) {
          Navigator.pop(context);

          final start = MonthlySeriesGroup.occurrenceStart(occurrence);
          final today = DateTime(clock.year, clock.month, clock.day);
          final isUpcoming = start != null && !start.isBefore(today);

          showOccurrenceActions(
            context: context,
            group: group,
            occurrence: occurrence,
            isUpcoming: isUpcoming,
            onReschedule: !isUpcoming
                ? null
                : () {
                    Navigator.pop(context);
                    openReschedule(
                      context: context,
                      group: group,
                      occurrence: occurrence,
                      now: clock,
                    );
                  },
          );
        },
      ),
    );
  }
}

/// Search and the three states a manager filters by.
///
/// Both work on the complete list rather than on whatever has been scrolled
/// past, because this endpoint returns every row in one response.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.state});

  final MonthlyBookingLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MonthlyBookingCubit>();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.inactive3,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.inactive5),
            ),
            child: TextField(
              onChanged: cubit.search,
              style: AppTextStyles.font14Regular,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'ابحث باسم العميل أو الملعب',
                hintStyle: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.lightGrey),
                prefixIcon:
                    Icon(Icons.search, size: 19.r, color: AppColors.dark2),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: 32.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: SeriesFilter.values.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (_, i) {
                final filter = SeriesFilter.values[i];
                final selected = filter == state.filter;

                return GestureDetector(
                  onTap: () => cubit.filterBy(filter),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.inactive3,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : AppColors.inactive4,
                      ),
                    ),
                    child: Text(
                      filter.label,
                      style: AppTextStyles.font12SemiBold.copyWith(
                        color: selected ? AppColors.white : AppColors.dark2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Two different nothings: a venue with no monthly bookings at all, and a
/// filter that happens to match none. Telling them apart saves the manager
/// wondering whether their data has disappeared.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFiltered});

  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(18.r),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueLight2,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFiltered ? Icons.search_off_rounded : Icons.repeat_rounded,
                      size: 34.r,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    isFiltered
                        ? 'لا توجد نتائج مطابقة'
                        : 'لا توجد حجوزات شهرية حالياً',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font16Bold
                        .copyWith(color: AppColors.dark),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    isFiltered
                        ? 'جرّب تغيير البحث أو الفلتر.'
                        : 'الحجوزات الشهرية المتكررة ستظهر هنا، مع مواعيدها '
                            'والمبالغ المستحقة عليها.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14Regular
                        .copyWith(color: AppColors.dark2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40.r, color: AppColors.dark2),
            SizedBox(height: 14.h),
            Text(
              'تعذّر تحميل الحجوزات الشهرية',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16Bold.copyWith(color: AppColors.dark),
            ),
            SizedBox(height: 7.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.font12Regular
                  .copyWith(color: AppColors.dark2),
            ),
            SizedBox(height: 18.h),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 28.w, vertical: 11.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: AppTextStyles.font14Bold
                      .copyWith(color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the full server-side view of a series — the one that also carries the
/// venue's pending decision. Only meaningful for a real series.
void openFullSeriesScreen(BuildContext context, int seriesId) {
  context.push(RoutesKeys.kManagerSeriesDetails, extra: seriesId);
}
