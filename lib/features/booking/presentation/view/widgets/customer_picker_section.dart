import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/features/booking/data/model/manager_customer.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_customer_cubit/add_customer_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/manager_customers_cubit/manager_customers_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/page_view_cubit/page_view_cubit_cubit.dart';

/// «اختر العميل» — a search-first operational screen.
///
/// A venue with three hundred customers cannot be worked through a dropdown.
/// The search field is the screen's first control, the results are cards big
/// enough to hit while holding a phone, and each one leads with the name the
/// manager themselves wrote in their book — not the name the customer chose on
/// the platform.
///
/// «الحالة» used to live here. It is a property of the booking, not of the
/// person, and it now sits on the confirmation screen beside the amount, where
/// «خالص» means something.
class CustomerPickerSection extends StatefulWidget {
  const CustomerPickerSection({super.key, required this.controller});

  final PageController controller;

  @override
  State<CustomerPickerSection> createState() => _CustomerPickerSectionState();
}

class _CustomerPickerSectionState extends State<CustomerPickerSection> {
  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    context.read<ManagerCustomersCubit>().load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 320) {
      context.read<ManagerCustomersCubit>().loadMore();
    }
  }

  /// Typing «محمد» is four keystrokes; without this it is four round trips and
  /// four chances for an out-of-order response.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<ManagerCustomersCubit>().load(search: value);
    });
  }

  void _choose(ManagerCustomer customer) {
    context.read<ManagerCustomersCubit>().select(customer);

    // The booking carries the customer's id. `nameCustomer` is display only —
    // it never becomes an identity, and it never rewrites the platform name.
    context.read<PageViewCubit>().setCustomerId(
          customer.id,
          customer.phoneNo,
          customer.displayName,
        );

    context.read<PageViewCubit>().nextPage();
    widget.controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManagerCustomersCubit, ManagerCustomersState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اختر العميل',
                      style: AppTextStyles.font20Bold
                          .copyWith(color: AppColors.uiBlack)),
                  SizedBox(height: 12.h),
                  _searchField(),
                  SizedBox(height: 10.h),
                  _addButton(),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(child: _results(state)),
          ],
        );
      },
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.font16Regular,
      decoration: InputDecoration(
        hintText: 'ابحث بالاسم أو رقم الهاتف',
        hintStyle:
            AppTextStyles.font14Regular.copyWith(color: AppColors.fontColor),
        prefixIcon: Icon(Icons.search, color: AppColors.fontColor, size: 22.w),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, size: 20.w),
                onPressed: () {
                  _search.clear();
                  context.read<ManagerCustomersCubit>().load(search: '');
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: AppColors.inactive3,
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _addButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: _openAddSheet,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: AppColors.primaryBlueLight2,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.primaryBlueLight),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_alt, size: 20.w, color: AppColors.primary),
            SizedBox(width: 8.w),
            Text('إضافة عميل جديد',
                style:
                    AppTextStyles.font14Bold.copyWith(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Widget _results(ManagerCustomersState state) {
    if (state.isLoading) return const _CustomerSkeleton();

    if (state.error != null) {
      return _Empty(
        icon: Icons.error_outline,
        tone: AppColors.errorRed,
        title: 'تعذّر تحميل العملاء',
        body: state.error!,
      );
    }

    if (state.customers.isEmpty) {
      return _Empty(
        icon: Icons.person_search_outlined,
        title: state.search.isEmpty
            ? 'لا يوجد عملاء بعد'
            : 'لا يوجد عميل بهذا الاسم أو الرقم',
        body: 'أضف عميلاً جديداً وسيصبح جاهزاً للحجز فوراً.',
      );
    }

    return ListView.separated(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      itemCount: state.customers.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        if (index >= state.customers.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final customer = state.customers[index];
        return _CustomerCard(
          customer: customer,
          selected: state.selected?.id == customer.id,
          onTap: () => _choose(customer),
        );
      },
    );
  }

  void _openAddSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    baseBottomSheet(
      context: context,
      hideNavBar: true,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<AddCustomerCubit>()),
            BlocProvider.value(value: context.read<PageViewCubit>()),
            BlocProvider.value(value: context.read<ManagerCustomersCubit>()),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('عميل جديد',
                  style: AppTextStyles.font18Bold
                      .copyWith(color: AppColors.uiBlack)),
              SizedBox(height: 6.h),
              // Says out loud what the backend already does, so a manager
              // adding somebody who turns out to have a Goal Master account
              // is not surprised by the result.
              Text(
                'إذا كان الرقم مسجّلاً في Goal Master سيتم ربط العميل بحسابه'
                ' دون تغيير اسمه في المنصة.',
                style: AppTextStyles.font12Regular
                    .copyWith(color: AppColors.fontColor),
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                controller: nameController,
                inputType: TextInputType.name,
                hint: 'اسم العميل عندك',
              ),
              SizedBox(height: 14.h),
              CustomTextField(
                controller: phoneController,
                inputType: TextInputType.phone,
                hint: 'رقم الجوال',
              ),
              SizedBox(height: 18.h),
              BlocConsumer<AddCustomerCubit, AddCustomerState>(
                listener: (sheetContext, state) {
                  if (state is AddCustomerSuccess) {
                    final created = ManagerCustomer(
                      id: int.tryParse(state.customerId ?? '0') ?? 0,
                      // The alias is what the manager just typed, and it is
                      // what they will look for a minute from now.
                      displayName: nameController.text.trim(),
                      alias: nameController.text.trim(),
                      platformName: nameController.text.trim(),
                      phoneNo: phoneController.text.trim(),
                    );

                    Navigator.pop(sheetContext);

                    // Selectable immediately — no booking required first.
                    context.read<ManagerCustomersCubit>().adopt(created);
                    showCustomSuccessToast('تم إضافة العميل بنجاح');
                    _choose(created);
                  } else if (state is AddCustomerFailure) {
                    showCustomFailureToast(
                        'يرجى التأكد من صحة البيانات المدخلة');
                  }
                },
                builder: (sheetContext, state) {
                  if (state is AddCustomerLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ButtonApp(
                    text: 'إضافة',
                    textColor: Colors.white,
                    backGround: AppColors.primary,
                    onTap: () {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();

                      if (name.isEmpty || phone.isEmpty) {
                        showCustomFailureToast('يرجى تعبئة جميع الحقول');
                        return;
                      }

                      sheetContext
                          .read<AddCustomerCubit>()
                          .addCustomer(fullName: name, phone: phone);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.selected,
    required this.onTap,
  });

  final ManagerCustomer customer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        constraints: BoxConstraints(minHeight: 68.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlueLight2 : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.inactive4,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.inactive3,
                shape: BoxShape.circle,
              ),
              child: Text(
                customer.initial,
                style: AppTextStyles.font16Bold.copyWith(
                    color: selected ? Colors.white : AppColors.fontColor),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customer.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font16Bold
                        .copyWith(color: AppColors.uiBlack),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    customer.phoneNo,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    style: AppTextStyles.font14Regular
                        .copyWith(color: AppColors.fontColor),
                  ),
                  // Shown only when it says something the line above did not.
                  if (customer.hasDistinctPlatformName) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'في Goal Master: ${customer.platformName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.font12Regular
                          .copyWith(color: AppColors.inactiveText5),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24.w),
          ],
        ),
      ),
    );
  }
}

class _CustomerSkeleton extends StatelessWidget {
  const _CustomerSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      itemCount: 6,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, __) => Container(
        height: 68.h,
        decoration: BoxDecoration(
          color: AppColors.inactive3,
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.body,
    this.tone,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? AppColors.fontColor;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36.w, color: color),
            SizedBox(height: 12.h),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTextStyles.font16Bold.copyWith(color: color)),
            SizedBox(height: 6.h),
            Text(body,
                textAlign: TextAlign.center,
                style: AppTextStyles.font14Regular
                    .copyWith(color: AppColors.fontColor)),
          ],
        ),
      ),
    );
  }
}
