import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/routing/route_utils.dart';
import 'package:goal_master_admin/core/routing/routes_keys.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';

class ManagerTopUpSheetVisa extends StatefulWidget {
  const ManagerTopUpSheetVisa({super.key});

  @override
  State<ManagerTopUpSheetVisa> createState() => _ManagerTopUpSheetVisaState();
}

class _ManagerTopUpSheetVisaState extends State<ManagerTopUpSheetVisa> {
  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ادخل مبلغ الشحن',
            style: AppTextStyles.font16Bold.copyWith(color: Colors.black),
          ),
          HeightSpace(8.h),
          CustomTextField(
            hint: 'ادخل المبلغ',
            controller: amountController,
            inputType: TextInputType.number,
          ),
          HeightSpace(16.h),
          ButtonApp(
            text: 'تأكيد الشحن',
            backGround: AppColors.primary,
            textColor: Colors.white,
            onTap: () async {
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('من فضلك أدخل مبلغ صحيح')),
                );
                return;
              }

              Navigator.pop(context);

              final res = await push<String>(
                RoutesKeys.kManagerPaymentWebView,
                context,
                extra: {'amount': amount.toStringAsFixed(0)},
              );

              if (!context.mounted) return;
              if (res == 'success') {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );
  }
}
