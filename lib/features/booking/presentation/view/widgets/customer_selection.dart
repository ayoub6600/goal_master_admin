import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goal_master_admin/core/components/bottom_sheet/base_bottom_sheet.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_drop_down_shimmer_items.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_customer_cubit/add_customer_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/page_view_cubit/page_view_cubit_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/customer_dropdown.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/step_title.dart';
import 'package:goal_master_admin/features/profail/data/model/customer_list_response.dart';

class CustomerSelection extends StatefulWidget {
  final PageController controller;

  const CustomerSelection({super.key, required this.controller});

  @override
  State<CustomerSelection> createState() => _CustomerSelectionState();
}

class _CustomerSelectionState extends State<CustomerSelection> {
  Customer? selectedCustomer;

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
              context
                  .read<PageViewCubit>()
                  .goToNextPageIfReady(widget.controller);
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
                    if (selectedCustomer != null) ...[
                      HeightSpace(16.h),
                      Text(
                          "تم اختيار العميل: ${selectedCustomer!.fullName ?? 'بدون اسم'} (${selectedCustomer!.phoneNo ?? 'بدون رقم'})",
                          style: AppTextStyles.font16Regular),
                    ],
                    HeightSpace(16.h),
                    CustomerDropdownWidget(
                      onCustomerSelected: (customer) {
                        setState(() {
                          selectedCustomer = customer;
                        });
                        context.read<PageViewCubit>().setCustomerId(
                            customer.id ?? 0,
                            customer.phoneNo ?? "",
                            customer.fullName ?? "");
                        context
                            .read<PageViewCubit>()
                            .goToNextPageIfReady(widget.controller);
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
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider.value(
                          value: context.read<AddCustomerCubit>()),
                      BlocProvider.value(value: context.read<PageViewCubit>()),
                    ],
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
                              final newCustomer = Customer(
                                id: int.tryParse(state.customerId ?? "0") ?? 0,
                                fullName: nameController.text,
                                phoneNo: phoneController.text,
                                phoneVerified: 1,
                              );

                              setState(() {
                                selectedCustomer = newCustomer;
                              });

                              Navigator.pop(context);

                              context.read<PageViewCubit>().setCustomerId(
                                  newCustomer.id ?? 0,
                                  newCustomer.phoneNo ?? "",
                                  newCustomer.fullName ?? "");
                              context
                                  .read<PageViewCubit>()
                                  .goToNextPageIfReady(widget.controller);

                              showCustomSuccessToast("تم اضافة العميل بنجاح");
                            } else if (state is AddCustomerFailure) {
                              showCustomFailureToast(
                                  "يرجى التأكد من صحة البيانات المدخلة");
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
