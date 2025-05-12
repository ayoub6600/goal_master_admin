import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_drop_down_shimmer_items.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/services/service_locator.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/assets.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_cubit/booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/booking_list.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/features/profail/data/model/allowed_amount_response.dart';
import 'package:goal_master_admin/features/profail/data/repo/profile_repo_imp.dart';
import 'package:goal_master_admin/features/profail/presentation/manager/customer_cubit/customer_cubit.dart';
import 'package:intl/intl.dart';
//fltterblo
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/components/custom_date_picker.dart';
import '../../../../../core/components/custom_drop_down_shimmer.dart';

class BookingViewBody extends StatelessWidget {
  const BookingViewBody({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeightSpace(16),
        GestureDetector(
          onTap: () {
            final parentContext = context; // ده اللي فيه BlocProvider

            baseBottomSheet(
                title: "بحث",
                context: context,
                hideNavBar: false,
                child: BlocProvider(
                  create: (context) => CustomerCubit(
                    bookingRepo: getIt<ProfileRepoImp>(),
                  ),
                  child: BookingViewBodyBottomSheet(
                    cubitContext: parentContext,
                  ),
                ));
          },
          child: Container(
            width: 300.w,
            height: 40.h,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                width: 1,
                color: const Color(0xffDADEE3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ابحث",
                    style: AppTextStyles.font14Medium
                        .copyWith(color: AppColors.fontColor)),
                Image.asset(Assets.imagesPngImageSearchNormal),
              ],
            ),
          ),
        ),
        HeightSpace(16.h),
        Expanded(child: BookingList()),
      ],
    );
  }
}

class BookingViewBodyBottomSheet extends StatefulWidget {
  final BuildContext cubitContext;
  const BookingViewBodyBottomSheet({super.key, required this.cubitContext});

  @override
  State<BookingViewBodyBottomSheet> createState() =>
      _BookingViewBodyBottomSheetState();
}

class _BookingViewBodyBottomSheetState
    extends State<BookingViewBodyBottomSheet> {
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController customerIdController = TextEditingController();
  final TextEditingController serviceStatusController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  @override
  void dispose() {
    // employeeIdController.dispose();
    // customerIdController.dispose();
    // serviceStatusController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final cubit = widget.cubitContext.read<BookingCubit>();

    if (cubit.employeeId != null) {
      employeeIdController.text = cubit.employeeId!;
    }
    if (cubit.customerId != null) {
      customerIdController.text = cubit.customerId!;
    }
    if (cubit.status != null) {
      serviceStatusController.text = cubit.status!;
    }

    if (cubit.bookingStart != null) {
      startDate = DateTime.tryParse(cubit.bookingStart!);
    }
    if (cubit.bookingEnd != null) {
      endDate = DateTime.tryParse(cubit.bookingEnd!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = widget.cubitContext.read<BookingCubit>();

    return SingleChildScrollView(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("من", style: AppTextStyles.font14Medium),
                    HeightSpace(8.h),
                    CustomDatePicker(
                      initialDate: startDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 3650)),
                      lastDate: DateTime.now(),
                      onDatePicked: (value) {
                        if (value != null) {
                          startDate = value;
                          cubit.updateBookingStart(
                              DateFormat('yyyy-MM-dd').format(value));
                        }
                      },
                    ),
                  ],
                ),
              ),
              WidthSpace(16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("إلى", style: AppTextStyles.font14Medium),
                    HeightSpace(8.h),
                    CustomDatePicker(
                      initialDate: endDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 3650)),
                      lastDate: DateTime.now(),
                      onDatePicked: (value) {
                        if (value != null) {
                          endDate = value;
                          cubit.updateBookingEnd(
                              DateFormat('yyyy-MM-dd').format(value));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          HeightSpace(16.h),
          CustomDropDownShimmerNew(
            label: "",
            hint: "اختر الحالة",
            items: [
              {"id": 0, "name_ar": "قيد الانتظار"},
              {"id": 1, "name_ar": "قيد المعالجة"},
              {"id": 2, "name_ar": "موافَق عليه"},
              {"id": 3, "name_ar": "ملغي"},
              {"id": 4, "name_ar": "مكتمل"},
            ],
            selectedValue: cubit.status,
            onChanged: (val) {
              print("-------->val: $val");
              cubit.updateStatus(val ?? "");
            },
          ),
          HeightSpace(16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      hint: "رقم الموظف",
                      controller: employeeIdController,
                      inputType: TextInputType.number,
                    ),
                    HeightSpace(8.h),
                    CustomerDropdown(
                      selectedCustomerId: cubit.customerId,
                      onChanged: (id) {
                        cubit.updateCustomerId(id ?? '');
                      },
                    ),
                    HeightSpace(8.h),
                  ],
                ),
              ),
            ],
          ),
          HeightSpace(16.h),
          ButtonApp(
            text: "بحث",
            onTap: () async {
              cubit.updateEmployeeId(employeeIdController.text);
              cubit.updateCustomerId(customerIdController.text);

              await cubit.filterBooking();

              Navigator.of(context).pop();

              Future.delayed(Duration(milliseconds: 500), () {
                employeeIdController.clear();
                customerIdController.clear();
                serviceStatusController.clear();
                startDate = null;
                endDate = null;
                cubit.clearFilters();
              });
            },
          ),
        ],
      ),
    );
  }
}

class CustomerDropdown extends StatefulWidget {
  final Function(String?) onChanged;
  final String? selectedCustomerId;

  const CustomerDropdown({
    Key? key,
    required this.onChanged,
    this.selectedCustomerId,
  }) : super(key: key);

  @override
  _CustomerDropdownState createState() => _CustomerDropdownState();
}

class _CustomerDropdownState extends State<CustomerDropdown> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCubit, CustomerState>(
      builder: (context, state) {
        final cubit = context.read<CustomerCubit>();
        final customers = cubit.customers;

        return DropdownButtonFormField<String>(
          isExpanded: true,
          value: widget.selectedCustomerId,
          hint: Text("اختر العميل"),
          items: customers
              .map((customer) => DropdownMenuItem<String>(
                    value: customer.id.toString(),
                    child: Text(customer.fullName),
                  ))
              .toList(),
          onChanged: widget.onChanged,
        );
      },
    );
  }
}
