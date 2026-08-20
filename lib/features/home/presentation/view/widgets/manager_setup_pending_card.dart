import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:goal_master_admin/core/components/button_app.dart';
import 'package:goal_master_admin/core/styles/app_text_styles.dart';
import 'package:goal_master_admin/core/styles/spaces.dart';
import 'package:goal_master_admin/features/auth/data/model/login_model/user.dart';

class ManagerSetupPendingCard extends StatelessWidget {
  const ManagerSetupPendingCard({
    super.key,
    required this.user,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
    this.compact = false,
  });

  final User user;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final planName =
        user.currentSubscription?.planName?.trim().isNotEmpty == true
            ? user.currentSubscription!.planName!
            : 'بدون باقة محددة';
    final subscriptionNote = user.isTrialingSubscription
        ? 'الحساب داخل فترة تجريبية. يمكنك تجهيز الملعب الآن، وبعد انتهاء التجربة سيتم الدفع من المحفظة بالبطاقة أو بالكرت.'
        : user.needsSubscriptionPaymentNow
            ? 'فترة التجربة انتهت أو الاشتراك غير مفعل حاليًا. راجع المحفظة لإتمام الدفع ثم أكمل التفعيل.'
            : 'الاشتراك مفعل حاليًا ويمكنك متابعة تجهيز الملعب بشكل طبيعي.';
    final nextStep = user.nextSetupStepLabel;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14.w : 18.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff0D2A1B),
            Color(0xff183F29),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  'مدير جديد',
                  style: AppTextStyles.font12Medium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.stadium_rounded,
                color: Colors.white.withValues(alpha: 0.92),
                size: compact ? 24.sp : 28.sp,
              ),
            ],
          ),
          HeightSpace(16.h),
          Text(
            'ابدأ بتفعيل حساب مدير الملعب',
            style:
                (compact ? AppTextStyles.font18Bold : AppTextStyles.font24Bold)
                    .copyWith(color: Colors.white),
          ),
          HeightSpace(8.h),
          Text(
            'تم إنشاء الحساب بنجاح، لكن التشغيل الكامل يعتمد على إكمال مراحل التأسيس بالترتيب الصحيح من النظام.',
            style: AppTextStyles.font14Regular.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.55,
            ),
          ),
          HeightSpace(12.h),
          Text(
            subscriptionNote,
            style: AppTextStyles.font14Medium.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.5,
            ),
          ),
          HeightSpace(16.h),
          _buildStep('تم إنشاء حساب مدير الملعب', true),
          _buildStep('المحفظة أصبحت جاهزة من الآن', true),
          _buildStep(
            user.needsSubscriptionPaymentNow
                ? 'فعّل الاشتراك من المحفظة أولاً'
                : nextStep,
            false,
          ),
          HeightSpace(16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الباقة الحالية',
                  style: AppTextStyles.font12Medium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                HeightSpace(6.h),
                Text(
                  planName,
                  style: AppTextStyles.font16Bold.copyWith(
                    color: const Color(0xffCFF3B3),
                  ),
                ),
              ],
            ),
          ),
          HeightSpace(16.h),
          ButtonApp(
            text: user.needsSubscriptionPaymentNow ? 'فتح المحفظة' : nextStep,
            onTap: onPrimaryTap,
          ),
          HeightSpace(10.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSecondaryTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: Text(
                'خطة التفعيل',
                style: AppTextStyles.font14Bold.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String title, bool isDone) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isDone ? const Color(0xffA6E46D) : Colors.white70,
            size: 18.sp,
          ),
          WidthSpace(10.w),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.font14Medium.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
