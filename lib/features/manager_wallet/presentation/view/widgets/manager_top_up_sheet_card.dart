import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/components/custom_failure_toast.dart';
import 'package:goal_master_admin/core/components/custom_success_toast.dart';
import 'package:goal_master_admin/core/components/custom_text_field/custom_app_form_text_field.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_wallet/presentation/manager/manager_wallet_card_cubit/manager_wallet_card_cubit.dart';

class ManagerTopUpSheetCard extends StatelessWidget {
  const ManagerTopUpSheetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ManagerWalletCardCubit>();

    return BlocConsumer<ManagerWalletCardCubit, ManagerWalletCardState>(
      listener: (context, state) {
        if (state is ManagerWalletCardSuccess) {
          showCustomSuccessToast(state.message);
          cubit.codeController.clear();
          Navigator.of(context).pop(true);
        } else if (state is ManagerWalletCardFailure) {
          showCustomFailureToast(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is ManagerWalletCardLoading;

        return AbsorbPointer(
          absorbing: isLoading,
          child: Padding(
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
                  'ادخل رقم الكرت',
                  style: AppTextStyles.font16Bold.copyWith(
                    color: Colors.black,
                  ),
                ),
                HeightSpace(8.h),
                CustomTextField(
                  hint: 'ادخل الرقم',
                  controller: cubit.codeController,
                  inputType: TextInputType.text,
                ),
                HeightSpace(16.h),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ButtonApp(
                        text: 'تأكيد الشحن',
                        backGround: AppColors.primary,
                        textColor: Colors.white,
                        onTap: cubit.chargeCard,
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
