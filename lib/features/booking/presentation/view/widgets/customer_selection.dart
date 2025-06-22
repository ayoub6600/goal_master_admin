import 'package:flutter/material.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_drop_down_shimmer_items.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_customer_cubit/add_customer_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/page_view_cubit/page_view_cubit_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/customer_dropdown.dart';

import 'package:goal_master_admin/features/booking/presentation/view/widgets/step_title.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class CustomerSelection extends StatelessWidget {
  final PageController controller;

  const CustomerSelection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle(
          title: "اختار العميل ",
          description: "اختار العميل المناسب للحجز الذي تريده",
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomDropDownShimmerNew(
            label: "",
            hint: "اختر الحالة",
            items: [
              {"id": 0, "name_ar": "قيد الانتظار"},
              {"id": 1, "name_ar": "قيد المعالجة"},
              {"id": 2, "name_ar": "موافَق عليه"},
              {"id": 3, "name_ar": "ملغي"},
              {"id": 4, "name_ar": "مكتمل"},
            ],
            selectedValue: "cubit.status",
            onChanged: (val) {
              context.read<PageViewCubit>().updateStatus(val ?? "");
              print("تم اختيار الحالة: $val");
              context.read<PageViewCubit>().goToNextPageIfReady(controller);
              //  cubit.updateStatus(val ?? "");
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomerDropdownWidget(
                      onCustomerSelected: (customer) {
                        print("تم اختيار العميل: ${customer.id}");

                        context.read<PageViewCubit>().setCustomerId(
                            customer.id ?? 0, customer.phoneNo ?? "");
                        context
                            .read<PageViewCubit>()
                            .goToNextPageIfReady(controller);
                        // context.read<PageViewCubit>().nextPage();
                        // controller.animateToPage(controller.page!.toInt() + 1,
                        //     duration: const Duration(seconds: 1),
                        //     curve: Curves.fastOutSlowIn);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ButtonApp(
            text: "اضافة عميل",
            onTap: () {
              final nameController = TextEditingController();
              final phoneController = TextEditingController();

              baseBottomSheet(
                context: context,
                hideNavBar: true,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BlocProvider.value(
                    value: context.read<AddCustomerCubit>(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomTextField(
                          controller: nameController,
                          inputType: TextInputType.name,
                          hint: "اسم العميل",
                        ),
                        HeightSpace(20.h),
                        CustomTextField(
                          controller: phoneController,
                          inputType: TextInputType.phone,
                          hint: "رقم الجوال",
                        ),
                        HeightSpace(20.h),
                        BlocConsumer<AddCustomerCubit, AddCustomerState>(
                          listener: (context, state) {
                            if (state is AddCustomerSuccess) {
                              Navigator.pop(context);
                              print("✅ Customer ID Added: ${state.customerId}");

                              context.read<PageViewCubit>().setCustomerId(
                                  int.parse(state.customerId ?? "0"),
                                  phoneController.text);
                              context
                                  .read<PageViewCubit>()
                                  .goToNextPageIfReady(controller);

                              showCustomSuccessToast("تم اضافة العميل بنجاح");
                            } else if (state is AddCustomerFailure) {
                              CustomFailureToastWidget(
                                  toastText: state.message);
                            }
                          },
                          builder: (context, state) {
                            if (state is AddCustomerLoading) {
                              return CircularProgressIndicator();
                            }

                            return ButtonApp(
                              text: "اضافة",
                              textColor: Colors.white,
                              backGround: AppColors.primary,
                              onTap: () {
                                final name = nameController.text.trim();
                                final phone = phoneController.text.trim();
                                if (name.isEmpty || phone.isEmpty) {
                                  CustomFailureToastWidget(
                                      toastText: "يرجى تعبئة جميع الحقول");
                                  return;
                                }
                                context.read<AddCustomerCubit>().addCustomer(
                                      fullName: name,
                                      phone: phone,
                                    );
                              },
                            );
                          },
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
