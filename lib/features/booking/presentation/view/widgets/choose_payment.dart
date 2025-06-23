import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/booking/presentation/manager/add_booking_cubit/add_booking_cubit.dart';
import 'package:goal_master_admin/features/booking/presentation/view/widgets/step_title.dart';

class ChoosePayment extends StatefulWidget {
  final PageController controller;

  const ChoosePayment({super.key, required this.controller});

  @override
  State<ChoosePayment> createState() => _ChoosePaymentState();
}

class _ChoosePaymentState extends State<ChoosePayment> {
  int? selectedPaymentType;
  bool _isMonthly = false;

  void selectPayment(int type) {
    setState(() {
      selectedPaymentType = type;
    });
    context.read<AddBookingCubit>().setPaymentType(type);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepTitle(
            title: "اختر طريقة الدفع",
            description: "قم باختيار الطريقة التي ترغب بالدفع من خلالها",
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "هل الحجز شهري؟",
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: _isMonthly,
                  onChanged: (val) {
                    setState(() {
                      _isMonthly = val;
                    });
                    context.read<AddBookingCubit>().setIsMonthly(val);
                  },
                ),
              ],
            ),
          ),
          HeightSpace(20.h),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: CustomTextField(
              hint: "المبلغ المدفوع",
              controller: context.read<AddBookingCubit>().paidAmountController,
              inputType: TextInputType.number,
            ),
          ),
          HeightSpace(20.h),
          _buildPaymentOption(
            title: "الدفع نقدا",
            icon: Icons.wallet,
            type: 1,
          ),
          // _buildPaymentOption(
          //   title: "رصيد المستخدم",
          //   icon: Icons.wallet,
          //   type: 4,
          // ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required IconData icon,
    required int type,
  }) {
    final isSelected = selectedPaymentType == type;

    return ListTile(
      tileColor: isSelected ? Colors.green.withOpacity(0.1) : null,
      leading: Icon(
        icon,
        color: isSelected ? Colors.green : null,
      ),
      trailing:
          isSelected ? Icon(Icons.check_circle, color: Colors.green) : null,
      title: Text(
        title,
        style: AppTextStyles.font16Bold.copyWith(
          color: isSelected ? Colors.green : null,
        ),
      ),
      onTap: () => selectPayment(type),
    );
  }
}
