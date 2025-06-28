import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_date_picker.dart';
import 'package:goal_master_admin/core/components/custom_drop_down_shimmer_items.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/booking_cubit/booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/customer_dropdown.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/employee_dropdown_selection.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController bookingIdController = TextEditingController();

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
    if (cubit.bookingId != null) {
      bookingIdController.text = cubit.bookingId!;
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
          CustomTextField(
            hint: "رقم الحجز",
            controller: bookingIdController,
            inputType: TextInputType.number,
            // onChanged: (val) {
            //   cubit.updateCustomerId(val);
            // },
          ),
          CustomDropDownShimmerNew(
            label: "",
            hint: "اختر الحالة",
            items: [
              {"id": 0, "name_ar": "غير خالص"},
              {"id": 1, "name_ar": "انتظار قبول الطلب"},
              {"id": 2, "name_ar": "موافَق عليه"},
              {"id": 3, "name_ar": "ملغي"},
              {"id": 4, "name_ar": "خالص"},
            ],
            selectedValue: cubit.status,
            onChanged: (val) {
              cubit.updateStatus(val ?? "");
            },
          ),
          HeightSpace(16.h),
          EmployeeDropdownSelection(cubitContext: widget.cubitContext),
          HeightSpace(16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomerDropdownWidget(
                      onCustomerSelected: (customer) {
                        customerIdController.text = customer.id.toString();
                        cubit.updateCustomerId(customer.id.toString());
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
              cubit.updateBookingId(bookingIdController.text);
              cubit.updateCustomerId(customerIdController.text);

              await cubit.filterBooking();

              Navigator.of(context).pop();

              Future.delayed(Duration(milliseconds: 500), () {
                employeeIdController.clear();
                customerIdController.clear();
                serviceStatusController.clear();
                bookingIdController.clear();
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
