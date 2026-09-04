import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/styles/app_colors.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/manager_setup/data/model/manager_setup_bootstrap_response.dart';
import 'package:goal_master_admin/features/manager_setup/presentation/view/widgets/add_first_venue/setup_theme.dart';

/// The manager's wallet balance, and a way into the wallet screen.
///
/// This is the screen's only statement of the balance — the hero card used to
/// print the same number a few centimetres above it.
class SetupWalletCard extends StatelessWidget {
  const SetupWalletCard({
    super.key,
    required this.wallet,
    required this.onOpen,
  });

  final WalletSummary wallet;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: SetupColors.tintedSurface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: SetupColors.doneBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primary,
              size: 22.sp,
            ),
          ),
          WidthSpace(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'محفظة مدير الملعب',
                  style: AppTextStyles.font12Medium.copyWith(
                    color: SetupColors.secondaryText,
                  ),
                ),
                HeightSpace(2.h),
                Text(
                  '${wallet.currentBalance.toStringAsFixed(2)} د.ل',
                  style: AppTextStyles.font18Bold,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onOpen,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
            ),
            child: Text(
              'فتح المحفظة',
              style: AppTextStyles.font14Bold.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
